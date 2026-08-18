"""CT-021 a CT-023 e CT-060 a CT-063 — implementacoes das portas (PRD 4.2)."""

from __future__ import annotations

import logging
import sys
import types
from datetime import datetime
from decimal import Decimal

import pytest

from robo_livelo.adaptadores import (
    CatalogoArquivo,
    CatalogoComReserva,
    CatalogoPostgres,
    PaginaLiveloHttp,
    PreferenciasComReserva,
    PreferenciasPadrao,
    PreferenciasPostgres,
    RepositorioNulo,
    RepositorioPostgres,
)
from robo_livelo.modelos import LojaFavorita, PontuacaoDeLoja, RetratoDaExecucao
from robo_livelo.portas import ConfiguracaoInvalida, FalhaAoGuardar, FalhaAoObterPagina
from testes.conftest import FUSO_BRASILIA, faz_parceiro


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


# --- CT-130 a CT-133: preferencias globais (RN28, PRD V2 8.1) ---


def teste_ct130_preferencias_padrao_sem_banco():
    """Quem nao tem Neon roda com os padroes do PRD-V2 6.1."""
    padrao = PreferenciasPadrao().carregar()
    assert padrao.multiplicador_padrao == Decimal("2.0")
    assert padrao.piso_pontos_padrao == Decimal("4")
    assert padrao.assinante_clube is False


def preferencias_fake(monkeypatch, linhas):
    class CursorFake:
        def execute(self, consulta):
            return None

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

    monkeypatch.setitem(
        sys.modules,
        "psycopg",
        types.SimpleNamespace(connect=lambda url: ConexaoFake(), Error=RuntimeError),
    )
    return PreferenciasPostgres("postgresql://fake").carregar()


def teste_ct131_preferencias_do_banco(monkeypatch):
    linhas = [
        ("multiplicador_padrao", "2.5"),
        ("piso_pontos_padrao", "6"),
        ("assinante_clube", "true"),
    ]
    lidas = preferencias_fake(monkeypatch, linhas)
    assert lidas.multiplicador_padrao == Decimal("2.5")
    assert lidas.piso_pontos_padrao == Decimal("6")
    assert lidas.assinante_clube is True


def teste_ct132_preferencia_ilegivel_ou_ausente_cai_no_padrao(monkeypatch, caplog):
    """Aqui a escolha e o contrario da do catalogo: existe valor sensato para
    seguir, entao a rodada continua — mas nao em silencio."""
    with caplog.at_level(logging.WARNING, logger="robo_livelo.adaptadores"):
        lidas = preferencias_fake(monkeypatch, [("multiplicador_padrao", "dois")])

    assert lidas.multiplicador_padrao == Decimal("2.0")
    assert lidas.piso_pontos_padrao == Decimal("4")  # ausente da tabela
    assert lidas.assinante_clube is False
    assert [r for r in caplog.records if r.levelno == logging.WARNING]


def teste_ct133_preferencias_caem_para_o_padrao_quando_o_banco_falha(caplog):
    class PreferenciasFalhas:
        def carregar(self):
            raise ConfiguracaoInvalida("banco inacessivel")

    com_reserva = PreferenciasComReserva(PreferenciasFalhas(), PreferenciasPadrao())
    with caplog.at_level(logging.WARNING, logger="robo_livelo.adaptadores"):
        assert com_reserva.carregar().multiplicador_padrao == Decimal("2.0")
    assert [r for r in caplog.records if r.levelno == logging.WARNING]


# --- CT-144 a CT-146: gravacao do retrato (RF15, migracao 002) ---


class CursorGravador:
    def __init__(self, erro=None):
        self.executados = []
        self.lotes = []
        self._erro = erro

    def execute(self, consulta, parametros=None):
        if self._erro:
            raise self._erro
        self.executados.append((consulta, parametros))

    def executemany(self, consulta, lote):
        self.lotes.append((consulta, list(lote)))

    def fetchone(self):
        return (42,)

    def __enter__(self):
        return self

    def __exit__(self, *_):
        return False


def repositorio_fake(monkeypatch, cursor):
    class ConexaoFake:
        def cursor(self):
            return cursor

        def __enter__(self):
            return self

        def __exit__(self, *_):
            return False

    monkeypatch.setitem(
        sys.modules,
        "psycopg",
        types.SimpleNamespace(connect=lambda url: ConexaoFake(), Error=RuntimeError),
    )
    return RepositorioPostgres("postgresql://fake")


def teste_ct144_grava_execucao_e_pontuacoes(monkeypatch):
    """Uma linha de execucao e uma por favorita, todas na mesma transacao."""
    loja_encontrada = LojaFavorita(nome="Natura", categoria="Beleza")
    loja_ausente = LojaFavorita(nome="Magalu", categoria="Marketplace")
    parceiro = faz_parceiro(
        "Natura",
        "8",
        base="2",
        clube="12",
        campanha="PROMOTION",
        descricao_campanha="Campanha válida de 11 a 13/08/2026.",
    )

    momento = datetime(2026, 8, 11, 10, 0, tzinfo=FUSO_BRASILIA)
    snapshot = RetratoDaExecucao(
        momento=momento,
        parceiros_lidos=254,
        versao="1.4.0",
        pontuacoes=(
            PontuacaoDeLoja(
                loja=loja_encontrada,
                parceiro=parceiro,
                valor_de_disparo=Decimal("4"),
                alertou=True,
            ),
            PontuacaoDeLoja(loja=loja_ausente),
        ),
    )

    cursor = CursorGravador()
    repositorio_fake(monkeypatch, cursor).registrar(snapshot)

    _, parametros = cursor.executados[0]
    assert parametros == (momento, 254, 1, "1.4.0")

    _, linhas = cursor.lotes[0]
    assert len(linhas) == 2
    assert linhas[0]["nome"] == "Natura"  # RN01: nome canonico do catalogo
    assert linhas[0]["pontos_atuais"] == Decimal("8")
    assert linhas[0]["valor_de_disparo"] == Decimal("4")
    assert linhas[0]["alertou"] is True
    assert linhas[0]["descricao_campanha"] == "Campanha válida de 11 a 13/08/2026."
    # RN19: favorita ausente vira linha vazia, nao desaparece
    assert linhas[1]["nome"] == "Magalu"
    assert linhas[1]["pontos_atuais"] is None
    assert linhas[1]["alertou"] is False
    assert linhas[1]["descricao_campanha"] is None


def teste_ct145_link_fora_do_dominio_nao_e_gravado(monkeypatch):
    """RN08 vale para o site tambem: link arbitrario nao entra na pagina."""
    hostil = faz_parceiro("Natura", "8", base="2", link="https://site-malicioso.example/x")
    snapshot = RetratoDaExecucao(
        momento=datetime(2026, 8, 11, 10, 0, tzinfo=FUSO_BRASILIA),
        parceiros_lidos=1,
        versao="1.4.0",
        pontuacoes=(
            PontuacaoDeLoja(loja=LojaFavorita(nome="Natura", categoria="Beleza"), parceiro=hostil),
        ),
    )

    cursor = CursorGravador()
    repositorio_fake(monkeypatch, cursor).registrar(snapshot)
    assert cursor.lotes[0][1][0]["link"] is None


def teste_ct146_falha_ao_gravar_nao_vaza_a_senha(monkeypatch):
    """PRD 9.1: a excecao do psycopg carrega a URL inteira."""

    class ErroDoBanco(RuntimeError):
        pass

    cursor = CursorGravador(erro=ErroDoBanco("falhou em postgresql://usuario:senha_secreta@host"))

    class ConexaoFake:
        def cursor(self):
            return cursor

        def __enter__(self):
            return self

        def __exit__(self, *_):
            return False

    monkeypatch.setitem(
        sys.modules,
        "psycopg",
        types.SimpleNamespace(connect=lambda url: ConexaoFake(), Error=ErroDoBanco),
    )

    snapshot = RetratoDaExecucao(
        momento=datetime(2026, 8, 11, 10, 0, tzinfo=FUSO_BRASILIA),
        parceiros_lidos=1,
        versao="1.4.0",
    )
    with pytest.raises(FalhaAoGuardar) as erro:
        RepositorioPostgres("postgresql://usuario:senha_secreta@host").registrar(snapshot)

    assert "senha_secreta" not in str(erro.value)
    assert erro.value.__cause__ is None


def teste_repositorio_nulo_nao_quebra_sem_banco(caplog):
    """Quem clonou o projeto sem Neon continua recebendo e-mail."""
    snapshot = RetratoDaExecucao(
        momento=datetime(2026, 8, 11, 10, 0, tzinfo=FUSO_BRASILIA),
        parceiros_lidos=1,
        versao="1.4.0",
    )
    with caplog.at_level(logging.INFO, logger="robo_livelo.adaptadores"):
        RepositorioNulo().registrar(snapshot)
    assert any("nao foi guardado" in r.getMessage() for r in caplog.records)


def teste_ct159_banco_vazio_nao_e_falha(monkeypatch, caplog):
    """A reserva cobre indisponibilidade, nao vontade.

    Levantar aqui faria `CatalogoComReserva` cair no TOML e ressuscitar as
    lojas que o dono acabou de apagar pelo site — o banco nunca seria a
    fonte da verdade.
    """
    with caplog.at_level(logging.WARNING, logger="robo_livelo.adaptadores"):
        lojas = repositorio_de_catalogo_fake(monkeypatch, []).listar()

    assert lojas == []
    assert any("Nenhuma loja favorita" in r.getMessage() for r in caplog.records)


def teste_ct160_banco_vazio_nao_aciona_a_reserva(monkeypatch):
    """Sem callback de reidratacao, o adaptador generico preserva o vazio."""
    reserva = CatalogoOk([LojaFavorita(nome="Do arquivo", categoria="Beleza")])
    principal = repositorio_de_catalogo_fake(monkeypatch, [])

    assert CatalogoComReserva(principal, reserva).listar() == []
    assert reserva.chamadas == 0


def teste_ct161_banco_vazio_nao_reidrata_favoritas():
    principal = CatalogoOk([])
    reserva = CatalogoOk([LojaFavorita(nome="Do arquivo", categoria="Beleza")])

    assert CatalogoComReserva(principal, reserva).listar() == []
    assert reserva.chamadas == 0


def repositorio_de_catalogo_fake(monkeypatch, linhas):
    class CursorFake:
        def execute(self, consulta, parametros=None):
            return None

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

    monkeypatch.setitem(
        sys.modules,
        "psycopg",
        types.SimpleNamespace(connect=lambda url: ConexaoFake(), Error=RuntimeError),
    )
    return CatalogoPostgres("postgresql://fake")
