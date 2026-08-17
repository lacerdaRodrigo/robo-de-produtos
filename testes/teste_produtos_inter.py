"""CT-200 a CT-208 — dominio, paginacao e publicacao atomica da V4."""

from __future__ import annotations

import json
from dataclasses import fields
from datetime import datetime
from decimal import Decimal

import pytest

from robo_livelo.adaptadores_produtos_inter import FonteProdutosInterHttp
from robo_livelo.extrator_produtos_inter import (
    RespostaProdutosInterInvalida,
    extrair_lojas_diretas,
    extrair_pagina_produtos,
    normalizar_busca_produtos,
)
from robo_livelo.modelos_produtos_inter import LojaDiretaInter, ProdutoDiretoInter
from robo_livelo.portas_produtos_inter import FalhaProdutosInter, PaginacaoProdutosInterInvalida
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
        "slug": f"Smartphone-Motorola-Edge-60/p/{identificador}",
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
        "tags": [
            {"text": "Oferta", "textColor": "#fff"},
            {"text": "<externo>", "background": "#000"},
        ],
        "image": "https://nao-entra.example/imagem.png",
        "skus": [
            {
                "brand": "Motorola",
                "categoryName": "Celulares",
                "stock": 354,
            }
        ],
    }


def teste_ct200_extrai_pagina_com_moeda_decimal_e_sem_imagem():
    resultado = extrair_pagina_produtos(pagina(0, True, produto("edge")), id_loja="loja-1")

    assert resultado.itens_lidos == 1
    assert resultado.produtos[0].preco_atual_valor == Decimal("2999.9")
    assert resultado.produtos[0].etiquetas == ("Oferta", "<externo>")
    assert resultado.produtos[0].caminho == "/Smartphone-Motorola-Edge-60/p/edge"
    assert resultado.produtos[0].marca == "Motorola"
    assert resultado.produtos[0].categoria == "Celulares"
    assert resultado.produtos[0].estoque == 354
    assert "image" not in {campo.name for campo in fields(ProdutoDiretoInter)}


def teste_ct200_catalogo_real_usa_raiz_sellers():
    lojas = extrair_lojas_diretas(
        json.dumps(
            {
                "sellers": [
                    {"id": "intercasasbahia", "slug": "casas-bahia", "name": "Casas Bahia"},
                    {"id": "interponto", "slug": "ponto", "name": "Ponto"},
                ]
            }
        )
    )

    assert [(loja.id_externo, loja.slug) for loja in lojas] == [
        ("intercasasbahia", "casas-bahia"),
        ("interponto", "ponto"),
    ]


def teste_ct201_caminho_externo_e_item_de_outra_loja_nao_entram():
    externo = produto("ruim")
    externo["slug"] = "https://golpe.example/produto"
    outra_loja = produto("outra")
    outra_loja["sellerId"] = "loja-2"

    resultado = extrair_pagina_produtos(pagina(0, True, externo, outra_loja), id_loja="loja-1")
    assert resultado.produtos == ()


def teste_ct201_variante_numerica_e_preservada_mas_query_arbitraria_nao():
    variante = produto("variante")
    variante["slug"] += "?v=168245243979"
    arbitrario = produto("arbitrario")
    arbitrario["slug"] += "?redirect=https://externo.example"

    resultado = extrair_pagina_produtos(
        pagina(0, True, variante, arbitrario),
        id_loja="loja-1",
    )

    assert [item.caminho for item in resultado.produtos] == [
        "/Smartphone-Motorola-Edge-60/p/variante?v=168245243979"
    ]


def teste_ct201_preco_atual_ausente_descarta_item():
    sem_preco = produto("sem-preco")
    sem_preco.pop("priceValue")

    resultado = extrair_pagina_produtos(pagina(0, True, sem_preco), id_loja="loja-1")

    assert resultado.produtos == ()


class RespostaHttpFake:
    status_code = 200

    def __init__(self, texto: str):
        self.text = texto
        self.content = texto.encode()


def teste_ct202_requisicao_envia_contrato_real_e_search_id_estavel():
    chamadas = []

    def postar(url, **opcoes):
        chamadas.append((url, opcoes))
        return RespostaHttpFake(pagina(36, True, produto("edge")))

    fonte = FonteProdutosInterHttp(postar=postar)

    fonte.pagina(LOJA, "uuid-da-rodada", 36, 36)

    corpo = chamadas[0][1]["json"]
    assert corpo == {
        "aggregate": True,
        "slug": "casas-bahia",
        "searchText": "",
        "sort": "NAME_ASCENDENT",
        "pagination": {"offset": 36, "limit": 36},
        "featureFilters": [],
        "searchId": "uuid-da-rodada",
    }
    assert chamadas[0][1]["headers"]["User-Agent"].startswith("radar-beneficios/4")


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
    def __init__(self, respostas: dict[object, str]):
        self.respostas = respostas
        self.chamadas: list[tuple[str, int, int]] = []

    def pagina(self, loja, search_id, offset, limite, *, busca=""):
        self.chamadas.append((search_id, offset, limite, busca))
        chave = (busca, offset)
        return self.respostas[chave] if chave in self.respostas else self.respostas[offset]


class FonteSequencialProdutos:
    def __init__(self, respostas: list[str]):
        self.respostas = iter(respostas)
        self.chamadas: list[tuple[str, int, int, str]] = []

    def pagina(self, loja, search_id, offset, limite, *, busca=""):
        self.chamadas.append((search_id, offset, limite, busca))
        return next(self.respostas)


class RepositorioFakeProdutos:
    def __init__(self):
        self.publicadas = []
        self.falhas = []

    def iniciar_loja(self, loja, momento, versao, *, rodada_id=None):
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


def teste_ct203_busca_suplementar_ultrapassa_janela_e_deduplica():
    fonte = FonteFakeProdutos(
        {
            ("", 0): pagina(0, True, produto("base"), total=1),
            ("smartphone", 0): pagina(
                0,
                True,
                produto("base"),
                produto("edge-60-pro"),
                total=2,
            ),
        }
    )
    repositorio = RepositorioFakeProdutos()
    ids = iter(("uuid-base", "uuid-smartphone"))

    resumo = coletar_produtos_de_loja(
        fonte,
        repositorio,
        LOJA,
        agora=AGORA,
        buscas_suplementares=("smartphone",),
        gerar_uuid=lambda: next(ids),
    )

    assert fonte.chamadas == [
        ("uuid-base", 0, 36, ""),
        ("uuid-smartphone", 0, 36, "smartphone"),
    ]
    assert resumo.total_declarado == 3
    assert resumo.paginas == 2
    assert resumo.itens_lidos == 3
    assert resumo.itens_unicos == 2
    assert resumo.duplicados == 1
    assert [item.id_externo for item in repositorio.publicadas[0][2]] == [
        "base",
        "edge-60-pro",
    ]


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


def teste_ct205_total_positivo_sem_produto_valido_preserva_snapshot():
    invalido = produto("invalido")
    invalido["slug"] = "https://externo.example/produto"
    fonte = FonteFakeProdutos({0: pagina(0, True, invalido, total=1)})
    repositorio = RepositorioFakeProdutos()

    with pytest.raises(FalhaProdutosInter, match="nenhum item"):
        coletar_produtos_de_loja(fonte, repositorio, LOJA, agora=AGORA)

    assert repositorio.publicadas == []
    assert repositorio.falhas == [(77, "schema_invalido")]


@pytest.mark.parametrize("conteudo", ["{quebrado", "[]", '{"products": []}'])
def teste_ct205_resposta_sem_raiz_paginada_falha(conteudo):
    with pytest.raises(RespostaProdutosInterInvalida):
        extrair_pagina_produtos(conteudo, id_loja="loja-1")

def teste_ct209_total_muda_reinicia_segmento_sem_publicar_tentativa_parcial():
    fonte = FonteSequencialProdutos(
        [
            pagina(0, False, produto("tentativa-antiga"), total=72),
            pagina(36, True, produto("mudou"), total=73),
            pagina(0, True, produto("novo-1"), produto("novo-2"), total=2),
        ]
    )
    repositorio = RepositorioFakeProdutos()
    ids = iter(("uuid-instavel", "uuid-estavel"))

    resumo = coletar_produtos_de_loja(
        fonte,
        repositorio,
        LOJA,
        agora=AGORA,
        gerar_uuid=lambda: next(ids),
    )

    assert [chamada[:2] for chamada in fonte.chamadas] == [
        ("uuid-instavel", 0),
        ("uuid-instavel", 36),
        ("uuid-estavel", 0),
    ]
    assert resumo.total_declarado == 2
    assert resumo.paginas == 1
    assert resumo.itens_lidos == 2
    assert [item.id_externo for item in repositorio.publicadas[0][2]] == [
        "novo-1",
        "novo-2",
    ]
    assert repositorio.falhas == []


def teste_ct209_total_continua_mudando_falha_apos_tres_tentativas():
    respostas = []
    for indice in range(3):
        respostas.extend(
            [
                pagina(0, False, produto(f"inicio-{indice}"), total=72),
                pagina(36, True, produto(f"mudou-{indice}"), total=73),
            ]
        )
    fonte = FonteSequencialProdutos(respostas)
    repositorio = RepositorioFakeProdutos()
    ids = iter(("uuid-1", "uuid-2", "uuid-3"))

    with pytest.raises(PaginacaoProdutosInterInvalida, match="mudou o total"):
        coletar_produtos_de_loja(
            fonte,
            repositorio,
            LOJA,
            agora=AGORA,
            gerar_uuid=lambda: next(ids),
        )

    assert len(fonte.chamadas) == 6
    assert repositorio.publicadas == []
    assert repositorio.falhas == [(77, "total_incoerente")]

