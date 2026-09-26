from __future__ import annotations

from datetime import datetime
from pathlib import Path

from robo_celular import daemon, fila
from robo_celular.agenda import FUSO_BRASILIA
from robo_celular.estado_local import EstadoLocal
from robo_celular.github import RespostaRuns


def teste_intervalo_github_preserva_margem_da_api_publica() -> None:
    assert daemon.validar_intervalo_github("120") == 120
    assert daemon.validar_intervalo_github("180") == 180
    assert daemon.validar_intervalo_github("3600") == 3600
    for valor in ("119", "3601", "invalido"):
        try:
            daemon.validar_intervalo_github(valor)
        except ValueError:
            pass
        else:
            raise AssertionError(f"intervalo inválido aceito: {valor}")


class GitHubFalso:
    def __init__(self, resposta: RespostaRuns) -> None:
        self.resposta = resposta
        self.etags: list[str | None] = []

    def consultar(self, etag: str | None = None) -> RespostaRuns:
        self.etags.append(etag)
        return self.resposta


def teste_agendamento_roda_uma_vez_sem_consulta_remota(tmp_path: Path) -> None:
    estado = EstadoLocal(tmp_path / "estado.sqlite3")
    fontes: list[str] = []
    worker = daemon.WorkerCelular(
        "postgresql://db/app?sslmode=require",
        estado,
        github=GitHubFalso(RespostaRuns((), None)),
        executar=lambda fonte: fontes.append(fonte) or 0,
        processar_pichau=lambda _url: None,
        sincronizar=lambda _chave: None,
    )
    momento = datetime(2026, 9, 25, 9, 10, tzinfo=FUSO_BRASILIA)

    worker.executar_agendamentos(momento)
    worker.executar_agendamentos(momento)

    assert fontes == ["livelo"]
    assert estado.metadado("github_inicializado") is None


def teste_run_manual_concluido_e_processado_idempotentemente(tmp_path: Path, monkeypatch) -> None:
    estado = EstadoLocal(tmp_path / "estado.sqlite3")
    estado.gravar_metadado("github_inicializado", "sim")
    execucao = {
        "id": 77,
        "event": "workflow_dispatch",
        "status": "completed",
        "conclusion": "success",
        "path": ".github/workflows/robo.yml@refs/heads/main",
        "head_sha": "a" * 40,
    }
    github = GitHubFalso(RespostaRuns((execucao,), '"etag-77"'))
    pedidos: list[tuple[str, int | None]] = []
    sincronizacoes: list[str] = []

    def processar(_url, fonte, *, github_run_id=None, executar):
        pedidos.append((fonte, github_run_id))
        return True

    monkeypatch.setattr(fila, "processar_pedido", processar)
    monkeypatch.setattr(fila, "consultar_estado", lambda *_args: "sucesso")
    worker = daemon.WorkerCelular(
        "postgresql://db/app?sslmode=require",
        estado,
        github=github,
        processar_pichau=lambda _url: None,
        sincronizar=sincronizacoes.append,
    )

    worker.consultar_github()
    worker.consultar_github()

    assert pedidos == [("livelo", 77)]
    assert sincronizacoes == [f"github-77-{'a' * 40}"]
    assert estado.run_foi_visto(77)
    assert estado.metadado("github_etag") == '"etag-77"'
    assert github.etags == [None, '"etag-77"']


def teste_primeiro_baseline_drena_fila_antes_de_marcar_runs_antigos(
    tmp_path: Path, monkeypatch
) -> None:
    estado = EstadoLocal(tmp_path / "estado.sqlite3")
    github = GitHubFalso(
        RespostaRuns(
            (
                {
                    "id": 12,
                    "event": "workflow_dispatch",
                    "status": "completed",
                    "conclusion": "success",
                    "path": ".github/workflows/inter.yml",
                },
            ),
            '"etag-old"',
        )
    )
    fontes_drenadas: list[str] = []

    def sem_pedido(_url, fonte, *, github_run_id=None, executar):
        assert github_run_id is None
        fontes_drenadas.append(fonte)
        return None

    monkeypatch.setattr(fila, "processar_pedido", sem_pedido)
    worker = daemon.WorkerCelular(
        "postgresql://db/app?sslmode=require",
        estado,
        github=github,
        processar_pichau=lambda _url: None,
        sincronizar=lambda _chave: None,
    )

    worker.consultar_github()

    assert fontes_drenadas == ["livelo", "inter"]
    assert estado.run_foi_visto(12)
    assert estado.metadado("github_etag") == '"etag-old"'


def teste_baseline_nao_esconde_runs_se_neon_estiver_indisponivel(
    tmp_path: Path, monkeypatch
) -> None:
    estado = EstadoLocal(tmp_path / "estado.sqlite3")
    github = GitHubFalso(RespostaRuns((), '"etag"'))
    monkeypatch.setattr(
        fila,
        "processar_pedido",
        lambda *_args, **_kwargs: (_ for _ in ()).throw(fila.FalhaFilaColeta("Neon indisponível")),
    )
    worker = daemon.WorkerCelular(
        "postgresql://db/app?sslmode=require",
        estado,
        github=github,
        processar_pichau=lambda _url: None,
        sincronizar=lambda _chave: None,
    )

    worker.consultar_github()

    assert estado.metadado("github_inicializado") is None
    assert estado.metadado("github_etag") is None
