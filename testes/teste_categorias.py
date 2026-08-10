"""CT-001 a CT-008 — reconhecimento de loja favorita (RN03, RN04, RN05)."""

from __future__ import annotations

from robo_livelo.categorias import agrupar, favoritas_ausentes, normalizar, reconhecer
from testes.conftest import faz_parceiro


def teste_ct001_loja_exata_na_lista(favoritas):
    assert reconhecer("Natura", favoritas).categoria == "Beleza"


def teste_ct002_acentuacao_diferente(favoritas):
    com_acento = reconhecer("O Boticário", favoritas)
    sem_acento = reconhecer("O Boticario", favoritas)
    assert com_acento == sem_acento
    assert com_acento.categoria == "Beleza"


def teste_ct003_caixa_alta_e_baixa(favoritas):
    variacoes = ["CASAS BAHIA", "casas bahia", "Casas Bahia"]
    resultados = {reconhecer(v, favoritas) for v in variacoes}
    assert len(resultados) == 1
    assert resultados.pop().nome == "Casas Bahia"


def teste_ct004_loja_nao_cadastrada(favoritas):
    assert reconhecer("Loja Que Nao Existe", favoritas) is None


def teste_ct005_sufixo_so_casa_se_for_apelido_cadastrado(favoritas):
    """RN04: apelido cadastrado casa; sufixo nao cadastrado nao casa."""
    assert reconhecer("CEA", favoritas).nome == "C&A"
    assert reconhecer("Booking com", favoritas).nome == "Booking.com"
    assert reconhecer("Casas Bahia Oficial", favoritas) is None
    assert reconhecer("Natura Cosmeticos", favoritas) is None


def teste_ct006_lojas_parecidas_nao_se_confundem(favoritas):
    """Caso real da pagina: Petlove nao esta em promocao, Petlove Saude esta."""
    assert reconhecer("Petlove", favoritas).categoria == "Pet"
    assert reconhecer("Petlove Saúde", favoritas) is None
    assert reconhecer("Pontofrio", favoritas).nome == "Pontofrio"
    assert reconhecer("Ponto", favoritas) is None


def teste_ct007_string_vazia(favoritas):
    assert reconhecer("", favoritas) is None
    assert reconhecer("   ", favoritas) is None


def teste_ct008_espacos_extras(favoritas):
    assert reconhecer("  Natura  ", favoritas) == reconhecer("Natura", favoritas)
    assert normalizar(" Casas   Bahia ") == "casas bahia"


def teste_agrupamento_descarta_parceiro_sem_promocao(favoritas):
    """RF04 dentro do agrupamento."""
    parceiros = [
        faz_parceiro("Natura", "5"),
        faz_parceiro("Magalu", "9", em_promocao=False),
    ]
    agrupado = agrupar(parceiros, favoritas)
    assert list(agrupado) == ["Beleza"]


def teste_agrupamento_ordena_categorias_e_lojas(favoritas):
    """RF06: categoria por nome, loja por pontuacao decrescente."""
    parceiros = [
        faz_parceiro("Magalu", "3"),
        faz_parceiro("Natura", "2"),
        faz_parceiro("Casas Bahia", "7"),
    ]
    agrupado = agrupar(parceiros, favoritas)
    assert list(agrupado) == ["Beleza", "Marketplace / Varejo Geral"]
    nomes = [p.nome for p in agrupado["Marketplace / Varejo Geral"]]
    assert nomes == ["Casas Bahia", "Magalu"]


def teste_favoritas_ausentes_considera_apelidos(favoritas):
    """RN19: loja encontrada pelo apelido nao pode ser dada como ausente."""
    parceiros = [faz_parceiro("CEA", "2"), faz_parceiro("Natura", "3")]
    ausentes = favoritas_ausentes(parceiros, favoritas)
    assert "C&A" not in ausentes
    assert "Natura" not in ausentes
    assert "Magalu" in ausentes


def teste_agrupamento_usa_o_nome_canonico_do_catalogo(favoritas):
    """A Livelo escreve "CEA" e "Booking com"; o e-mail mostra o nome do catalogo."""
    parceiros = [faz_parceiro("CEA", "5"), faz_parceiro("Booking com", "4")]
    agrupado = agrupar(parceiros, favoritas)
    assert agrupado["Moda"][0].nome == "C&A"
    assert agrupado["Viagem"][0].nome == "Booking.com"
