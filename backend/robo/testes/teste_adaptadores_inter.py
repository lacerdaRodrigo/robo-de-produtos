"""CT-185 e CT-187 — adaptadores exclusivos do Shopping Inter."""

from __future__ import annotations

import sys
import types
from datetime import datetime

import pytest

from robo_livelo.adaptadores_inter import FonteInterHttp, RepositorioInterPostgres
from robo_livelo.modelos_inter import FavoritaInter
from robo_livelo.portas_inter import FalhaAoGuardarInter, FalhaAoObterInter
from robo_livelo.retrato_inter import montar_retrato_inter
from testes.conftest import FUSO_BRASILIA, faz_loja_inter


class RespostaInterFake:
    def __init__(self, status=200, texto="[]"):
        self.status_code = status
        self.text = texto
        self.content = texto.encode()


def teste_ct187_sucesso_faz_uma_requisicao():
    chamadas = []

    def obter(*args, **kwargs):
        chamadas.append((args, kwargs))
        return RespostaInterFake()

    assert FonteInterHttp(obter=obter).obter_json() == "[]"
    assert len(chamadas) == 1
    assert chamadas[0][1]["timeout"] == 30.0


def teste_ct187_retry_apenas_para_falha_transitoria():
    respostas = iter([RespostaInterFake(503), RespostaInterFake(200, "[1]")])
    fonte = FonteInterHttp(obter=lambda *_a, **_k: next(respostas), dormir=lambda _: None)
    assert fonte.obter_json() == "[1]"

    chamadas = []
    fonte_401 = FonteInterHttp(
        obter=lambda *_a, **_k: chamadas.append(1) or RespostaInterFake(401),
        dormir=lambda _: None,
    )
    with pytest.raises(FalhaAoObterInter, match="401"):
        fonte_401.obter_json()
    assert len(chamadas) == 1


class CursorInterFake:
    def __init__(self, *, falhar_no_lote=False):
        self.executados = []
        self.lotes = []
        self.falhar_no_lote = falhar_no_lote

    def execute(self, consulta, parametros=None):
        self.executados.append((consulta, parametros))

    def executemany(self, consulta, parametros):
        if self.falhar_no_lote:
            raise ErroBanco("postgresql://usuario:senha@host")
        self.lotes.append((consulta, list(parametros)))

    def fetchone(self):
        return (42,)

    def fetchall(self):
        return [("ca", "C&A")]

    def __enter__(self):
        return self

    def __exit__(self, *_):
        return False


class ErroBanco(RuntimeError):
    pass


class ConexaoInterFake:
    def __init__(self, cursor):
        self.cursor_fake = cursor
        self.erro_no_exit = None

    def cursor(self):
        return self.cursor_fake

    def __enter__(self):
        return self

    def __exit__(self, tipo, valor, _traceback):
        self.erro_no_exit = tipo
        return False


def repositorio(monkeypatch, cursor):
    conexao = ConexaoInterFake(cursor)
    monkeypatch.setitem(
        sys.modules,
        "psycopg",
        types.SimpleNamespace(connect=lambda _url: conexao, Error=ErroBanco),
    )
    return RepositorioInterPostgres("postgresql://fake"), conexao


def teste_repositorio_inicia_e_lista_favoritas(monkeypatch):
    repo, _ = repositorio(monkeypatch, CursorInterFake())
    agora = datetime(2026, 8, 14, 20, 0, tzinfo=FUSO_BRASILIA)
    assert repo.iniciar(agora, "9.9.9") == 42
    assert repo.listar() == [FavoritaInter("ca", "C&A")]


def teste_ct185_falha_no_lote_desfaz_transacao_e_esconde_segredo(monkeypatch):
    cursor = CursorInterFake(falhar_no_lote=True)
    repo, conexao = repositorio(monkeypatch, cursor)
    agora = datetime(2026, 8, 14, 20, 0, tzinfo=FUSO_BRASILIA)
    loja = faz_loja_inter("C&A", "12", id_externo="ca")
    retrato = montar_retrato_inter(
        [loja],
        [FavoritaInter("ca", "C&A")],
        momento=agora,
        lojas_lidas=381,
        versao="9.9.9",
    )

    with pytest.raises(FalhaAoGuardarInter) as erro:
        repo.concluir(42, (loja,), retrato)

    assert conexao.erro_no_exit is ErroBanco
    assert "senha" not in str(erro.value)
