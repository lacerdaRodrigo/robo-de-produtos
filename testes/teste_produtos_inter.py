"""CT-200 a CT-208 — dominio, paginacao e publicacao atomica da V4."""

from __future__ import annotations

import json
from dataclasses import fields
from datetime import datetime
from decimal import Decimal

import pytest

from robo_livelo.extrator_produtos_inter import (
    RespostaProdutosInterInvalida,
    extrair_pagina_produtos,
    normalizar_busca_produtos,
)
from robo_livelo.modelos_produtos_inter import LojaDiretaInter, ProdutoDiretoInter
from robo_livelo.portas_produtos_inter import PaginacaoProdutosInterInvalida
from robo_livelo.principal_produtos_inter import coletar_produtos_de_loja
from testes.conftest import FUSO_BRASILIA

AGORA = datetime(2026, 8, 16, 20, 0, tzinfo=FUSO_BRASILIA)
LOJA = LojaDiretaInter("loja-1", "casas-bahia", "Casas Bahia", selecionada=True)


def pagina(offset: int, ultima: bool, *produtos: dict, total: int = 3, limite: int = 36) -> str:
    return json.dumps(
        {
            "products": list(produtos),
            "pagination": {"offset": offset, "limit": limite, "total": total, "isLastPage": ultima},
        }
    )


def produto(identificador: str, nome: str = "Smartphone Motorola Edge 60 Pro 5G") -> dict:
    return {
        "id": identificador,
        "sellerId": "loja-1",
        "name": nome,
        "slug": f"/produto/{identificador}",
        "brand": "Motorola",
        "categoryName": "Celulares",
        "listPrice": "R$ 3.999,00",
        "listPriceValue": 3999.00,
        "price": "R$ 2.999,90",
        "priceValue": 2999.90,
        "discountPrice": "R$ 999,10",
        "discountPriceValue": 999.10,
        "discountPercentage": "25%",
        "discountPercentageValue": 25,
        "fullCashback": "R$ 30,00",
        "fullCashbackValue": 30,
        "fullCashbackPercentage": "1%",
        "fullCashbackPercentageValue": 1,
        "fullLiquidPrice": "R$ 2.969,90",
        "fullLiquidPriceValue": 2969.90,
        "fullInstallmentsDescription": "12x sem juros",
        "stock": "Em estoque",
        "tags": ["Oferta", "<externo>"],
        "image": "https://nao-entra.example/imagem.png",
    }


def teste_ct200_extrai_pagina_com_moeda_decimal_e_sem_imagem():
    resultado = extrair_pagina_produtos(pagina(0, True, produto("edge")), id_loja="loja-1")

    assert resultado.itens_lidos == 1
    assert resultado.produtos[0].preco_atual_valor == Decimal("2999.9")
    assert resultado.produtos[0].etiquetas == ("Oferta", "<externo>")
    assert "image" not in {campo.name for campo in fields(ProdutoDiretoInter)}


def teste_ct201_caminho_externo_e_item_de_outra_loja_nao_entram():
    externo = produto("ruim")
    externo["slug"] = "https://golpe.example/produto"
    outra_loja = produto("outra")
    outra_loja["sellerId"] = "loja-2"

    resultado = extrair_pagina_produtos(pagina(0, True, externo, outra_loja), id_loja="loja-1")
    assert resultado.produtos == ()


def teste_ct202_busca_remove_artigos_e_equivale_celular_a_smartphone():
    assert (
        normalizar_busca_produtos("Celular Motorola Edge 60 Pro")
        == "smartphone motorola edge 60 pro"
    )
    assert (
        normalizar_busca_produtos("Smartphone Motorola Edge 60 Pro")
        == "smartphone motorola edge 60 pro"
    )


class FonteFakeProdutos:
    def __init__(self, respostas: dict[int, str]):
        self.respostas = respostas
        self.chamadas: list[tuple[str, int, int]] = []

    def pagina(self, loja, search_id, offset, limite):
        self.chamadas.append((search_id, offset, limite))
        return self.respostas[offset]


class RepositorioFakeProdutos:
    def __init__(self):
        self.publicadas = []
        self.falhas = []

    def iniciar_loja(self, loja, momento, versao):
        return 77

    def publicar_loja(self, execucao_id, loja, produtos, resumo):
        self.publicadas.append((execucao_id, loja, produtos, resumo))

    def falhar_loja(self, execucao_id, codigo):
        self.falhas.append((execucao_id, codigo))


def teste_ct203_pagina_ate_ultima_deduplica_e_mantem_search_id():
    fonte = FonteFakeProdutos(
        {
            0: pagina(0, False, produto("edge"), produto("g"), total=3),
            36: pagina(36, True, produto("edge"), produto("f"), total=3),
        }
    )
    repositorio = RepositorioFakeProdutos()

    resumo = coletar_produtos_de_loja(
        fonte, repositorio, LOJA, agora=AGORA, gerar_uuid=lambda: "uuid-da-loja"
    )

    assert [chamada[1] for chamada in fonte.chamadas] == [0, 36]
    assert {chamada[0] for chamada in fonte.chamadas} == {"uuid-da-loja"}
    assert resumo.itens_lidos == 4
    assert resumo.itens_unicos == 3
    assert resumo.duplicados == 1
    assert [item.id_externo for item in repositorio.publicadas[0][2]] == ["edge", "g", "f"]
    assert repositorio.falhas == []


def teste_ct204_offset_repetido_falha_sem_publicar():
    fonte = FonteFakeProdutos(
        {
            0: pagina(0, False, produto("edge"), total=72),
            36: pagina(0, True, produto("g"), total=72),
        }
    )
    repositorio = RepositorioFakeProdutos()

    with pytest.raises(PaginacaoProdutosInterInvalida, match="offset diferente"):
        coletar_produtos_de_loja(fonte, repositorio, LOJA, agora=AGORA)

    assert repositorio.publicadas == []
    assert repositorio.falhas == [(77, "offset_incoerente")]


@pytest.mark.parametrize("conteudo", ["{quebrado", "[]", '{"products": []}'])
def teste_ct205_resposta_sem_raiz_paginada_falha(conteudo):
    with pytest.raises(RespostaProdutosInterInvalida):
        extrair_pagina_produtos(conteudo, id_loja="loja-1")
