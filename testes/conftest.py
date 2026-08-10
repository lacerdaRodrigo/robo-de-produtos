"""Fixtures e fakes compartilhados.

Os fakes implementam as portas do PRD 4.2. Testar contra o contrato do
projeto, e nao contra o detalhe interno de requests/smtplib, e o que faz o
teste sobreviver a troca prevista em C04.
"""

from __future__ import annotations

from decimal import Decimal
from pathlib import Path

import pytest

from robo_livelo.modelos import LojaFavorita, Mensagem, Parceiro

PASTA_FIXTURES = Path(__file__).parent / "fixtures"


@pytest.fixture
def html_exemplo() -> str:
    """HTML real da pagina da Livelo, recortado em 20 parceiros."""
    return (PASTA_FIXTURES / "exemplo_parceiros.html").read_text(encoding="utf-8")


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
    anteriores: str | None = "2",
    clube: str | None = None,
    prefixo_ate: bool = False,
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
    )


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
