"""Execução serial dos comandos dos domínios no telefone."""

from __future__ import annotations

import os
import subprocess
import sys
from collections.abc import Callable, Mapping
from pathlib import Path

RAIZ_ROBO = Path(__file__).resolve().parents[2]
RUNNER_PICHAU = RAIZ_ROBO / "scripts" / "pichau" / "run.sh"
ExecutarComando = Callable[..., subprocess.CompletedProcess[bytes]]


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
    executar: ExecutarComando = subprocess.run,
) -> int:
    ambiente_processo = dict(os.environ if ambiente is None else ambiente)
    ambiente_processo["PYTHONUNBUFFERED"] = "1"
    ambiente_processo.setdefault("LIMIAR_PARCEIROS", "150")
    ambiente_processo.setdefault("LIMIAR_LOJAS_INTER", "100")

    for comando in comandos_da_fonte(fonte):
        try:
            resultado = executar(
                list(comando),
                cwd=RAIZ_ROBO,
                check=False,
                env=ambiente_processo,
            )
        except OSError:
            return 127
        if resultado.returncode != 0:
            return resultado.returncode
    return 0
