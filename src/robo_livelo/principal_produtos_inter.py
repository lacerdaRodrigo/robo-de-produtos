"""Orquestracao por loja do catalogo Compre direto (V4.2 e V4.3)."""

from __future__ import annotations

import logging
import math
import os
import sys
import uuid
from datetime import datetime, timedelta, timezone

from dotenv import load_dotenv

from robo_livelo import __version__
from robo_livelo.adaptadores_produtos_inter import (
    FonteLojasDiretasInterHttp,
    FonteProdutosInterHttp,
    RepositorioProdutosInterPostgres,
)
from robo_livelo.extrator_produtos_inter import (
    RespostaProdutosInterInvalida,
    extrair_lojas_diretas,
    extrair_pagina_produtos,
)
from robo_livelo.modelos_produtos_inter import LojaDiretaInter, ResumoColetaProdutosInter
from robo_livelo.portas_produtos_inter import (
    FalhaAoGuardarProdutosInter,
    FalhaProdutosInter,
    FonteProdutosInter,
    PaginacaoProdutosInterInvalida,
    RepositorioProdutosInter,
)

_log = logging.getLogger("robo_livelo.produtos_inter")
FUSO_BRASILIA = timezone(timedelta(hours=-3))
LIMITE_PAGINA = 36
LIMIAR_LOJAS_DIRETAS = 100


def montar_repositorio_produtos_inter(ambiente: dict[str, str]) -> RepositorioProdutosInterPostgres:
    return RepositorioProdutosInterPostgres((ambiente.get("DATABASE_URL") or "").strip())


def coletar_produtos_de_loja(
    fonte: FonteProdutosInter,
    repositorio: RepositorioProdutosInter,
    loja: LojaDiretaInter,
    *,
    agora: datetime | None = None,
    versao: str = __version__,
    limite: int = LIMITE_PAGINA,
    gerar_uuid=uuid.uuid4,
) -> ResumoColetaProdutosInter:
    """Coleta uma loja inteira; qualquer falha preserva o ultimo snapshot."""

    iniciada_em = agora or datetime.now(FUSO_BRASILIA)
    execucao_id = repositorio.iniciar_loja(loja, iniciada_em, versao)
    try:
        search_id = str(gerar_uuid())
        offset = 0
        total_declarado: int | None = None
        paginas = 0
        itens_lidos = 0
        duplicados = 0
        por_id = {}
        fingerprints: set[tuple[int, tuple[str, ...]]] = set()

        while True:
            pagina = extrair_pagina_produtos(
                fonte.pagina(loja, search_id, offset, limite), id_loja=loja.id_externo
            )
            if pagina.offset != offset:
                raise PaginacaoProdutosInterInvalida(
                    "A fonte devolveu offset diferente do solicitado.", codigo="offset_incoerente"
                )
            if total_declarado is None:
                total_declarado = pagina.total
            elif pagina.total != total_declarado:
                raise PaginacaoProdutosInterInvalida(
                    "A fonte mudou o total declarado durante a coleta.", codigo="total_incoerente"
                )

            fingerprint = (pagina.offset, tuple(produto.id_externo for produto in pagina.produtos))
            if fingerprint in fingerprints:
                raise PaginacaoProdutosInterInvalida(
                    "A fonte repetiu uma pagina de produtos.", codigo="pagina_repetida"
                )
            fingerprints.add(fingerprint)
            paginas += 1
            itens_lidos += pagina.itens_lidos
            for produto in pagina.produtos:
                if produto.id_externo in por_id:
                    duplicados += 1
                else:
                    por_id[produto.id_externo] = produto

            if pagina.ultima:
                break
            proximo_offset = offset + pagina.limite
            if proximo_offset <= offset or not pagina.produtos:
                raise PaginacaoProdutosInterInvalida(
                    "A fonte nao avancou uma pagina utilizavel.", codigo="offset_incoerente"
                )
            maximo_paginas = math.ceil(total_declarado / max(1, pagina.limite)) + 2
            if paginas >= maximo_paginas:
                raise PaginacaoProdutosInterInvalida(
                    "A fonte excedeu a margem de paginas declarada.", codigo="limite_paginacao"
                )
            offset = proximo_offset

        concluida_em = agora or datetime.now(FUSO_BRASILIA)
        resumo = ResumoColetaProdutosInter(
            iniciada_em=iniciada_em,
            concluida_em=concluida_em,
            total_declarado=total_declarado or 0,
            paginas=paginas,
            itens_lidos=itens_lidos,
            itens_unicos=len(por_id),
            duplicados=duplicados,
        )
        repositorio.publicar_loja(execucao_id, loja, tuple(por_id.values()), resumo)
    except Exception as erro:
        falha = _falha_controlada(erro)
        try:
            repositorio.falhar_loja(execucao_id, falha.codigo)
        except FalhaAoGuardarProdutosInter:
            _log.warning("Nao foi possivel registrar a falha da loja %s.", loja.id_externo)
        raise falha from None

    _log.info(
        "Produtos %s: %d paginas, %d lidos, %d unicos, %d duplicados.",
        loja.slug,
        resumo.paginas,
        resumo.itens_lidos,
        resumo.itens_unicos,
        resumo.duplicados,
    )
    return resumo


def sincronizar_lojas_diretas(
    fonte: FonteLojasDiretasInterHttp,
    repositorio: RepositorioProdutosInterPostgres,
) -> int:
    lojas = extrair_lojas_diretas(fonte.obter_json())
    if len(lojas) < LIMIAR_LOJAS_DIRETAS:
        raise FalhaProdutosInter(
            f"Apenas {len(lojas)} lojas diretas validas, abaixo do limiar {LIMIAR_LOJAS_DIRETAS}.",
            codigo="catalogo_pequeno",
        )
    repositorio.sincronizar_lojas(lojas)
    return len(lojas)


def _falha_controlada(erro: Exception) -> FalhaProdutosInter:
    if isinstance(erro, FalhaProdutosInter):
        return erro
    if isinstance(erro, RespostaProdutosInterInvalida):
        codigo = "json_invalido" if "JSON" in str(erro) else "schema_invalido"
        return FalhaProdutosInter(str(erro), codigo=codigo)
    return FalhaProdutosInter(f"Falha inesperada: {type(erro).__name__}.", codigo="inesperada")


def principal() -> int:
    """Entrada manual para V4.1: sincroniza lojas, depois coleta selecionadas."""

    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
    load_dotenv()
    try:
        repositorio = montar_repositorio_produtos_inter(dict(os.environ))
        catalogo = sincronizar_lojas_diretas(FonteLojasDiretasInterHttp(), repositorio)
        selecionadas = repositorio.listar_selecionadas()
        _log.info("Lojas diretas sincronizadas: %d; selecionadas: %d.", catalogo, len(selecionadas))
        falhas = 0
        for loja in selecionadas:
            try:
                coletar_produtos_de_loja(FonteProdutosInterHttp(), repositorio, loja)
            except FalhaProdutosInter as erro:
                falhas += 1
                _log.error("%s (%s): %s", loja.nome, erro.codigo, erro)
        return 1 if falhas else 0
    except Exception as erro:
        falha = _falha_controlada(erro)
        _log.error("%s: %s", falha.codigo, falha)
        return 1


if __name__ == "__main__":
    sys.exit(principal())
