"""Fila Postgres entre o workflow Pichau e o executor Android local."""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path

import psycopg

ESTADOS_TERMINAIS = {"sucesso", "falha"}
ORIGENS_VALIDAS = {"schedule", "workflow_dispatch"}
INTERVALO_PADRAO_SEGUNDOS = 30
PRAZO_PADRAO_SEGUNDOS = 20 * 60
LEASE_PADRAO_SEGUNDOS = 30 * 60
CAMINHO_RUNNER = Path(__file__).resolve().parents[2] / "scripts" / "pichau-android-run.sh"
CODIGOS_RUNNER = {
    30: "adb-ausente",
    31: "adb-servidor",
    32: "adb-wifi-descoberta",
    33: "adb-wifi-conexao",
    34: "adb-wifi-estado",
}


class FalhaFilaAndroid(RuntimeError):
    """Falha operacional segura da fila, sem expor credenciais ou payload."""


def codigo_falha_runner(codigo: int) -> str:
    """Converte códigos técnicos em motivos operacionais sem dados privados."""

    return CODIGOS_RUNNER.get(codigo, f"runner-{codigo}")


@dataclass(frozen=True, slots=True)
class TrabalhoAndroid:
    id: int
    chave_idempotencia: str
    origem: str
    estado: str
    tentativas: int
    execucao_id: int | None
    codigo_falha: str | None


def validar_database_url(database_url: str | None) -> str:
    valor = (database_url or "").strip()
    if not valor:
        raise FalhaFilaAndroid("DATABASE_URL nao configurada para a fila Android.")
    if not any(
        marcador in valor
        for marcador in ("sslmode=require", "sslmode=verify-ca", "sslmode=verify-full")
    ):
        raise FalhaFilaAndroid("DATABASE_URL da fila precisa exigir SSL.")
    return valor


def validar_chave_idempotencia(chave: str) -> str:
    valor = chave.strip()
    if (
        not valor
        or len(valor) > 160
        or any(
            caractere not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789:_-"
            for caractere in valor
        )
    ):
        raise FalhaFilaAndroid("chave de idempotencia invalida.")
    return valor


def validar_origem(origem: str) -> str:
    if origem not in ORIGENS_VALIDAS:
        raise FalhaFilaAndroid("origem de disparo invalida.")
    return origem


def _conectar(database_url: str):
    return psycopg.connect(validar_database_url(database_url))


def _trabalho(linha: tuple[object, ...] | None) -> TrabalhoAndroid | None:
    if linha is None:
        return None
    return TrabalhoAndroid(
        id=int(linha[0]),
        chave_idempotencia=str(linha[1]),
        origem=str(linha[2]),
        estado=str(linha[3]),
        tentativas=int(linha[4]),
        execucao_id=int(linha[5]) if linha[5] is not None else None,
        codigo_falha=str(linha[6]) if linha[6] is not None else None,
    )


COLUNAS_TRABALHO = """
    id, chave_idempotencia, origem, estado, tentativas, execucao_id, codigo_falha
"""
COLUNAS_TRABALHO_FILA = """
    fila.id, fila.chave_idempotencia, fila.origem, fila.estado,
    fila.tentativas, fila.execucao_id, fila.codigo_falha
"""


def enfileirar(
    database_url: str,
    *,
    chave_idempotencia: str,
    origem: str,
    github_run_id: int | None = None,
) -> TrabalhoAndroid:
    chave = validar_chave_idempotencia(chave_idempotencia)
    origem_validada = validar_origem(origem)
    with _conectar(database_url) as conexao, conexao.cursor() as cursor:
        cursor.execute(
            f"""
            INSERT INTO pichau_android_fila (
                chave_idempotencia, origem, github_run_id, estado
            ) VALUES (%s, %s, %s, 'pendente')
            ON CONFLICT (chave_idempotencia) DO NOTHING
            RETURNING {COLUNAS_TRABALHO}
            """,
            (chave, origem_validada, github_run_id),
        )
        linha = cursor.fetchone()
        if linha is None:
            cursor.execute(
                f"""
                SELECT {COLUNAS_TRABALHO}
                  FROM pichau_android_fila
                 WHERE chave_idempotencia = %s
                """,
                (chave,),
            )
            linha = cursor.fetchone()
    trabalho = _trabalho(linha)
    if trabalho is None:
        raise FalhaFilaAndroid("nao foi possivel criar ou localizar a solicitacao Android.")
    return trabalho


def obter(database_url: str, trabalho_id: int) -> TrabalhoAndroid:
    with _conectar(database_url) as conexao, conexao.cursor() as cursor:
        cursor.execute(
            f"""
            SELECT {COLUNAS_TRABALHO}
              FROM pichau_android_fila
             WHERE id = %s
            """,
            (trabalho_id,),
        )
        trabalho = _trabalho(cursor.fetchone())
    if trabalho is None:
        raise FalhaFilaAndroid("solicitacao Android nao encontrada.")
    return trabalho


def aguardar(
    database_url: str,
    trabalho_id: int,
    *,
    prazo_segundos: int = PRAZO_PADRAO_SEGUNDOS,
    intervalo_segundos: int = INTERVALO_PADRAO_SEGUNDOS,
    dormir=time.sleep,
) -> TrabalhoAndroid:
    limite = time.monotonic() + prazo_segundos
    ultimo_estado: str | None = None
    while True:
        trabalho = obter(database_url, trabalho_id)
        if trabalho.estado != ultimo_estado:
            print(
                "Pichau Android fila: "
                f"id={trabalho.id} estado={trabalho.estado} tentativas={trabalho.tentativas}"
            )
            ultimo_estado = trabalho.estado
        if trabalho.estado in ESTADOS_TERMINAIS:
            if trabalho.estado == "falha":
                codigo = trabalho.codigo_falha or "runner"
                raise FalhaFilaAndroid(f"runner Android terminou com falha: {codigo}")
            return trabalho
        if time.monotonic() >= limite:
            raise FalhaFilaAndroid("tempo limite aguardando o executor Android.")
        dormir(intervalo_segundos)


def reivindicar(
    database_url: str,
    *,
    lease_segundos: int = LEASE_PADRAO_SEGUNDOS,
) -> TrabalhoAndroid | None:
    with _conectar(database_url) as conexao, conexao.cursor() as cursor:
        cursor.execute(
            f"""
            WITH candidata AS (
                SELECT id
                  FROM pichau_android_fila
                 WHERE estado = 'pendente'
                    OR (estado = 'executando' AND lease_ate <= now())
                 ORDER BY criada_em, id
                 FOR UPDATE SKIP LOCKED
                 LIMIT 1
            )
            UPDATE pichau_android_fila fila
               SET estado = 'executando',
                   tentativas = fila.tentativas + 1,
                   iniciada_em = now(),
                   concluida_em = NULL,
                   lease_ate = now() + make_interval(secs => %s),
                   codigo_falha = NULL
              FROM candidata
             WHERE fila.id = candidata.id
            RETURNING {COLUNAS_TRABALHO_FILA}
            """,
            (lease_segundos,),
        )
        trabalho = _trabalho(cursor.fetchone())
    return trabalho


def finalizar(
    database_url: str,
    trabalho_id: int,
    *,
    sucesso: bool,
    codigo_falha: str | None = None,
    execucao_id: int | None = None,
) -> None:
    estado = "sucesso" if sucesso else "falha"
    codigo = None if sucesso else (codigo_falha or "runner")[:80]
    with _conectar(database_url) as conexao, conexao.cursor() as cursor:
        cursor.execute(
            """
            UPDATE pichau_android_fila
               SET estado = %s,
                   concluida_em = now(),
                   lease_ate = NULL,
                   codigo_falha = %s,
                   execucao_id = %s
             WHERE id = %s AND estado = 'executando'
            """,
            (estado, codigo, execucao_id, trabalho_id),
        )


def executar_trabalho(
    database_url: str,
    *,
    runner: Path = CAMINHO_RUNNER,
    executar=subprocess.run,
) -> bool | None:
    trabalho = reivindicar(database_url)
    if trabalho is None:
        return None
    try:
        # A credencial é necessária para a fila Python, mas não deve ser
        # herdada pelo Appium/ADB nem por processos filhos do navegador.
        ambiente = os.environ.copy()
        ambiente.pop("DATABASE_URL", None)
        resultado = executar(
            [str(runner)],
            cwd=str(runner.parent.parent),
            check=False,
            env=ambiente,
        )
        sucesso = resultado.returncode == 0
        codigo = None if sucesso else codigo_falha_runner(resultado.returncode)
    except OSError:
        sucesso = False
        codigo = "runner-indisponivel"
    finalizar(database_url, trabalho.id, sucesso=sucesso, codigo_falha=codigo)
    return sucesso


def _database_url_argumento(valor: str | None) -> str:
    return validar_database_url(valor or os.getenv("DATABASE_URL"))


def criar_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="comando", required=True)

    enqueue = subparsers.add_parser("enqueue", help="insere uma solicitacao")
    enqueue.add_argument("--database-url")
    enqueue.add_argument("--chave", required=True)
    enqueue.add_argument("--origem", required=True)
    enqueue.add_argument("--github-run-id", type=int)

    wait = subparsers.add_parser("wait", help="aguarda uma solicitacao")
    wait.add_argument("--database-url")
    wait.add_argument("--id", type=int, required=True)
    wait.add_argument("--timeout-seconds", type=int, default=PRAZO_PADRAO_SEGUNDOS)
    wait.add_argument("--poll-seconds", type=int, default=INTERVALO_PADRAO_SEGUNDOS)

    worker = subparsers.add_parser("worker", help="processa uma solicitacao pendente")
    worker.add_argument("--database-url")
    worker.add_argument("--once", action="store_true")
    return parser


def executar_cli(argv: list[str] | None = None) -> int:
    argumentos = criar_parser().parse_args(argv)
    database_url = _database_url_argumento(getattr(argumentos, "database_url", None))
    if argumentos.comando == "enqueue":
        trabalho = enfileirar(
            database_url,
            chave_idempotencia=argumentos.chave,
            origem=argumentos.origem,
            github_run_id=argumentos.github_run_id,
        )
        print(trabalho.id)
        return 0
    if argumentos.comando == "wait":
        aguardar(
            database_url,
            argumentos.id,
            prazo_segundos=argumentos.timeout_seconds,
            intervalo_segundos=argumentos.poll_seconds,
        )
        return 0
    resultado = executar_trabalho(database_url)
    return 1 if resultado is False else 0


if __name__ == "__main__":
    try:
        raise SystemExit(executar_cli())
    except FalhaFilaAndroid as erro:
        print(f"Pichau Android fila: {erro}", file=sys.stderr)
        raise SystemExit(2) from erro
