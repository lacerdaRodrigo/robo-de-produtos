from __future__ import annotations

from io import BytesIO
from urllib.request import Request

from robo_celular.github import ClienteRunsGitHub, RespostaRuns, fonte_da_execucao


def teste_somente_dispatch_manual_concluido_com_sucesso_e_reconhecido() -> None:
    base = {
        "event": "workflow_dispatch",
        "status": "completed",
        "conclusion": "success",
        "path": ".github/workflows/inter.yml@refs/heads/main",
    }

    assert fonte_da_execucao(base) == "inter"
    assert fonte_da_execucao({**base, "event": "schedule"}) is None
    assert fonte_da_execucao({**base, "conclusion": "failure"}) is None
    assert fonte_da_execucao({**base, "path": ".github/workflows/robo.yml"}) == "livelo"


def teste_cliente_usa_etag_e_limita_resposta() -> None:
    chamadas: list[Request] = []

    class Resposta(BytesIO):
        status = 200
        headers = {"ETag": '"nova-versao"'}

        def __enter__(self):
            return self

        def __exit__(self, *_args):
            self.close()

    def abrir(requisicao: Request, *, timeout: int):
        assert timeout == 15
        chamadas.append(requisicao)
        return Resposta(b'{"workflow_runs":[{"id":7,"event":"workflow_dispatch"}]}')

    resposta = ClienteRunsGitHub("dono/repositorio", abrir=abrir).consultar('"anterior"')

    assert resposta == RespostaRuns(({"id": 7, "event": "workflow_dispatch"},), '"nova-versao"')
    assert chamadas[0].get_header("If-none-match") == '"anterior"'
    assert "per_page=100" in chamadas[0].full_url
    assert "event=workflow_dispatch" in chamadas[0].full_url
