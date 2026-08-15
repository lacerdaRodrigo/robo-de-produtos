"""Contratos que isolam o dominio Shopping Inter do mundo externo."""

from __future__ import annotations

from datetime import datetime
from typing import Protocol, runtime_checkable

from robo_livelo.modelos_inter import FavoritaInter, LojaInter, RetratoInter


class FalhaInter(RuntimeError):
    """Falha controlada com codigo seguro para log e banco."""

    def __init__(self, mensagem: str, *, codigo: str = "inesperada") -> None:
        super().__init__(mensagem)
        self.codigo = codigo


class FalhaAoObterInter(FalhaInter):
    """A fonte publica nao respondeu de forma utilizavel."""


class FalhaAoGuardarInter(FalhaInter):
    """O Postgres nao concluiu uma operacao do Inter."""


class ConfiguracaoInterInvalida(FalhaInter):
    """Configuracao obrigatoria da V3 ausente ou invalida."""


class SiteInterMudou(FalhaInter):
    """A resposta valida tem lojas de menos para substituir o retrato."""


@runtime_checkable
class FonteInter(Protocol):
    def obter_json(self) -> str: ...


@runtime_checkable
class CatalogoFavoritasInter(Protocol):
    def listar(self) -> list[FavoritaInter]: ...


@runtime_checkable
class RepositorioInter(Protocol):
    def iniciar(self, momento: datetime, versao: str) -> int: ...

    def concluir(
        self,
        execucao_id: int,
        lojas: tuple[LojaInter, ...],
        retrato: RetratoInter,
    ) -> None: ...

    def falhar(self, execucao_id: int, codigo: str) -> None: ...
