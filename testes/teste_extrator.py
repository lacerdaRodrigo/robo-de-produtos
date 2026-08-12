"""CT-010 a CT-020 e CT-080 a CT-095 — nucleo puro: payload JSON vira Parceiro.

Nunca toca a rede. A V2.0 troca a raspagem de HTML por leitura do
__NEXT_DATA__ (RF14) — CT-015, CT-016, CT-019 e o antigo
`teste_link_sem_card_e_ignorado` foram aposentados porque testavam
mecanismos que deixaram de existir (atributo `alt`, link solto no HTML):
não existe "card sem alt" nem "link fora de um item" num array JSON.
"""

from __future__ import annotations

import json
import logging
from datetime import datetime
from decimal import Decimal

from robo_livelo.extrator import TITULO_SECAO_PARCEIROS, extrair_parceiros
from testes.conftest import (
    FUSO_BRASILIA,
    TITULO_SECAO_DESTAQUE,
    envolver_payload_em_html,
    monta_html_payload,
    monta_item_parceiro,
)

AGORA_TESTE = datetime(2026, 8, 11, 10, 0, tzinfo=FUSO_BRASILIA)


def um(html: str, *, agora: datetime = AGORA_TESTE):
    parceiros = extrair_parceiros(html, agora=agora)
    assert len(parceiros) == 1
    return parceiros[0]


def pagina(*itens: dict) -> str:
    return monta_html_payload(*itens)


# ── CT-010 a CT-020: adaptados do V1 para o formato JSON ────────────────────


def teste_ct010_loja_sem_promocao():
    parceiro = um(pagina(monta_item_parceiro(promotion=False)))
    assert parceiro.em_promocao is False


def teste_ct011_promocao_preenche_pontos_base():
    """O "eram X pontos" do V1 vira `pontos_base` (parityBau), nao mais regex."""
    parceiro = um(pagina(monta_item_parceiro(parity="4", parity_bau="2", promotion=True)))
    assert parceiro.em_promocao is True
    assert parceiro.pontos_atuais == Decimal("4")
    assert parceiro.pontos_base == Decimal("2")


def teste_ct012_tier_clube_livelo():
    parceiro = um(pagina(monta_item_parceiro(parity="8", parity_club="12", promotion=True)))
    assert parceiro.pontos_clube == Decimal("12")
    assert parceiro.pontos_atuais == Decimal("8")


def teste_ct013_prefixo_ate():
    parceiro = um(pagina(monta_item_parceiro(parity="5", separator_slug="ATE")))
    assert parceiro.prefixo_ate is True
    assert parceiro.pontos_atuais == Decimal("5")


def teste_ct014_moeda_em_dolar():
    """RN11: nunca converte, exibe como veio."""
    parceiro = um(pagina(monta_item_parceiro(nome="Booking com", currency="U$")))
    assert parceiro.moeda == "U$"


def teste_ct017_parceiro_duplicado():
    """RN06: repetido conta uma vez so."""
    itens = [monta_item_parceiro(nome="Natura"), monta_item_parceiro(nome="Natura")]
    assert len(extrair_parceiros(pagina(*itens), agora=AGORA_TESTE)) == 1


def teste_ct018_pagina_sem_parceiros():
    assert extrair_parceiros(pagina(), agora=AGORA_TESTE) == []


def teste_ct020_nome_com_caracteres_especiais():
    for nome in ("Sam's Club", "O.U.i Paris", "C&A"):
        parceiro = um(pagina(monta_item_parceiro(nome=nome)))
        assert parceiro.nome == nome


# ── CT-080 em diante: novos, especificos do payload JSON (RF14) ─────────────


def teste_ct080_mapeamento_completo_rf14():
    momento_inicio = "2026-08-05-00:00:00 GMT-03:00"
    momento_fim = "2026-08-20-23:59:00 GMT-03:00"
    parceiro = um(
        pagina(
            monta_item_parceiro(
                parity="6",
                parity_bau="4",
                promotion=True,
                date_start=momento_inicio,
                date_end=momento_fim,
                active_campaign="PROMOTION",
            )
        )
    )
    assert parceiro.pontos_base == Decimal("4")
    assert parceiro.inicio_promocao == datetime(2026, 8, 5, 0, 0, tzinfo=FUSO_BRASILIA)
    assert parceiro.fim_promocao == datetime(2026, 8, 20, 23, 59, tzinfo=FUSO_BRASILIA)
    assert parceiro.campanha == "PROMOTION"


def teste_ct081_fracionario_sem_residuo_de_float():
    """PRD 5.4: json.loads com parse_float=Decimal evita 2.9000000000000004."""
    parceiro = um(pagina(monta_item_parceiro(parity="2.9")))
    assert parceiro.pontos_atuais == Decimal("2.9")
    assert str(parceiro.pontos_atuais) == "2.9"


def teste_ct082_localiza_secao_por_titulo_nao_por_indice():
    """C06: a secao de listagem antes da de destaque, ainda assim acha certo."""
    payload = {
        "props": {
            "pageProps": {
                "page": {
                    "components": [
                        {
                            "type": "listagem",
                            "props": {
                                "title": TITULO_SECAO_PARCEIROS,
                                "configPartners": [monta_item_parceiro(nome="Natura")],
                            },
                        },
                        {
                            "type": "carrossel",
                            "props": {
                                "title": TITULO_SECAO_DESTAQUE,
                                "configPartners": [
                                    monta_item_parceiro(id="X", nome="Item Do Carrossel Errado")
                                ],
                            },
                        },
                    ]
                }
            }
        }
    }
    html = envolver_payload_em_html(json.dumps(payload))
    nomes = {p.nome for p in extrair_parceiros(html, agora=AGORA_TESTE)}
    assert nomes == {"Natura"}


def teste_ct083_secao_ausente_devolve_lista_vazia():
    payload = {"props": {"pageProps": {"page": {"components": []}}}}
    html = envolver_payload_em_html(json.dumps(payload))
    assert extrair_parceiros(html, agora=AGORA_TESTE) == []


def teste_ct084_sem_dateend_nao_quebra():
    parceiro = um(pagina(monta_item_parceiro(promotion=True, date_start=None, date_end=None)))
    assert parceiro.fim_promocao is None
    assert parceiro.em_promocao is True


def teste_ct085_data_malformada_vira_none():
    parceiro = um(pagina(monta_item_parceiro(promotion=True, date_end="nao e uma data")))
    assert parceiro.fim_promocao is None
    assert parceiro.em_promocao is True  # sem data legivel, RN21 nao desliga


def teste_ct086_rn21_dateend_no_passado_desliga_em_promocao():
    parceiro = um(
        pagina(
            monta_item_parceiro(
                promotion=True,
                date_start="2026-08-01-00:00:00 GMT-03:00",
                date_end="2026-08-05-23:59:00 GMT-03:00",  # antes de AGORA_TESTE
            )
        )
    )
    assert parceiro.em_promocao is False


def teste_ct087_rn21_dateend_no_futuro_mantem_em_promocao():
    parceiro = um(
        pagina(
            monta_item_parceiro(
                promotion=True,
                date_start="2026-08-10-00:00:00 GMT-03:00",
                date_end="2026-08-20-23:59:00 GMT-03:00",  # depois de AGORA_TESTE
            )
        )
    )
    assert parceiro.em_promocao is True


def teste_ct088_sem_pontuacao_legivel_e_descartado():
    """Descarta so aquele item, os outros seguem (PRD 6.4)."""
    item_quebrado = monta_item_parceiro(nome="Loja Quebrada")
    item_quebrado["parity"]["parity"] = "nao e numero"
    item_bom = monta_item_parceiro(nome="Natura")

    parceiros = extrair_parceiros(pagina(item_quebrado, item_bom), agora=AGORA_TESTE)
    assert [p.nome for p in parceiros] == ["Natura"]


def teste_ct089_sem_nome_e_descartado():
    item_sem_nome = monta_item_parceiro(nome="")
    item_bom = monta_item_parceiro(nome="Natura")
    parceiros = extrair_parceiros(pagina(item_sem_nome, item_bom), agora=AGORA_TESTE)
    assert [p.nome for p in parceiros] == ["Natura"]


def teste_ct090_dedup_por_nome():
    itens = [monta_item_parceiro(nome="Petlove"), monta_item_parceiro(nome="Petlove")]
    assert len(extrair_parceiros(pagina(*itens), agora=AGORA_TESTE)) == 1


def teste_ct091_separator_slug_ate_hipotese():
    """RN12: hipotese de mapeamento, sem exemplo real confirmado ainda."""
    parceiro = um(pagina(monta_item_parceiro(separator_slug="ATE")))
    assert parceiro.prefixo_ate is True


def teste_ct092_moeda_preservada():
    parceiro = um(pagina(monta_item_parceiro(currency="U$")))
    assert parceiro.moeda == "U$"


def teste_ct093_parity_club_igual_a_parity_nao_popula_clube():
    parceiro = um(pagina(monta_item_parceiro(parity="4", parity_club="4")))
    assert parceiro.pontos_clube is None


def teste_ct094_parity_club_distinto_popula_clube():
    parceiro = um(pagina(monta_item_parceiro(parity="4", parity_club="10")))
    assert parceiro.pontos_clube == Decimal("10")


def teste_ct095_fixture_real_traz_os_casos_dificeis(payload_exemplo):
    """A fixture e o payload de verdade, recortado (nao inventado)."""
    por_nome = {p.nome: p for p in extrair_parceiros(payload_exemplo, agora=AGORA_TESTE)}

    assert set(por_nome) == {
        "Mercado Livre",
        "Booking com",
        "O Boticário",
        "Casas Bahia",
        "Magalu",
        "Pontofrio",
        "Petlove",
        "ABC da Construcao",
        "Sephora",
        "Coffee Mais",
        "Aliexpress",
    }

    assert por_nome["Casas Bahia"].prefixo_ate is True
    assert por_nome["Booking com"].moeda == "U$"

    # RN23: base parada (3 -> 3), boost so no tier Clube.
    boticario = por_nome["O Boticário"]
    assert boticario.pontos_atuais == boticario.pontos_base == Decimal("3")
    assert boticario.pontos_clube == Decimal("10")

    # RN21: dateEnd no passado desliga em_promocao mesmo com promotion:true no payload.
    assert por_nome["Magalu"].em_promocao is False

    # RN22 candidato: termina no mesmo dia de AGORA_TESTE.
    assert por_nome["Casas Bahia"].fim_promocao.date() == AGORA_TESTE.date()

    # dateEnd malformado nao derruba o item nem desliga a promocao.
    assert por_nome["Petlove"].fim_promocao is None
    assert por_nome["Petlove"].em_promocao is True

    # promotion:true sem dateEnd nenhum tambem nao quebra.
    assert por_nome["Pontofrio"].fim_promocao is None
    assert por_nome["Pontofrio"].em_promocao is True

    # Os tres casos reais de campanha ligada ao Clube, copiados da pagina de
    # 2026-08-11 (RN23). Sephora e Coffee Mais tem a base movida; Aliexpress
    # nao — e a diferenca que separa "ganham mais" de "exclusivo".
    assert por_nome["Sephora"].campanha == "PROMOTION_CLUB"
    assert por_nome["Sephora"].pontos_base == Decimal("1")
    assert por_nome["Sephora"].pontos_atuais == Decimal("6")
    assert por_nome["Coffee Mais"].campanha == "PROMOTION_CLUB"
    assert por_nome["Coffee Mais"].prefixo_ate is True
    assert por_nome["Aliexpress"].campanha == "CLUB"
    assert por_nome["Aliexpress"].pontos_atuais == por_nome["Aliexpress"].pontos_base

    # "Liga Vitória Seguro Auto" tem `parity: null` na pagina real — produto da
    # propria Livelo, nao parceiro. Sai da lista sem virar WARNING (CT-106).
    assert "Liga Vitória Seguro Auto" not in por_nome


# ── Robustez contra payload hostil (RN07: todo dado do site e hostil) ───────


def teste_script_next_data_ausente_devolve_lista_vazia():
    html = "<html><body><p>pagina sem o script esperado</p></body></html>"
    assert extrair_parceiros(html, agora=AGORA_TESTE) == []


def teste_json_invalido_no_script_devolve_lista_vazia():
    html = envolver_payload_em_html("{isso nao e json valido")
    assert extrair_parceiros(html, agora=AGORA_TESTE) == []


def teste_payload_json_que_nao_e_objeto_devolve_lista_vazia():
    html = envolver_payload_em_html(json.dumps(["lista", "solta"]))
    assert extrair_parceiros(html, agora=AGORA_TESTE) == []


def teste_componente_que_nao_e_objeto_e_ignorado():
    payload = {
        "props": {
            "pageProps": {
                "page": {
                    "components": [
                        "isso nao e um componente",
                        None,
                        {
                            "type": "listagem",
                            "props": {
                                "title": TITULO_SECAO_PARCEIROS,
                                "configPartners": [monta_item_parceiro(nome="Natura")],
                            },
                        },
                    ]
                }
            }
        }
    }
    html = envolver_payload_em_html(json.dumps(payload))
    nomes = {p.nome for p in extrair_parceiros(html, agora=AGORA_TESTE)}
    assert nomes == {"Natura"}


def teste_item_que_nao_e_objeto_e_descartado():
    itens = ["isso nao e um item", None, monta_item_parceiro(nome="Natura")]
    html = pagina(*itens)
    nomes = {p.nome for p in extrair_parceiros(html, agora=AGORA_TESTE)}
    assert nomes == {"Natura"}


def teste_parity_que_nao_e_objeto_e_item_descartado():
    item = monta_item_parceiro(nome="Loja Quebrada")
    item["parity"] = "isso deveria ser um objeto"
    item_bom = monta_item_parceiro(nome="Natura")
    parceiros = extrair_parceiros(pagina(item, item_bom), agora=AGORA_TESTE)
    assert [p.nome for p in parceiros] == ["Natura"]


def teste_parity_bau_nao_numerico_vira_none_sem_derrubar_item():
    item = monta_item_parceiro(nome="Natura")
    item["parity"]["parityBau"] = "nao e numero"
    parceiro = um(pagina(item))
    assert parceiro.pontos_base is None


def teste_parity_club_nao_numerico_vira_none_sem_derrubar_item():
    item = monta_item_parceiro(nome="Natura")
    item["parity"]["parityClub"] = "nao e numero"
    parceiro = um(pagina(item))
    assert parceiro.pontos_clube is None


def teste_ct106_item_sem_parity_nao_vira_warning(caplog):
    """Produto da propria Livelo (LVA, XXX...) nao tem pontuacao e nao e erro.

    Sao 11 itens assim em toda execucao. WARNING para caso conhecido e
    recorrente afoga o aviso que realmente importa (RNF06).
    """
    sem_parity = monta_item_parceiro(id="LVA", nome="Livelo Assinatura")
    del sem_parity["parity"]
    bom = monta_item_parceiro(nome="Natura")

    with caplog.at_level(logging.DEBUG, logger="robo_livelo.extrator"):
        parceiros = extrair_parceiros(pagina(sem_parity, bom), agora=AGORA_TESTE)

    assert [p.nome for p in parceiros] == ["Natura"]
    assert not [r for r in caplog.records if r.levelno >= logging.WARNING]
    assert any(r.levelno == logging.DEBUG and "LVA" in r.getMessage() for r in caplog.records)
    assert any("ignorados: 1" in r.getMessage() for r in caplog.records)


def teste_ct107_item_com_parity_ilegivel_continua_sendo_warning(caplog):
    """Contraprova de CT-106: pontuacao que existe mas nao da para ler e sintoma."""
    quebrado = monta_item_parceiro(id="NAT", nome="Natura")
    quebrado["parity"]["parity"] = "nao e numero"

    with caplog.at_level(logging.DEBUG, logger="robo_livelo.extrator"):
        extrair_parceiros(pagina(quebrado), agora=AGORA_TESTE)

    assert [r for r in caplog.records if r.levelno == logging.WARNING]
