"""Fila idempotente de pedidos manuais Livelo e Inter."""

from __future__ import annotations

import argparse
import os
import re
import sys
from collections.abc import Callable
from dataclasses import dataclass
from urllib.parse import parse_qs, urlsplit

import psycopg

from robo_celular.executores import executar_fonte

FONTES_VALIDAS = {"livelo", "inter"}
CODIGO_SEGURO = re.compile(r"^[a-z0-9][a-z0-9_-]{0,79}$")


class FalhaFilaColeta(RuntimeError):
    """Falha operacional que não inclui URL, senha ou detalhe do driver."""


@dataclass(frozen=True, slots=True)
class TrabalhoColeta:
    id: int
    fonte: str
    github_run_id: int
    tentativas: int


def _conectar(database_url: str):
    return psycopg.connect(validar_database_url(database_url), connect_timeout=10)


def validar_database_url(valor: str | None) -> str:
    url = (valor or "").strip()
    if not url:
        raise FalhaFilaColeta("DATABASE_URL ausente para a fila de coletas.")
    analisada = urlsplit(url)
    if analisada.scheme not in {"postgres", "postgresql"} or not analisada.hostname:
        raise FalhaFilaColeta("DATABASE_URL inválida para a fila de coletas.")
    sslmode = parse_qs(analisada.query).get("sslmode", [""])[0]
    if sslmode not in {"require", "verify-ca", "verify-full"}:
        raise FalhaFilaColeta("DATABASE_URL precisa exigir SSL.")
    return url


def validar_fonte(fonte: str) -> str:
    if fonte not in FONTES_VALIDAS:
        raise FalhaFilaColeta("fonte de coleta inválida.")
    return fonte


def solicitar(database_url: str, fonte: str, github_run_id: int) -> int:
    fonte_validada = validar_fonte(fonte)
    if github_run_id <= 0:
        raise FalhaFilaColeta("identificador da execução GitHub inválido.")
    try:
        with _conectar(database_url) as conexao, conexao.cursor() as cursor:
            cursor.execute(
                "SELECT public.solicitar_coleta_android(%s, %s)",
                (fonte_validada, github_run_id),
            )
            linha = cursor.fetchone()
    except psycopg.Error as erro:
        raise FalhaFilaColeta("não foi possível registrar o pedido manual.") from erro
    if linha is None or not isinstance(linha[0], int):
        raise FalhaFilaColeta("o banco não confirmou o pedido manual.")
    return linha[0]


def reivindicar(
    database_url: str,
    fonte: str,
    github_run_id: int | None = None,
) -> TrabalhoColeta | None:
    fonte_validada = validar_fonte(fonte)
    try:
        with _conectar(database_url) as conexao, conexao.cursor() as cursor:
            cursor.execute(
                "SELECT * FROM public.reivindicar_coleta_android(%s, %s)",
                (fonte_validada, github_run_id),
            )
            linha = cursor.fetchone()
    except psycopg.Error as erro:
        raise FalhaFilaColeta("não foi possível consultar os pedidos manuais.") from erro
    if linha is None:
        return None
    return TrabalhoColeta(
        id=int(linha[0]),
        fonte=str(linha[1]),
        github_run_id=int(linha[2]),
        tentativas=int(linha[3]),
    )


def finalizar(
    database_url: str,
    trabalho_id: int,
    *,
    sucesso: bool,
    codigo_falha: str | None = None,
) -> None:
    codigo = None
    if not sucesso:
        candidato = (codigo_falha or "coleta").lower()
        codigo = candidato if CODIGO_SEGURO.fullmatch(candidato) else "coleta"
    try:
        with _conectar(database_url) as conexao, conexao.cursor() as cursor:
            cursor.execute(
                "SELECT public.finalizar_coleta_android(%s, %s, %s)",
                (trabalho_id, sucesso, codigo),
            )
    except psycopg.Error as erro:
        raise FalhaFilaColeta("não foi possível registrar o resultado da coleta.") from erro


def consultar_estado(database_url: str, fonte: str, github_run_id: int) -> str | None:
    fonte_validada = validar_fonte(fonte)
    try:
        with _conectar(database_url) as conexao, conexao.cursor() as cursor:
            cursor.execute(
                "SELECT public.consultar_coleta_android(%s, %s)",
                (fonte_validada, github_run_id),
            )
            linha = cursor.fetchone()
    except psycopg.Error as erro:
        raise FalhaFilaColeta("não foi possível consultar o estado do pedido.") from erro
    return str(linha[0]) if linha is not None and linha[0] is not None else None


def processar_pedido(
    database_url: str,
    fonte: str,
    *,
    github_run_id: int | None = None,
    executar: Callable[[str], int] = executar_fonte,
) -> bool | None:
    trabalho = reivindicar(database_url, fonte, github_run_id)
    if trabalho is None:
        return None
    try:
        codigo = executar(trabalho.fonte)
    except Exception:
        codigo = 1
    finalizar(
        database_url,
        trabalho.id,
        sucesso=codigo == 0,
        codigo_falha=None if codigo == 0 else f"coleta-{trabalho.fonte}",
    )
    return codigo == 0


def criar_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subcomandos = parser.add_subparsers(dest="comando", required=True)
    subcomandos.add_parser("health", help="confirma acesso seguro à fila manual")
    enqueue = subcomandos.add_parser("solicitar", help="enfileira uma coleta manual")
    enqueue.add_argument("--fonte", choices=sorted(FONTES_VALIDAS), required=True)
    enqueue.add_argument("--github-run-id", type=int, required=True)
    return parser


def principal(argv: list[str] | None = None) -> int:
    argumentos = criar_parser().parse_args(argv)
    database_url = os.getenv("DATABASE_URL", "")
    if argumentos.comando == "health":
        try:
            consultar_estado(database_url, "livelo", -1)
        except FalhaFilaColeta as erro:
            print(f"Fila de coletas: {erro}", file=sys.stderr)
            return 2
        print("Fila de coletas: Neon acessível.")
        return 0
    try:
        identificador = solicitar(
            database_url,
            argumentos.fonte,
            argumentos.github_run_id,
        )
    except FalhaFilaColeta as erro:
        print(f"Fila de coletas: {erro}", file=sys.stderr)
        return 2
    print(f"Pedido {argumentos.fonte} enfileirado: id={identificador}")
    return 0


if __name__ == "__main__":
    raise SystemExit(principal())
