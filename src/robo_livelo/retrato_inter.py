"""Nucleo puro: junta catalogo do Inter e escolhas locais."""

from __future__ import annotations

from collections.abc import Iterable
from datetime import datetime

from robo_livelo.modelos_inter import (
    CashbackFavoritaInter,
    FavoritaInter,
    LojaInter,
    RetratoInter,
)


def montar_retrato_inter(
    lojas: Iterable[LojaInter],
    favoritas: Iterable[FavoritaInter],
    *,
    momento: datetime,
    lojas_lidas: int,
    versao: str,
) -> RetratoInter:
    por_id = {loja.id_externo: loja for loja in lojas}
    escolhidas = tuple(
        CashbackFavoritaInter(favorita=favorita, loja=por_id.get(favorita.id_externo))
        for favorita in favoritas
    )
    return RetratoInter(
        momento=momento,
        lojas_lidas=lojas_lidas,
        lojas_validas=len(por_id),
        versao=versao,
        favoritas=escolhidas,
    )
