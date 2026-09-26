"""Estado pequeno e local do agendador, sem catálogo ou histórico comercial."""

from __future__ import annotations

import os
import sqlite3
from collections.abc import Iterable, Iterator
from contextlib import contextmanager
from pathlib import Path


class EstadoLocal:
    def __init__(self, caminho: Path) -> None:
        self.caminho = caminho
        self.caminho.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
        with self._conectar() as conexao:
            conexao.execute("PRAGMA journal_mode=WAL")
            conexao.executescript(
                """
                CREATE TABLE IF NOT EXISTS metadado (
                    chave TEXT PRIMARY KEY,
                    valor TEXT NOT NULL
                );
                CREATE TABLE IF NOT EXISTS execucao_agendada (
                    chave TEXT PRIMARY KEY,
                    estado TEXT NOT NULL CHECK (estado IN ('iniciada', 'sucesso', 'falha')),
                    iniciada_em TEXT NOT NULL,
                    concluida_em TEXT
                );
                CREATE TABLE IF NOT EXISTS github_run_visto (
                    run_id INTEGER PRIMARY KEY,
                    visto_em TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
                );
                """
            )
        os.chmod(self.caminho, 0o600)

    @contextmanager
    def _conectar(self) -> Iterator[sqlite3.Connection]:
        conexao = sqlite3.connect(self.caminho, timeout=10)
        conexao.execute("PRAGMA synchronous=FULL")
        try:
            with conexao:
                yield conexao
        finally:
            conexao.close()

    def metadado(self, chave: str) -> str | None:
        with self._conectar() as conexao:
            linha = conexao.execute(
                "SELECT valor FROM metadado WHERE chave = ?", (chave,)
            ).fetchone()
        return str(linha[0]) if linha else None

    def gravar_metadado(self, chave: str, valor: str) -> None:
        with self._conectar() as conexao:
            conexao.execute(
                "INSERT INTO metadado (chave, valor) VALUES (?, ?) "
                "ON CONFLICT (chave) DO UPDATE SET valor = excluded.valor",
                (chave, valor),
            )

    def inicializar_github(self, run_ids: Iterable[int], etag: str | None) -> None:
        with self._conectar() as conexao:
            conexao.executemany(
                "INSERT OR IGNORE INTO github_run_visto (run_id) VALUES (?)",
                ((run_id,) for run_id in run_ids),
            )
            conexao.execute(
                "INSERT INTO metadado (chave, valor) VALUES ('github_inicializado', 'sim') "
                "ON CONFLICT (chave) DO UPDATE SET valor = excluded.valor"
            )
            if etag:
                conexao.execute(
                    "INSERT INTO metadado (chave, valor) VALUES ('github_etag', ?) "
                    "ON CONFLICT (chave) DO UPDATE SET valor = excluded.valor",
                    (etag,),
                )

    def run_foi_visto(self, run_id: int) -> bool:
        with self._conectar() as conexao:
            linha = conexao.execute(
                "SELECT 1 FROM github_run_visto WHERE run_id = ?", (run_id,)
            ).fetchone()
        return linha is not None

    def marcar_run_visto(self, run_id: int) -> None:
        with self._conectar() as conexao:
            conexao.execute("INSERT OR IGNORE INTO github_run_visto (run_id) VALUES (?)", (run_id,))

    def reservar_agendamento(self, chave: str, iniciada_em: str) -> bool:
        with self._conectar() as conexao:
            cursor = conexao.execute(
                "INSERT OR IGNORE INTO execucao_agendada (chave, estado, iniciada_em) "
                "VALUES (?, 'iniciada', ?)",
                (chave, iniciada_em),
            )
        return cursor.rowcount == 1

    def concluir_agendamento(self, chave: str, *, sucesso: bool, concluida_em: str) -> None:
        with self._conectar() as conexao:
            conexao.execute(
                "UPDATE execucao_agendada SET estado = ?, concluida_em = ? WHERE chave = ?",
                ("sucesso" if sucesso else "falha", concluida_em, chave),
            )
