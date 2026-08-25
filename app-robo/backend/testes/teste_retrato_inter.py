"""CT-184 — retrato das favoritas do Shopping Inter."""

from datetime import datetime

from robo_livelo.modelos_inter import FavoritaInter
from robo_livelo.retrato_inter import montar_retrato_inter
from testes.conftest import FUSO_BRASILIA, faz_loja_inter


def teste_ct184_favorita_ausente_permanece_no_retrato():
    momento = datetime(2026, 8, 14, 20, 0, tzinfo=FUSO_BRASILIA)
    retrato = montar_retrato_inter(
        [faz_loja_inter("C&A", "12", id_externo="ca")],
        [FavoritaInter("ca", "C&A"), FavoritaInter("riachuelo", "Riachuelo")],
        momento=momento,
        lojas_lidas=381,
        versao="9.9.9",
    )

    assert retrato.lojas_lidas == 381
    assert retrato.lojas_validas == 1
    assert retrato.favoritas_encontradas == 1
    assert retrato.favoritas[0].encontrada is True
    assert retrato.favoritas[1].encontrada is False
    assert retrato.favoritas[1].nome == "Riachuelo"
