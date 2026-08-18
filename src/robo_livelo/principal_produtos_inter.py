"""Orquestracao coordenadora e por loja do catalogo Compre direto."""

from __future__ import annotations

import argparse
import json
import logging
import math
import os
import sys
import time
import uuid
from dataclasses import dataclass
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
from robo_livelo.modelos_produtos_inter import (
    LojaDiretaInter,
    ProdutoDiretoInter,
    ResumoColetaProdutosInter,
)
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
INTERVALO_ENTRE_PAGINAS = 1.5
BUSCAS_SUPLEMENTARES = ("smartphone",)
MAX_TENTATIVAS_TOTAL_INCOERENTE = 3


@dataclass(frozen=True, slots=True)
class _CandidatoSegmento:
    """Tentativa que chegou ao fim da paginacao e pode disputar a publicacao."""

    tentativa: int
    total_minimo: int
    total_maximo: int
    paginas: int
    itens_lidos: int
    duplicados: int
    produtos: tuple[ProdutoDiretoInter, ...]

    @property
    def coerente(self) -> bool:
        return self.total_minimo == self.total_maximo

    @property
    def itens_unicos(self) -> int:
        return len(self.produtos)


def _melhor_candidato(candidatos: list[_CandidatoSegmento]) -> _CandidatoSegmento:
    """Prefere mais produtos validos; desempata por itens lidos e recencia."""

    return max(
        candidatos,
        key=lambda candidato: (
            candidato.itens_unicos,
            candidato.itens_lidos,
            candidato.tentativa,
        ),
    )


def montar_repositorio_produtos_inter(ambiente: dict[str, str]) -> RepositorioProdutosInterPostgres:
    return RepositorioProdutosInterPostgres((ambiente.get("DATABASE_URL") or "").strip())


def coletar_produtos_de_loja(
    fonte: FonteProdutosInter,
    repositorio: RepositorioProdutosInter,
    loja: LojaDiretaInter,
    *,
    rodada_id: int | None = None,
    agora: datetime | None = None,
    versao: str = __version__,
    limite: int = LIMITE_PAGINA,
    gerar_uuid=uuid.uuid4,
    buscas_suplementares: tuple[str, ...] = (),
    intervalo_paginas: float = 0.0,
    dormir=time.sleep,
    tentativas_total_incoerente: int = MAX_TENTATIVAS_TOTAL_INCOERENTE,
) -> ResumoColetaProdutosInter:
    """Coleta uma loja inteira; qualquer falha preserva o ultimo snapshot."""

    iniciada_em = agora or datetime.now(FUSO_BRASILIA)
    execucao_id = repositorio.iniciar_loja(
        loja,
        iniciada_em,
        versao,
        rodada_id=rodada_id,
    )
    try:
        total_declarado_soma = 0
        total_declarado_minimo_soma = 0
        total_declarado_maximo_soma = 0
        paginas = 0
        itens_lidos = 0
        duplicados = 0
        tentativas_executadas = 0
        degradada = False
        por_id = {}
        for indice_segmento, busca in enumerate(("", *buscas_suplementares)):
            if indice_segmento and intervalo_paginas > 0:
                dormir(intervalo_paginas)
            limite_tentativas = max(1, tentativas_total_incoerente)
            candidatos: list[_CandidatoSegmento] = []
            escolhido: _CandidatoSegmento | None = None
            for tentativa in range(1, limite_tentativas + 1):
                search_id = str(gerar_uuid())
                offset = 0
                paginas_segmento = 0
                itens_lidos_segmento = 0
                duplicados_segmento = 0
                produtos_segmento = {}
                totais_segmento: list[int] = []
                fingerprints_segmento: set[tuple[str, int, tuple[str, ...]]] = set()

                while True:
                    pagina = extrair_pagina_produtos(
                        fonte.pagina(
                            loja,
                            search_id,
                            offset,
                            limite,
                            busca=busca,
                        ),
                        id_loja=loja.id_externo,
                    )
                    if pagina.offset != offset:
                        raise PaginacaoProdutosInterInvalida(
                            "A fonte devolveu offset diferente do solicitado.",
                            codigo="offset_incoerente",
                        )
                    totais_segmento.append(pagina.total)

                    fingerprint = (
                        busca,
                        pagina.offset,
                        tuple(produto.id_externo for produto in pagina.produtos),
                    )
                    if fingerprint in fingerprints_segmento:
                        raise PaginacaoProdutosInterInvalida(
                            "A fonte repetiu uma pagina de produtos.",
                            codigo="pagina_repetida",
                        )
                    fingerprints_segmento.add(fingerprint)
                    paginas_segmento += 1
                    itens_lidos_segmento += pagina.itens_lidos
                    for produto in pagina.produtos:
                        if produto.id_externo in produtos_segmento:
                            duplicados_segmento += 1
                        else:
                            produtos_segmento[produto.id_externo] = produto

                    if pagina.ultima:
                        break
                    proximo_offset = offset + pagina.limite
                    if proximo_offset <= offset or not pagina.produtos:
                        raise PaginacaoProdutosInterInvalida(
                            "A fonte nao avancou uma pagina utilizavel.",
                            codigo="offset_incoerente",
                        )
                    maximo_paginas = math.ceil(max(totais_segmento) / max(1, pagina.limite)) + 2
                    if paginas_segmento >= maximo_paginas:
                        raise PaginacaoProdutosInterInvalida(
                            "A fonte excedeu a margem de paginas declarada.",
                            codigo="limite_paginacao",
                        )
                    offset = proximo_offset
                    if intervalo_paginas > 0:
                        dormir(intervalo_paginas)

                candidato = _CandidatoSegmento(
                    tentativa=tentativa,
                    total_minimo=min(totais_segmento),
                    total_maximo=max(totais_segmento),
                    paginas=paginas_segmento,
                    itens_lidos=itens_lidos_segmento,
                    duplicados=duplicados_segmento,
                    produtos=tuple(produtos_segmento.values()),
                )
                candidatos.append(candidato)
                if candidato.coerente:
                    escolhido = candidato
                    break
                _log.warning(
                    "Total variou na coleta de %s, segmento %r, tentativa %d/%d: "
                    "%d-%d; %d produtos unicos.",
                    loja.slug,
                    busca,
                    tentativa,
                    limite_tentativas,
                    candidato.total_minimo,
                    candidato.total_maximo,
                    candidato.itens_unicos,
                )
                if tentativa < limite_tentativas and intervalo_paginas > 0:
                    dormir(intervalo_paginas)

            tentativas_executadas += len(candidatos)
            if escolhido is None:
                escolhido = _melhor_candidato(candidatos)
                degradada = True
                _log.warning(
                    "Usando melhor tentativa de %s, segmento %r, como coleta degradada: "
                    "tentativa %d/%d, %d paginas, %d produtos unicos, totais %d-%d.",
                    loja.slug,
                    busca,
                    escolhido.tentativa,
                    limite_tentativas,
                    escolhido.paginas,
                    escolhido.itens_unicos,
                    escolhido.total_minimo,
                    escolhido.total_maximo,
                )

            total_declarado_soma += escolhido.total_maximo
            total_declarado_minimo_soma += escolhido.total_minimo
            total_declarado_maximo_soma += escolhido.total_maximo
            paginas += escolhido.paginas
            itens_lidos += escolhido.itens_lidos
            duplicados += escolhido.duplicados
            for produto in escolhido.produtos:
                if produto.id_externo in por_id:
                    duplicados += 1
                else:
                    por_id[produto.id_externo] = produto
            if escolhido.total_maximo and not escolhido.itens_unicos:
                raise RespostaProdutosInterInvalida(
                    "A fonte declarou produtos, mas nenhum item passou pela validacao."
                )

        concluida_em = agora or datetime.now(FUSO_BRASILIA)
        resumo = ResumoColetaProdutosInter(
            iniciada_em=iniciada_em,
            concluida_em=concluida_em,
            total_declarado=total_declarado_soma,
            paginas=paginas,
            itens_lidos=itens_lidos,
            itens_unicos=len(por_id),
            duplicados=duplicados,
            degradada=degradada,
            tentativas=tentativas_executadas,
            total_declarado_minimo=total_declarado_minimo_soma,
            total_declarado_maximo=total_declarado_maximo_soma,
        )
        repositorio.publicar_loja(
            execucao_id,
            loja,
            tuple(por_id.values()),
            resumo,
            catalogo_completo=not resumo.degradada,
        )
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


def preparar_rodada(
    fonte: FonteLojasDiretasInterHttp,
    repositorio: RepositorioProdutosInterPostgres,
    *,
    agora: datetime | None = None,
    versao: str = __version__,
) -> tuple[int, list[LojaDiretaInter]]:
    lojas = extrair_lojas_diretas(fonte.obter_json())
    if len(lojas) < LIMIAR_LOJAS_DIRETAS:
        raise FalhaProdutosInter(
            f"Apenas {len(lojas)} lojas diretas validas, abaixo do limiar {LIMIAR_LOJAS_DIRETAS}.",
            codigo="catalogo_pequeno",
        )
    repositorio.sincronizar_lojas(lojas)
    selecionadas = repositorio.listar_selecionadas()
    momento = agora or datetime.now(FUSO_BRASILIA)
    rodada_id = repositorio.iniciar_rodada(momento, versao, len(selecionadas))
    _log.info("Lojas diretas sincronizadas: %d; selecionadas: %d.", len(lojas), len(selecionadas))
    return rodada_id, selecionadas


def _falha_controlada(erro: Exception) -> FalhaProdutosInter:
    if isinstance(erro, FalhaProdutosInter):
        return erro
    if isinstance(erro, RespostaProdutosInterInvalida):
        codigo = "json_invalido" if "JSON" in str(erro) else "schema_invalido"
        return FalhaProdutosInter(str(erro), codigo=codigo)
    return FalhaProdutosInter(f"Falha inesperada: {type(erro).__name__}.", codigo="inesperada")


def _argumentos(argv: list[str] | None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "acao",
        nargs="?",
        choices=("executar", "preparar", "coletar", "concluir"),
        default="executar",
    )
    parser.add_argument("--execucao-id", type=int)
    parser.add_argument("--loja-id")
    return parser.parse_args(argv)


def principal(argv: list[str] | None = None) -> int:
    """Executa localmente ou atende aos tres jobs do workflow matricial."""

    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
    load_dotenv()
    opcoes = _argumentos(argv)
    try:
        repositorio = montar_repositorio_produtos_inter(dict(os.environ))
        if opcoes.acao == "preparar":
            rodada_id, selecionadas = preparar_rodada(FonteLojasDiretasInterHttp(), repositorio)
            print(f"execucao_id={rodada_id}")
            print(
                "lojas="
                + json.dumps(
                    [loja.id_externo for loja in selecionadas],
                    ensure_ascii=True,
                    separators=(",", ":"),
                )
            )
            print(f"tem_lojas={'true' if selecionadas else 'false'}")
            return 0

        if opcoes.acao == "coletar":
            if not opcoes.execucao_id or not opcoes.loja_id:
                raise FalhaProdutosInter(
                    "Coleta exige --execucao-id e --loja-id.", codigo="inesperada"
                )
            loja = repositorio.obter_loja_selecionada(opcoes.loja_id)
            coletar_produtos_de_loja(
                FonteProdutosInterHttp(),
                repositorio,
                loja,
                rodada_id=opcoes.execucao_id,
                buscas_suplementares=BUSCAS_SUPLEMENTARES,
                intervalo_paginas=INTERVALO_ENTRE_PAGINAS,
            )
            return 0

        if opcoes.acao == "concluir":
            if not opcoes.execucao_id:
                raise FalhaProdutosInter("Conclusao exige --execucao-id.", codigo="inesperada")
            estado = repositorio.concluir_rodada(
                opcoes.execucao_id,
                datetime.now(FUSO_BRASILIA),
            )
            _log.info("Rodada %d concluida como %s.", opcoes.execucao_id, estado)
            return 0 if estado == "sucesso" else 1

        rodada_id, selecionadas = preparar_rodada(FonteLojasDiretasInterHttp(), repositorio)
        for loja in selecionadas:
            try:
                coletar_produtos_de_loja(
                    FonteProdutosInterHttp(),
                    repositorio,
                    loja,
                    rodada_id=rodada_id,
                    buscas_suplementares=BUSCAS_SUPLEMENTARES,
                    intervalo_paginas=INTERVALO_ENTRE_PAGINAS,
                )
            except FalhaProdutosInter as erro:
                _log.error("%s (%s): %s", loja.nome, erro.codigo, erro)
        estado = repositorio.concluir_rodada(rodada_id, datetime.now(FUSO_BRASILIA))
        return 0 if estado == "sucesso" else 1
    except Exception as erro:
        falha = _falha_controlada(erro)
        _log.error("%s: %s", falha.codigo, falha)
        return 1


if __name__ == "__main__":
    sys.exit(principal())
