"""CT-021 a CT-023 e CT-060 a CT-063 — implementacoes das portas (PRD 4.2)."""

from __future__ import annotations

import pytest

from robo_livelo.adaptadores import CatalogoArquivo, PaginaLiveloHttp
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
    """O catalogo versionado precisa carregar sem erro."""
    lojas = CatalogoArquivo("config/lojas_favoritas.toml").listar()
    assert len(lojas) == 38
    por_nome = {loja.nome: loja for loja in lojas}
    assert por_nome["C&A"].apelidos == ("CEA",)
    assert por_nome["Booking.com"].apelidos == ("Booking com",)
