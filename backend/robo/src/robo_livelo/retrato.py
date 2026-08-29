"""Nucleo puro: monta o retrato da execucao. Ver PRD-V2 RF15, RN24, RN30.

Nao grava nada — quem grava e o adaptador por tras da porta
`RepositorioDeExecucao`. Aqui so se decide *o que* vale registrar.
"""

from __future__ import annotations

from datetime import datetime

from robo_livelo import alertas, categorias
from robo_livelo.modelos import (
    LojaFavorita,
    Parceiro,
    PontuacaoDeLoja,
    Preferencias,
    RetratoDaExecucao,
)


def montar_retrato(
    parceiros: list[Parceiro],
    favoritas: list[LojaFavorita],
    preferencias: Preferencias,
    *,
    agora: datetime,
    versao: str,
) -> RetratoDaExecucao:
    """Junta cada favorita com o que a pagina disse dela nesta rodada.

    RN24: entram **todas** as favoritas, em promocao ou nao — e ate as que
    nao apareceram na pagina. E o que permite consultar a pontuacao base
    sem abrir a Livelo (O5), que e o motivo do site existir.
    """
    encontrados = {categorias.normalizar(p.nome): p for p in parceiros}

    pontuacoes = []
    for loja in favoritas:
        parceiro = None
        for grafia in (loja.nome, *loja.apelidos):  # RN04: grafia exata
            parceiro = encontrados.get(categorias.normalizar(grafia))
            if parceiro is not None:
                break

        if parceiro is None:
            pontuacoes.append(PontuacaoDeLoja(loja=loja))
            continue

        pontuacoes.append(
            PontuacaoDeLoja(
                loja=loja,
                # RN01: o nome exibido e o canonico do catalogo, nao o do
                # site — mesma decisao que `categorias.agrupar` ja tomava.
                parceiro=parceiro,
                valor_de_disparo=alertas.valor_de_disparo(parceiro, loja, preferencias),  # RN30
                alertou=alertas.merece_alerta(parceiro, loja, preferencias),  # RN27
            )
        )

    return RetratoDaExecucao(
        momento=agora,
        parceiros_lidos=len(parceiros),
        versao=versao,
        catalogo=tuple(parceiros),
        pontuacoes=tuple(pontuacoes),
    )
