"""Nucleo puro: transforma o payload JSON da pagina em objetos Parceiro.

Nao toca a rede. Recebe uma string (a pagina inteira), devolve estrutura.
Ver PRD secao 6 e PRD-V2 RF14. Regras aplicadas aqui: RN06, RN11, RN12,
RN15, RN21.
"""

from __future__ import annotations

import json
import logging
import re
from datetime import datetime
from decimal import Decimal, InvalidOperation

from bs4 import BeautifulSoup

from robo_livelo.modelos import Parceiro

_log = logging.getLogger(__name__)

# A Livelo pode reordenar as secoes da pagina (C06) — por isso a secao e
# achada pelo titulo, nunca por indice fixo em `components`. Titulo mudou de
# "C&P - Site - Listagem de Parceiros" para "C&P - Site/App - Listagem de
# Parceiros" em 2026-08-12, confirmado contra a pagina real.
TITULO_SECAO_PARCEIROS = "C&P - Site/App - Listagem de Parceiros"

# separatorSlug "ATE" para o prefixo "Ate X pontos" (RN12). Confirmado contra
# a pagina real em 2026-08-11: 36 dos 270 itens usavam "ATE", 223 "IGUAL".
_ATE_SEPARATOR_SLUG = "ATE"
_ID_EXTERNO_VALIDO = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_-]{0,99}$")


class CatalogoLiveloInvalido(ValueError):
    """O payload possui identidades conflitantes e não pode ser publicado."""


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


def _texto_legal(bruto) -> str | None:
    """`legalTerms` vem em HTML curto, ex.: "<p>Campanha valida...</p>".

    RN07: todo dado do site e hostil, entao so o texto sai daqui, nunca a
    marcacao crua. Campanha sem letra miuda chega como "<p><br></p>" — texto
    vazio vira None, nao string vazia, mesma semantica de pontos_base ausente.
    """
    if not bruto or not isinstance(bruto, str):
        return None
    texto = BeautifulSoup(bruto, "lxml").get_text(separator=" ", strip=True)
    return texto or None


def _categorias_do_item(bruto) -> tuple[str, ...]:
    """Preserva os códigos de categoria fornecidos pela Livelo.

    O payload real usa uma string separada por espaços. ``todos`` é apenas o
    filtro geral da página, não uma categoria de negócio. Uma lista também é
    aceita para tolerar uma evolução compatível do payload.
    """
    if isinstance(bruto, str):
        candidatas = bruto.split()
    elif isinstance(bruto, list):
        candidatas = [str(valor) for valor in bruto]
    else:
        candidatas = []

    resultado: list[str] = []
    vistos: set[str] = set()
    for candidata in candidatas:
        categoria = candidata.strip().casefold()
        if not categoria or categoria == "todos" or categoria in vistos:
            continue
        vistos.add(categoria)
        resultado.append(categoria)
    return tuple(resultado)


def _para_parceiro(item: dict, *, agora: datetime) -> Parceiro | None:
    if not isinstance(item, dict):
        _log.warning("Item do payload nao e um objeto, descartado: %r", item)
        return None

    nome = item.get("name")
    id_externo = str(item.get("id") or "").strip()
    parity_bruta = item.get("parity")
    parity = parity_bruta or {}
    if not isinstance(parity, dict):
        parity = {}

    try:
        if not nome:
            raise KeyError("name")
        pontos_atuais = _para_decimal(parity["parity"])
    except (KeyError, TypeError, InvalidOperation):
        # Item sem `parity` nenhuma e caso conhecido e esperado: sao os
        # produtos da propria Livelo (LVA, LVM, LVR...) e as entradas de
        # teste dela (XXX, SSG), que nao tem pontuacao por nao serem
        # parceiro. Gritar WARNING a cada execucao por isso afogaria o
        # aviso que importa, entao esses caem em DEBUG e o resumo vai em
        # uma linha so, ao fim da extracao.
        if not parity_bruta:
            _log.debug("Item do payload sem pontuacao (nao e parceiro): %r", item.get("id"))
        else:
            _log.warning(
                "Item do payload sem nome ou pontuacao legivel, descartado: %r", item.get("id")
            )
        return None

    if not _ID_EXTERNO_VALIDO.fullmatch(id_externo):
        raise CatalogoLiveloInvalido(
            f"ID externo ausente ou inválido no catálogo Livelo: {id_externo!r}."
        )

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
        id_externo=id_externo,
        categorias=_categorias_do_item(item.get("categories")),
        em_promocao=em_promocao,
        pontos_clube=pontos_clube,
        prefixo_ate=(parity.get("separatorSlug") or "").strip().upper() == _ATE_SEPARATOR_SLUG,
        pontos_base=pontos_base,
        inicio_promocao=inicio_promocao,
        fim_promocao=fim_promocao,
        campanha=parity.get("activeCampaign"),
        descricao_campanha=_texto_legal(parity.get("legalTerms")),
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
    por_id: dict[str, Parceiro] = {}
    descartados = 0
    for item in _config_partners(dados):
        parceiro = _para_parceiro(item, agora=agora)
        if parceiro is None:
            descartados += 1
            continue
        anterior = por_id.get(parceiro.id_externo)
        if anterior is not None:
            if anterior != parceiro:
                raise CatalogoLiveloInvalido(
                    f"ID externo conflitante no catálogo Livelo: {parceiro.id_externo!r}."
                )
            continue
        por_id[parceiro.id_externo] = parceiro
        parceiros.append(parceiro)

    if descartados:
        _log.info("Itens do payload sem pontuacao, ignorados: %d", descartados)

    return parceiros
