"""Orquestracao exclusiva da coleta de cashback do Shopping Inter."""

from __future__ import annotations

import logging
import os
import sys
from datetime import datetime, timedelta, timezone

from dotenv import load_dotenv

from robo_livelo import __version__
from robo_livelo.adaptadores_inter import FonteInterHttp, RepositorioInterPostgres
from robo_livelo.extrator_inter import (
    ConflitoIdentidadeInter,
    RespostaInterInvalida,
    extrair_lojas,
)
from robo_livelo.modelos_inter import RetratoInter
from robo_livelo.portas_inter import (
    CatalogoFavoritasInter,
    ConfiguracaoInterInvalida,
    FalhaAoGuardarInter,
    FalhaInter,
    FonteInter,
    RepositorioInter,
    SiteInterMudou,
)
from robo_livelo.retrato_inter import montar_retrato_inter

_log = logging.getLogger("robo_livelo.inter")

FUSO_BRASILIA = timezone(timedelta(hours=-3))
LIMIAR_LOJAS_INTER = 100


def montar_repositorio_inter(ambiente: dict[str, str]) -> RepositorioInterPostgres:
    url = (ambiente.get("DATABASE_URL") or "").strip()
    if not url:
        raise ConfiguracaoInterInvalida(
            "DATABASE_URL nao configurada para o Inter.", codigo="banco"
        )
    return RepositorioInterPostgres(url)


def verificar_cashbacks_inter(
    fonte: FonteInter,
    catalogo: CatalogoFavoritasInter,
    repositorio: RepositorioInter,
    *,
    limiar: int = LIMIAR_LOJAS_INTER,
    agora: datetime | None = None,
    versao: str = __version__,
) -> RetratoInter:
    momento = agora or datetime.now(FUSO_BRASILIA)
    execucao_id = repositorio.iniciar(momento, versao)

    try:
        favoritas = catalogo.listar()
        extracao = extrair_lojas(fonte.obter_json())
        if extracao.lojas_validas < limiar:
            raise SiteInterMudou(
                f"Apenas {extracao.lojas_validas} lojas validas, abaixo do limiar {limiar}.",
                codigo="catalogo_pequeno",
            )
        retrato = montar_retrato_inter(
            extracao.lojas,
            favoritas,
            momento=momento,
            lojas_lidas=extracao.lojas_lidas,
            versao=versao,
        )
        repositorio.concluir(execucao_id, extracao.lojas, retrato)
    except Exception as erro:
        falha = _falha_controlada(erro)
        try:
            repositorio.falhar(execucao_id, falha.codigo)
        except FalhaAoGuardarInter:
            _log.warning("Nao foi possivel registrar a falha da execucao %d.", execucao_id)
        raise falha from None

    _log.info(
        "Inter atualizado: %d lidas, %d validas, %d favoritas encontradas.",
        retrato.lojas_lidas,
        retrato.lojas_validas,
        retrato.favoritas_encontradas,
    )
    return retrato


def _falha_controlada(erro: Exception) -> FalhaInter:
    if isinstance(erro, FalhaInter):
        return erro
    if isinstance(erro, ConflitoIdentidadeInter):
        return FalhaInter(str(erro), codigo="conflito_identidade")
    if isinstance(erro, RespostaInterInvalida):
        codigo = "json_invalido" if "JSON" in str(erro) else "schema_invalido"
        return FalhaInter(str(erro), codigo=codigo)
    return FalhaInter(f"Falha inesperada: {type(erro).__name__}.", codigo="inesperada")


def principal() -> int:
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
    load_dotenv()
    ambiente = dict(os.environ)

    try:
        repositorio = montar_repositorio_inter(ambiente)
        verificar_cashbacks_inter(
            fonte=FonteInterHttp(),
            catalogo=repositorio,
            repositorio=repositorio,
            limiar=int(ambiente.get("LIMIAR_LOJAS_INTER", LIMIAR_LOJAS_INTER)),
        )
    except Exception as erro:
        falha = _falha_controlada(erro)
        _log.error("%s: %s", falha.codigo, falha)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(principal())
