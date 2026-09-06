"""Modelos imutaveis do catalogo Pichau.

Valores financeiros mantem o texto original e, quando possivel, um Decimal
para persistencia. Nenhuma imagem faz parte do contrato.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from decimal import Decimal
from typing import Literal

DisponibilidadePichau = Literal["disponivel", "esgotado", "pre_venda", "nao_informado"]


@dataclass(frozen=True, slots=True)
class PichauProduto:
    id_externo: str
    nome: str
    url_produto: str
    sku: str | None = None
    marca: str | None = None
    categoria_externa: str = "PC Gamer"
    disponibilidade: DisponibilidadePichau = "nao_informado"
    preco_original_texto: str | None = None
    preco_original_valor: Decimal | None = None
    preco_pix_texto: str | None = None
    preco_pix_valor: Decimal | None = None
    desconto_pix_texto: str | None = None
    desconto_pix_valor: Decimal | None = None
    preco_cartao_texto: str | None = None
    preco_cartao_valor: Decimal | None = None
    parcelamento: str | None = None
    valor_parcela_texto: str | None = None
    sem_juros: bool | None = None
    estoque_texto: str | None = None
    etiquetas: tuple[str, ...] = field(default_factory=tuple)


@dataclass(frozen=True, slots=True)
class PaginaPichau:
    pagina: int
    por_pagina: int
    total: int
    ultima: bool
    itens_lidos: int
    produtos: tuple[PichauProduto, ...]


@dataclass(frozen=True, slots=True)
class ResumoColetaPichau:
    iniciada_em: datetime
    concluida_em: datetime
    total_declarado: int
    paginas: int
    itens_lidos: int
    itens_unicos: int
    duplicados: int
    tentativas: int = 1
    degradada: bool = False
