"""Portas e falhas controladas da coleta Pichau."""

from __future__ import annotations

from datetime import datetime
from typing import Protocol, runtime_checkable

from .modelos import PichauProduto, ResumoColetaPichau


class FalhaPichau(RuntimeError):
    def __init__(self, mensagem: str, *, codigo: str = "inesperada") -> None:
        super().__init__(mensagem)
        self.codigo = codigo


class FalhaAoObterPichau(FalhaPichau):
    pass


class FalhaAoGuardarPichau(FalhaPichau):
    pass


class ConfiguracaoPichauInvalida(FalhaPichau):
    pass


class PaginacaoPichauInvalida(FalhaPichau):
    pass


class RespostaPichauInvalida(FalhaPichau):
    pass


@runtime_checkable
class FontePichau(Protocol):
    url_categoria: str

    def pagina(self, pagina: int) -> str: ...

    def detalhe(self, url_produto: str) -> str: ...


@runtime_checkable
class RepositorioPichau(Protocol):
    def iniciar_execucao(self, momento: datetime, versao: str) -> int: ...

    def publicar(
        self,
        execucao_id: int,
        produtos: tuple[PichauProduto, ...],
        resumo: ResumoColetaPichau,
    ) -> None: ...

    def falhar(self, execucao_id: int, codigo: str) -> None: ...
