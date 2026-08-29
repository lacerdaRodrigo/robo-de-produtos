"""Cria o esquema no Postgres e carrega o catalogo do TOML.

Uso:
    python scripts/carregar_catalogo.py

Le DATABASE_URL do .env. Idempotente: rodar duas vezes nao duplica nada.
O TOML continua sendo a carga inicial; a fonte da verdade passa a ser o
banco (PRD V2, secao 3.3).
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

import psycopg
from dotenv import load_dotenv

from robo_livelo.adaptadores import CatalogoArquivo

RAIZ = Path(__file__).resolve().parents[3]
ESQUEMA = RAIZ / "migracoes" / "001_esquema.sql"
CATALOGO = Path(__file__).resolve().parents[1] / "config" / "lojas_favoritas.toml"


def principal() -> int:
    load_dotenv()
    url = os.environ.get("DATABASE_URL", "")
    if not url:
        print("DATABASE_URL nao configurada. Preencha o .env.", file=sys.stderr)
        return 1

    lojas = CatalogoArquivo(CATALOGO).listar()
    print(f"Catalogo lido: {len(lojas)} lojas.")

    with psycopg.connect(url) as conexao, conexao.cursor() as cursor:
        cursor.execute(ESQUEMA.read_text(encoding="utf-8"))
        print("Esquema aplicado.")

        for loja in lojas:
            cursor.execute(
                """
                INSERT INTO loja (nome, categoria) VALUES (%s, %s)
                ON CONFLICT (nome) DO UPDATE SET categoria = EXCLUDED.categoria
                RETURNING id
                """,
                (loja.nome, loja.categoria),
            )
            loja_id = cursor.fetchone()[0]

            for apelido in loja.apelidos:
                cursor.execute(
                    """
                    INSERT INTO apelido (loja_id, texto) VALUES (%s, %s)
                    ON CONFLICT (texto) DO NOTHING
                    """,
                    (loja_id, apelido),
                )

        cursor.execute("SELECT COUNT(*) FROM loja")
        total_lojas = cursor.fetchone()[0]
        cursor.execute("SELECT COUNT(*) FROM apelido")
        total_apelidos = cursor.fetchone()[0]

    print(f"Banco carregado: {total_lojas} lojas, {total_apelidos} apelidos.")
    return 0


if __name__ == "__main__":
    sys.exit(principal())
