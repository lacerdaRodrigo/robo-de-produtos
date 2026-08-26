"""Ordenacao pura das favoritas do Shopping Inter (RN37/RN38)."""

from __future__ import annotations

from collections.abc import Iterable
from decimal import Decimal

from robo_livelo.modelos_inter import CashbackFavoritaInter


def ordenar_favoritas(
    favoritas: Iterable[CashbackFavoritaInter],
) -> list[CashbackFavoritaInter]:
    """Positivos primeiro; zero/ausente depois; nao encontrada no final."""

    def chave(item: CashbackFavoritaInter) -> tuple[int, Decimal, str]:
        if item.loja is None:
            return (2, Decimal(0), item.nome.casefold())
        valor = item.loja.cashback_principal_valor
        if valor is None or valor <= 0:
            return (1, Decimal(0), item.nome.casefold())
        return (0, -valor, item.nome.casefold())

    return sorted(favoritas, key=chave)
