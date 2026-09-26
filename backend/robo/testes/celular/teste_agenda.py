from __future__ import annotations

from datetime import UTC, datetime

import pytest

from robo_celular.agenda import FUSO_BRASILIA, HORARIOS, coletas_devidas


def teste_grade_separa_fontes_e_horarios() -> None:
    assert [(item.fonte, item.hora, item.minuto) for item in HORARIOS] == [
        ("livelo", 9, 10),
        ("livelo", 14, 10),
        ("livelo", 20, 10),
        ("pichau", 9, 30),
        ("pichau", 14, 30),
        ("pichau", 20, 30),
        ("inter", 10, 30),
        ("inter", 15, 30),
        ("inter", 21, 30),
    ]


def teste_aceita_janela_curta_em_brasilia_e_pula_atraso_longo() -> None:
    no_limite = datetime(2026, 9, 25, 9, 11, 30, tzinfo=FUSO_BRASILIA)
    atrasado = datetime(2026, 9, 25, 9, 11, 31, tzinfo=FUSO_BRASILIA)

    assert [horario.fonte for horario, _ in coletas_devidas(no_limite)] == ["livelo"]
    assert coletas_devidas(atrasado) == []


def teste_converte_instante_utc_para_fuso_local() -> None:
    instante = datetime(2026, 9, 25, 12, 10, tzinfo=UTC)

    assert [horario.fonte for horario, _ in coletas_devidas(instante)] == ["livelo"]


def teste_rejeita_horario_sem_fuso() -> None:
    with pytest.raises(ValueError, match="fuso horário"):
        coletas_devidas(datetime(2026, 9, 25, 9, 10))
