"""Composicao da coleta Pichau e entrada do workflow."""

from __future__ import annotations

import logging
import os
from collections.abc import Callable
from datetime import UTC, datetime

from . import __version__
from .adaptadores import FontePichauHttp, RepositorioPichauPostgres, agora_utc
from .extrator import extrair_pagina
from .modelos import PichauProduto, ResumoColetaPichau
from .portas import ConfiguracaoPichauInvalida, FalhaPichau, PaginacaoPichauInvalida

_log = logging.getLogger(__name__)


def coletar_catalogo(
    fonte: FontePichauHttp,
    *,
    por_pagina: int = 36,
    max_paginas: int = 200,
    dormir: Callable[[float], None] | None = None,
) -> tuple[tuple[PichauProduto, ...], ResumoColetaPichau]:
    """Lê páginas sequenciais e rejeita paginação repetida ou incoerente."""

    iniciada = datetime.now(UTC)
    produtos: dict[str, PichauProduto] = {}
    fingerprints: set[tuple[str, ...]] = set()
    total_declarado: int | None = None
    paginas_lidas = 0
    itens_lidos = 0
    duplicados = 0
    tentativas = 1
    try:
        for numero in range(1, max_paginas + 1):
            if dormir and numero > 1:
                dormir(1.0)
            html = fonte.pagina(numero)
            pagina = extrair_pagina(
                html,
                pagina_esperada=numero,
                por_pagina=por_pagina,
                base_url=f"{fonte.url_categoria}{'?page=' + str(numero) if numero > 1 else ''}",
            )
            fingerprint = tuple(item.id_externo for item in pagina.produtos)
            if fingerprint and fingerprint in fingerprints:
                raise PaginacaoPichauInvalida(
                    "A fonte repetiu uma pagina do catalogo.", codigo="repetida"
                )
            fingerprints.add(fingerprint)
            if total_declarado is None:
                total_declarado = pagina.total
            elif pagina.total != total_declarado:
                raise PaginacaoPichauInvalida(
                    "O total do catalogo mudou durante a coleta.", codigo="incoerente"
                )
            paginas_lidas += 1
            itens_lidos += pagina.itens_lidos
            for produto in pagina.produtos:
                if produto.id_externo in produtos:
                    duplicados += 1
                produtos[produto.id_externo] = produto
            if pagina.ultima:
                break
        else:
            raise PaginacaoPichauInvalida(
                "O catalogo nao encerrou dentro do limite de paginas.", codigo="limite"
            )
        total = total_declarado or 0
        degradada = itens_lidos < total
        resumo = ResumoColetaPichau(
            iniciada_em=iniciada,
            concluida_em=datetime.now(UTC),
            total_declarado=total,
            paginas=paginas_lidas,
            itens_lidos=itens_lidos,
            itens_unicos=len(produtos),
            duplicados=duplicados,
            tentativas=tentativas,
            degradada=degradada,
        )
        return tuple(
            sorted(produtos.values(), key=lambda item: (item.nome.casefold(), item.id_externo))
        ), resumo
    except PaginacaoPichauInvalida:
        raise


def executar() -> int:
    logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"))
    database_url = os.getenv("DATABASE_URL")
    if not database_url:
        raise ConfiguracaoPichauInvalida("DATABASE_URL nao configurada.", codigo="configuracao")
    fonte = FontePichauHttp()
    repositorio = RepositorioPichauPostgres(database_url)
    execucao_id = repositorio.iniciar_execucao(agora_utc(), __version__)
    try:
        produtos, resumo = coletar_catalogo(fonte)
        if resumo.degradada:
            repositorio.falhar(execucao_id, "parcial")
            _log.error("Coleta Pichau parcial; snapshot anterior preservado.")
            return 2
        repositorio.publicar(execucao_id, produtos, resumo)
        _log.info("Coleta Pichau publicada: %d produtos.", len(produtos))
        return 0
    except FalhaPichau as erro:
        repositorio.falhar(execucao_id, erro.codigo)
        _log.error("Coleta Pichau nao publicada: %s", erro)
        return 2


if __name__ == "__main__":
    raise SystemExit(executar())
