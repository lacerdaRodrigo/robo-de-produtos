"""CT-030 a CT-038 e CT-064 a CT-068 — montagem do e-mail."""

from __future__ import annotations

from decimal import Decimal

from robo_livelo.montador_email import (
    ASSUNTO_SEM_PROMOCAO,
    formatar_pontos,
    link_confiavel,
    montar,
)
from testes.conftest import faz_parceiro


def teste_ct030_uma_categoria_uma_loja():
    mensagem = montar({"Beleza": [faz_parceiro("Natura", "5")]})
    assert "Natura" in mensagem.corpo_html
    assert "Beleza" in mensagem.corpo_html


def teste_ct031_varias_categorias_e_lojas():
    agrupamento = {
        "Beleza": [faz_parceiro("Natura", "5"), faz_parceiro("Avon", "4")],
        "Moda": [faz_parceiro("Renner", "3"), faz_parceiro("Nike", "2")],
        "Pet": [faz_parceiro("Petz", "6"), faz_parceiro("Petlove", "5")],
    }
    mensagem = montar(agrupamento)
    for lojas in agrupamento.values():
        for parceiro in lojas:
            assert parceiro.nome in mensagem.corpo_html
            assert parceiro.nome in mensagem.corpo_texto


def teste_ct032_ordenacao_por_pontos_preservada():
    html = montar({"Beleza": [faz_parceiro("Natura", "9"), faz_parceiro("Avon", "1")]}).corpo_html
    assert html.index("Natura") < html.index("Avon")


def teste_ct033_loja_sem_tier_clube():
    mensagem = montar({"Beleza": [faz_parceiro("Natura", "5", clube=None)]})
    assert "Clube" not in mensagem.corpo_html


def teste_ct034_loja_com_tier_clube():
    mensagem = montar({"Beleza": [faz_parceiro("Natura", "5", clube="12")]})
    assert "Clube: 12 pontos" in mensagem.corpo_html


def teste_ct035_assunto_reflete_o_total():
    agrupamento = {"Beleza": [faz_parceiro(f"Loja {i}", "3") for i in range(5)]}
    assert "5" in montar(agrupamento).assunto


def teste_ct036_categorias_na_ordem_recebida():
    html = montar(
        {"Beleza": [faz_parceiro("Natura", "5")], "Moda": [faz_parceiro("Renner", "4")]}
    ).corpo_html
    assert html.index("Beleza") < html.index("Moda")


def teste_ct037_sem_promocoes_gera_email_com_assunto_proprio():
    """RF10: o e-mail sai mesmo vazio, e o assunto diz isso."""
    mensagem = montar({})
    assert mensagem.assunto == ASSUNTO_SEM_PROMOCAO
    assert mensagem.corpo_html
    assert "Nenhuma" in mensagem.corpo_texto


def teste_ct038_texto_simples_bate_com_html():
    agrupamento = {"Beleza": [faz_parceiro("Natura", "5"), faz_parceiro("Avon", "3")]}
    mensagem = montar(agrupamento)
    for nome in ("Natura", "Avon"):
        assert nome in mensagem.corpo_html
        assert nome in mensagem.corpo_texto


def teste_ct064_escape_de_texto_hostil():
    """RN07: nome vindo do site nao pode injetar markup."""
    parceiro = faz_parceiro('<b>Loja</b> & "X"', "5")
    html = montar({"Beleza": [parceiro]}).corpo_html
    assert "<b>Loja</b>" not in html
    assert "&lt;b&gt;Loja&lt;/b&gt;" in html
    assert "&amp;" in html


def teste_ct065_link_fora_do_dominio_da_livelo():
    """PRD 9.2: link arbitrario nao entra no e-mail."""
    hostil = faz_parceiro("Natura", "5", link="https://site-malicioso.example/phishing")
    html = montar({"Beleza": [hostil]}).corpo_html
    assert "site-malicioso.example" not in html
    assert "Ver oferta" not in html

    assert link_confiavel("https://www.livelo.com.br/juntar-pontos/parceiros/natura/NAT")
    assert link_confiavel("https://livelo.com.br/x")
    assert not link_confiavel("https://livelo.com.br.evil.example/x")
    assert not link_confiavel("javascript:alert(1)")
    assert not link_confiavel("")


def teste_ct066_categoria_vazia_nao_aparece():
    """RN14."""
    html = montar({"Beleza": [faz_parceiro("Natura", "5")], "Moda": []}).corpo_html
    assert "Moda" not in html


def teste_ct067_pontuacao_fracionada_sem_lixo_de_float():
    """PRD 5.4: Decimal evita 2.9000000000000004."""
    html = montar({"Beleza": [faz_parceiro("Natura", "2.9")]}).corpo_html
    assert "2,9 pontos" in html
    assert "2.9000" not in html
    assert formatar_pontos(Decimal("3.00")) == "3"


def teste_ct068_prefixo_ate_preservado():
    """RN12."""
    html = montar({"Beleza": [faz_parceiro("Natura", "5", prefixo_ate=True)]}).corpo_html
    assert "Até 5 pontos" in html


def teste_pior_caso_cabe_no_limite_do_gmail():
    """C05: acima de ~102 KB o Gmail corta a exibicao e esconde o resto.

    Guarda automatica contra o crescimento do catalogo. O cenario e
    impossivel na pratica — todas as favoritas em promocao no mesmo dia,
    todas com Clube — mas e ele que define o teto. Se este teste falhar,
    o catalogo cresceu demais e o e-mail precisa encolher antes.
    """
    from robo_livelo.adaptadores import CatalogoArquivo

    limite_do_gmail = 102 * 1024
    favoritas = CatalogoArquivo("config/lojas_favoritas.toml").listar()

    agrupamento: dict[str, list] = {}
    for loja in favoritas:
        agrupamento.setdefault(loja.categoria, []).append(
            faz_parceiro(loja.nome, "84", clube="120", prefixo_ate=True)
        )

    tamanho = len(montar(agrupamento).corpo_html)
    assert tamanho < limite_do_gmail, (
        f"O pior caso ocupa {tamanho} bytes, acima do corte do Gmail. "
        "Reduza o catalogo ou enxugue o HTML do e-mail."
    )


def teste_moeda_em_dolar_nao_e_convertida():
    """RN11."""
    html = montar({"Viagem": [faz_parceiro("Booking com", "4", moeda="U$")]}).corpo_html
    assert "U$ 1" in html
