"""CT-024, CT-040 a CT-043 e CT-070 em diante — orquestracao com fakes."""

from __future__ import annotations

import logging
from datetime import datetime
from decimal import Decimal

import pytest

from robo_livelo.adaptadores import (
    CatalogoArquivo,
    CatalogoComReserva,
    PreferenciasComReserva,
    PreferenciasPadrao,
    RepositorioNulo,
    RepositorioPostgres,
)
from robo_livelo.modelos import Preferencias
from robo_livelo.portas import FalhaAoGuardar, FalhaAoObterPagina, SiteMudou
from robo_livelo.principal import (
    montar_catalogo,
    montar_preferencias,
    montar_repositorio,
    verificar_promocoes,
)
from testes.conftest import (
    FUSO_BRASILIA,
    CatalogoFake,
    FonteFake,
    formatar_data_livelo,
    monta_html_payload,
    monta_item_parceiro,
)

AGORA_TESTE = datetime(2026, 8, 11, 10, 0, tzinfo=FUSO_BRASILIA)


class RepositorioFake:
    def __init__(self) -> None:
        self.retratos = []

    def registrar(self, retrato) -> None:
        self.retratos.append(retrato)


def pagina(*lojas: tuple[str, str, bool]) -> str:
    """(nome, pontos, promo) -> payload JSON embrulhado em HTML (RF14).

    Desde a V2.2 quem decide o alerta e RN27, nao a etiqueta da Livelo:
    `promo=True` monta o item com base 1, para a pontuacao de fato cruzar
    o limiar (2x a base e piso 4). `promo=False` deixa base igual a
    pontuacao atual.
    """
    itens = [
        monta_item_parceiro(
            nome=nome,
            parity=pontos,
            parity_bau="1" if promo else None,
            promotion=promo,
        )
        for nome, pontos, promo in lojas
    ]
    return monta_html_payload(*itens)


def executa(
    html: str,
    favoritas,
    *,
    limiar: int = 1,
    agora: datetime = AGORA_TESTE,
    repositorio=None,
):
    fonte = FonteFake(html)
    total = verificar_promocoes(
        fonte=fonte,
        catalogo=CatalogoFake(favoritas),
        limiar=limiar,
        agora=agora,
        repositorio=repositorio,
    )
    return total, fonte


def teste_ct024_alerta_de_quebra(favoritas):
    """RN13: parceiros de menos encerra com falha. Veio do teste_extrator."""
    html = pagina(("Natura", "4", True))
    with pytest.raises(SiteMudou, match="abaixo do limiar"):
        executa(html, favoritas, limiar=150)


def teste_ct040_filtra_loja_fora_do_catalogo(favoritas):
    html = pagina(("Natura", "4", True), ("Loja Aleatoria", "9", True))
    total, _ = executa(html, favoritas)
    assert total == 1


def teste_ct041_filtra_loja_sem_promocao(favoritas):
    html = pagina(("Natura", "4", True), ("Magalu", "3", False))
    total, _ = executa(html, favoritas)
    assert total == 1


def teste_ct042_conta_alertas_em_categorias_diferentes(favoritas):
    html = pagina(("Natura", "4", True), ("Magalu", "6", True))
    total, _ = executa(html, favoritas)
    assert total == 2


def teste_ct043_sem_promocoes_conclui_com_zero(favoritas):
    html = pagina(("Natura", "3", False))
    total, _ = executa(html, favoritas)
    assert total == 0


def teste_ct070_favoritas_ausentes_vao_pro_log(favoritas, caplog):
    html = pagina(("Natura", "4", True))
    with caplog.at_level(logging.WARNING):
        executa(html, favoritas)

    assert "Magalu" in caplog.text


def teste_ct071_parceiro_malformado_nao_derruba(favoritas):
    """PRD 6.4: descarta so aquele parceiro e segue."""
    item_quebrado = monta_item_parceiro(nome="Loja Quebrada", promotion=True)
    item_quebrado["parity"]["parity"] = "sem pontuacao legivel"
    item_bom = monta_item_parceiro(nome="Natura", parity="4", parity_bau="1", promotion=True)

    total, _ = executa(monta_html_payload(item_quebrado, item_bom), favoritas)
    assert total == 1


def teste_falha_de_rede_sobe_como_erro(favoritas):
    """RNF06: falha ruidosa, nunca silenciosa."""
    with pytest.raises(FalhaAoObterPagina):
        verificar_promocoes(
            fonte=FonteFake(erro=FalhaAoObterPagina("sem rede")),
            catalogo=CatalogoFake(favoritas),
        )


def teste_ct102_mesmo_agora_chega_ao_extrator(favoritas):
    """Fim a fim: uma promocao que termina hoje ainda conta como alerta."""
    fim_hoje = AGORA_TESTE.replace(hour=23, minute=59)
    item = monta_item_parceiro(
        nome="Natura",
        parity="4",
        parity_bau="1",
        promotion=True,
        date_start="2026-08-09-00:00:00 GMT-03:00",
        date_end=formatar_data_livelo(fim_hoje),
    )

    total, _ = executa(monta_html_payload(item), favoritas, agora=AGORA_TESTE)
    assert total == 1


def teste_rn21_promocao_expirada_nao_conta_fim_a_fim(favoritas):
    item = monta_item_parceiro(
        nome="Natura",
        parity="4",
        promotion=True,
        date_start="2026-08-01-00:00:00 GMT-03:00",
        date_end="2026-08-05-23:59:00 GMT-03:00",
    )

    total, _ = executa(monta_html_payload(item), favoritas, agora=AGORA_TESTE)
    assert total == 0


def teste_ct114_sem_database_url_o_catalogo_vem_do_arquivo(tmp_path):
    catalogo = montar_catalogo({}, tmp_path / "lojas.toml")
    assert isinstance(catalogo, CatalogoArquivo)


def teste_ct115_com_database_url_o_banco_manda_e_o_arquivo_fica_de_reserva(tmp_path):
    catalogo = montar_catalogo({"DATABASE_URL": "postgresql://fake"}, tmp_path / "lojas.toml")
    assert isinstance(catalogo, CatalogoComReserva)


def teste_ct116_database_url_em_branco_conta_como_ausente(tmp_path):
    catalogo = montar_catalogo({"DATABASE_URL": "   "}, tmp_path / "lojas.toml")
    assert isinstance(catalogo, CatalogoArquivo)


def teste_ct134_sem_database_url_as_preferencias_sao_os_padroes():
    assert isinstance(montar_preferencias({}), PreferenciasPadrao)


def teste_ct135_com_database_url_as_preferencias_vem_do_banco_com_reserva():
    assert isinstance(
        montar_preferencias({"DATABASE_URL": "postgresql://fake"}), PreferenciasComReserva
    )


def teste_ct136_alerta_usa_a_pontuacao_nao_a_etiqueta(favoritas):
    """RN27 fim a fim: registra como alerta somente quem realmente subiu."""
    etiquetado_sem_aumento = monta_item_parceiro(
        nome="O Boticario", parity="3", parity_bau="3", promotion=True
    )
    aumento_sem_etiqueta = monta_item_parceiro(
        nome="Natura", parity="6", parity_bau="2", promotion=False
    )
    repositorio = RepositorioFake()

    total, _ = executa(
        monta_html_payload(etiquetado_sem_aumento, aumento_sem_etiqueta),
        favoritas,
        repositorio=repositorio,
    )

    assert total == 1
    (snapshot,) = repositorio.retratos
    alertadas = {item.loja.nome for item in snapshot.pontuacoes if item.alertou}
    assert alertadas == {"Natura"}


def teste_ct137_preferencias_do_banco_mudam_o_resultado(favoritas):
    """RN28 fim a fim: a mesma pagina com reguas diferentes."""

    class PreferenciasFake:
        def __init__(self, preferencias):
            self._preferencias = preferencias

        def carregar(self):
            return self._preferencias

    html = pagina(("Natura", "4", True))

    def roda(preferencias):
        return verificar_promocoes(
            fonte=FonteFake(html),
            catalogo=CatalogoFake(favoritas),
            limiar=1,
            agora=AGORA_TESTE,
            preferencias=PreferenciasFake(preferencias),
        )

    assert roda(Preferencias()) == 1
    assert roda(Preferencias(piso_pontos_padrao=Decimal("10"))) == 0
    assert roda(Preferencias(multiplicador_padrao=Decimal("9"))) == 0


def teste_ct138_suspeita_de_rn29_vai_para_o_log(favoritas, caplog):
    itens = [
        monta_item_parceiro(nome=nome, parity="3", parity_bau="3", promotion=True)
        for nome in ("Natura", "O Boticario", "Magalu")
    ]
    repositorio = RepositorioFake()
    with caplog.at_level(logging.WARNING, logger="robo_livelo"):
        total, _ = executa(
            monta_html_payload(*itens),
            favoritas,
            repositorio=repositorio,
        )

    assert total == 0
    assert any("RN29" in registro.getMessage() for registro in caplog.records)
    assert repositorio.retratos[0].qualidade == "degradada"


def teste_ct147_sem_database_url_nao_ha_onde_guardar():
    assert isinstance(montar_repositorio({}), RepositorioNulo)


def teste_ct148_com_database_url_o_retrato_vai_para_o_banco():
    assert isinstance(
        montar_repositorio({"DATABASE_URL": "postgresql://fake"}), RepositorioPostgres
    )


def teste_ct149_retrato_registra_todas_as_favoritas(favoritas):
    repositorio = RepositorioFake()
    html = pagina(("Natura", "4", True), ("Magalu", "3", False))

    total, _ = executa(html, favoritas, repositorio=repositorio)

    assert total == 1
    (snapshot,) = repositorio.retratos
    assert len(snapshot.pontuacoes) == len(favoritas)
    assert snapshot.alertas == 1
    assert snapshot.parceiros_lidos == 2
    assert snapshot.qualidade == "completa"


def teste_ct150_falha_ao_guardar_derruba_a_execucao(favoritas):
    """Sem outro canal de saida, banco indisponivel precisa falhar ruidosamente."""

    class RepositorioFalho:
        def registrar(self, retrato):
            raise FalhaAoGuardar("banco inacessivel")

    with pytest.raises(FalhaAoGuardar, match="banco inacessivel"):
        verificar_promocoes(
            fonte=FonteFake(pagina(("Natura", "4", True))),
            catalogo=CatalogoFake(favoritas),
            limiar=1,
            agora=AGORA_TESTE,
            repositorio=RepositorioFalho(),
        )


def teste_ct163_catalogo_vazio_avisa_no_log(caplog):
    repositorio = RepositorioFake()
    with caplog.at_level(logging.WARNING, logger="robo_livelo"):
        total = verificar_promocoes(
            fonte=FonteFake(pagina(("Natura", "4", True))),
            catalogo=CatalogoFake([]),
            limiar=1,
            agora=AGORA_TESTE,
            repositorio=repositorio,
        )

    assert total == 0
    assert repositorio.retratos[0].pontuacoes == ()
    assert len(repositorio.retratos[0].catalogo) == 1
    assert any("Nenhuma loja cadastrada" in registro.getMessage() for registro in caplog.records)
