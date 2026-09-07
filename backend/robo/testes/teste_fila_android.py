from __future__ import annotations

from pathlib import Path
from types import SimpleNamespace

import pytest

from robo_pichau import fila_android


class CursorFalso:
    def __init__(self, respostas: list[tuple[object, ...] | None]) -> None:
        self.respostas = respostas
        self.consultas: list[tuple[str, object]] = []

    def __enter__(self) -> CursorFalso:
        return self

    def __exit__(self, *_args: object) -> None:
        return None

    def execute(self, consulta: str, parametros: object = None) -> None:
        self.consultas.append((consulta, parametros))

    def fetchone(self) -> tuple[object, ...] | None:
        return self.respostas.pop(0)


class ConexaoFalsa:
    def __init__(self, cursor: CursorFalso) -> None:
        self._cursor = cursor

    def __enter__(self) -> ConexaoFalsa:
        return self

    def __exit__(self, *_args: object) -> None:
        return None

    def cursor(self) -> CursorFalso:
        return self._cursor


def trabalho(id_: int = 7, estado: str = "executando") -> fila_android.TrabalhoAndroid:
    return fila_android.TrabalhoAndroid(
        id=id_,
        chave_idempotencia="github-7",
        origem="workflow_dispatch",
        estado=estado,
        tentativas=1,
        execucao_id=None,
        codigo_falha=None,
    )


def teste_fila_valida_url_chave_e_origem_sem_expor_segredo() -> None:
    assert fila_android.validar_database_url("postgres://db?sslmode=require")
    assert fila_android.validar_chave_idempotencia("github-123_abc") == "github-123_abc"
    assert fila_android.validar_origem("schedule") == "schedule"
    with pytest.raises(fila_android.FalhaFilaAndroid):
        fila_android.validar_database_url("postgres://db")
    with pytest.raises(fila_android.FalhaFilaAndroid):
        fila_android.validar_chave_idempotencia("github/123")
    with pytest.raises(fila_android.FalhaFilaAndroid):
        fila_android.validar_origem("outro")


def teste_enfileirar_eh_idempotente_e_retorna_id_existente(monkeypatch) -> None:
    linha = (7, "github-7", "workflow_dispatch", "pendente", 0, None, None)
    cursor = CursorFalso([linha])
    conexao = ConexaoFalsa(cursor)
    monkeypatch.setattr(fila_android, "_conectar", lambda _url: conexao)

    resultado = fila_android.enfileirar(
        "postgres://db?sslmode=require",
        chave_idempotencia="github-7",
        origem="workflow_dispatch",
        github_run_id=7,
    )

    assert resultado == fila_android.TrabalhoAndroid(
        id=7,
        chave_idempotencia="github-7",
        origem="workflow_dispatch",
        estado="pendente",
        tentativas=0,
        execucao_id=None,
        codigo_falha=None,
    )
    assert len(cursor.consultas) == 1
    assert "ON CONFLICT" in cursor.consultas[0][0]
    assert cursor.consultas[0][1] == ("github-7", "workflow_dispatch", 7)


def teste_reivindicar_usa_lease_e_pode_recuperar_trabalho_abandonado(monkeypatch) -> None:
    linha = (7, "github-7", "schedule", "executando", 2, None, None)
    cursor = CursorFalso([linha])
    conexao = ConexaoFalsa(cursor)
    monkeypatch.setattr(fila_android, "_conectar", lambda _url: conexao)

    resultado = fila_android.reivindicar("postgres://db?sslmode=require", lease_segundos=1800)

    assert resultado == fila_android.TrabalhoAndroid(
        id=7,
        chave_idempotencia="github-7",
        origem="schedule",
        estado="executando",
        tentativas=2,
        execucao_id=None,
        codigo_falha=None,
    )
    assert "FOR UPDATE SKIP LOCKED" in cursor.consultas[0][0]
    assert cursor.consultas[0][1] == (1800,)


def teste_executar_trabalho_finaliza_sucesso_ou_falha(monkeypatch, tmp_path: Path) -> None:
    runner = tmp_path / "pichau-android-run.sh"
    runner.touch()
    finalizados: list[tuple[int, bool, str | None]] = []
    monkeypatch.setattr(fila_android, "reivindicar", lambda _url: trabalho())
    monkeypatch.setattr(
        fila_android,
        "finalizar",
        lambda _url, id_, *, sucesso, codigo_falha=None, execucao_id=None: finalizados.append(
            (id_, sucesso, codigo_falha)
        ),
    )

    sucesso = fila_android.executar_trabalho(
        "postgres://db?sslmode=require",
        runner=runner,
        executar=lambda *_args, **_kwargs: SimpleNamespace(returncode=0),
    )
    falha = fila_android.executar_trabalho(
        "postgres://db?sslmode=require",
        runner=runner,
        executar=lambda *_args, **_kwargs: SimpleNamespace(returncode=2),
    )

    assert sucesso is True
    assert falha is False
    assert finalizados == [(7, True, None), (7, False, "runner-2")]
