"""Estruturas imutaveis do dominio Shopping Inter (PRD-V3, secao 8)."""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from decimal import Decimal


@dataclass(frozen=True, slots=True)
class LojaInter:
    """Uma loja normalizada da fonte publica do Shopping Inter."""

    id_externo: str
    slug: str
    nome: str
    cashback_principal_texto: str
    cashback_principal_valor: Decimal | None
    cashback_secundario_texto: str | None = None
    cashback_secundario_valor: Decimal | None = None
    etiqueta: str | None = None
    descricao_principal: str | None = None
    descricao_secundaria: str | None = None


@dataclass(frozen=True, slots=True)
class FavoritaInter:
    """Uma escolha local ligada ao identificador externo, nunca ao nome."""

    id_externo: str
    nome: str


@dataclass(frozen=True, slots=True)
class CashbackFavoritaInter:
    """Como uma favorita apareceu numa execucao do Inter."""

    favorita: FavoritaInter
    loja: LojaInter | None = None

    @property
    def encontrada(self) -> bool:
        return self.loja is not None

    @property
    def nome(self) -> str:
        return self.loja.nome if self.loja else self.favorita.nome


@dataclass(frozen=True, slots=True)
class RetratoInter:
    """Snapshot atomico que alimenta exclusivamente a area do Inter."""

    momento: datetime
    lojas_lidas: int
    lojas_validas: int
    versao: str
    favoritas: tuple[CashbackFavoritaInter, ...] = field(default_factory=tuple)

    @property
    def favoritas_encontradas(self) -> int:
        return sum(item.encontrada for item in self.favoritas)
