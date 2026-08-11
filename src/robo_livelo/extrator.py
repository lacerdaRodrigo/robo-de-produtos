"""Nucleo puro: transforma o payload JSON da pagina em objetos Parceiro.

Nao toca a rede. Recebe uma string (a pagina inteira), devolve estrutura.
Ver PRD secao 6 e PRD-V2 RF14. Regras aplicadas aqui: RN06, RN11, RN12,
RN15, RN21.
"""

from __future__ import annotations

import json
import logging
from datetime import datetime
from decimal import Decimal, InvalidOperation

from bs4 import BeautifulSoup

from robo_livelo.modelos import Parceiro

_log = logging.getLogger(__name__)

# A Livelo pode reordenar as secoes da pagina (C06) — por isso a secao e
# achada pelo titulo, nunca por indice fixo em `components`.
TITULO_SECAO_PARCEIROS = "C&P - Site - Listagem de Parceiros"

# separatorSlug "ATE" para o prefixo "Ate X pontos" (RN12): hipotese, sem
# exemplo real confirmado ainda. So "IGUAL" foi observado em producao.
_ATE_SEPARATOR_SLUG = "ATE"


def _texto_do_payload(html: str) -> str | None:
    """Localiza o <script id="__NEXT_DATA__"> dentro do HTML da pagina."""
    sopa = BeautifulSoup(html, "lxml")
    tag = sopa.find("script", id="__NEXT_DATA__")
    if tag is None or not tag.string:
        _log.warning("Script __NEXT_DATA__ nao encontrado na pagina.")
        return None
    return tag.string


def _config_partners(dados: dict) -> list[dict]:
    """Acha a lista de parceiros pelo titulo da secao, nao pelo indice (C06)."""
    props_raiz = dados.get("props") or {}
    page_props = props_raiz.get("pageProps") or {}
    page = page_props.get("page") or {}
    componentes = page.get("components") or []

    for componente in componentes:
        if not isinstance(componente, dict):
            continue
        props = componente.get("props") or {}
        if props.get("title") == TITULO_SECAO_PARCEIROS:
            return props.get("configPartners") or []

    _log.warning("Secao %r nao encontrada nos components da pagina.", TITULO_SECAO_PARCEIROS)
    return []


def _parse_data(texto: str | None) -> datetime | None:
    """dateStart/dateEnd vem como "2026-08-13-23:59:00 GMT-03:00", nao ISO8601.

    Data ausente ou ilegivel vira None sem derrubar o parceiro (RF14).
    """
    if not texto:
        return None
    limpo = texto.replace("GMT", "").strip()
    try:
        return datetime.strptime(limpo, "%Y-%m-%d-%H:%M:%S %z")
    except ValueError:
        _log.warning("Data de validade ilegivel, descartada: %r", texto)
        return None


def _para_decimal(valor) -> Decimal:
    return Decimal(str(valor))


def _para_parceiro(item: dict, *, agora: datetime) -> Parceiro | None:
    if not isinstance(item, dict):
        _log.warning("Item do payload nao e um objeto, descartado: %r", item)
        return None

    nome = item.get("name")
    parity = item.get("parity") or {}
    if not isinstance(parity, dict):
        parity = {}

    try:
        if not nome:
            raise KeyError("name")
        pontos_atuais = _para_decimal(parity["parity"])
    except (KeyError, TypeError, InvalidOperation):
        _log.warning(
            "Item do payload sem nome ou pontuacao legivel, descartado: %r", item.get("id")
        )
        return None

    pontos_base = None
    if parity.get("parityBau") is not None:
        try:
            pontos_base = _para_decimal(parity["parityBau"])
        except InvalidOperation:
            pontos_base = None

    pontos_clube = None
    if parity.get("parityClub") is not None:
        try:
            valor_clube = _para_decimal(parity["parityClub"])
        except InvalidOperation:
            valor_clube = None
        if valor_clube is not None and valor_clube != pontos_atuais:  # so quando ha distincao
            pontos_clube = valor_clube

    inicio_promocao = _parse_data(parity.get("dateStart"))
    fim_promocao = _parse_data(parity.get("dateEnd"))

    em_promocao = bool(parity.get("promotion", False))
    if em_promocao and fim_promocao is not None and fim_promocao < agora:  # RN21
        em_promocao = False

    return Parceiro(
        nome=nome,
        pontos_atuais=pontos_atuais,
        moeda=parity.get("currency") or "",
        link=(item.get("link") or item.get("partnerDetailsPage") or "").strip(),
        em_promocao=em_promocao,
        pontos_clube=pontos_clube,
        prefixo_ate=(parity.get("separatorSlug") or "").strip().upper() == _ATE_SEPARATOR_SLUG,
        pontos_base=pontos_base,
        inicio_promocao=inicio_promocao,
        fim_promocao=fim_promocao,
        campanha=parity.get("activeCampaign"),
    )


def extrair_parceiros(html: str, *, agora: datetime) -> list[Parceiro]:
    """Devolve os parceiros presentes no payload JSON embutido na pagina.

    Parceiro malformado e descartado e registrado no log, sem derrubar a
    execucao (PRD 6.4). Repetido conta uma vez so (RN06). Se a secao do
    payload nao for achada, devolve lista vazia — quem transforma isso em
    falha e o limiar RN13, em principal.py.
    """
    texto = _texto_do_payload(html)
    if texto is None:
        return []

    try:
        dados = json.loads(texto, parse_float=Decimal, parse_int=Decimal)
    except json.JSONDecodeError:
        _log.warning("Payload __NEXT_DATA__ nao e JSON valido.")
        return []
    if not isinstance(dados, dict):
        _log.warning("Payload __NEXT_DATA__ nao e um objeto JSON.")
        return []

    parceiros: list[Parceiro] = []
    vistos: set[str] = set()
    for item in _config_partners(dados):
        parceiro = _para_parceiro(item, agora=agora)
        if parceiro is None:
            continue
        if parceiro.nome in vistos:  # RN06
            continue
        vistos.add(parceiro.nome)
        parceiros.append(parceiro)

    return parceiros
