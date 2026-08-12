"""Estruturas de dados do dominio. Nucleo puro: nao faz I/O.

Ver PRD secao 5.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
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
    pontos_base: Decimal | None = None
    inicio_promocao: datetime | None = None
    fim_promocao: datetime | None = None
    campanha: str | None = None


@dataclass(frozen=True, slots=True)
class LojaFavorita:
    """Uma loja monitorada, vinda da configuracao (PRD 5.3).

    `multiplicador` e `piso_pontos` sao o limiar proprio da loja (RN28).
    `None` significa "usa o padrao global" — a mesma semantica do NULL nas
    colunas do banco. Ninguem consome esses dois ainda: quem vai usa-los e
    o `alertas.py` da V2.2. Estao aqui porque o adaptador ja le as colunas.
    """

    nome: str
    categoria: str
    apelidos: tuple[str, ...] = field(default_factory=tuple)
    multiplicador: Decimal | None = None
    piso_pontos: Decimal | None = None


@dataclass(frozen=True, slots=True)
class Preferencias:
    """Padroes globais de alerta (RN28) e o tier do leitor (RN23).

    Os valores default sao os do PRD-V2 §6.1, calibrados contra a medicao de
    2026-08-09: com 2,0 e piso 4, aquele dia produziria um e-mail com 12
    lojas de 126 favoritas. Existem aqui para o projeto rodar sem banco.
    """

    multiplicador_padrao: Decimal = Decimal("2.0")
    piso_pontos_padrao: Decimal = Decimal("4")
    assinante_clube: bool = False


@dataclass(frozen=True, slots=True)
class Mensagem:
    """O e-mail pronto para envio (RF07, RF08)."""

    assunto: str
    corpo_html: str
    corpo_texto: str
