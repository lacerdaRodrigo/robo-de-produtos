"""Execução serial dos comandos dos domínios no telefone."""

from __future__ import annotations

import os
import subprocess
import sys
import time
from collections.abc import Callable, Mapping
from pathlib import Path

from robo_compartilhado.processos import executar_com_prazo

RAIZ_ROBO = Path(__file__).resolve().parents[2]
RUNNER_PICHAU = RAIZ_ROBO / "scripts" / "pichau" / "run.sh"
ExecutarComando = Callable[..., subprocess.CompletedProcess[bytes]]
PRAZOS_FONTE_SEGUNDOS = {"livelo": 15 * 60, "inter": 50 * 60, "pichau": 20 * 60}


def comandos_da_fonte(fonte: str) -> tuple[tuple[str, ...], ...]:
    python = sys.executable
    if fonte == "livelo":
        return ((python, "-m", "robo_livelo.principal"),)
    if fonte == "inter":
        return (
            (python, "-m", "robo_inter.principal_inter"),
            (python, "-m", "robo_inter.principal_produtos_inter"),
        )
    if fonte == "pichau":
        return ((str(RUNNER_PICHAU),),)
    raise ValueError("fonte de coleta desconhecida")


def executar_fonte(
    fonte: str,
    *,
    ambiente: Mapping[str, str] | None = None,
    executar: ExecutarComando = executar_com_prazo,
) -> int:
    ambiente_processo = dict(os.environ if ambiente is None else ambiente)
    ambiente_processo["PYTHONUNBUFFERED"] = "1"
    ambiente_processo.setdefault("LIMIAR_PARCEIROS", "150")
    ambiente_processo.setdefault("LIMIAR_LOJAS_INTER", "100")

    limite = time.monotonic() + PRAZOS_FONTE_SEGUNDOS[fonte]
    for comando in comandos_da_fonte(fonte):
        restante = limite - time.monotonic()
        if restante <= 0:
            return 124
        try:
            resultado = executar(
                list(comando),
                cwd=RAIZ_ROBO,
                check=False,
                env=ambiente_processo,
                timeout=restante,
            )
        except subprocess.TimeoutExpired:
            return 124
        except OSError:
            return 127
        if resultado.returncode != 0:
            return resultado.returncode
    return 0
