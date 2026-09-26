"""Agenda local das coletas no fuso de Brasília."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date, datetime, time
from zoneinfo import ZoneInfo

FUSO_BRASILIA = ZoneInfo("America/Sao_Paulo")
JANELA_ATRASO_SEGUNDOS = 90


@dataclass(frozen=True, slots=True)
class HorarioColeta:
    fonte: str
    hora: int
    minuto: int

    def momento(self, dia: date) -> datetime:
        return datetime.combine(dia, time(self.hora, self.minuto), FUSO_BRASILIA)

    def chave(self, dia: date) -> str:
        return f"{self.fonte}:{dia.isoformat()}:{self.hora:02d}{self.minuto:02d}"


HORARIOS = (
    *(HorarioColeta("livelo", hora, 10) for hora in (9, 14, 20)),
    *(HorarioColeta("pichau", hora, 30) for hora in (9, 14, 20)),
    *(HorarioColeta("inter", hora, 30) for hora in (10, 15, 21)),
)


def coletas_devidas(
    agora: datetime,
    *,
    janela_atraso_segundos: int = JANELA_ATRASO_SEGUNDOS,
) -> list[tuple[HorarioColeta, datetime]]:
    """Retorna somente slots dentro da pequena tolerância, sem recuperar atrasos longos."""

    if agora.tzinfo is None or agora.utcoffset() is None:
        raise ValueError("agora precisa conter fuso horário")
    momento = agora.astimezone(FUSO_BRASILIA)
    devidas: list[tuple[HorarioColeta, datetime]] = []
    for horario in HORARIOS:
        slot = horario.momento(momento.date())
        atraso = (momento - slot).total_seconds()
        if 0 <= atraso <= janela_atraso_segundos:
            devidas.append((horario, slot))
    return devidas
