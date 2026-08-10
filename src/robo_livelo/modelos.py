"""Estruturas de dados do dominio. Nucleo puro: nao faz I/O.

Ver PRD secao 5.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from decimal import Decimal

DOMINIO_LIVELO = "livelo.com.br"


@dataclass(frozen=True, slots=True)
class Parceiro:
    """Um parceiro lido da pagina, ja normalizado. Imutavel (PRD 5.4)."""

    nome: str
    pontos_atuais: Decimal
    moeda: str
    link: str
    em_promocao: bool = False
    pontos_anteriores: Decimal | None = None
    pontos_clube: Decimal | None = None
    prefixo_ate: bool = False


@dataclass(frozen=True, slots=True)
class LojaFavorita:
    """Uma loja monitorada, vinda da configuracao (PRD 5.3)."""

    nome: str
    categoria: str
    apelidos: tuple[str, ...] = field(default_factory=tuple)


@dataclass(frozen=True, slots=True)
class Mensagem:
    """O e-mail pronto para envio (RF07, RF08)."""

    assunto: str
    corpo_html: str
    corpo_texto: str
