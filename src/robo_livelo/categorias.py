"""Nucleo puro: reconhece lojas favoritas, agrupa e ordena.

Regras aplicadas aqui: RN01, RN03, RN04, RN05, RN14, RF06.
"""

from __future__ import annotations

import unicodedata

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


def agrupar(parceiros: list[Parceiro], favoritas: list[LojaFavorita]) -> dict[str, list[Parceiro]]:
    """Agrupa por categoria as favoritas que estao em promocao.

    Descarta quem nao e favorita (RN05) e quem nao esta em promocao (RF04).
    Ordena categorias por nome e lojas por pontuacao decrescente (RF06).
    Categoria sem loja nao aparece (RN14).
    """
    indice = _indice(favoritas)
    agrupado: dict[str, list[Parceiro]] = {}

    for parceiro in parceiros:
        if not parceiro.em_promocao:
            continue
        loja = indice.get(normalizar(parceiro.nome))
        if loja is None:
            continue
        # RN01: a loja tem uma categoria fixa, e o nome exibido e o canonico.
        agrupado.setdefault(loja.categoria, []).append(parceiro)

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
