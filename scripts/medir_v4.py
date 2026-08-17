"""Mede uma coleta V4 completa sem escrever no banco (gate V4.1)."""

from __future__ import annotations

import argparse
import json
import time
from datetime import UTC, datetime

from robo_livelo.adaptadores_produtos_inter import (
    FonteLojasDiretasInterHttp,
    FonteProdutosInterHttp,
)
from robo_livelo.extrator_produtos_inter import extrair_lojas_diretas, normalizar_busca_produtos
from robo_livelo.modelos_produtos_inter import (
    LojaDiretaInter,
    ProdutoDiretoInter,
    ResumoColetaProdutosInter,
)
from robo_livelo.principal_produtos_inter import BUSCAS_SUPLEMENTARES, coletar_produtos_de_loja


class RepositorioSomenteMedicao:
    """Porta em memoria: prova pagina/deduplicacao sem tocar no Neon."""

    def __init__(self) -> None:
        self.resumo: ResumoColetaProdutosInter | None = None

    def iniciar_loja(
        self,
        loja: LojaDiretaInter,
        momento: datetime,
        versao: str,
        *,
        rodada_id: int | None = None,
    ) -> int:
        return 1

    def publicar_loja(
        self,
        execucao_id: int,
        loja: LojaDiretaInter,
        produtos: tuple[ProdutoDiretoInter, ...],
        resumo: ResumoColetaProdutosInter,
    ) -> None:
        self.resumo = resumo

    def falhar_loja(self, execucao_id: int, codigo: str) -> None:
        return None


def principal() -> int:
    argumentos = argparse.ArgumentParser(description=__doc__)
    argumentos.add_argument("--loja", default="casas-bahia", help="slug da loja direta")
    opcoes = argumentos.parse_args()

    inicio = time.perf_counter()
    lojas = extrair_lojas_diretas(FonteLojasDiretasInterHttp().obter_json())
    alvo = normalizar_busca_produtos(opcoes.loja)
    loja = next((item for item in lojas if normalizar_busca_produtos(item.slug) == alvo), None)
    if loja is None:
        print(json.dumps({"erro": "loja_nao_encontrada", "lojas_lidas": len(lojas)}))
        return 1

    repositorio = RepositorioSomenteMedicao()
    resumo = coletar_produtos_de_loja(
        FonteProdutosInterHttp(),
        repositorio,
        loja,
        agora=datetime.now(UTC),
        buscas_suplementares=BUSCAS_SUPLEMENTARES,
        intervalo_paginas=1.5,
    )
    print(
        json.dumps(
            {
                "loja": loja.slug,
                "lojas_diretas_lidas": len(lojas),
                "total_declarado": resumo.total_declarado,
                "paginas": resumo.paginas,
                "itens_lidos": resumo.itens_lidos,
                "itens_unicos": resumo.itens_unicos,
                "duplicados": resumo.duplicados,
                "duracao_segundos": round(time.perf_counter() - inicio, 2),
            },
            ensure_ascii=False,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(principal())
