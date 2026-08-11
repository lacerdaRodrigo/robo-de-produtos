"""Orquestracao e composition root. Ver PRD secao 7.

Ordem deliberada: segredos sao validados na largada, antes de tocar a rede
(PRD 7.3). Falhar depois de baixar a pagina gastaria uma requisicao a toa.
"""

from __future__ import annotations

import logging
import os
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

from dotenv import load_dotenv

from robo_livelo import categorias, extrator, montador_email
from robo_livelo.adaptadores import CatalogoArquivo, NotificadorEmail, PaginaLiveloHttp
from robo_livelo.portas import (
    CatalogoFavoritas,
    FonteDePagina,
    Notificador,
    SiteMudou,
)

_log = logging.getLogger("robo_livelo")

LIMIAR_PADRAO = 150  # PRD 2.4: a pagina trazia 247 parceiros em 2026-08-09
CAMINHO_CONFIG_PADRAO = Path("config/lojas_favoritas.toml")

# Brasil nao usa mais horario de verao desde 2019 — fuso fixo, sem
# dependencia nova (RNF13).
FUSO_BRASILIA = timezone(timedelta(hours=-3))

_SEGREDOS = ("EMAIL_REMETENTE", "SENHA_APP_GMAIL", "EMAIL_DESTINO")


def validar_segredos(ambiente: dict[str, str]) -> None:
    """PRD 7.3: falha antes da rede se faltar segredo."""
    faltando = [nome for nome in _SEGREDOS if not ambiente.get(nome)]
    if faltando:
        raise SystemExit(f"Variaveis obrigatorias ausentes: {', '.join(faltando)}")


def verificar_promocoes(
    fonte: FonteDePagina,
    catalogo: CatalogoFavoritas,
    notificador: Notificador,
    limiar: int = LIMIAR_PADRAO,
    agora: datetime | None = None,
) -> int:
    """Executa a fatia vertical completa e devolve quantas promocoes achou.

    `agora` e resolvido aqui (unica camada que le o relogio) e propagado
    para o extrator e o montador de e-mail, para os dois concordarem sobre
    "hoje" mesmo que a execucao atravesse a meia-noite (RN21, RN22).
    """
    agora = agora or datetime.now(FUSO_BRASILIA)

    favoritas = catalogo.listar()
    _log.info("Lojas favoritas carregadas: %d", len(favoritas))

    html = fonte.obter_html()
    parceiros = extrator.extrair_parceiros(html, agora=agora)
    _log.info("Parceiros extraidos: %d", len(parceiros))

    # RN13: ausencia de promocao nao e erro, ausencia de parceiros e.
    if len(parceiros) < limiar:
        raise SiteMudou(
            f"Apenas {len(parceiros)} parceiros extraidos, abaixo do limiar de {limiar}. "
            "O layout da pagina provavelmente mudou."
        )

    ausentes = categorias.favoritas_ausentes(parceiros, favoritas)
    if ausentes:  # RN19: vai para o log, nunca para o e-mail
        _log.warning("Favoritas nao encontradas na pagina: %s", ", ".join(ausentes))

    agrupamento = categorias.agrupar(parceiros, favoritas)
    total = sum(len(lojas) for lojas in agrupamento.values())

    mensagem = montador_email.montar(agrupamento, agora=agora)
    notificador.enviar(mensagem)  # RF10: envia em toda execucao
    _log.info("E-mail enviado. Promocoes: %d em %d categorias.", total, len(agrupamento))
    return total


def principal(argv: list[str] | None = None) -> int:
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
    load_dotenv()

    ambiente = dict(os.environ)
    validar_segredos(ambiente)

    limiar = int(ambiente.get("LIMIAR_PARCEIROS", LIMIAR_PADRAO))
    caminho = Path(ambiente.get("CAMINHO_CONFIG", CAMINHO_CONFIG_PADRAO))

    try:
        verificar_promocoes(
            fonte=PaginaLiveloHttp(),
            catalogo=CatalogoArquivo(caminho),
            notificador=NotificadorEmail(
                remetente=ambiente["EMAIL_REMETENTE"],
                senha=ambiente["SENHA_APP_GMAIL"],
                destino=ambiente["EMAIL_DESTINO"],
            ),
            limiar=limiar,
        )
    except Exception as erro:
        # RNF06: qualquer falha e ruidosa e sai com codigo diferente de zero.
        _log.error("%s: %s", type(erro).__name__, erro)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(principal())
