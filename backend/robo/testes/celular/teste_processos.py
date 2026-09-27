from __future__ import annotations

import signal
import subprocess
import sys

import pytest

from robo_compartilhado.processos import executar_com_prazo


def teste_timeout_encerra_grupo_com_sigterm_e_sigkill(monkeypatch) -> None:
    agora = 0.0
    chamadas = 0
    grupo_ativo = True

    class ProcessoFalso:
        pid = 321
        returncode = None

        def poll(self):
            return self.returncode

        def communicate(self, timeout=None):
            nonlocal chamadas
            chamadas += 1
            if chamadas == 1:
                raise subprocess.TimeoutExpired(["coletor"], timeout, output=b"parcial")
            return b"", b""

    processo = ProcessoFalso()
    sinais: list[int] = []

    def matar_grupo(_pid, sinal):
        nonlocal grupo_ativo
        if sinal == signal.SIGTERM:
            sinais.append(sinal)
            processo.returncode = -signal.SIGTERM
        elif sinal == signal.SIGKILL:
            sinais.append(sinal)
            grupo_ativo = False
        elif not grupo_ativo:
            raise ProcessLookupError

    def dormir(duracao):
        nonlocal agora
        agora += duracao

    monkeypatch.setattr("robo_compartilhado.processos.os.name", "posix")
    monkeypatch.setattr("robo_compartilhado.processos.os.killpg", matar_grupo)
    monkeypatch.setattr("robo_compartilhado.processos.time.monotonic", lambda: agora)
    monkeypatch.setattr("robo_compartilhado.processos.time.sleep", dormir)

    with pytest.raises(subprocess.TimeoutExpired) as erro:
        executar_com_prazo(
            ["coletor"],
            timeout=10,
            popen=lambda *_args, **_kwargs: processo,
        )

    assert sinais == [signal.SIGTERM, signal.SIGKILL]
    assert erro.value.output == b"parcial"


def teste_sucesso_retorna_completed_process() -> None:
    class ProcessoFalso:
        pid = 123
        returncode = 0

        def communicate(self, timeout=None):
            return b"ok", b""

    resultado = executar_com_prazo(
        ["coletor"],
        timeout=10,
        popen=lambda *_args, **_kwargs: ProcessoFalso(),
    )

    assert resultado.args == ["coletor"]
    assert resultado.returncode == 0
    assert resultado.stdout == b"ok"
    assert resultado.stderr == b""


def teste_processo_real_aceita_check_false_sem_repassar_opcao_a_popen() -> None:
    resultado = executar_com_prazo(
        [sys.executable, "-c", "print('coletor-ok')"],
        timeout=10,
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )

    assert resultado.returncode == 0
    assert resultado.stdout == b"coletor-ok\n"


def teste_check_verdadeiro_lanca_com_output_e_stderr_do_processo_real() -> None:
    with pytest.raises(subprocess.CalledProcessError) as erro:
        executar_com_prazo(
            [
                sys.executable,
                "-c",
                "import sys; print('saida'); print('erro', file=sys.stderr); sys.exit(7)",
            ],
            timeout=10,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )

    assert erro.value.returncode == 7
    assert erro.value.output == b"saida\n"
    assert erro.value.stderr == b"erro\n"
