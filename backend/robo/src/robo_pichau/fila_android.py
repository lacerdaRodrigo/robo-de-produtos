"""Fila Postgres entre o workflow Pichau e o executor Android local."""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
import time
from collections.abc import Callable
from dataclasses import dataclass, field
from pathlib import Path

import psycopg

from .diagnostico import formatar_diagnostico, sanitizar_diagnostico

ESTADOS_TERMINAIS = {"sucesso", "falha"}
ORIGENS_VALIDAS = {"schedule", "workflow_dispatch"}
INTERVALO_PADRAO_SEGUNDOS = 30
PRAZO_PADRAO_SEGUNDOS = 20 * 60
LEASE_PADRAO_SEGUNDOS = 30 * 60
CAMINHO_RUNNER = Path(__file__).resolve().parents[2] / "scripts" / "pichau-android-run.sh"
CAMINHO_REPOSITORIO = Path(__file__).resolve().parents[4]
CODIGOS_RUNNER = {
    1: "runner-inesperado",
    2: "runner-inesperado",
    30: "adb-ausente",
    31: "adb-servidor",
    32: "adb-wifi-descoberta",
    33: "adb-wifi-conexao",
    34: "adb-wifi-estado",
    35: "appium",
    40: "pichau-configuracao",
    41: "pichau-navegador",
    42: "pichau-acesso",
    43: "pichau-dados",
    44: "pichau-banco",
    45: "pichau-parcial",
}
_CODIGO_FALHA_SEGURO = re.compile(r"^[a-z0-9][a-z0-9_-]{0,79}$")
_CHAVE_COM_COMMIT = re.compile(r"^github-[0-9]+-([0-9a-f]{40})$")


class FalhaFilaAndroid(RuntimeError):
    """Falha operacional segura da fila, sem expor credenciais ou payload."""


def codigo_falha_runner(codigo: int) -> str:
    """Converte códigos técnicos em motivos operacionais sem dados privados."""

    return CODIGOS_RUNNER.get(codigo, "runner-inesperado")


@dataclass(frozen=True, slots=True)
class TrabalhoAndroid:
    id: int
    chave_idempotencia: str
    origem: str
    estado: str
    tentativas: int
    execucao_id: int | None
    codigo_falha: str | None
    diagnostico: dict[str, object] = field(default_factory=dict)


def validar_codigo_falha(codigo: object, *, padrao: str = "runner") -> str:
    valor = str(codigo or "").strip().lower()
    return valor if _CODIGO_FALHA_SEGURO.fullmatch(valor) else padrao


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


def commit_solicitado(chave_idempotencia: str) -> str | None:
    """Extrai o commit do workflow novo, mantendo filas antigas compatíveis."""

    correspondencia = _CHAVE_COM_COMMIT.fullmatch(chave_idempotencia)
    return correspondencia.group(1) if correspondencia else None


def sincronizar_checkout(
    chave_idempotencia: str,
    *,
    repositorio: Path = CAMINHO_REPOSITORIO,
    executar=subprocess.run,
) -> None:
    """Avança o Samsung até ``origin/main`` e confirma o commit solicitante."""

    ambiente = os.environ.copy()
    ambiente["GIT_TERMINAL_PROMPT"] = "0"

    def git(*argumentos: str) -> subprocess.CompletedProcess[str]:
        try:
            resultado = executar(
                ["git", "-C", str(repositorio), *argumentos],
                check=False,
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                text=True,
                timeout=120,
                env=ambiente,
            )
        except (OSError, subprocess.TimeoutExpired) as erro:
            raise FalhaFilaAndroid("checkout do executor Android indisponivel.") from erro
        if resultado.returncode != 0:
            raise FalhaFilaAndroid("checkout do executor Android nao pode ser atualizado.")
        return resultado

    estado = git("status", "--porcelain", "--untracked-files=no").stdout
    if str(estado or "").strip():
        raise FalhaFilaAndroid("checkout do executor Android possui alteracoes locais.")
    head_anterior = str(git("rev-parse", "HEAD").stdout or "").strip()
    git(
        "fetch",
        "--quiet",
        "--no-tags",
        "origin",
        "+refs/heads/main:refs/remotes/origin/main",
    )
    git("merge", "--ff-only", "--quiet", "origin/main")

    commit = commit_solicitado(chave_idempotencia)
    if commit is not None:
        git("merge-base", "--is-ancestor", commit, "HEAD")
    head_atual = str(git("rev-parse", "HEAD").stdout or "").strip()

    if head_atual != head_anterior:
        try:
            resultado = executar(
                [
                    sys.executable,
                    "-m",
                    "pip",
                    "install",
                    "--disable-pip-version-check",
                    "--no-input",
                    "-e",
                    ".[pichau-android]",
                ],
                cwd=repositorio / "backend" / "robo",
                check=False,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                timeout=300,
                env=ambiente,
            )
        except (OSError, subprocess.TimeoutExpired) as erro:
            raise FalhaFilaAndroid("dependencias do executor Android indisponiveis.") from erro
        if resultado.returncode != 0:
            raise FalhaFilaAndroid("dependencias do executor Android nao podem ser atualizadas.")


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
        codigo_falha=(validar_codigo_falha(linha[6]) if linha[6] is not None else None),
        diagnostico=sanitizar_diagnostico(linha[7] if len(linha) > 7 else {}),
    )


COLUNAS_TRABALHO = """
    id, chave_idempotencia, origem, estado, tentativas, execucao_id, codigo_falha,
    diagnostico
"""
COLUNAS_TRABALHO_FILA = """
    fila.id, fila.chave_idempotencia, fila.origem, fila.estado,
    fila.tentativas, fila.execucao_id, fila.codigo_falha, fila.diagnostico
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


def verificar_saude(database_url: str) -> None:
    """Confirma acesso mínimo à fila sem expor detalhes da conexão."""

    try:
        with _conectar(database_url) as conexao, conexao.cursor() as cursor:
            cursor.execute("SELECT 1 FROM pichau_android_fila LIMIT 0")
    except psycopg.Error as erro:
        raise FalhaFilaAndroid("banco da fila Android indisponivel.") from erro


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
    ultimo_diagnostico = ""
    while True:
        trabalho = obter(database_url, trabalho_id)
        if trabalho.estado != ultimo_estado:
            print(
                "Pichau Android fila: "
                f"id={trabalho.id} estado={trabalho.estado} tentativas={trabalho.tentativas}",
                flush=True,
            )
            ultimo_estado = trabalho.estado
        diagnostico_formatado = formatar_diagnostico(trabalho.diagnostico)
        if diagnostico_formatado and diagnostico_formatado != ultimo_diagnostico:
            print(f"Pichau Android diagnostico: {diagnostico_formatado}", flush=True)
            if trabalho.diagnostico.get("estado") == "recuperando":
                _anotar_github("warning", diagnostico_formatado)
            ultimo_diagnostico = diagnostico_formatado
        if trabalho.estado in ESTADOS_TERMINAIS:
            codigo = "sucesso" if trabalho.estado == "sucesso" else _codigo_trabalho(trabalho)
            _escrever_resumo_github(trabalho, codigo=codigo)
            if trabalho.estado == "falha":
                _anotar_github("error", f"id={trabalho.id} codigo={codigo}")
                raise FalhaFilaAndroid(f"runner Android terminou com falha: {codigo}")
            return trabalho
        if time.monotonic() >= limite:
            if trabalho.estado == "pendente":
                _escrever_resumo_github(trabalho, codigo="executor-offline")
                _anotar_github("error", f"id={trabalho.id} codigo=executor-offline")
                raise FalhaFilaAndroid(
                    "executor Android nao reivindicou a solicitacao dentro do prazo: "
                    "executor-offline."
                )
            _escrever_resumo_github(trabalho, codigo="executor-timeout")
            _anotar_github("error", f"id={trabalho.id} codigo=executor-timeout")
            raise FalhaFilaAndroid("tempo limite aguardando o executor Android.")
        dormir(intervalo_segundos)


def _codigo_trabalho(trabalho: TrabalhoAndroid) -> str:
    diagnostico = sanitizar_diagnostico(trabalho.diagnostico)
    granular = diagnostico.get("codigo")
    if granular is not None:
        return validar_codigo_falha(granular)
    return validar_codigo_falha(trabalho.codigo_falha)


def _anotar_github(nivel: str, mensagem: str) -> None:
    if os.getenv("GITHUB_ACTIONS") == "true":
        print(f"::{nivel} title=Pichau Android::{mensagem}", flush=True)


def _escrever_resumo_github(trabalho: TrabalhoAndroid, *, codigo: str) -> None:
    caminho = os.getenv("GITHUB_STEP_SUMMARY", "").strip()
    if not caminho:
        return
    diagnostico = formatar_diagnostico(trabalho.diagnostico)
    linhas = [
        "### Pichau Android",
        "",
        f"- `id={trabalho.id} estado={trabalho.estado} tentativas={trabalho.tentativas}`",
        f"- `codigo={validar_codigo_falha(codigo)}`",
    ]
    if diagnostico:
        linhas.append(f"- `{diagnostico}`")
    try:
        with Path(caminho).open("a", encoding="utf-8") as arquivo:
            arquivo.write("\n".join(linhas) + "\n")
    except OSError:
        # O resumo é diagnóstico auxiliar; a fila continua sendo a fonte do
        # resultado e não deve mudar de estado por falha local do runner.
        return


def reivindicar(
    database_url: str,
    *,
    lease_segundos: int = LEASE_PADRAO_SEGUNDOS,
    prazo_pendente_segundos: int = PRAZO_PADRAO_SEGUNDOS,
) -> TrabalhoAndroid | None:
    with _conectar(database_url) as conexao, conexao.cursor() as cursor:
        # Uma pipeline que já desistiu não pode virar uma coleta atrasada quando
        # o telefone reaparecer horas depois. Jobs em execução permanecem sob o
        # lease e continuam recuperáveis pelo contrato existente.
        cursor.execute(
            """
            UPDATE pichau_android_fila
               SET estado = 'falha',
                   concluida_em = now(),
                   lease_ate = NULL,
                   codigo_falha = 'executor-offline'
             WHERE estado = 'pendente'
               AND criada_em <= now() - make_interval(secs => %s)
            """,
            (prazo_pendente_segundos,),
        )
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
                   codigo_falha = NULL,
                   diagnostico = '{{}}'::jsonb
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
    codigo = None if sucesso else validar_codigo_falha(codigo_falha)
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
    sincronizar: Callable[[str], None] = sincronizar_checkout,
) -> bool | None:
    trabalho = reivindicar(database_url)
    if trabalho is None:
        return None
    print(
        f"Pichau Android fila: id={trabalho.id} estado=executando tentativas={trabalho.tentativas}",
        flush=True,
    )
    try:
        sincronizar(trabalho.chave_idempotencia)
        print(
            f"Pichau Android fila: id={trabalho.id} checkout=ok",
            flush=True,
        )
        # A credencial é necessária para a fila Python, mas não deve ser
        # herdada pelo Appium/ADB nem por processos filhos do navegador.
        ambiente = os.environ.copy()
        ambiente.pop("DATABASE_URL", None)
        ambiente["PICHAU_ANDROID_FILA_ID"] = str(trabalho.id)
        resultado = executar(
            [str(runner)],
            cwd=str(runner.parent.parent),
            check=False,
            env=ambiente,
        )
        sucesso = resultado.returncode == 0
        codigo = None if sucesso else codigo_falha_runner(resultado.returncode)
    except FalhaFilaAndroid:
        sucesso = False
        codigo = "pichau-checkout"
    except OSError:
        sucesso = False
        codigo = "runner-indisponivel"
    atual = obter(database_url, trabalho.id)
    if not sucesso:
        codigo = _codigo_trabalho(atual) if atual.diagnostico else codigo
    finalizar(
        database_url,
        trabalho.id,
        sucesso=sucesso,
        codigo_falha=codigo,
        execucao_id=atual.diagnostico.get("execucao_id")
        if isinstance(atual.diagnostico.get("execucao_id"), int)
        else None,
    )
    estado = "sucesso" if sucesso else "falha"
    print(
        f"Pichau Android fila: id={trabalho.id} estado={estado} tentativas={trabalho.tentativas}",
        flush=True,
    )
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

    health = subparsers.add_parser("health", help="confirma acesso ao banco da fila")
    health.add_argument("--database-url")
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
    if argumentos.comando == "health":
        verificar_saude(database_url)
        print("Pichau Android fila: banco acessivel.")
        return 0
    resultado = executar_trabalho(database_url)
    return 1 if resultado is False else 0


if __name__ == "__main__":
    try:
        raise SystemExit(executar_cli())
    except FalhaFilaAndroid as erro:
        print(f"Pichau Android fila: {erro}", file=sys.stderr)
        raise SystemExit(2) from erro
