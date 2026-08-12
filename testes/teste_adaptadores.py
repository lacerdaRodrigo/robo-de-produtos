"""CT-021 a CT-023 e CT-060 a CT-063 — implementacoes das portas (PRD 4.2)."""

from __future__ import annotations

import logging
import sys
import types
from decimal import Decimal

import pytest

from robo_livelo.adaptadores import (
    CatalogoArquivo,
    CatalogoComReserva,
    CatalogoPostgres,
    PaginaLiveloHttp,
)
from robo_livelo.modelos import LojaFavorita
from robo_livelo.portas import ConfiguracaoInvalida, FalhaAoObterPagina


class RespostaFake:
    def __init__(self, texto: str = "<html></html>") -> None:
        self.text = texto
        self.content = texto.encode("utf-8")

    def raise_for_status(self) -> None:
        return None


def fonte(monkeypatch, comportamento, **kwargs) -> PaginaLiveloHttp:
    monkeypatch.setattr("robo_livelo.adaptadores.requests.get", comportamento)
    return PaginaLiveloHttp(dormir=lambda _: None, **kwargs)


def teste_ct021_erro_de_rede_e_tratado(monkeypatch):
    def sempre_falha(*_a, **_k):
        raise ConnectionError("sem rede")

    with pytest.raises(FalhaAoObterPagina):
        fonte(monkeypatch, sempre_falha).obter_html()


def teste_ct022_retry_apos_falha_temporaria(monkeypatch):
    chamadas = {"n": 0}

    def falha_uma_vez(*_a, **_k):
        chamadas["n"] += 1
        if chamadas["n"] == 1:
            raise TimeoutError("instavel")
        return RespostaFake("<html>ok</html>")

    assert "ok" in fonte(monkeypatch, falha_uma_vez).obter_html()
    assert chamadas["n"] == 2


def teste_ct023_desiste_apos_esgotar_tentativas(monkeypatch):
    chamadas = {"n": 0}

    def sempre_falha(*_a, **_k):
        chamadas["n"] += 1
        raise ConnectionError("sem rede")

    with pytest.raises(FalhaAoObterPagina, match="3 tentativas"):
        fonte(monkeypatch, sempre_falha, tentativas=3).obter_html()
    assert chamadas["n"] == 3


def teste_ct060_resposta_grande_demais(monkeypatch):
    """PRD 9.2: resposta acima do limite vira falha, sem retry."""
    chamadas = {"n": 0}

    def gigante(*_a, **_k):
        chamadas["n"] += 1
        return RespostaFake("x" * 5000)

    with pytest.raises(FalhaAoObterPagina, match="excede o limite"):
        fonte(monkeypatch, gigante, tamanho_maximo=1000).obter_html()
    assert chamadas["n"] == 1


def teste_ct061_config_ausente_ou_vazia(tmp_path):
    with pytest.raises(ConfiguracaoInvalida, match="nao encontrada"):
        CatalogoArquivo(tmp_path / "nao-existe.toml").listar()

    vazio = tmp_path / "vazio.toml"
    vazio.write_text("", encoding="utf-8")
    with pytest.raises(ConfiguracaoInvalida, match="Nenhuma loja"):
        CatalogoArquivo(vazio).listar()


def teste_ct062_config_malformada(tmp_path):
    quebrado = tmp_path / "quebrado.toml"
    quebrado.write_text('[[loja]\nnome = "sem fechar', encoding="utf-8")
    with pytest.raises(ConfiguracaoInvalida, match="malformada"):
        CatalogoArquivo(quebrado).listar()


def teste_ct063_apelido_repetido_entre_lojas(tmp_path):
    duplicado = tmp_path / "duplicado.toml"
    duplicado.write_text(
        '[[loja]]\nnome = "Magalu"\napelidos = ["Mag"]\ncategoria = "Varejo"\n'
        '[[loja]]\nnome = "Magazine"\napelidos = ["Mag"]\ncategoria = "Varejo"\n',
        encoding="utf-8",
    )
    with pytest.raises(ConfiguracaoInvalida, match="repetida"):
        CatalogoArquivo(duplicado).listar()


def teste_loja_sem_categoria_e_recusada(tmp_path):
    incompleto = tmp_path / "incompleto.toml"
    incompleto.write_text('[[loja]]\nnome = "Magalu"\n', encoding="utf-8")
    with pytest.raises(ConfiguracaoInvalida, match="sem nome ou sem categoria"):
        CatalogoArquivo(incompleto).listar()


def teste_config_real_do_projeto_e_valida():
    """O catalogo versionado precisa carregar sem erro.

    Nao fixa a quantidade de lojas: o catalogo e dado que muda quando se
    adiciona ou remove loja, e um numero fixo aqui quebraria a cada edicao
    sem apontar defeito nenhum. O que se verifica sao as invariantes.
    """
    lojas = CatalogoArquivo("config/lojas_favoritas.toml").listar()
    assert len(lojas) > 100

    por_nome = {loja.nome: loja for loja in lojas}
    assert por_nome["C&A"].apelidos == ("CEA",)
    assert por_nome["Booking.com"].apelidos == ("Booking com",)

    # Toda loja tem categoria, e nenhuma loja aparece em duas categorias (RN01).
    assert all(loja.categoria for loja in lojas)
    assert len(por_nome) == len(lojas)

    # Pares que uma correspondencia por substring confundiria. Nao ha problema
    # em ambos serem favoritos — RN04 e o que garante que cada um pontue por si.
    for base, parecido in [
        ("Hering", "Hering Outlet"),
        ("Carrefour Mercado", "Carrefour Shopping"),
    ]:
        if parecido in por_nome:
            assert por_nome[base] != por_nome[parecido]


# --- CT-108 a CT-112: catalogo do banco e reserva em arquivo (PRD V2 7.1.1) ---


class CatalogoFalho:
    def __init__(self, erro: Exception) -> None:
        self._erro = erro
        self.chamadas = 0

    def listar(self):
        self.chamadas += 1
        raise self._erro


class CatalogoOk:
    def __init__(self, lojas) -> None:
        self._lojas = lojas
        self.chamadas = 0

    def listar(self):
        self.chamadas += 1
        return self._lojas


def teste_ct108_reserva_assume_quando_o_principal_falha(caplog):
    """A troca do TOML pelo banco so e segura com reserva: Neon fora do ar
    nao pode derrubar a execucao inteira."""
    lojas = [LojaFavorita(nome="Natura", categoria="Beleza")]
    principal = CatalogoFalho(ConfiguracaoInvalida("banco inacessivel"))
    reserva = CatalogoOk(lojas)

    with caplog.at_level(logging.WARNING, logger="robo_livelo.adaptadores"):
        assert CatalogoComReserva(principal, reserva).listar() == lojas

    assert reserva.chamadas == 1
    # A queda precisa ser visivel: rodar de reserva por semanas sem ninguem
    # perceber seria pior do que falhar.
    assert [r for r in caplog.records if r.levelno == logging.WARNING]


def teste_ct109_reserva_nao_e_tocada_quando_o_principal_responde():
    lojas = [LojaFavorita(nome="Natura", categoria="Beleza")]
    reserva = CatalogoOk([])
    assert CatalogoComReserva(CatalogoOk(lojas), reserva).listar() == lojas
    assert reserva.chamadas == 0


def teste_ct110_limiar_por_loja_no_arquivo_vira_decimal(tmp_path):
    """RN28: limiar proprio da loja. Ausente significa "usa o padrao global"."""
    config = tmp_path / "lojas.toml"
    config.write_text(
        """
        [[loja]]
        nome = "Natura"
        categoria = "Beleza"
        multiplicador = 2.5
        piso_pontos = 6

        [[loja]]
        nome = "Magalu"
        categoria = "Marketplace"
        """,
        encoding="utf-8",
    )

    natura, magalu = CatalogoArquivo(config).listar()
    assert natura.multiplicador == Decimal("2.5")
    assert natura.piso_pontos == Decimal("6")
    assert magalu.multiplicador is None and magalu.piso_pontos is None


@pytest.mark.parametrize(
    "linha",
    ["multiplicador = 'muito'", "multiplicador = 0", "piso_pontos = -1"],
)
def teste_ct111_limiar_invalido_no_arquivo_e_recusado(tmp_path, linha):
    """Limiar errado por engano de digitacao viraria alerta errado depois."""
    config = tmp_path / "lojas.toml"
    config.write_text(
        f'[[loja]]\nnome = "Natura"\ncategoria = "Beleza"\n{linha}\n', encoding="utf-8"
    )
    with pytest.raises(ConfiguracaoInvalida):
        CatalogoArquivo(config).listar()


def teste_ct112_catalogo_do_banco_mapeia_as_colunas(monkeypatch):
    """O adaptador le nome, categoria, apelidos, multiplicador e piso_pontos."""
    linhas = [
        ("Natura", "Beleza", ["Natura Cosmeticos"], Decimal("2.5"), Decimal("6")),
        ("Magalu", "Marketplace", [], None, None),
    ]
    executadas: list[str] = []

    class CursorFake:
        def execute(self, consulta):
            executadas.append(consulta)

        def fetchall(self):
            return linhas

        def __enter__(self):
            return self

        def __exit__(self, *_):
            return False

    class ConexaoFake:
        def cursor(self):
            return CursorFake()

        def __enter__(self):
            return self

        def __exit__(self, *_):
            return False

    psycopg_fake = types.SimpleNamespace(connect=lambda url: ConexaoFake(), Error=RuntimeError)
    monkeypatch.setitem(sys.modules, "psycopg", psycopg_fake)

    natura, magalu = CatalogoPostgres("postgresql://fake").listar()
    assert (natura.nome, natura.categoria, natura.apelidos) == (
        "Natura",
        "Beleza",
        ("Natura Cosmeticos",),
    )
    assert natura.multiplicador == Decimal("2.5") and natura.piso_pontos == Decimal("6")
    assert magalu.multiplicador is None and magalu.piso_pontos is None
    assert "multiplicador" in executadas[0] and "piso_pontos" in executadas[0]


def teste_ct113_senha_da_url_nao_vaza_na_mensagem_de_erro(monkeypatch):
    """PRD 9.1: o log do Actions e publico. A excecao original carrega a URL."""

    class ErroDoBanco(RuntimeError):
        pass

    def conectar_falhando(url):
        raise ErroDoBanco(f"nao conectou em {url}")

    psycopg_fake = types.SimpleNamespace(connect=conectar_falhando, Error=ErroDoBanco)
    monkeypatch.setitem(sys.modules, "psycopg", psycopg_fake)

    with pytest.raises(ConfiguracaoInvalida) as erro:
        CatalogoPostgres("postgresql://usuario:senha_secreta@host/banco").listar()
    assert "senha_secreta" not in str(erro.value)
    assert erro.value.__cause__ is None
