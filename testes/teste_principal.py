"""CT-024, CT-040 a CT-046, CT-069 a CT-073 e CT-102 — orquestracao com fakes."""

from __future__ import annotations

import logging
from datetime import datetime

import pytest

from robo_livelo.adaptadores import NotificadorEmail
from robo_livelo.montador_email import ASSUNTO_SEM_PROMOCAO
from robo_livelo.portas import FalhaAoNotificar, FalhaAoObterPagina, SiteMudou
from robo_livelo.principal import validar_segredos, verificar_promocoes
from testes.conftest import (
    FUSO_BRASILIA,
    CatalogoFake,
    FonteFake,
    NotificadorFake,
    formatar_data_livelo,
    monta_html_payload,
    monta_item_parceiro,
)

AGORA_TESTE = datetime(2026, 8, 11, 10, 0, tzinfo=FUSO_BRASILIA)


def pagina(*lojas: tuple[str, str, bool]) -> str:
    """(nome, pontos, promo) -> payload JSON embrulhado em HTML (RF14)."""
    itens = [
        monta_item_parceiro(nome=nome, parity=pontos, promotion=promo)
        for nome, pontos, promo in lojas
    ]
    return monta_html_payload(*itens)


def executa(
    html: str,
    favoritas,
    *,
    limiar: int = 1,
    notificador=None,
    agora: datetime = AGORA_TESTE,
):
    notificador = notificador or NotificadorFake()
    fonte = FonteFake(html)
    total = verificar_promocoes(
        fonte=fonte,
        catalogo=CatalogoFake(favoritas),
        notificador=notificador,
        limiar=limiar,
        agora=agora,
    )
    return total, notificador, fonte


def teste_ct024_alerta_de_quebra(favoritas):
    """RN13: parceiros de menos encerra com falha. Veio do teste_extrator."""
    html = pagina(("Natura", "4", True))
    with pytest.raises(SiteMudou, match="abaixo do limiar"):
        executa(html, favoritas, limiar=150)


def teste_ct040_filtra_loja_fora_do_catalogo(favoritas):
    html = pagina(("Natura", "4", True), ("Loja Aleatoria", "9", True))
    total, notificador, _ = executa(html, favoritas)
    assert total == 1
    assert "Loja Aleatoria" not in notificador.enviadas[0].corpo_html


def teste_ct041_filtra_loja_sem_promocao(favoritas):
    html = pagina(("Natura", "4", True), ("Magalu", "3", False))
    total, notificador, _ = executa(html, favoritas)
    assert total == 1
    assert "Magalu" not in notificador.enviadas[0].corpo_html


def teste_ct042_agrupamento_por_categoria(favoritas):
    html = pagina(("Natura", "4", True), ("O Boticario", "6", True))
    total, notificador, _ = executa(html, favoritas)
    assert total == 2
    assert notificador.enviadas[0].corpo_html.count("Beleza") == 1


def teste_ct043_sem_promocoes_envia_mesmo_assim(favoritas):
    """RF10: substitui os antigos CT-043 e CT-044 do SEMPRE_ENVIAR."""
    html = pagina(("Natura", "3", False))
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
    html = pagina(("Natura", "4", True))
    with caplog.at_level(logging.WARNING):
        _, notificador, _ = executa(html, favoritas)

    assert "Magalu" in caplog.text
    assert "Magalu" not in notificador.enviadas[0].corpo_html


def teste_ct071_parceiro_malformado_nao_derruba(favoritas):
    """PRD 6.4: descarta so aquele parceiro e segue."""
    item_quebrado = monta_item_parceiro(nome="Loja Quebrada", promotion=True)
    item_quebrado["parity"]["parity"] = "sem pontuacao legivel"
    item_bom = monta_item_parceiro(nome="Natura", parity="4", promotion=True)

    html = monta_html_payload(item_quebrado, item_bom)
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
    html = pagina(("Natura", "4", True))
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


def teste_ct102_mesmo_agora_chega_ao_extrator_e_ao_email(favoritas):
    """Fim a fim: uma promocao que termina hoje aparece destacada no e-mail."""
    fim_hoje = AGORA_TESTE.replace(hour=23, minute=59)
    item = monta_item_parceiro(
        nome="Natura",
        parity="4",
        promotion=True,
        date_start="2026-08-09-00:00:00 GMT-03:00",
        date_end=formatar_data_livelo(fim_hoje),
    )
    html = monta_html_payload(item)
    _, notificador, _ = executa(html, favoritas, agora=AGORA_TESTE)

    assert "Termina hoje!" in notificador.enviadas[0].corpo_html


def teste_rn21_promocao_expirada_nao_entra_no_email_fim_a_fim(favoritas):
    """RN21 fim a fim: dateEnd no passado nao conta como promocao."""
    item = monta_item_parceiro(
        nome="Natura",
        parity="4",
        promotion=True,
        date_start="2026-08-01-00:00:00 GMT-03:00",
        date_end="2026-08-05-23:59:00 GMT-03:00",  # antes de AGORA_TESTE
    )
    html = monta_html_payload(item)
    total, notificador, _ = executa(html, favoritas, agora=AGORA_TESTE)

    assert total == 0
    assert "Natura" not in notificador.enviadas[0].corpo_html
