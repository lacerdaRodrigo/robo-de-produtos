"""CT-175 a CT-180, CT-182, CT-183 e CT-186 — extrator puro do Inter."""

from __future__ import annotations

import json
from dataclasses import fields
from decimal import Decimal

import pytest

from robo_livelo.extrator_inter import (
    ConflitoIdentidadeInter,
    RespostaInterInvalida,
    extrair_lojas,
)
from robo_livelo.modelos_inter import LojaInter


def teste_ct175_fixture_recortada_vira_cinco_lojas(json_inter_exemplo):
    extracao = extrair_lojas(json_inter_exemplo)

    assert extracao.lojas_lidas == 5
    assert extracao.lojas_validas == 5
    assert [loja.nome for loja in extracao.lojas] == [
        "Magazine Luiza",
        "Riachuelo",
        "C&A",
        "Amazon",
        "Pague Menos",
    ]


def teste_ct176_oferta_principal_usa_decimal(json_inter_exemplo):
    magalu = extrair_lojas(json_inter_exemplo).lojas[0]
    assert magalu.cashback_principal_texto == "Até 20% de cashback"
    assert magalu.cashback_principal_valor == Decimal("20")
    assert isinstance(magalu.cashback_principal_valor, Decimal)


def teste_ct177_oferta_secundaria_fica_separada(json_inter_exemplo):
    magalu = extrair_lojas(json_inter_exemplo).lojas[0]
    assert magalu.cashback_principal_valor == Decimal("20")
    assert magalu.cashback_secundario_valor == Decimal("14")
    assert "não-correntistas" in (magalu.descricao_secundaria or "")


def teste_ct178_zero_preserva_ofertas_disponiveis(json_inter_exemplo):
    amazon = extrair_lojas(json_inter_exemplo).lojas[3]
    assert amazon.cashback_principal_texto == "Ofertas disponíveis"
    assert amazon.cashback_principal_valor == Decimal("0")


def teste_ct179_descricao_multilinha_e_vazia(json_inter_exemplo):
    magalu, _, cea, *_ = extrair_lojas(json_inter_exemplo).lojas
    assert "20% de cashback" in (magalu.descricao_principal or "")
    assert "\n\n" in (magalu.descricao_principal or "")
    assert cea.descricao_principal is None
    assert cea.descricao_secundaria is None


def teste_ct180_identidade_nao_depende_do_nome(json_inter_exemplo):
    dados = json.loads(json_inter_exemplo)
    dados[2]["name"] = "C&A Modas"
    cea = extrair_lojas(json.dumps(dados)).lojas[2]
    assert cea.id_externo == "d4bb2c85-5f9a-4fc7-89e0-78b2899a9b5e"
    assert cea.slug == "ca"


def teste_ct183_raiz_ou_json_invalido_falha():
    for conteudo in ("{quebrado", '{"lojas": []}', '"texto"'):
        with pytest.raises(RespostaInterInvalida):
            extrair_lojas(conteudo)


def teste_identidade_duplicada_invalida_resposta(json_inter_exemplo):
    dados = json.loads(json_inter_exemplo)
    dados[1]["id"] = dados[0]["id"]
    with pytest.raises(ConflitoIdentidadeInter, match="ID de loja duplicado"):
        extrair_lojas(json.dumps(dados))


def teste_item_invalido_e_descartado_sem_perder_os_outros(json_inter_exemplo):
    dados = json.loads(json_inter_exemplo)
    dados[0]["fullCashbackValue"] = "nao e numero"
    extracao = extrair_lojas(json.dumps(dados))
    assert extracao.lojas_lidas == 5
    assert extracao.lojas_validas == 4
    assert "Magazine Luiza" not in {loja.nome for loja in extracao.lojas}


def teste_ct186_modelo_nao_expoe_imagem(json_inter_exemplo):
    nomes = {campo.name for campo in fields(LojaInter)}
    assert "imageUrl" not in nomes
    assert "image_url" not in nomes
    assert extrair_lojas(json_inter_exemplo).lojas_validas == 5
