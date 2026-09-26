"""Leitura pública de pedidos manuais concluídos no GitHub Actions."""

from __future__ import annotations

import json
from collections.abc import Callable
from dataclasses import dataclass
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen

CAMINHOS_WORKFLOWS = {
    ".github/workflows/robo.yml": "livelo",
    ".github/workflows/inter.yml": "inter",
    ".github/workflows/pichau.yml": "pichau",
}


class FalhaGitHub(RuntimeError):
    """Falha sem corpo ou informação sensível da resposta HTTP."""


@dataclass(frozen=True, slots=True)
class RespostaRuns:
    execucoes: tuple[dict[str, object], ...]
    etag: str | None
    sem_alteracao: bool = False


def fonte_da_execucao(execucao: dict[str, object]) -> str | None:
    if (
        execucao.get("event") != "workflow_dispatch"
        or execucao.get("status") != "completed"
        or execucao.get("conclusion") != "success"
    ):
        return None
    caminho = str(execucao.get("path", "")).split("@", maxsplit=1)[0]
    return CAMINHOS_WORKFLOWS.get(caminho)


class ClienteRunsGitHub:
    def __init__(
        self,
        repositorio: str = "lacerdaRodrigo/robo-de-produtos",
        *,
        abrir: Callable[..., object] = urlopen,
    ) -> None:
        self.url = f"https://api.github.com/repos/{repositorio}/actions/runs?" + urlencode(
            {"event": "workflow_dispatch", "status": "completed", "per_page": 100}
        )
        self._abrir = abrir

    def consultar(self, etag: str | None = None) -> RespostaRuns:
        cabecalhos = {
            "Accept": "application/vnd.github+json",
            "User-Agent": "radar-beneficios-termux",
            "X-GitHub-Api-Version": "2022-11-28",
        }
        if etag:
            cabecalhos["If-None-Match"] = etag
        requisicao = Request(self.url, headers=cabecalhos)
        try:
            resposta = self._abrir(requisicao, timeout=15)
        except HTTPError as erro:
            if erro.code == 304:
                return RespostaRuns((), etag, sem_alteracao=True)
            raise FalhaGitHub(f"consulta de pedidos falhou (HTTP {erro.code}).") from None
        except (URLError, TimeoutError, OSError):
            raise FalhaGitHub("consulta de pedidos indisponível.") from None

        with resposta:
            status = getattr(resposta, "status", 200)
            if status == 304:
                return RespostaRuns((), etag, sem_alteracao=True)
            if status != 200:
                raise FalhaGitHub(f"consulta de pedidos falhou (HTTP {status}).")
            try:
                conteudo = resposta.read(2_000_000)
                dados = json.loads(conteudo)
            except (OSError, json.JSONDecodeError, UnicodeDecodeError):
                raise FalhaGitHub("resposta de pedidos inválida.") from None
            execucoes = dados.get("workflow_runs") if isinstance(dados, dict) else None
            if not isinstance(execucoes, list):
                raise FalhaGitHub("resposta de pedidos inválida.")
            validas = tuple(item for item in execucoes if isinstance(item, dict))
            return RespostaRuns(validas, resposta.headers.get("ETag"), sem_alteracao=False)
