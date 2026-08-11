"""CT-030 a CT-038, CT-064 a CT-068 e CT-096 a CT-101 — montagem do e-mail."""

from __future__ import annotations

from datetime import datetime, timedelta
from decimal import Decimal

from robo_livelo.montador_email import (
    ASSUNTO_SEM_PROMOCAO,
    formatar_pontos,
    link_confiavel,
    montar,
)
from testes.conftest import FUSO_BRASILIA, faz_parceiro

AGORA_TESTE = datetime(2026, 8, 11, 12, 0, tzinfo=FUSO_BRASILIA)


def teste_ct030_uma_categoria_uma_loja():
    mensagem = montar({"Beleza": [faz_parceiro("Natura", "5")]}, agora=AGORA_TESTE)
    assert "Natura" in mensagem.corpo_html
    assert "Beleza" in mensagem.corpo_html


def teste_ct031_varias_categorias_e_lojas():
    agrupamento = {
        "Beleza": [faz_parceiro("Natura", "5"), faz_parceiro("Avon", "4")],
        "Moda": [faz_parceiro("Renner", "3"), faz_parceiro("Nike", "2")],
        "Pet": [faz_parceiro("Petz", "6"), faz_parceiro("Petlove", "5")],
    }
    mensagem = montar(agrupamento, agora=AGORA_TESTE)
    for lojas in agrupamento.values():
        for parceiro in lojas:
            assert parceiro.nome in mensagem.corpo_html
            assert parceiro.nome in mensagem.corpo_texto


def teste_ct032_ordenacao_por_pontos_preservada():
    agrupamento = {"Beleza": [faz_parceiro("Natura", "9"), faz_parceiro("Avon", "1")]}
    html = montar(agrupamento, agora=AGORA_TESTE).corpo_html
    assert html.index("Natura") < html.index("Avon")


def teste_ct033_loja_sem_tier_clube():
    mensagem = montar({"Beleza": [faz_parceiro("Natura", "5", clube=None)]}, agora=AGORA_TESTE)
    assert "Clube" not in mensagem.corpo_html


def teste_ct034_loja_com_tier_clube():
    mensagem = montar({"Beleza": [faz_parceiro("Natura", "5", clube="12")]}, agora=AGORA_TESTE)
    assert "Clube: 12 pontos" in mensagem.corpo_html


def teste_ct035_assunto_reflete_o_total():
    agrupamento = {"Beleza": [faz_parceiro(f"Loja {i}", "3") for i in range(5)]}
    assert "5" in montar(agrupamento, agora=AGORA_TESTE).assunto


def teste_ct036_categorias_na_ordem_recebida():
    agrupamento = {"Beleza": [faz_parceiro("Natura", "5")], "Moda": [faz_parceiro("Renner", "4")]}
    html = montar(agrupamento, agora=AGORA_TESTE).corpo_html
    assert html.index("Beleza") < html.index("Moda")


def teste_ct037_sem_promocoes_gera_email_com_assunto_proprio():
    """RF10: o e-mail sai mesmo vazio, e o assunto diz isso."""
    mensagem = montar({}, agora=AGORA_TESTE)
    assert mensagem.assunto == ASSUNTO_SEM_PROMOCAO
    assert mensagem.corpo_html
    assert "Nenhuma" in mensagem.corpo_texto


def teste_ct038_texto_simples_bate_com_html():
    agrupamento = {"Beleza": [faz_parceiro("Natura", "5"), faz_parceiro("Avon", "3")]}
    mensagem = montar(agrupamento, agora=AGORA_TESTE)
    for nome in ("Natura", "Avon"):
        assert nome in mensagem.corpo_html
        assert nome in mensagem.corpo_texto


def teste_ct064_escape_de_texto_hostil():
    """RN07: nome vindo do site nao pode injetar markup."""
    parceiro = faz_parceiro('<b>Loja</b> & "X"', "5")
    html = montar({"Beleza": [parceiro]}, agora=AGORA_TESTE).corpo_html
    assert "<b>Loja</b>" not in html
    assert "&lt;b&gt;Loja&lt;/b&gt;" in html
    assert "&amp;" in html


def teste_ct065_link_fora_do_dominio_da_livelo():
    """PRD 9.2: link arbitrario nao entra no e-mail."""
    hostil = faz_parceiro("Natura", "5", link="https://site-malicioso.example/phishing")
    html = montar({"Beleza": [hostil]}, agora=AGORA_TESTE).corpo_html
    assert "site-malicioso.example" not in html
    assert "Ver oferta" not in html

    assert link_confiavel("https://www.livelo.com.br/juntar-pontos/parceiros/natura/NAT")
    assert link_confiavel("https://livelo.com.br/x")
    assert not link_confiavel("https://livelo.com.br.evil.example/x")
    assert not link_confiavel("javascript:alert(1)")
    assert not link_confiavel("")


def teste_ct066_categoria_vazia_nao_aparece():
    """RN14."""
    agrupamento = {"Beleza": [faz_parceiro("Natura", "5")], "Moda": []}
    html = montar(agrupamento, agora=AGORA_TESTE).corpo_html
    assert "Moda" not in html


def teste_ct067_pontuacao_fracionada_sem_lixo_de_float():
    """PRD 5.4: Decimal evita 2.9000000000000004."""
    html = montar({"Beleza": [faz_parceiro("Natura", "2.9")]}, agora=AGORA_TESTE).corpo_html
    assert "2,9 pontos" in html
    assert "2.9000" not in html
    assert formatar_pontos(Decimal("3.00")) == "3"


def teste_ct068_prefixo_ate_preservado():
    """RN12."""
    html = montar(
        {"Beleza": [faz_parceiro("Natura", "5", prefixo_ate=True)]}, agora=AGORA_TESTE
    ).corpo_html
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
            faz_parceiro(
                loja.nome,
                "84",
                clube="120",
                prefixo_ate=True,
                base="80",
                fim=AGORA_TESTE + timedelta(days=3),
            )
        )

    tamanho = len(montar(agrupamento, agora=AGORA_TESTE).corpo_html)
    assert tamanho < limite_do_gmail, (
        f"O pior caso ocupa {tamanho} bytes, acima do corte do Gmail. "
        "Reduza o catalogo ou enxugue o HTML do e-mail."
    )


def teste_moeda_em_dolar_nao_e_convertida():
    """RN11."""
    html = montar(
        {"Viagem": [faz_parceiro("Booking com", "4", moeda="U$")]}, agora=AGORA_TESTE
    ).corpo_html
    assert "U$ 1" in html


def teste_versao_aparece_no_rodape():
    """Saber qual versao gerou o e-mail e o que torna um defeito rastreavel."""
    from robo_livelo import __version__

    mensagem = montar({"Beleza": [faz_parceiro("Natura", "5")]}, agora=AGORA_TESTE)
    assert __version__ in mensagem.corpo_html
    assert __version__ in mensagem.corpo_texto


# ── CT-096 em diante: validade (RF18/RN22) e marcacao Clube (RN23) ──────────


def teste_ct096_termina_hoje_recebe_destaque():
    fim_hoje = AGORA_TESTE.replace(hour=23, minute=59)
    parceiro = faz_parceiro("Natura", "5", fim=fim_hoje)
    mensagem = montar({"Beleza": [parceiro]}, agora=AGORA_TESTE)
    assert "Termina hoje!" in mensagem.corpo_html
    assert "Termina hoje!" in mensagem.corpo_texto


def teste_ct097_validade_futura_mostra_data():
    fim_futuro = AGORA_TESTE + timedelta(days=5)
    parceiro = faz_parceiro("Natura", "5", fim=fim_futuro)
    mensagem = montar({"Beleza": [parceiro]}, agora=AGORA_TESTE)
    assert f"Válido até {fim_futuro:%d/%m}" in mensagem.corpo_html
    assert "Termina hoje!" not in mensagem.corpo_html


def teste_ct098_sem_fim_promocao_sem_texto_de_validade():
    parceiro = faz_parceiro("Natura", "5", fim=None)
    mensagem = montar({"Beleza": [parceiro]}, agora=AGORA_TESTE)
    assert "Válido até" not in mensagem.corpo_html
    assert "Termina hoje!" not in mensagem.corpo_html


def teste_ct099_marca_exclusivo_clube_quando_base_parada():
    """RN23: o exemplo real do PRD-V2 — base 3->3, boost so no Clube."""
    parceiro = faz_parceiro("O Boticário", "3", base="3", clube="10")
    mensagem = montar({"Beleza": [parceiro]}, agora=AGORA_TESTE)
    assert "exclusivo assinantes Clube" in mensagem.corpo_html
    assert "exclusivo assinantes Clube" in mensagem.corpo_texto


def teste_ct100_base_tambem_turbinada_nao_marca_exclusivo():
    """RN23: a base tambem se moveu — e bonus geral, nao so do Clube."""
    parceiro = faz_parceiro("Natura", "6", base="4", clube="10")
    mensagem = montar({"Beleza": [parceiro]}, agora=AGORA_TESTE)
    assert "exclusivo assinantes Clube" not in mensagem.corpo_html
    assert "Clube: 10 pontos" in mensagem.corpo_html


def teste_ct101_sem_pontos_clube_sem_marcacao():
    """Regressao de CT-033: sem pontos_clube, nenhuma marcacao aparece."""
    parceiro = faz_parceiro("Natura", "5", clube=None, base="5")
    mensagem = montar({"Beleza": [parceiro]}, agora=AGORA_TESTE)
    assert "Clube" not in mensagem.corpo_html
