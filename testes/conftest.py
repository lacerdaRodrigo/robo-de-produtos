"""Fixtures e fakes compartilhados.

Os fakes implementam as portas do PRD 4.2. Testar contra o contrato do
projeto, e nao contra o detalhe interno de requests/smtplib, e o que faz o
teste sobreviver a troca prevista em C04.
"""

from __future__ import annotations

import json
from datetime import datetime, timedelta, timezone
from decimal import Decimal
from pathlib import Path

import pytest

from robo_livelo.extrator import TITULO_SECAO_PARCEIROS
from robo_livelo.modelos import LojaFavorita, Mensagem, Parceiro

PASTA_FIXTURES = Path(__file__).parent / "fixtures"

FUSO_BRASILIA = timezone(timedelta(hours=-3))

# Titulo real da secao de destaque (carrossel), usada como "vizinha" nos
# payloads de teste para provar que a busca da secao principal e por titulo,
# nao por indice (C06) — o schema de item dessa secao e diferente do da
# listagem completa (partnerCode/details, em vez de id/name direto).
TITULO_SECAO_DESTAQUE = "[AP] - Mosaico Carrossel de Parceiros - Página Compre e Pontue"


@pytest.fixture
def html_exemplo() -> str:
    """HTML real da pagina da Livelo (V1), recortado em 20 parceiros."""
    return (PASTA_FIXTURES / "exemplo_parceiros.html").read_text(encoding="utf-8")


@pytest.fixture
def payload_exemplo() -> str:
    """Payload JSON real da Livelo, recortado (schema confirmado ao vivo em 2026-08)."""
    texto = (PASTA_FIXTURES / "payload_parceiros.json").read_text(encoding="utf-8")
    return envolver_payload_em_html(texto)


@pytest.fixture
def favoritas() -> list[LojaFavorita]:
    return [
        LojaFavorita(nome="Natura", categoria="Beleza"),
        LojaFavorita(nome="O Boticário", categoria="Beleza"),
        LojaFavorita(nome="Casas Bahia", categoria="Marketplace / Varejo Geral"),
        LojaFavorita(nome="Magalu", categoria="Marketplace / Varejo Geral"),
        LojaFavorita(nome="Pontofrio", categoria="Marketplace / Varejo Geral"),
        LojaFavorita(nome="Petlove", categoria="Pet"),
        LojaFavorita(nome="C&A", categoria="Moda", apelidos=("CEA",)),
        LojaFavorita(nome="Booking.com", categoria="Viagem", apelidos=("Booking com",)),
    ]


def faz_parceiro(
    nome: str = "Natura",
    pontos: str = "4",
    *,
    moeda: str = "R$",
    link: str = "https://www.livelo.com.br/juntar-pontos/parceiros/natura/NAT",
    em_promocao: bool = True,
    anteriores: str | None = None,
    clube: str | None = None,
    prefixo_ate: bool = False,
    base: str | None = None,
    inicio: datetime | None = None,
    fim: datetime | None = None,
    campanha: str | None = None,
    descricao_campanha: str | None = None,
) -> Parceiro:
    return Parceiro(
        nome=nome,
        pontos_atuais=Decimal(pontos),
        moeda=moeda,
        link=link,
        em_promocao=em_promocao,
        pontos_anteriores=Decimal(anteriores) if anteriores is not None else None,
        pontos_clube=Decimal(clube) if clube is not None else None,
        prefixo_ate=prefixo_ate,
        pontos_base=Decimal(base) if base is not None else None,
        inicio_promocao=inicio,
        fim_promocao=fim,
        campanha=campanha,
        descricao_campanha=descricao_campanha,
    )


def formatar_data_livelo(momento: datetime) -> str:
    """Formato customizado da Livelo: "2026-08-13-23:59:00 GMT-03:00" (nao ISO8601)."""
    offset = momento.utcoffset() or timedelta(0)
    sinal = "+" if offset >= timedelta(0) else "-"
    minutos_totais = int(abs(offset).total_seconds() // 60)
    horas, minutos = divmod(minutos_totais, 60)
    return momento.strftime("%Y-%m-%d-%H:%M:%S") + f" GMT{sinal}{horas:02d}:{minutos:02d}"


def envolver_payload_em_html(json_texto: str) -> str:
    """Embrulha um payload JSON no <script id="__NEXT_DATA__"> como a pagina real faz."""
    return (
        "<!doctype html><html><body>"
        f'<script id="__NEXT_DATA__" type="application/json">{json_texto}</script>'
        "</body></html>"
    )


def monta_item_parceiro(
    *,
    id: str = "NAT",
    nome: str = "Natura",
    link: str = "https://www.livelo.com.br/juntar-pontos/parceiros/natura/NAT",
    currency: str = "R$",
    parity: str = "4",
    parity_bau: str | None = None,
    parity_club: str | None = None,
    promotion: bool = False,
    date_start: str | None = None,
    date_end: str | None = None,
    active_campaign: str = "BAU",
    separator_slug: str = "IGUAL",
    legal_terms: str = "",
) -> dict:
    """Item sintetico no formato real de `configPartners` (RF14)."""
    bloco_parity: dict = {
        "currency": currency,
        "currencyValue": 1,
        "parity": float(parity),
        "parityClub": float(parity_club) if parity_club is not None else float(parity),
        "parityBau": float(parity_bau) if parity_bau is not None else float(parity),
        "legalTerms": legal_terms,
        "separator": "=" if separator_slug == "IGUAL" else "<",
        "promotion": promotion,
        "separatorSlug": separator_slug,
        "activeCampaign": active_campaign,
        "categoryParities": [],
    }
    if date_start is not None:
        bloco_parity["dateStart"] = date_start
    if date_end is not None:
        bloco_parity["dateEnd"] = date_end

    return {
        "id": id,
        "name": nome,
        "link": link,
        "partnerDetailsPage": link,
        "categories": "todos",
        "parity": bloco_parity,
    }


def monta_payload(*itens: dict, titulo: str = TITULO_SECAO_PARCEIROS) -> dict:
    """Payload completo, com a secao de destaque (schema diferente) antes da
    listagem de propósito — prova que a extração busca por título, não índice.
    """
    secao_destaque = {
        "type": "carrossel",
        "props": {
            "title": TITULO_SECAO_DESTAQUE,
            "configPartners": [
                {"partnerCode": "BOK", "details": {"id": "BOK", "name": "Booking com"}}
            ],
        },
    }
    secao_listagem = {
        "type": "listagem",
        "props": {"title": titulo, "configPartners": list(itens)},
    }
    return {"props": {"pageProps": {"page": {"components": [secao_destaque, secao_listagem]}}}}


def monta_html_payload(*itens: dict, titulo: str = TITULO_SECAO_PARCEIROS) -> str:
    return envolver_payload_em_html(json.dumps(monta_payload(*itens, titulo=titulo)))


class FonteFake:
    """Porta FonteDePagina."""

    def __init__(self, html: str = "", erro: Exception | None = None) -> None:
        self.html = html
        self.erro = erro
        self.chamadas = 0

    def obter_html(self) -> str:
        self.chamadas += 1
        if self.erro:
            raise self.erro
        return self.html


class CatalogoFake:
    """Porta CatalogoFavoritas."""

    def __init__(self, lojas: list[LojaFavorita], erro: Exception | None = None) -> None:
        self._lojas = lojas
        self.erro = erro

    def listar(self) -> list[LojaFavorita]:
        if self.erro:
            raise self.erro
        return self._lojas


class NotificadorFake:
    """Porta Notificador."""

    def __init__(self, erro: Exception | None = None) -> None:
        self.enviadas: list[Mensagem] = []
        self.erro = erro

    def enviar(self, mensagem: Mensagem) -> None:
        if self.erro:
            raise self.erro
        self.enviadas.append(mensagem)

    @property
    def foi_chamado(self) -> bool:
        return bool(self.enviadas)
