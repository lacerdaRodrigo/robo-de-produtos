"""CT-139 a CT-143 — o retrato que alimenta o site (RF15, RN24, RN30)."""

from __future__ import annotations

from datetime import datetime
from decimal import Decimal

from robo_livelo.modelos import LojaFavorita, Preferencias
from robo_livelo.retrato import montar_retrato
from testes.conftest import FUSO_BRASILIA, faz_parceiro

AGORA_TESTE = datetime(2026, 8, 11, 10, 0, tzinfo=FUSO_BRASILIA)
PADRAO = Preferencias()

FAVORITAS = [
    LojaFavorita(nome="Natura", categoria="Beleza", alerta_ativo=True),
    LojaFavorita(nome="C&A", categoria="Moda", apelidos=("CEA",), alerta_ativo=True),
    LojaFavorita(nome="Magalu", categoria="Marketplace", alerta_ativo=True),
]


def monta(parceiros, favoritas=FAVORITAS, preferencias=PADRAO):
    return montar_retrato(parceiros, favoritas, preferencias, agora=AGORA_TESTE, versao="9.9.9")


def teste_ct139_todas_as_favoritas_entram_mesmo_sem_promocao():
    """RN24: a pagina existe para responder "quanto a Renner da hoje?" (O5).

    Se so as promocoes entrassem, o site nao responderia a pergunta que
    justifica a fase inteira.
    """
    retrato = monta([faz_parceiro("Natura", "3", base="3", em_promocao=False)])

    assert len(retrato.pontuacoes) == 3
    assert [p.loja.nome for p in retrato.pontuacoes] == ["Natura", "C&A", "Magalu"]
    assert retrato.alertas == 0


def teste_ct140_favorita_ausente_vira_linha_sem_parceiro():
    """RN19: a loja nao some do site — some a pontuacao dela.

    Sumir com a loja faria o leitor achar que ela saiu do catalogo, quando
    o que aconteceu foi a Livelo mudar a grafia do nome.
    """
    retrato = monta([faz_parceiro("Natura", "8", base="2")])
    por_nome = {p.loja.nome: p for p in retrato.pontuacoes}

    assert por_nome["Magalu"].parceiro is None
    assert por_nome["Magalu"].valor_de_disparo is None
    assert por_nome["Magalu"].alertou is False
    assert por_nome["Natura"].parceiro is not None


def teste_ct141_apelido_liga_a_loja_certa():
    """RN04: a Livelo escreve "CEA", o catalogo diz "C&A"."""
    retrato = monta([faz_parceiro("CEA", "6", base="2")])
    por_nome = {p.loja.nome: p for p in retrato.pontuacoes}

    assert por_nome["C&A"].parceiro is not None
    assert por_nome["C&A"].alertou is True


def teste_ct142_valor_de_disparo_acompanha_a_regua():
    """RN30: o numero exibido depende da regua daquele momento, por isso e
    gravado calculado — a regua muda com o tempo."""
    parceiros = [faz_parceiro("Natura", "5", base="2")]
    frouxa = monta(parceiros).pontuacoes[0]
    apertada = monta(parceiros, preferencias=Preferencias(piso_pontos_padrao=Decimal("9")))

    assert frouxa.valor_de_disparo == Decimal("4")
    assert frouxa.alertou is True
    assert apertada.pontuacoes[0].valor_de_disparo == Decimal("9")
    assert apertada.pontuacoes[0].alertou is False


def teste_ct143_retrato_carrega_contagem_e_versao():
    """RN26: o carimbo do site sai daqui. A versao torna o defeito rastreavel."""
    parceiros = [faz_parceiro("Natura", "8", base="2"), faz_parceiro("Outra", "3", base="3")]
    retrato = monta(parceiros)

    assert retrato.momento == AGORA_TESTE
    assert retrato.parceiros_lidos == 2  # a pagina inteira, nao so as favoritas
    assert retrato.catalogo == tuple(parceiros)
    assert retrato.versao == "9.9.9"
    assert retrato.alertas == 1


def teste_ct169_sino_desligado_suprime_alerta_calculado():
    loja = LojaFavorita(nome="Natura", categoria="Beleza", alerta_ativo=False)
    retrato = monta([faz_parceiro("Natura", "8", base="2")], favoritas=[loja])

    assert retrato.pontuacoes[0].valor_de_disparo == Decimal("4")
    assert retrato.pontuacoes[0].alertou is False
