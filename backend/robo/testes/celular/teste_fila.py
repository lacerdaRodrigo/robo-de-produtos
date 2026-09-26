from __future__ import annotations

from robo_celular import fila


class CursorFalso:
    def __init__(self, linha: tuple[object, ...] | None) -> None:
        self.linha = linha
        self.consulta = ""
        self.parametros = None

    def __enter__(self):
        return self

    def __exit__(self, *_args):
        return None

    def execute(self, consulta: str, parametros=None) -> None:
        self.consulta = consulta
        self.parametros = parametros

    def fetchone(self):
        return self.linha


class ConexaoFalsa:
    def __init__(self, cursor: CursorFalso) -> None:
        self.cursor_falso = cursor

    def __enter__(self):
        return self

    def __exit__(self, *_args):
        return None

    def cursor(self):
        return self.cursor_falso


def teste_url_exige_postgres_e_ssl() -> None:
    assert fila.validar_database_url("postgresql://db/app?sslmode=require")

    for url in ("", "https://db", "postgresql://db/app"):
        try:
            fila.validar_database_url(url)
        except fila.FalhaFilaColeta:
            pass
        else:
            raise AssertionError("URL inválida foi aceita")


def teste_solicitacao_chama_funcao_idempotente_com_fonte_e_run(monkeypatch) -> None:
    cursor = CursorFalso((17,))
    conexao = ConexaoFalsa(cursor)
    monkeypatch.setattr(fila.psycopg, "connect", lambda *_args, **_kwargs: conexao)

    resultado = fila.solicitar("postgresql://db/app?sslmode=require", "livelo", 12345)

    assert resultado == 17
    assert "solicitar_coleta_android" in cursor.consulta
    assert cursor.parametros == ("livelo", 12345)


def teste_fonte_invalida_nao_abre_conexao(monkeypatch) -> None:
    monkeypatch.setattr(
        fila.psycopg,
        "connect",
        lambda *_args, **_kwargs: (_ for _ in ()).throw(AssertionError("conectou")),
    )

    try:
        fila.solicitar("postgresql://db/app?sslmode=require", "fonte-externa", 2)
    except fila.FalhaFilaColeta:
        pass
    else:
        raise AssertionError("fonte inválida foi aceita")
