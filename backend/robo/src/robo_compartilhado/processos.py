"""Execução de subprocessos com prazo e encerramento do grupo filho."""

from __future__ import annotations

import os
import signal
import subprocess
import time
from collections.abc import Callable, Sequence
from contextlib import suppress

ExecutarProcesso = Callable[..., subprocess.CompletedProcess[bytes]]


def _encerrar_grupo(processo: subprocess.Popen[bytes]) -> None:
    if os.name == "posix":
        try:
            os.killpg(processo.pid, signal.SIGTERM)
        except ProcessLookupError:
            return

        encerra_em = time.monotonic() + 5
        while True:
            processo.poll()
            try:
                os.killpg(processo.pid, 0)
            except ProcessLookupError:
                break
            restante = encerra_em - time.monotonic()
            if restante <= 0:
                with suppress(ProcessLookupError):
                    os.killpg(processo.pid, signal.SIGKILL)
                break
            time.sleep(min(0.1, restante))
        processo.communicate()
        return

    if processo.poll() is not None:  # pragma: no cover - executor de produção é Linux/Termux
        return
    processo.terminate()  # pragma: no cover - executor de produção é Linux/Termux
    try:
        processo.communicate(timeout=5)
    except subprocess.TimeoutExpired:  # pragma: no cover - executor de produção é Linux/Termux
        processo.kill()
        processo.communicate()


def executar_com_prazo(
    comando: str | Sequence[str],
    *,
    timeout: float,
    check: bool = False,
    popen: Callable[..., subprocess.Popen[bytes]] = subprocess.Popen,
    **opcoes: object,
) -> subprocess.CompletedProcess[bytes]:
    """Executa um grupo isolado e mata também os descendentes após o prazo."""

    argumentos = dict(opcoes)
    argumentos["start_new_session"] = os.name == "posix"
    processo = popen(comando, **argumentos)
    try:
        stdout, stderr = processo.communicate(timeout=timeout)
    except subprocess.TimeoutExpired as erro:
        _encerrar_grupo(processo)
        raise subprocess.TimeoutExpired(
            comando,
            timeout,
            output=erro.output,
            stderr=erro.stderr,
        ) from erro
    resultado = subprocess.CompletedProcess(comando, processo.returncode, stdout, stderr)
    if check and resultado.returncode != 0:
        raise subprocess.CalledProcessError(
            resultado.returncode,
            comando,
            output=stdout,
            stderr=stderr,
        )
    return resultado
