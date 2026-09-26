from __future__ import annotations

from types import SimpleNamespace

from robo_celular.executores import comandos_da_fonte, executar_fonte


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


def teste_fonte_desconhecida_e_rejeitada() -> None:
    try:
        comandos_da_fonte("outra")
    except ValueError as erro:
        assert str(erro) == "fonte de coleta desconhecida"
    else:
        raise AssertionError("fonte desconhecida não foi rejeitada")
