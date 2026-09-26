from __future__ import annotations

from pathlib import Path

from robo_celular.estado_local import EstadoLocal


def teste_estado_local_e_idempotente_e_privado(tmp_path: Path) -> None:
    caminho = tmp_path / "privado" / "estado.sqlite3"
    estado = EstadoLocal(caminho)

    assert estado.reservar_agendamento("livelo:2026-09-25:0910", "inicio")
    assert not estado.reservar_agendamento("livelo:2026-09-25:0910", "duplicado")
    estado.concluir_agendamento("livelo:2026-09-25:0910", sucesso=True, concluida_em="fim")
    estado.gravar_metadado("github_etag", '"etag-1"')

    assert caminho.stat().st_mode & 0o777 == 0o600
    assert estado.metadado("github_etag") == '"etag-1"'
    assert not estado.reservar_agendamento("livelo:2026-09-25:0910", "repetir")


def teste_baseline_github_guarda_ids_e_etag(tmp_path: Path) -> None:
    estado = EstadoLocal(tmp_path / "estado.sqlite3")
    estado.inicializar_github([41, 42], '"etag"')

    assert estado.run_foi_visto(41)
    assert estado.run_foi_visto(42)
    assert not estado.run_foi_visto(43)
    assert estado.metadado("github_inicializado") == "sim"
    assert estado.metadado("github_etag") == '"etag"'
