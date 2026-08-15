"""CT-181 — ranking puro do cashback principal."""

from robo_livelo.modelos_inter import CashbackFavoritaInter, FavoritaInter
from robo_livelo.ranking_inter import ordenar_favoritas
from testes.conftest import faz_loja_inter


def item(nome, valor, *, encontrada=True):
    favorita = FavoritaInter(id_externo=nome, nome=nome)
    loja = faz_loja_inter(nome, valor, id_externo=nome) if encontrada else None
    return CashbackFavoritaInter(favorita=favorita, loja=loja)


def teste_ct181_positivos_zero_ausente_e_nao_encontrada():
    itens = [
        item("Amazon", "0"),
        item("Riachuelo", "15"),
        item("Sem número", None),
        item("C&A", "12"),
        item("Ausente", None, encontrada=False),
        item("Magazine Luiza", "20"),
        item("Outra 15", "15"),
    ]

    assert [item.nome for item in ordenar_favoritas(itens)] == [
        "Magazine Luiza",
        "Outra 15",
        "Riachuelo",
        "C&A",
        "Amazon",
        "Sem número",
        "Ausente",
    ]
