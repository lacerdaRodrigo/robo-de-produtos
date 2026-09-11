from __future__ import annotations

from dataclasses import replace
from pathlib import Path
from types import SimpleNamespace

import pytest

from robo_pichau import fila_android
from robo_pichau.diagnostico import DiagnosticoInvalido, validar_diagnostico


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


def teste_codigo_runner_expoe_somente_categoria_operacional() -> None:
    assert fila_android.codigo_falha_runner(32) == "adb-wifi-descoberta"
    assert fila_android.codigo_falha_runner(34) == "adb-wifi-estado"
    assert fila_android.codigo_falha_runner(35) == "appium"
    assert fila_android.codigo_falha_runner(41) == "pichau-navegador"
    assert fila_android.codigo_falha_runner(2) == "runner-inesperado"
    assert fila_android.codigo_falha_runner(99) == "runner-inesperado"


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
    assert "executor-offline" in cursor.consultas[0][0]
    assert cursor.consultas[0][1] == (fila_android.PRAZO_PADRAO_SEGUNDOS,)
    assert "FOR UPDATE SKIP LOCKED" in cursor.consultas[1][0]
    assert cursor.consultas[1][1] == (1800,)


def teste_timeout_identifica_job_nunca_reivindicado(monkeypatch) -> None:
    pendente = fila_android.TrabalhoAndroid(
        id=7,
        chave_idempotencia="github-7",
        origem="schedule",
        estado="pendente",
        tentativas=0,
        execucao_id=None,
        codigo_falha=None,
    )
    monkeypatch.setattr(fila_android, "obter", lambda *_args: pendente)

    with pytest.raises(fila_android.FalhaFilaAndroid, match="executor-offline"):
        fila_android.aguardar(
            "postgres://db?sslmode=require",
            7,
            prazo_segundos=0,
            intervalo_segundos=1,
            dormir=lambda _segundos: pytest.fail("nao deve dormir apos o prazo"),
        )


def teste_executar_trabalho_finaliza_sucesso_ou_falha(monkeypatch, tmp_path: Path) -> None:
    runner = tmp_path / "pichau-android-run.sh"
    runner.touch()
    finalizados: list[tuple[int, bool, str | None, int | None]] = []
    monkeypatch.setattr(fila_android, "reivindicar", lambda _url: trabalho())
    atuais = iter(
        [
            trabalho(),
            replace(
                trabalho(),
                diagnostico={
                    "versao": 1,
                    "estado": "falha",
                    "etapa": "pagina",
                    "codigo": "pichau-http-503",
                    "execucao_id": 99,
                },
            ),
        ]
    )
    monkeypatch.setattr(fila_android, "obter", lambda *_args: next(atuais))
    monkeypatch.setattr(
        fila_android,
        "finalizar",
        lambda _url, id_, *, sucesso, codigo_falha=None, execucao_id=None: finalizados.append(
            (id_, sucesso, codigo_falha, execucao_id)
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
    assert finalizados == [(7, True, None, None), (7, False, "pichau-http-503", 99)]


def teste_runner_nao_herda_database_url_do_worker(monkeypatch, tmp_path: Path) -> None:
    runner = tmp_path / "pichau-android-run.sh"
    runner.touch()
    ambiente_recebido = {}
    monkeypatch.setenv("DATABASE_URL", "postgres://usuario:senha@host/db?sslmode=require")
    monkeypatch.setenv("PICHAU_WAKE_LOCK_OWNER", "worker")
    monkeypatch.setattr(fila_android, "reivindicar", lambda _url: trabalho())
    monkeypatch.setattr(fila_android, "obter", lambda *_args: trabalho())
    monkeypatch.setattr(fila_android, "finalizar", lambda *_args, **_kwargs: None)

    def executar(*_args, **kwargs):
        ambiente_recebido.update(kwargs["env"])
        return SimpleNamespace(returncode=0)

    fila_android.executar_trabalho(
        "postgres://db?sslmode=require", runner=runner, executar=executar
    )

    assert "DATABASE_URL" not in ambiente_recebido
    assert ambiente_recebido["PICHAU_WAKE_LOCK_OWNER"] == "worker"
    assert ambiente_recebido["PICHAU_ANDROID_FILA_ID"] == "7"


def teste_runner_remove_tarefas_recentes_sem_coordenada_de_tela() -> None:
    runner = fila_android.CAMINHO_RUNNER.read_text(encoding="utf-8")

    assert "dumpsys activity recents" in runner
    assert "type=standard" in runner
    assert 'am stack remove "$tarefa_id"' in runner
    assert "input keyevent KEYCODE_HOME" in runner
    assert runner.count("limpar_tarefas_recentes") >= 3
    assert "uiautomator" not in runner


def teste_health_faz_somente_sondagem_minima(monkeypatch) -> None:
    cursor = CursorFalso([])
    conexao = ConexaoFalsa(cursor)
    monkeypatch.setattr(fila_android, "_conectar", lambda _url: conexao)

    fila_android.verificar_saude("postgres://db?sslmode=require")

    assert cursor.consultas == [("SELECT 1 FROM pichau_android_fila LIMIT 0", None)]


def teste_diagnostico_valida_vocabulario_tamanho_e_segredos() -> None:
    seguro = validar_diagnostico(
        {
            "versao": 1,
            "estado": "recuperando",
            "etapa": "recuperacao",
            "tentativa_sessao": 1,
            "recuperacao_utilizada": True,
            "codigo": "pichau-http-503",
            "status_http": 503,
            "primeira_falha": {
                "codigo": "pichau-http-503",
                "etapa": "pagina",
                "estrategia": "fetch",
                "pagina": 2,
                "status_http": 503,
            },
        }
    )

    assert seguro["codigo"] == "pichau-http-503"
    for chave in ("mensagem", "html", "titulo", "url", "cookie", "serial", "porta"):
        with pytest.raises(DiagnosticoInvalido):
            validar_diagnostico({"versao": 1, chave: "segredo-nao-publicar"})


def teste_wait_formata_diagnostico_e_prefere_codigo_granular_no_actions(
    monkeypatch, tmp_path: Path, capsys
) -> None:
    resumo = tmp_path / "summary.md"
    segredo = "senha-nao-publicar"
    recuperando = fila_android.TrabalhoAndroid(
        id=7,
        chave_idempotencia="github-7",
        origem="workflow_dispatch",
        estado="executando",
        tentativas=1,
        execucao_id=None,
        codigo_falha=None,
        diagnostico={
            "versao": 1,
            "estado": "recuperando",
            "etapa": "recuperacao",
            "tentativa_sessao": 1,
            "recuperacao_utilizada": True,
            "primeira_falha": {"codigo": "pichau-rede", "etapa": "pagina"},
        },
    )
    falha = fila_android.TrabalhoAndroid(
        id=7,
        chave_idempotencia="github-7",
        origem="workflow_dispatch",
        estado="falha",
        tentativas=1,
        execucao_id=99,
        codigo_falha="pichau-acesso",
        diagnostico={
            "versao": 1,
            "estado": "falha",
            "etapa": "pagina",
            "tentativa_sessao": 2,
            "recuperacao_utilizada": True,
            "codigo": "pichau-http-503",
            "status_http": 503,
        },
    )
    respostas = iter([recuperando, falha])
    monkeypatch.setattr(fila_android, "obter", lambda *_args: next(respostas))
    monkeypatch.setenv("GITHUB_ACTIONS", "true")
    monkeypatch.setenv("GITHUB_STEP_SUMMARY", str(resumo))
    monkeypatch.setenv("DATABASE_URL", f"postgres://usuario:{segredo}@host/db?sslmode=require")

    with pytest.raises(fila_android.FalhaFilaAndroid, match="pichau-http-503"):
        fila_android.aguardar(
            "postgres://db?sslmode=require",
            7,
            intervalo_segundos=0,
            dormir=lambda _segundos: None,
        )

    saida = capsys.readouterr().out + resumo.read_text(encoding="utf-8")
    assert "::warning" in saida
    assert "::error" in saida
    assert "codigo=pichau-http-503" in saida
    assert "primeira_falha_codigo=pichau-rede" in saida
    assert segredo not in saida


def teste_linha_antiga_ou_diagnostico_invalido_cai_na_categoria_atual() -> None:
    antiga = fila_android._trabalho((7, "github-7", "schedule", "falha", 1, None, "pichau-acesso"))
    hostil = fila_android._trabalho(
        (
            8,
            "github-8",
            "schedule",
            "falha",
            1,
            None,
            "pichau-acesso",
            {"mensagem": "cookie=segredo"},
        )
    )

    assert antiga is not None and antiga.diagnostico == {}
    assert hostil is not None and hostil.diagnostico == {}
    assert fila_android._codigo_trabalho(hostil) == "pichau-acesso"
