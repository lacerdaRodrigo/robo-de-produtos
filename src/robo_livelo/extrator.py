"""Nucleo puro: transforma o HTML da pagina em objetos Parceiro.

Nao toca a rede. Recebe uma string, devolve estrutura. Ver PRD secao 6.
Regras aplicadas aqui: RN06, RN11, RN12, RN15.
"""

from __future__ import annotations

import logging
import re
from decimal import Decimal, InvalidOperation

from bs4 import BeautifulSoup

from robo_livelo.modelos import Parceiro

_log = logging.getLogger(__name__)

# Seletores da pagina da Livelo. Sao a parte mais fragil do projeto (C04):
# se a Livelo mudar o layout, e aqui que quebra, e RN13 e quem avisa.
_SELETOR_LINK = '[data-testid="a_PartnerCard_card_link"]'
_SELETOR_CARD = '[data-testid="div_PartnerCard"]'
_SELETOR_LOGO = '[data-testid="img_PartnerCard_partnerImage"]'
_SELETOR_TAG_PROMOCAO = '[data-testid="span_PartnerCard_promotionTag"]'

_PREFIXO_LOGO = "Logo "
_MARCADOR_CLUBE = "Clube"

# "Ate 4 pontos por R$ 1" / "2 pontos por U$ 1"
_PONTOS = re.compile(
    r"(?P<ate>At[eé]\s+)?(?P<valor>\d+(?:[.,]\d+)?)\s+pontos?\s+por\s+(?P<moeda>R\$|U\$)",
    re.IGNORECASE,
)
# "Eram 1 ponto" / "Eram 2 pontos"
_ANTERIORES = re.compile(r"Eram\s+(?P<valor>\d+(?:[.,]\d+)?)\s+pontos?", re.IGNORECASE)


def _para_decimal(texto: str) -> Decimal:
    """Converte o numero como a Livelo escreve. Decimal, nunca float (PRD 5.4)."""
    return Decimal(texto.replace(".", "").replace(",", "."))


def _nome_do_card(card, link) -> str | None:
    """Le o nome exibido. RN15: usa o alt do logo, com o texto do link como reserva."""
    logo = card.select_one(_SELETOR_LOGO)
    alt = (logo.get("alt") or "").strip() if logo else ""
    if alt.startswith(_PREFIXO_LOGO):
        alt = alt[len(_PREFIXO_LOGO) :].strip()
    if alt:
        return alt
    texto = link.get_text(" ", strip=True)
    return texto or None


def extrair_parceiros(html: str) -> list[Parceiro]:
    """Devolve os parceiros presentes no HTML.

    Parceiro malformado e descartado e registrado no log, sem derrubar a
    execucao (PRD 6.4). Repetido conta uma vez so (RN06).
    """
    sopa = BeautifulSoup(html, "lxml")
    parceiros: list[Parceiro] = []
    vistos: set[str] = set()

    for link in sopa.select(_SELETOR_LINK):
        card = link.select_one(_SELETOR_CARD)
        if card is None:
            continue

        nome = _nome_do_card(card, link)
        if not nome:
            _log.warning("Card sem nome identificavel, descartado.")
            continue

        if nome in vistos:  # RN06
            continue

        texto = card.get_text(" ", strip=True)
        base, _, clube = texto.partition(_MARCADOR_CLUBE)

        achado = _PONTOS.search(base)
        if achado is None:
            _log.warning("Parceiro %r sem pontuacao legivel, descartado.", nome)
            continue

        try:
            pontos_atuais = _para_decimal(achado.group("valor"))
            anteriores = _ANTERIORES.search(base)
            pontos_anteriores = _para_decimal(anteriores.group("valor")) if anteriores else None

            pontos_clube = None
            if clube:
                achado_clube = _PONTOS.search(clube)
                if achado_clube:
                    pontos_clube = _para_decimal(achado_clube.group("valor"))
        except (InvalidOperation, ValueError):
            _log.warning("Parceiro %r com valor nao numerico, descartado.", nome)
            continue

        vistos.add(nome)
        parceiros.append(
            Parceiro(
                nome=nome,
                pontos_atuais=pontos_atuais,
                moeda=achado.group("moeda").upper(),  # RN11: nunca converte
                link=(link.get("href") or "").strip(),
                em_promocao=card.select_one(_SELETOR_TAG_PROMOCAO) is not None,
                pontos_anteriores=pontos_anteriores,
                pontos_clube=pontos_clube,
                prefixo_ate=bool(achado.group("ate")),  # RN12
            )
        )

    return parceiros
