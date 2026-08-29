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

from robo_livelo import __version__, alertas, categorias, extrator, retrato
from robo_livelo.adaptadores import (
    CatalogoArquivo,
    CatalogoComReserva,
    CatalogoPostgres,
    PaginaLiveloHttp,
    PreferenciasComReserva,
    PreferenciasPadrao,
    PreferenciasPostgres,
    RepositorioNulo,
    RepositorioPostgres,
)
from robo_livelo.modelos import RetratoDaExecucao
from robo_livelo.portas import (
    CatalogoFavoritas,
    FonteDePagina,
    PreferenciasGlobais,
    RepositorioDeExecucao,
    SiteMudou,
)

_log = logging.getLogger("robo_livelo")

LIMIAR_PADRAO = 150  # PRD 2.4: a pagina trazia 247 parceiros em 2026-08-09
CAMINHO_CONFIG_PADRAO = Path("config/lojas_favoritas.toml")

# Brasil nao usa mais horario de verao desde 2019 — fuso fixo, sem
# dependencia nova (RNF13).
FUSO_BRASILIA = timezone(timedelta(hours=-3))


def montar_catalogo(ambiente: dict[str, str], caminho: Path) -> CatalogoFavoritas:
    """Escolhe de onde vem o catalogo (PRD V2, secao 7.1.1).

    Com `DATABASE_URL` no ambiente, o banco manda e o arquivo fica de
    reserva. Sem ela, o arquivo continua sendo a unica fonte — que e o
    estado de quem clona o projeto e roda na propria maquina, sem Neon.
    """
    url = (ambiente.get("DATABASE_URL") or "").strip()
    if not url:
        _log.info("Sem DATABASE_URL: catalogo lido de %s.", caminho)
        return CatalogoArquivo(caminho)

    _log.info("Catalogo lido do banco, com %s de reserva.", caminho)
    return CatalogoComReserva(CatalogoPostgres(url), CatalogoArquivo(caminho))


def montar_preferencias(ambiente: dict[str, str]) -> PreferenciasGlobais:
    """De onde vem a regua do alerta (RN28).

    Mesma logica do catalogo: banco quando ha `DATABASE_URL`, padroes do
    PRD-V2 §6.1 quando nao — e tambem quando o banco nao responde, porque
    ficar sem preferencia nao justifica perder a execucao.
    """
    url = (ambiente.get("DATABASE_URL") or "").strip()
    if not url:
        return PreferenciasPadrao()
    return PreferenciasComReserva(PreferenciasPostgres(url), PreferenciasPadrao())


def montar_repositorio(ambiente: dict[str, str]) -> RepositorioDeExecucao:
    """Onde o retrato da execucao e guardado (RF15).

    Sem `DATABASE_URL` nao ha onde guardar, e isso nao e erro para uma
    execucao local de diagnostico.
    """
    url = (ambiente.get("DATABASE_URL") or "").strip()
    if not url:
        return RepositorioNulo()
    return RepositorioPostgres(url)


def verificar_promocoes(
    fonte: FonteDePagina,
    catalogo: CatalogoFavoritas,
    limiar: int = LIMIAR_PADRAO,
    agora: datetime | None = None,
    preferencias: PreferenciasGlobais | None = None,
    repositorio: RepositorioDeExecucao | None = None,
) -> int:
    """Coleta a Livelo, grava o retrato e devolve quantos alertas achou.

    `agora` e resolvido aqui (unica camada que le o relogio) e propagado
    para o extrator, preservando a mesma referencia de tempo durante toda
    a execucao (RN21, RN22).
    """
    agora = agora or datetime.now(FUSO_BRASILIA)
    regua = (preferencias or PreferenciasPadrao()).carregar()
    _log.info(
        "Limiar: %sx a base, piso de %s pontos%s.",
        regua.multiplicador_padrao,
        regua.piso_pontos_padrao,
        ", assinante do Clube" if regua.assinante_clube else "",
    )

    favoritas = catalogo.listar()
    _log.info("Lojas favoritas carregadas: %d", len(favoritas))

    # Banco vazio é um estado válido e não aciona a reserva em TOML. Assim uma
    # limpeza não ressuscita escolhas antigas na coleta seguinte.
    if not favoritas:
        _log.warning("Nenhuma loja cadastrada. Nada sera monitorado.")

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
    if ausentes:  # RN19: vai para o log operacional
        _log.warning("Favoritas nao encontradas na pagina: %s", ", ".join(ausentes))

    # RN27/RN28: quem decide o que merece alerta e o nucleo, com a regua
    # que veio do banco. A etiqueta "Promocao" da Livelo deixa de mandar.
    agrupamento = categorias.agrupar(parceiros, favoritas, alertas.criterio_de_alerta(regua))
    total = sum(len(lojas) for lojas in agrupamento.values())

    suspeita = alertas.suspeita_de_base_degenerada(parceiros, total)  # RN29
    if suspeita:
        _log.warning("%s", suspeita)

    _guardar_retrato(
        repositorio or RepositorioNulo(),
        retrato.montar_retrato(parceiros, favoritas, regua, agora=agora, versao=__version__),
    )
    _log.info("Coleta concluida. Alertas: %d em %d categorias.", total, len(agrupamento))
    return total


def _guardar_retrato(repositorio: RepositorioDeExecucao, snapshot: RetratoDaExecucao) -> None:
    """RF15: alimenta a API e seus clientes.

    Sem o antigo canal de e-mail, persistir e o produto da coleta. Uma falha
    do repositorio configurado precisa subir e deixar o workflow vermelho;
    `RepositorioNulo` continua permitindo diagnostico local sem banco.
    """
    repositorio.registrar(snapshot)


def principal(argv: list[str] | None = None) -> int:
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
    load_dotenv()

    ambiente = dict(os.environ)

    limiar = int(ambiente.get("LIMIAR_PARCEIROS", LIMIAR_PADRAO))
    caminho = Path(ambiente.get("CAMINHO_CONFIG", CAMINHO_CONFIG_PADRAO))
    try:
        verificar_promocoes(
            fonte=PaginaLiveloHttp(),
            catalogo=montar_catalogo(ambiente, caminho),
            preferencias=montar_preferencias(ambiente),
            repositorio=montar_repositorio(ambiente),
            limiar=limiar,
        )
    except Exception as erro:
        # RNF06: qualquer falha e ruidosa e sai com codigo diferente de zero.
        _log.error("%s: %s", type(erro).__name__, erro)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(principal())
