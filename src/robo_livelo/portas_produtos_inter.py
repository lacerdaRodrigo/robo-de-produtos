"""Contratos e falhas controladas exclusivos da V4 do Shopping Inter."""

from __future__ import annotations

from datetime import datetime
from typing import Protocol, runtime_checkable

from robo_livelo.modelos_produtos_inter import (
    LojaDiretaInter,
    ProdutoDiretoInter,
    ResumoColetaProdutosInter,
)


class FalhaProdutosInter(RuntimeError):
    """Falha segura para log: o codigo nunca contem URL, payload ou segredo."""

    def __init__(self, mensagem: str, *, codigo: str = "inesperada") -> None:
        super().__init__(mensagem)
        self.codigo = codigo


class FalhaAoObterProdutosInter(FalhaProdutosInter):
    """A fonte publica de produtos nao respondeu de modo utilizavel."""


class FalhaAoGuardarProdutosInter(FalhaProdutosInter):
    """O Postgres nao concluiu a operacao atomica da loja."""


class ConfiguracaoProdutosInterInvalida(FalhaProdutosInter):
    """Configuracao obrigatoria da V4 ausente ou invalida."""


class PaginacaoProdutosInterInvalida(FalhaProdutosInter):
    """A fonte repetiu pagina, travou offset ou contradisse a propria pagina."""


@runtime_checkable
class FonteProdutosInter(Protocol):
    def pagina(
        self,
        loja: LojaDiretaInter,
        search_id: str,
        offset: int,
        limite: int,
        *,
        busca: str = "",
    ) -> str: ...


@runtime_checkable
class CatalogoLojasDiretasInter(Protocol):
    def listar_selecionadas(self) -> list[LojaDiretaInter]: ...

    def obter_loja_selecionada(self, id_externo: str) -> LojaDiretaInter: ...


@runtime_checkable
class RepositorioProdutosInter(Protocol):
    def iniciar_rodada(self, momento: datetime, versao: str, lojas_planejadas: int) -> int: ...

    def iniciar_loja(
        self,
        loja: LojaDiretaInter,
        momento: datetime,
        versao: str,
        *,
        rodada_id: int | None = None,
    ) -> int: ...

    def publicar_loja(
        self,
        execucao_id: int,
        loja: LojaDiretaInter,
        produtos: tuple[ProdutoDiretoInter, ...],
        resumo: ResumoColetaProdutosInter,
    ) -> None: ...

    def falhar_loja(self, execucao_id: int, codigo: str) -> None: ...

    def concluir_rodada(self, rodada_id: int, momento: datetime) -> str: ...
