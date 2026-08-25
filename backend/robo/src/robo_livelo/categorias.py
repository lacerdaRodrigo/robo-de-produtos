"""Nucleo puro: reconhece lojas favoritas, agrupa e ordena.

Regras aplicadas aqui: RN01, RN03, RN04, RN05, RN14, RF06.
"""

from __future__ import annotations

import unicodedata
from collections.abc import Callable
from dataclasses import replace

from robo_livelo.modelos import LojaFavorita, Parceiro


def normalizar(texto: str) -> str:
    """RN03: ignora acentuacao, caixa e espacos nas bordas.

    Nao mexe em pontuacao de proposito: e por isso que "C&A" precisa do
    apelido "CEA" e "Booking.com" precisa de "Booking com" (PRD 5.3).
    """
    sem_acento = unicodedata.normalize("NFKD", texto.strip())
    sem_acento = "".join(c for c in sem_acento if not unicodedata.combining(c))
    return " ".join(sem_acento.casefold().split())


def _indice(favoritas: list[LojaFavorita]) -> dict[str, LojaFavorita]:
    """Mapeia cada grafia aceita para sua loja. RN04: so correspondencia exata."""
    indice: dict[str, LojaFavorita] = {}
    for loja in favoritas:
        for grafia in (loja.nome, *loja.apelidos):
            chave = normalizar(grafia)
            if chave:
                indice[chave] = loja
    return indice


def reconhecer(nome: str, favoritas: list[LojaFavorita]) -> LojaFavorita | None:
    """Devolve a loja favorita correspondente, ou None (RN05).

    RN04 proibe substring: e o que impede "Petlove" de capturar
    "Petlove Saude", que e outro parceiro com pontuacao propria.
    """
    return _indice(favoritas).get(normalizar(nome))


def em_promocao(parceiro: Parceiro, loja: LojaFavorita) -> bool:
    """Criterio da V1: vale a etiqueta que a Livelo pendurou (RF04).

    Continua aqui como default porque agrupar nao precisa saber de limiar
    para agrupar. Quem roda o robo passa o criterio de RN27, montado em
    `alertas.criterio_de_alerta` — este e o piso, nao a regra em producao.
    """
    return parceiro.em_promocao


def agrupar(
    parceiros: list[Parceiro],
    favoritas: list[LojaFavorita],
    criterio: Callable[[Parceiro, LojaFavorita], bool] = em_promocao,
) -> dict[str, list[Parceiro]]:
    """Agrupa por categoria as favoritas que o criterio aprovar.

    Descarta quem nao e favorita (RN05) e quem o criterio recusar. Ordena
    categorias por nome e lojas por pontuacao decrescente (RF06). Categoria
    sem loja nao aparece (RN14).
    """
    indice = _indice(favoritas)
    agrupado: dict[str, list[Parceiro]] = {}

    for parceiro in parceiros:
        loja = indice.get(normalizar(parceiro.nome))
        if loja is None:
            continue
        if not criterio(parceiro, loja):
            continue
        # RN01: categoria fixa por loja. O nome exibido passa a ser o canonico
        # do catalogo, nao o do site: a Livelo escreve "CEA", "Booking com" e
        # "O Boticario", e quem le o e-mail espera "C&A", "Booking.com" e
        # "O Boticario" com acento. O nome do site ja cumpriu seu papel no
        # reconhecimento (RN04).
        agrupado.setdefault(loja.categoria, []).append(replace(parceiro, nome=loja.nome))

    return {
        categoria: sorted(lista, key=lambda p: p.pontos_atuais, reverse=True)
        for categoria, lista in sorted(agrupado.items())
        if lista
    }


def favoritas_ausentes(parceiros: list[Parceiro], favoritas: list[LojaFavorita]) -> list[str]:
    """RN19: favoritas que nao apareceram na pagina.

    Contrapeso de RN04. Um apelido novo criado pela Livelo faria a loja
    sumir do e-mail em silencio; esta lista vai para o log.
    """
    encontradas = {normalizar(p.nome) for p in parceiros}
    ausentes = [
        loja.nome
        for loja in favoritas
        if not {normalizar(g) for g in (loja.nome, *loja.apelidos)} & encontradas
    ]
    return sorted(ausentes)
