from __future__ import annotations

import subprocess
from types import SimpleNamespace

from robo_celular.executores import (
    PRAZOS_FONTE_SEGUNDOS,
    comandos_da_fonte,
    executar_fonte,
)


def teste_inter_roda_cashback_e_produtos_em_serie() -> None:
    comandos = comandos_da_fonte("inter")

    assert comandos[0][-1] == "robo_inter.principal_inter"
    assert comandos[1][-1] == "robo_inter.principal_produtos_inter"


def teste_falha_interrompe_serie_e_nao_dispara_proximo_coletor() -> None:
    chamadas: list[list[str]] = []

    def executar(comando: list[str], **_kwargs):
        chamadas.append(comando)
        return SimpleNamespace(returncode=7)

    codigo = executar_fonte("inter", executar=executar)

    assert codigo == 7
    assert len(chamadas) == 1


def teste_prazos_por_fonte_sao_finitos_e_inter_compartilha_um_prazo_total() -> None:
    assert PRAZOS_FONTE_SEGUNDOS == {
        "livelo": 900,
        "inter": 3000,
        "pichau": 1200,
    }

    chamadas: list[float] = []

    def executar(comando: list[str], **kwargs):
        chamadas.append(kwargs["timeout"])
        return SimpleNamespace(returncode=0)

    assert executar_fonte("inter", executar=executar) == 0
    assert len(chamadas) == 2
    assert all(0 < prazo <= 3000 for prazo in chamadas)


def teste_timeout_de_coleta_encerra_a_fonte_com_codigo_124() -> None:
    def executar(_comando: list[str], **kwargs):
        raise subprocess.TimeoutExpired(_comando, kwargs["timeout"])

    assert executar_fonte("livelo", executar=executar) == 124


def teste_fonte_desconhecida_e_rejeitada() -> None:
    try:
        comandos_da_fonte("outra")
    except ValueError as erro:
        assert str(erro) == "fonte de coleta desconhecida"
    else:
        raise AssertionError("fonte desconhecida não foi rejeitada")
