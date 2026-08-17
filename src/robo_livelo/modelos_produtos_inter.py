"""Estruturas imutaveis do catalogo de produtos diretos (PRD-V4 §8)."""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from decimal import Decimal


@dataclass(frozen=True, slots=True)
class LojaDiretaInter:
    """Vendedor da area Compre direto, separado da loja da V3."""

    id_externo: str
    slug: str
    nome: str
    selecionada: bool = False
    ativa: bool = True


@dataclass(frozen=True, slots=True)
class ProdutoDiretoInter:
    """Oferta de um produto em uma loja, tal como veio de uma listagem."""

    id_externo: str
    nome: str
    caminho: str
    marca: str | None = None
    categoria: str | None = None
    preco_cheio_texto: str | None = None
    preco_cheio_valor: Decimal | None = None
    preco_atual_texto: str | None = None
    preco_atual_valor: Decimal | None = None
    desconto_texto: str | None = None
    desconto_valor: Decimal | None = None
    desconto_percentual_texto: str | None = None
    desconto_percentual_valor: Decimal | None = None
    cashback_texto: str | None = None
    cashback_valor: Decimal | None = None
    cashback_percentual_texto: str | None = None
    cashback_percentual_valor: Decimal | None = None
    preco_liquido_texto: str | None = None
    preco_liquido_valor: Decimal | None = None
    parcelamento: str | None = None
    estoque: int | None = None
    etiquetas: tuple[str, ...] = field(default_factory=tuple)


@dataclass(frozen=True, slots=True)
class PaginaProdutosInter:
    """Uma pagina validada da fonte, sem efeitos colaterais."""

    offset: int
    limite: int
    total: int
    ultima: bool
    itens_lidos: int
    produtos: tuple[ProdutoDiretoInter, ...]


@dataclass(frozen=True, slots=True)
class ResumoColetaProdutosInter:
    """Metricas que acompanham a publicacao atomica de uma loja."""

    iniciada_em: datetime
    concluida_em: datetime
    total_declarado: int
    paginas: int
    itens_lidos: int
    itens_unicos: int
    duplicados: int
