"""CT-024, CT-040 a CT-046 e CT-069 a CT-073 — orquestracao com fakes."""

from __future__ import annotations

import logging

import pytest

from robo_livelo.adaptadores import NotificadorEmail
from robo_livelo.montador_email import ASSUNTO_SEM_PROMOCAO
from robo_livelo.portas import FalhaAoNotificar, FalhaAoObterPagina, SiteMudou
from robo_livelo.principal import validar_segredos, verificar_promocoes
from testes.conftest import CatalogoFake, FonteFake, NotificadorFake

CARD = """
<a data-testid="a_PartnerCard_card_link" href="{link}">
  <div data-testid="div_PartnerCard">
    {tag}
    <img data-testid="img_PartnerCard_partnerImage" alt="Logo {nome}"/>
    <div>{texto}</div>
  </div>
</a>
"""


def pagina(*lojas: tuple[str, str, bool]) -> str:
    cards = "".join(
        CARD.format(
            link=f"https://www.livelo.com.br/juntar-pontos/parceiros/{nome.lower()}/XXX",
            tag='<span data-testid="span_PartnerCard_promotionTag">Promoção</span>'
            if promo
            else "",
            nome=nome,
            texto=texto,
        )
        for nome, texto, promo in lojas
    )
    return f"<html><body>{cards}</body></html>"


def executa(html: str, favoritas, *, limiar: int = 1, notificador=None):
    notificador = notificador or NotificadorFake()
    fonte = FonteFake(html)
    total = verificar_promocoes(
        fonte=fonte,
        catalogo=CatalogoFake(favoritas),
        notificador=notificador,
        limiar=limiar,
    )
    return total, notificador, fonte


def teste_ct024_alerta_de_quebra(favoritas):
    """RN13: parceiros de menos encerra com falha. Veio do teste_extrator."""
    html = pagina(("Natura", "Promoção 4 pontos por R$ 1 Eram 2 pontos", True))
    with pytest.raises(SiteMudou, match="abaixo do limiar"):
        executa(html, favoritas, limiar=150)


def teste_ct040_filtra_loja_fora_do_catalogo(favoritas):
    html = pagina(
        ("Natura", "Promoção 4 pontos por R$ 1 Eram 2 pontos", True),
        ("Loja Aleatoria", "Promoção 9 pontos por R$ 1 Eram 1 ponto", True),
    )
    total, notificador, _ = executa(html, favoritas)
    assert total == 1
    assert "Loja Aleatoria" not in notificador.enviadas[0].corpo_html


def teste_ct041_filtra_loja_sem_promocao(favoritas):
    html = pagina(
        ("Natura", "Promoção 4 pontos por R$ 1 Eram 2 pontos", True),
        ("Magalu", "3 pontos por R$ 1", False),
    )
    total, notificador, _ = executa(html, favoritas)
    assert total == 1
    assert "Magalu" not in notificador.enviadas[0].corpo_html


def teste_ct042_agrupamento_por_categoria(favoritas):
    html = pagina(
        ("Natura", "Promoção 4 pontos por R$ 1 Eram 2 pontos", True),
        ("O Boticario", "Promoção 6 pontos por R$ 1 Eram 3 pontos", True),
    )
    total, notificador, _ = executa(html, favoritas)
    assert total == 2
    assert notificador.enviadas[0].corpo_html.count("Beleza") == 1


def teste_ct043_sem_promocoes_envia_mesmo_assim(favoritas):
    """RF10: substitui os antigos CT-043 e CT-044 do SEMPRE_ENVIAR."""
    html = pagina(("Natura", "3 pontos por R$ 1", False))
    total, notificador, _ = executa(html, favoritas)
    assert total == 0
    assert notificador.foi_chamado
    assert notificador.enviadas[0].assunto == ASSUNTO_SEM_PROMOCAO


def teste_ct045_credenciais_corretas_no_envio():
    class SmtpFake:
        def __init__(self, servidor, porta):
            self.servidor, self.porta = servidor, porta
            self.login_com = None
            self.mensagem = None

        def __enter__(self):
            SmtpFake.ultimo = self
            return self

        def __exit__(self, *_):
            return False

        def login(self, usuario, senha):
            self.login_com = (usuario, senha)

        def send_message(self, email):
            self.mensagem = email

    from robo_livelo.modelos import Mensagem

    NotificadorEmail(
        remetente="eu@gmail.com",
        senha="senha-de-app",
        destino="eu@gmail.com",
        conexao=SmtpFake,
    ).enviar(Mensagem(assunto="a", corpo_html="<p>a</p>", corpo_texto="a"))

    assert SmtpFake.ultimo.login_com == ("eu@gmail.com", "senha-de-app")
    assert SmtpFake.ultimo.mensagem["Subject"] == "a"


def teste_ct046_falha_de_login_no_gmail():
    import smtplib

    class SmtpRecusa:
        def __init__(self, *_a):
            pass

        def __enter__(self):
            return self

        def __exit__(self, *_):
            return False

        def login(self, *_a):
            raise smtplib.SMTPAuthenticationError(535, b"5.7.8 senha-secreta rejeitada")

        def send_message(self, _):
            pass

    from robo_livelo.modelos import Mensagem

    notificador = NotificadorEmail("eu@gmail.com", "segredo", "eu@gmail.com", conexao=SmtpRecusa)
    with pytest.raises(FalhaAoNotificar) as erro:
        notificador.enviar(Mensagem(assunto="a", corpo_html="a", corpo_texto="a"))

    assert "Senha de Aplicativo" in str(erro.value)
    assert "senha-secreta" not in str(erro.value)


def teste_ct069_segredo_faltando_falha_antes_da_rede():
    """PRD 7.3: nao gasta requisicao para descobrir que falta segredo."""
    with pytest.raises(SystemExit, match="SENHA_APP_GMAIL"):
        validar_segredos({"EMAIL_REMETENTE": "a@b.com", "EMAIL_DESTINO": "a@b.com"})

    validar_segredos(
        {"EMAIL_REMETENTE": "a@b.com", "SENHA_APP_GMAIL": "x", "EMAIL_DESTINO": "a@b.com"}
    )


def teste_ct070_favoritas_ausentes_vao_pro_log(favoritas, caplog):
    """RN19: no log, nunca no e-mail."""
    html = pagina(("Natura", "Promoção 4 pontos por R$ 1 Eram 2 pontos", True))
    with caplog.at_level(logging.WARNING):
        _, notificador, _ = executa(html, favoritas)

    assert "Magalu" in caplog.text
    assert "Magalu" not in notificador.enviadas[0].corpo_html


def teste_ct071_parceiro_malformado_nao_derruba(favoritas):
    """PRD 6.4: descarta so aquele parceiro e segue."""
    html = pagina(
        ("Natura", "Promoção 4 pontos por R$ 1 Eram 2 pontos", True),
        ("Loja Quebrada", "sem pontuacao legivel aqui", True),
    )
    total, notificador, _ = executa(html, favoritas)
    assert total == 1
    assert notificador.foi_chamado


def teste_ct072_destinatario_unico():
    """RN17 e RN18: sem CC, sem BCC."""

    class SmtpFake:
        def __init__(self, *_a):
            pass

        def __enter__(self):
            SmtpFake.ultimo = self
            return self

        def __exit__(self, *_):
            return False

        def login(self, *_a):
            pass

        def send_message(self, email):
            self.email = email

    from robo_livelo.modelos import Mensagem

    NotificadorEmail("eu@gmail.com", "x", "eu@gmail.com", conexao=SmtpFake).enviar(
        Mensagem(assunto="a", corpo_html="a", corpo_texto="a")
    )
    email = SmtpFake.ultimo.email
    assert email["To"] == "eu@gmail.com"
    assert email["Cc"] is None
    assert email["Bcc"] is None


def teste_ct073_nenhum_segredo_no_log(favoritas, caplog):
    """RNF05: o log do GitHub Actions e publico."""
    html = pagina(("Natura", "Promoção 4 pontos por R$ 1 Eram 2 pontos", True))
    with caplog.at_level(logging.DEBUG):
        executa(html, favoritas)

    for segredo in ("senha-de-app", "eu@gmail.com", "SENHA_APP_GMAIL"):
        assert segredo not in caplog.text


def teste_falha_de_rede_sobe_como_erro(favoritas):
    """RNF06: falha ruidosa, nunca silenciosa."""
    with pytest.raises(FalhaAoObterPagina):
        verificar_promocoes(
            fonte=FonteFake(erro=FalhaAoObterPagina("sem rede")),
            catalogo=CatalogoFake(favoritas),
            notificador=NotificadorFake(),
        )
