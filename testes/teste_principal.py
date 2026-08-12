"""CT-024, CT-040 a CT-046, CT-069 a CT-073 e CT-102 — orquestracao com fakes."""

from __future__ import annotations

import logging
from datetime import datetime
from decimal import Decimal

import pytest

from robo_livelo.adaptadores import (
    CatalogoArquivo,
    CatalogoComReserva,
    NotificadorEmail,
    PreferenciasComReserva,
    PreferenciasPadrao,
    RepositorioNulo,
    RepositorioPostgres,
)
from robo_livelo.modelos import Preferencias
from robo_livelo.montador_email import ASSUNTO_SEM_PROMOCAO
from robo_livelo.portas import (
    FalhaAoGuardar,
    FalhaAoNotificar,
    FalhaAoObterPagina,
    SiteMudou,
)
from robo_livelo.principal import (
    montar_catalogo,
    montar_preferencias,
    montar_repositorio,
    validar_segredos,
    verificar_promocoes,
)
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
    """(nome, pontos, promo) -> payload JSON embrulhado em HTML (RF14).

    Desde a V2.2 quem decide o alerta e RN27, nao a etiqueta da Livelo:
    `promo=True` monta o item com base 1, para a pontuacao de fato cruzar
    o limiar (2x a base e piso 4). `promo=False` deixa base igual a
    pontuacao atual — parceiro parado, que e o que a etiqueta ausente
    costuma significar.
    """
    itens = [
        monta_item_parceiro(
            nome=nome,
            parity=pontos,
            parity_bau="1" if promo else None,
            promotion=promo,
        )
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
    item_bom = monta_item_parceiro(nome="Natura", parity="4", parity_bau="1", promotion=True)

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
        parity_bau="1",
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


def teste_ct114_sem_database_url_o_catalogo_vem_do_arquivo(tmp_path):
    """Quem clona o projeto e roda na propria maquina nao tem Neon."""
    catalogo = montar_catalogo({}, tmp_path / "lojas.toml")
    assert isinstance(catalogo, CatalogoArquivo)


def teste_ct115_com_database_url_o_banco_manda_e_o_arquivo_fica_de_reserva(tmp_path):
    catalogo = montar_catalogo({"DATABASE_URL": "postgresql://fake"}, tmp_path / "lojas.toml")
    assert isinstance(catalogo, CatalogoComReserva)


def teste_ct116_database_url_em_branco_conta_como_ausente(tmp_path):
    """Secret nao configurado no Actions chega como string vazia, nao ausente."""
    catalogo = montar_catalogo({"DATABASE_URL": "   "}, tmp_path / "lojas.toml")
    assert isinstance(catalogo, CatalogoArquivo)


def teste_ct134_sem_database_url_as_preferencias_sao_os_padroes():
    assert isinstance(montar_preferencias({}), PreferenciasPadrao)


def teste_ct135_com_database_url_as_preferencias_vem_do_banco_com_reserva():
    assert isinstance(
        montar_preferencias({"DATABASE_URL": "postgresql://fake"}), PreferenciasComReserva
    )


def teste_ct136_alerta_manda_no_email_nao_a_etiqueta(favoritas):
    """RN27 fim a fim: a Livelo etiqueta um e esquece o outro, e o e-mail
    sai com o que realmente subiu."""
    etiquetado_sem_aumento = monta_item_parceiro(
        nome="O Boticario", parity="3", parity_bau="3", promotion=True
    )
    aumento_sem_etiqueta = monta_item_parceiro(
        nome="Natura", parity="6", parity_bau="2", promotion=False
    )
    html = monta_html_payload(etiquetado_sem_aumento, aumento_sem_etiqueta)

    total, notificador, _ = executa(html, favoritas)

    assert total == 1
    corpo = notificador.enviadas[0].corpo_html
    assert "Natura" in corpo
    assert "Boticário" not in corpo and "Boticario" not in corpo


def teste_ct137_preferencias_do_banco_mudam_o_resultado(favoritas):
    """RN28 fim a fim: a mesma pagina com reguas diferentes."""

    class PreferenciasFake:
        def __init__(self, preferencias):
            self._preferencias = preferencias

        def carregar(self):
            return self._preferencias

    html = pagina(("Natura", "4", True))  # base 1: dispara com 2,0x e piso 4

    def roda(preferencias):
        notificador = NotificadorFake()
        return verificar_promocoes(
            fonte=FonteFake(html),
            catalogo=CatalogoFake(favoritas),
            notificador=notificador,
            limiar=1,
            agora=AGORA_TESTE,
            preferencias=PreferenciasFake(preferencias),
        )

    assert roda(Preferencias()) == 1
    assert roda(Preferencias(piso_pontos_padrao=Decimal("10"))) == 0
    assert roda(Preferencias(multiplicador_padrao=Decimal("9"))) == 0


def teste_ct138_suspeita_de_rn29_vai_para_o_log(favoritas, caplog):
    """RN29: silencio com a pagina inteira parada e suspeita, nao dia fraco."""
    itens = [
        monta_item_parceiro(nome=nome, parity="3", parity_bau="3", promotion=True)
        for nome in ("Natura", "O Boticario", "Magalu")
    ]
    with caplog.at_level(logging.WARNING, logger="robo_livelo"):
        total, _, _ = executa(monta_html_payload(*itens), favoritas)

    assert total == 0
    assert any("RN29" in r.getMessage() for r in caplog.records)


def teste_ct147_sem_database_url_nao_ha_onde_guardar():
    assert isinstance(montar_repositorio({}), RepositorioNulo)


def teste_ct148_com_database_url_o_retrato_vai_para_o_banco():
    assert isinstance(
        montar_repositorio({"DATABASE_URL": "postgresql://fake"}), RepositorioPostgres
    )


def teste_ct149_retrato_registrado_apos_o_email(favoritas):
    """RF15 fim a fim: o site recebe todas as favoritas, nao so as alertadas."""

    class RepositorioFake:
        def __init__(self):
            self.retratos = []

        def registrar(self, retrato):
            self.retratos.append(retrato)

    repositorio = RepositorioFake()
    notificador = NotificadorFake()
    html = pagina(("Natura", "4", True), ("Magalu", "3", False))

    verificar_promocoes(
        fonte=FonteFake(html),
        catalogo=CatalogoFake(favoritas),
        notificador=notificador,
        limiar=1,
        agora=AGORA_TESTE,
        repositorio=repositorio,
    )

    (retrato,) = repositorio.retratos
    assert notificador.foi_chamado
    assert len(retrato.pontuacoes) == len(favoritas)  # RN24
    assert retrato.alertas == 1
    assert retrato.parceiros_lidos == 2


def teste_ct150_falha_ao_guardar_nao_derruba_a_execucao(favoritas, caplog):
    """A consequencia de nao gravar e o site velho, e o carimbo de RN26
    denuncia isso sozinho. Perder o e-mail do dia seria pior."""

    class RepositorioFalho:
        def registrar(self, retrato):
            raise FalhaAoGuardar("banco inacessivel")

    notificador = NotificadorFake()
    with caplog.at_level(logging.WARNING, logger="robo_livelo"):
        total = verificar_promocoes(
            fonte=FonteFake(pagina(("Natura", "4", True))),
            catalogo=CatalogoFake(favoritas),
            notificador=notificador,
            limiar=1,
            agora=AGORA_TESTE,
            repositorio=RepositorioFalho(),
        )

    assert total == 1
    assert notificador.foi_chamado
    assert any("banco inacessivel" in r.getMessage() for r in caplog.records)


def teste_ct163_catalogo_vazio_avisa_no_email_e_no_log(caplog):
    """Fim a fim: banco sem loja nenhuma nao vira 'dia sem promocao'."""
    from robo_livelo.montador_email import ASSUNTO_SEM_CATALOGO

    notificador = NotificadorFake()
    with caplog.at_level(logging.WARNING, logger="robo_livelo"):
        total = verificar_promocoes(
            fonte=FonteFake(pagina(("Natura", "4", True))),
            catalogo=CatalogoFake([]),
            notificador=notificador,
            limiar=1,
            agora=AGORA_TESTE,
        )

    assert total == 0
    assert notificador.enviadas[0].assunto == ASSUNTO_SEM_CATALOGO
    assert any("Nenhuma loja cadastrada" in r.getMessage() for r in caplog.records)
