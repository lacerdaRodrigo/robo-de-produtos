"""CT-010 a CT-020 — nucleo puro: HTML vira Parceiro. Nunca toca a rede."""

from __future__ import annotations

from decimal import Decimal

from robo_livelo.extrator import extrair_parceiros

CARD = """
<a data-testid="a_PartnerCard_card_link" href="{link}">
  <div data-testid="div_PartnerCard">
    {tag}
    <img data-testid="img_PartnerCard_partnerImage" {alt}/>
    <div>{texto}</div>
  </div>
</a>
"""
TAG_PROMOCAO = '<span data-testid="span_PartnerCard_promotionTag">Promoção</span>'


def monta_html(
    texto: str,
    *,
    nome: str = "Natura",
    promocao: bool = False,
    link: str = "https://www.livelo.com.br/juntar-pontos/parceiros/natura/NAT",
    com_alt: bool = True,
    extra: str = "",
) -> str:
    card = CARD.format(
        link=link,
        tag=TAG_PROMOCAO if promocao else "",
        alt=f'alt="Logo {nome}"' if com_alt else "",
        texto=texto,
    )
    return f"<html><body>{card}{extra}</body></html>"


def um(html: str):
    parceiros = extrair_parceiros(html)
    assert len(parceiros) == 1
    return parceiros[0]


def teste_ct010_loja_sem_promocao():
    parceiro = um(monta_html("2 pontos por R$ 1"))
    assert parceiro.em_promocao is False
    assert parceiro.pontos_anteriores is None


def teste_ct011_promocao_com_eram_x_pontos():
    parceiro = um(monta_html("Promoção 4 pontos por R$ 1 Eram 2 pontos", promocao=True))
    assert parceiro.em_promocao is True
    assert parceiro.pontos_atuais == Decimal("4")
    assert parceiro.pontos_anteriores == Decimal("2")


def teste_ct012_tier_clube_livelo():
    parceiro = um(
        monta_html(
            "Promoção Até 8 pontos por R$ 1 Eram 2 pontos Clube Até 12 pontos por R$ 1",
            promocao=True,
        )
    )
    assert parceiro.pontos_clube == Decimal("12")
    assert parceiro.pontos_atuais == Decimal("8")


def teste_ct013_prefixo_ate():
    parceiro = um(monta_html("Até 5 pontos por R$ 1"))
    assert parceiro.prefixo_ate is True
    assert parceiro.pontos_atuais == Decimal("5")


def teste_ct014_moeda_em_dolar():
    """RN11: nunca converte, exibe como veio."""
    parceiro = um(monta_html("4 pontos por U$ 1", nome="Booking com"))
    assert parceiro.moeda == "U$"


def teste_ct015_nome_via_atributo_alt():
    parceiro = um(monta_html("2 pontos por R$ 1", nome="Casas Bahia"))
    assert parceiro.nome == "Casas Bahia"


def teste_ct016_sem_alt_usa_reserva():
    """RN15: sem alt, usa o texto do link e nunca quebra."""
    parceiro = um(monta_html("3 pontos por R$ 1", com_alt=False))
    assert "3 pontos" in parceiro.nome


def teste_ct017_parceiro_duplicado():
    """RN06: repetido conta uma vez so."""
    extra = CARD.format(
        link="https://www.livelo.com.br/juntar-pontos/parceiros/natura/NAT",
        tag="",
        alt='alt="Logo Natura"',
        texto="2 pontos por R$ 1",
    )
    assert len(extrair_parceiros(monta_html("2 pontos por R$ 1", extra=extra))) == 1


def teste_ct018_pagina_sem_parceiros():
    assert extrair_parceiros("<html><body><p>nada aqui</p></body></html>") == []


def teste_ct019_link_que_nao_e_de_parceiro():
    html = monta_html("2 pontos por R$ 1", extra='<a href="/rodape">Fale conosco</a>')
    parceiros = extrair_parceiros(html)
    assert len(parceiros) == 1
    assert parceiros[0].nome == "Natura"


def teste_ct020_nome_com_caracteres_especiais():
    for nome in ("Sam's Club", "O.U.i Paris", "C&A"):
        parceiro = um(monta_html("2 pontos por R$ 1", nome=nome))
        assert parceiro.nome == nome


def teste_link_sem_card_e_ignorado():
    """PRD 6.4: estrutura inesperada nao derruba a extracao."""
    html = '<a data-testid="a_PartnerCard_card_link" href="/x">sem card dentro</a>'
    assert extrair_parceiros(html) == []


def teste_card_sem_nome_e_descartado():
    html = """
    <a data-testid="a_PartnerCard_card_link" href="/x">
      <div data-testid="div_PartnerCard">
        <img data-testid="img_PartnerCard_partnerImage" alt=""/>
      </div>
    </a>
    """
    assert extrair_parceiros(html) == []


def teste_parceiro_sem_pontuacao_legivel_e_descartado():
    """Descarta so aquele card, os outros seguem (PRD 6.4)."""
    bom = CARD.format(
        link="https://www.livelo.com.br/x",
        tag="",
        alt='alt="Logo Natura"',
        texto="4 pontos por R$ 1",
    )
    html = monta_html("texto sem pontuacao nenhuma", nome="Loja Quebrada", extra=bom)
    parceiros = extrair_parceiros(html)
    assert [p.nome for p in parceiros] == ["Natura"]


def teste_valor_fracionado_vira_decimal():
    parceiro = um(monta_html("2,9 pontos por R$ 1"))
    assert parceiro.pontos_atuais == Decimal("2.9")


def teste_fixture_real_traz_os_casos_dificeis(html_exemplo):
    """A fixture e a pagina de verdade, nao HTML inventado."""
    por_nome = {p.nome: p for p in extrair_parceiros(html_exemplo)}

    assert len(por_nome) == 20
    assert por_nome["Casas Bahia"].prefixo_ate is True
    assert por_nome["Booking com"].moeda == "U$"
    assert por_nome["Beleza na web"].pontos_clube == Decimal("12")
    assert por_nome["Consórcio Magalu"].em_promocao is True
    assert por_nome["Petlove"].em_promocao is False
    assert por_nome["Petlove Saúde"].em_promocao is True
