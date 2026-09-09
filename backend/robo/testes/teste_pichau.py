from __future__ import annotations

import json
import sys
from datetime import UTC, datetime
from decimal import Decimal
from pathlib import Path
from types import SimpleNamespace

import pytest

import robo_pichau.adaptadores as modulo_adaptadores
from robo_pichau.adaptadores import (
    FontePichauAndroid,
    FontePichauHttp,
    FontePichauSeleniumBase,
    RepositorioPichauPostgres,
    robots_permite,
    url_para_log,
)
from robo_pichau.extrator import (
    decimal_brasileiro,
    extrair_detalhe_produto,
    extrair_pagina,
    id_por_url,
    normalizar_busca,
    primeiro_preco,
)
from robo_pichau.modelos import PichauProduto, ResumoColetaPichau
from robo_pichau.portas import (
    ConfiguracaoPichauInvalida,
    FalhaAoGuardarPichau,
    FalhaAoObterPichau,
    PaginacaoPichauInvalida,
    RespostaPichauInvalida,
)
from robo_pichau.principal import (
    coletar_catalogo,
    criar_fonte_pichau,
    diagnosticar_catalogo,
    executar,
)

FIXTURE = Path(__file__).parent / "fixtures" / "pichau_catalogo.html"


def teste_url_de_log_remove_query_fragmento_e_credenciais() -> None:
    assert (
        url_para_log("https://www.pichau.com.br/pc?page=2&token=nao-logar#aba")
        == "https://www.pichau.com.br/pc"
    )
    assert url_para_log("https://usuario:senha@www.pichau.com.br/pc") == "dominio-nao-permitido"
    assert url_para_log("http://www.pichau.com.br/pc") == "dominio-nao-permitido"


def html() -> str:
    return FIXTURE.read_text(encoding="utf-8")


def detalhe_html() -> str:
    return (FIXTURE.parent / "pichau_produto.html").read_text(encoding="utf-8")


def resposta(status: int, corpo: str = "ok") -> SimpleNamespace:
    return SimpleNamespace(status_code=status, content=corpo.encode(), text=corpo)


def teste_decimal_brasileiro_preserva_centavos() -> None:
    assert decimal_brasileiro("R$ 7.499,90") == Decimal("7499.90")
    assert decimal_brasileiro("R$ 6,708.45") == Decimal("6708.45")
    assert decimal_brasileiro(None) is None
    assert decimal_brasileiro("abc") is None
    assert decimal_brasileiro("R$ 1.234.567") == Decimal("1234567")
    assert primeiro_preco("sem valor") == (None, None)


def teste_extrai_precos_disponibilidade_etiquetas_sem_imagem() -> None:
    pagina = extrair_pagina(html(), pagina_esperada=1, por_pagina=36)
    primeiro, segundo = pagina.produtos
    assert pagina.total == 2
    assert primeiro.preco_pix_valor == Decimal("7499.90")
    assert primeiro.preco_cartao_valor == Decimal("7999.90")
    assert primeiro.desconto_pix_valor == Decimal("9")
    assert primeiro.sem_juros is True
    assert primeiro.disponibilidade == "disponivel"
    assert primeiro.etiquetas == ("PC Gamer", "Oferta")
    assert segundo.disponibilidade == "esgotado"
    assert all("image" not in item.__repr__().lower() for item in pagina.produtos)


def teste_extrai_catalogo_next_com_total_precos_e_sku() -> None:
    documento = {
        "category": {"name": "Pichau Gamer"},
        "products": {
            "total_count": 1169,
            "items": [
                {
                    "id": 67332,
                    "sku": "PCM-Pichau-Gamer-67332",
                    "name": "PC Gamer Pichau Ryzen 9",
                    "url_key": "pc-gamer-pichau-ryzen-9",
                    "marcas_info": {"name": "Pichau"},
                    "stock_status": "IN_STOCK",
                    "pichau_prices": {
                        "avista": 6708.46,
                        "avista_discount": 15,
                        "base_price": 11069.03,
                        "final_price": 7892.30,
                        "max_installments": 12,
                        "min_installment_price": 657.69,
                    },
                    "amasty_label": {
                        "product_labels": [{"label": "Montado e Certificado"}],
                        "category_labels": [],
                    },
                    "image": {"url": "https://imagem.invalid/nao-armazenar.jpg"},
                }
            ],
        },
    }
    payload = json.dumps([1, json.dumps(documento, ensure_ascii=False)])
    pagina = extrair_pagina(
        f"<html><script>self.__next_f.push({payload})</script></html>",
        pagina_esperada=1,
        por_pagina=36,
    )

    produto = pagina.produtos[0]
    assert pagina.total == 1169
    assert produto.sku == "PCM-Pichau-Gamer-67332"
    assert produto.id_externo == produto.sku
    assert produto.preco_pix_valor == Decimal("6708.46")
    assert produto.preco_cartao_valor == Decimal("7892.30")
    assert produto.preco_original_valor == Decimal("11069.03")
    assert produto.parcelamento == "12x de R$ 657,69"
    assert produto.desconto_pix_valor == Decimal("15")
    assert produto.disponibilidade == "disponivel"
    assert "Montado e Certificado" in produto.etiquetas
    assert "imagem.invalid" not in produto.__repr__()


def teste_ausencia_de_preco_nao_vira_zero() -> None:
    produto = extrair_pagina(html(), pagina_esperada=1, por_pagina=36).produtos[1]
    assert produto.preco_original_valor is None
    assert produto.preco_cartao_valor is None


def teste_detalhe_completa_sku_sem_apagar_snapshot() -> None:
    produto = PichauProduto(
        id_externo="pichau-10001",
        nome="PC",
        url_produto="https://www.pichau.com.br/pc-gamer-demo-10001",
        preco_pix_texto="R$ 100,00",
    )
    detalhe = extrair_detalhe_produto(detalhe_html(), produto)
    assert detalhe.sku == "SKU-10001"
    assert detalhe.id_externo == "pichau-10001"
    assert detalhe.preco_pix_texto == "R$ 100,00"


def teste_coleta_deduplica_e_rejeita_pagina_repetida() -> None:
    class Fonte:
        url_categoria = "https://www.pichau.com.br/computadores/pichau-gamer"

        def pagina(self, pagina: int) -> str:
            return html().replace("de 2 resultados", "de 72 resultados")

    with pytest.raises(PaginacaoPichauInvalida, match="repetiu"):
        coletar_catalogo(Fonte(), dormir=lambda _: None)


def teste_coleta_registra_tempos_sem_dados_sensiveis(caplog) -> None:
    class Fonte:
        url_categoria = "https://www.pichau.com.br/computadores/pichau-gamer"

        def pagina(self, pagina: int) -> str:
            assert pagina == 1
            return html()

    caplog.set_level("INFO")
    coletar_catalogo(Fonte(), dormir=lambda _: None)

    assert "etapa=pagina_processada" in caplog.text
    assert "etapa=coleta" in caplog.text
    assert "cookie" not in caplog.text.lower()


def teste_fonte_retry_transitorio_e_nao_bypassa_403() -> None:
    respostas = iter([resposta(503), resposta(200, html())])
    fonte = FontePichauHttp(obter=lambda *_args, **_kwargs: next(respostas), dormir=lambda _: None)
    assert "Pichau Gaming" in fonte.pagina(1)

    bloqueada = FontePichauHttp(
        obter=lambda *_args, **_kwargs: resposta(403), dormir=lambda _: None
    )
    with pytest.raises(FalhaAoObterPichau, match="recusou"):
        bloqueada.pagina(1)


def teste_fonte_seleniumbase_usa_catalogo_renderizado_e_fecha_contexto(monkeypatch) -> None:
    documento = {
        "category": {},
        "products": {
            "total_count": 1,
            "items": [
                {
                    "id": 1,
                    "sku": "SKU-UC-1",
                    "name": "PC UC",
                    "url_key": "pc-uc-1",
                    "stock_status": "IN_STOCK",
                    "pichau_prices": {"avista": 1},
                }
            ],
        },
    }
    conteudo = f"<script>self.__next_f.push({json.dumps([1, json.dumps(documento)])})</script>"

    class Navegador:
        class Driver:
            def set_page_load_timeout(self, _valor) -> None:
                pass

        driver = Driver()

        def uc_open_with_reconnect(self, url, reconnect_time) -> None:
            self.url = url
            self.reconnect_time = reconnect_time

        def sleep(self, _segundos) -> None:
            pass

        def get_page_source(self) -> str:
            return conteudo

        def get_title(self) -> str:
            return "PC Gamer"

    class Contexto:
        def __init__(self) -> None:
            self.navegador = Navegador()
            self.fechado = False

        def __enter__(self):
            return self.navegador

        def __exit__(self, *_args) -> None:
            self.fechado = True

    contextos = []

    def SB(**opcoes):
        contexto = Contexto()
        contextos.append((contexto, opcoes))
        return contexto

    monkeypatch.setitem(sys.modules, "seleniumbase", SimpleNamespace(SB=SB))
    fonte = FontePichauSeleniumBase(dormir=lambda _: None)
    with fonte:
        pagina = extrair_pagina(fonte.pagina(1), pagina_esperada=1, por_pagina=36)

    assert pagina.total == 1
    assert pagina.produtos[0].sku == "SKU-UC-1"
    assert contextos[0][0].fechado is True
    assert contextos[0][1]["uc"] is True
    assert contextos[0][1]["headless2"] is True
    assert contextos[0][1]["xvfb"] is False


def teste_fonte_android_abre_chrome_le_catalogo_e_fecha_driver() -> None:
    documento = {
        "category": {},
        "products": {
            "total_count": 1,
            "items": [
                {
                    "id": 1,
                    "sku": "SKU-ANDROID-1",
                    "name": "PC Android",
                    "url_key": "pc-android-1",
                    "stock_status": "IN_STOCK",
                    "pichau_prices": {"avista": 1},
                }
            ],
        },
    }
    conteudo = f"<script>self.__next_f.push({json.dumps([1, json.dumps(documento)])})</script>"

    class Driver:
        current_url = "about:blank"
        title = "PC Gamer"

        def __init__(self) -> None:
            self.urls = []
            self.fechado = False

        def set_page_load_timeout(self, _valor) -> None:
            pass

        def get(self, url) -> None:
            self.urls.append(url)
            self.current_url = url

        @property
        def page_source(self) -> str:
            return conteudo

        def quit(self) -> None:
            self.fechado = True

    drivers = []

    def criar_driver(url, capacidades):
        assert url == "http://127.0.0.1:4723"
        assert capacidades["appium:automationName"] == "UiAutomator2"
        assert capacidades["appium:appPackage"] == "com.android.chrome"
        assert capacidades["appium:appActivity"] == "com.google.android.apps.chrome.Main"
        assert capacidades["appium:forceAppLaunch"] is True
        assert "browserName" not in capacidades
        driver = Driver()
        drivers.append(driver)
        return driver

    fonte = FontePichauAndroid(criar_driver=criar_driver, dormir=lambda _: None)
    with fonte:
        pagina = extrair_pagina(fonte.pagina(1), pagina_esperada=1, por_pagina=36)

    assert pagina.produtos[0].sku == "SKU-ANDROID-1"
    assert drivers[0].urls == [fonte._url_pagina(1)]
    assert drivers[0].fechado is True


def teste_fonte_android_le_documento_pelo_cdp_e_fecha_ponte() -> None:
    documento = {
        "category": {},
        "products": {
            "total_count": 1,
            "items": [
                {
                    "id": 1,
                    "sku": "SKU-CDP-1",
                    "name": "PC CDP",
                    "url_key": "pc-cdp-1",
                    "stock_status": "IN_STOCK",
                    "pichau_prices": {"avista": 1},
                }
            ],
        },
    }
    conteudo = f"<script>self.__next_f.push({json.dumps([1, json.dumps(documento)])})</script>"

    class Driver:
        def set_page_load_timeout(self, _valor) -> None:
            pass

        def quit(self) -> None:
            pass

    class DevTools:
        def __init__(self) -> None:
            self.alvos = []
            self.fechado = False

        def obter(self, url):
            self.alvos.append(url)
            return conteudo, "PC Gamer", url

        def fechar(self) -> None:
            self.fechado = True

    devtools = DevTools()
    fonte = FontePichauAndroid(
        criar_driver=lambda *_args: Driver(),
        cdp=devtools,
        dormir=lambda _: None,
    )
    with fonte:
        pagina = extrair_pagina(fonte.pagina(1), pagina_esperada=1, por_pagina=36)

    assert pagina.produtos[0].sku == "SKU-CDP-1"
    assert devtools.alvos == [fonte._url_pagina(1)]
    assert devtools.fechado is True


def teste_cdp_android_mantem_chrome_ativo_e_bloqueia_recursos_inuteis(monkeypatch) -> None:
    devtools = modulo_adaptadores._ChromeDevTools(udid="device", adb_port=None, timeout=10.0)
    chamadas = []
    monkeypatch.setattr(
        devtools,
        "_comando",
        lambda _socket, metodo, parametros=None: chamadas.append((metodo, parametros)),
    )

    devtools._preparar_pagina(object())

    assert [metodo for metodo, _ in chamadas] == [
        "Page.enable",
        "Page.bringToFront",
        "Network.enable",
        "Network.setCacheDisabled",
        "Network.setBlockedURLs",
    ]
    assert chamadas[3][1] == {"cacheDisabled": True}
    assert "*.jpg" in chamadas[4][1]["urls"]
    assert "*google-analytics*" in chamadas[4][1]["urls"]


def teste_fonte_android_recria_chrome_quando_devtools_nao_volta_do_reboot(
    monkeypatch,
) -> None:
    class DevTools:
        def __init__(self, **_kwargs):
            self.aberturas = 0
            self.verificacoes = 0
            self.urls_abertas = []
            self.aguardas = 0
            self.fechado = False

        def abrir(self) -> None:
            self.aberturas += 1

        def verificar(self) -> None:
            self.verificacoes += 1
            if self.verificacoes == 1:
                raise FalhaAoObterPichau("DevTools ausente", codigo="navegador")

        def abrir_url(self, url) -> None:
            self.urls_abertas.append(url)

        def aguardar_pagina(self) -> None:
            self.aguardas += 1

        def fechar(self) -> None:
            self.fechado = True

    class Driver:
        def __init__(self):
            self.timeout = None
            self.fechado = False

        def set_page_load_timeout(self, timeout):
            self.timeout = timeout

        def quit(self):
            self.fechado = True

    devtools = DevTools()
    driver = Driver()
    monkeypatch.setattr(modulo_adaptadores, "_ChromeDevTools", lambda **_: devtools)
    fonte = FontePichauAndroid(dormir=lambda _: None)
    monkeypatch.setattr(fonte, "_abrir_driver", lambda: driver)

    with fonte:
        assert fonte._driver is driver

    assert devtools.aberturas == 2
    assert devtools.verificacoes == 1
    assert devtools.urls_abertas == [fonte.url_categoria]
    assert devtools.aguardas == 1
    assert devtools.fechado is True
    assert driver.timeout == fonte.timeout
    assert driver.fechado is True


def teste_fonte_android_fetch_e_fallback_dom_por_pagina() -> None:
    documento = {
        "category": {},
        "products": {
            "total_count": 101,
            "items": [
                {
                    "id": 1,
                    "sku": "SKU-FETCH-1",
                    "name": "PC Fetch",
                    "url_key": "pc-fetch-1",
                    "stock_status": "IN_STOCK",
                    "pichau_prices": {"avista": 1},
                }
            ],
        },
    }
    conteudo = f"<script>self.__next_f.push({json.dumps([1, json.dumps(documento)])})</script>"

    class DevTools:
        def __init__(self, falhar_fetch: bool = False) -> None:
            self.falhar_fetch = falhar_fetch
            self.fetches: list[str] = []
            self.dom: list[str] = []
            self.fechado = False

        def abrir(self) -> None:
            pass

        def fechar(self) -> None:
            self.fechado = True

        def obter(self, url):
            self.dom.append(url)
            return conteudo, "PC Gamer", url

        def obter_fetch(self, url):
            self.fetches.append(url)
            if self.falhar_fetch:
                raise TimeoutError("SSR indisponivel")
            return conteudo, "PC Gamer", url

    devtools = DevTools()
    fonte = FontePichauAndroid(cdp=devtools, estrategia_leitura="fetch", dormir=lambda _: None)
    with fonte:
        extrair_pagina(fonte.pagina(1), pagina_esperada=1, por_pagina=100)
        extrair_pagina(fonte.pagina(2), pagina_esperada=2, por_pagina=100)

    assert devtools.fetches == [fonte._url_pagina(1), fonte._url_pagina(2)]
    assert devtools.dom == []

    fallback = DevTools(falhar_fetch=True)
    fonte_fallback = FontePichauAndroid(
        cdp=fallback, estrategia_leitura="fetch", dormir=lambda _: None
    )
    with fonte_fallback:
        extrair_pagina(fonte_fallback.pagina(2), pagina_esperada=2, por_pagina=100)

    assert fallback.fetches == [fonte_fallback._url_pagina(2)]
    assert fallback.dom == [fonte_fallback._url_pagina(2)]


def teste_fonte_android_fetch_precarrega_paginas_restantes() -> None:
    documento = {
        "category": {},
        "products": {
            "total_count": 401,
            "items": [
                {
                    "id": 1,
                    "sku": "SKU-PREFETCH-1",
                    "name": "PC Prefetch",
                    "url_key": "pc-prefetch-1",
                    "stock_status": "IN_STOCK",
                    "pichau_prices": {"avista": 1},
                }
            ],
        },
    }
    conteudo = f"<script>self.__next_f.push({json.dumps([1, json.dumps(documento)])})</script>"

    class DevTools:
        def __init__(self) -> None:
            self.fetches: list[str] = []

        def abrir(self) -> None:
            pass

        def fechar(self) -> None:
            pass

        def obter_fetch(self, url):
            self.fetches.append(url)
            return conteudo, "PC Gamer", url

    devtools = DevTools()
    fonte = FontePichauAndroid(cdp=devtools, estrategia_leitura="fetch", dormir=lambda _: None)
    with fonte:
        fonte.pagina(1)
        fonte.pagina(2)
        fonte.pagina(3)

    assert sorted(devtools.fetches) == sorted(
        [fonte._url_pagina(1), fonte._url_pagina(2), fonte._url_pagina(3)]
    )


def teste_fonte_android_le_resposta_de_rede_antes_do_dom() -> None:
    documento = {
        "category": {},
        "products": {
            "total_count": 1,
            "items": [
                {
                    "id": 1,
                    "sku": "SKU-REDE-1",
                    "name": "PC Rede",
                    "url_key": "pc-rede-1",
                    "stock_status": "IN_STOCK",
                    "pichau_prices": {"avista": 1},
                }
            ],
        },
    }
    conteudo = f"<script>self.__next_f.push({json.dumps([1, json.dumps(documento)])})</script>"

    class DevTools:
        def __init__(self) -> None:
            self.alvos: list[str] = []
            self.fechado = False

        def abrir(self) -> None:
            pass

        def fechar(self) -> None:
            self.fechado = True

        def obter_rede(self, url):
            self.alvos.append(url)
            return conteudo, "PC Gamer", url

    devtools = DevTools()
    fonte = FontePichauAndroid(cdp=devtools, estrategia_leitura="rede", dormir=lambda _: None)
    with fonte:
        pagina = extrair_pagina(fonte.pagina(1), pagina_esperada=1, por_pagina=200)

    assert pagina.produtos[0].sku == "SKU-REDE-1"
    assert devtools.alvos == [fonte._url_pagina(1)]
    assert devtools.fechado is True


def teste_cdp_android_preserva_evento_de_rede_antes_da_resposta_do_navigate(
    monkeypatch,
) -> None:
    url = "https://www.pichau.com.br/computadores/pichau-gamer?pageSize=200"
    eventos = iter(
        (
            json.dumps(
                {
                    "method": "Network.responseReceived",
                    "params": {
                        "type": "Document",
                        "requestId": "req-1",
                        "response": {"url": url, "status": 200},
                    },
                }
            ),
            json.dumps({"id": 1, "result": {}}),
            json.dumps({"method": "Network.loadingFinished", "params": {"requestId": "req-1"}}),
        )
    )

    class Socket:
        def __init__(self) -> None:
            self.enviadas: list[str] = []

        def send(self, mensagem: str) -> None:
            self.enviadas.append(mensagem)

        def recv(self) -> str:
            return next(eventos)

    socket = Socket()
    devtools = modulo_adaptadores._ChromeDevTools(udid="device", adb_port=None, timeout=10.0)
    chamadas = []

    def comando(_socket, metodo, parametros=None):
        chamadas.append((metodo, parametros))
        if metodo == "Network.getResponseBody":
            return {"result": {"body": "<html>catalogo</html>", "base64Encoded": False}}
        return {"result": {"result": {"value": "Pichau"}}}

    monkeypatch.setattr(devtools, "_comando", comando)
    resposta = devtools._navegar_e_obter_resposta(socket, url)

    assert resposta == {
        "html": "<html>catalogo</html>",
        "title": "Pichau",
        "url": url,
        "status": "200",
    }
    assert json.loads(socket.enviadas[0])["method"] == "Page.navigate"
    assert [metodo for metodo, _ in chamadas] == [
        "Network.getResponseBody",
        "Runtime.evaluate",
    ]


def teste_fonte_android_rejeita_estrategia_de_leitura_desconhecida() -> None:
    with pytest.raises(FalhaAoObterPichau, match="dom, fetch ou rede"):
        FontePichauAndroid(estrategia_leitura="outro")


def teste_fonte_android_aplica_ordenacao_publica() -> None:
    fonte = FontePichauAndroid(ordenacao="name-asc")
    assert fonte._url_pagina(2).endswith("pageSize=200&sort=name-asc&page=2")


def teste_fonte_android_rejeita_ordenacao_desconhecida() -> None:
    with pytest.raises(FalhaAoObterPichau, match="PICHAU_ANDROID_ORDENACAO"):
        FontePichauAndroid(ordenacao="outro")


def teste_fonte_android_nao_aceita_appium_remoto() -> None:
    with pytest.raises(FalhaAoObterPichau, match="Appium local"):
        FontePichauAndroid(appium_url="http://servidor-remoto:4723")


def teste_diagnostico_seleniumbase_nao_registra_html(caplog) -> None:
    fonte = FontePichauSeleniumBase()
    caplog.set_level("INFO")

    fonte._diagnosticar(
        contexto="catalogo",
        pagina=1,
        tentativa=3,
        fase="bloqueio_detectado",
        alvo="https://www.pichau.com.br/computadores/pichau-gamer",
        fonte="<html>cookie=nao-publicar</html>",
        titulo="Just a moment",
        desafio=True,
    )

    assert "titulo='Just a moment'" in caplog.text
    assert "bytes=" in caplog.text
    assert "cookie=nao-publicar" not in caplog.text


def teste_diagnostico_de_uma_pagina_nao_cria_execucao_no_banco(monkeypatch) -> None:
    documento = {
        "category": {},
        "products": {
            "total_count": 1,
            "items": [
                {
                    "id": 2,
                    "sku": "SKU-DIAGNOSTICO-1",
                    "name": "PC Diagnostico",
                    "url_key": "pc-diagnostico-1",
                    "stock_status": "IN_STOCK",
                    "pichau_prices": {"avista": 2},
                }
            ],
        },
    }
    conteudo = f"<script>self.__next_f.push({json.dumps([1, json.dumps(documento)])})</script>"

    class Fonte:
        url_categoria = "https://www.pichau.com.br/computadores/pichau-gamer"

        def __enter__(self):
            return self

        def __exit__(self, *_args) -> None:
            pass

        def pagina(self, pagina: int) -> str:
            assert pagina == 1
            return conteudo

        def detalhe(self, _url_produto: str) -> str:
            return ""

    monkeypatch.setattr("robo_pichau.principal.criar_fonte_pichau", lambda: Fonte())
    monkeypatch.delenv("DATABASE_URL", raising=False)
    monkeypatch.setattr(
        "robo_pichau.principal.RepositorioPichauPostgres",
        lambda *_args, **_kwargs: pytest.fail("diagnostico nao pode criar repositorio"),
    )

    assert executar(["--diagnostico"]) == 0


def teste_diagnostico_android_dom_pode_nao_ter_sku() -> None:
    documento = {
        "category": {},
        "products": {
            "total_count": 1,
            "items": [
                {
                    "name": "PC Android DOM",
                    "url_key": "pc-android-dom-12345",
                    "stock_status": "IN_STOCK",
                    "pichau_prices": {"avista": 1234.56},
                }
            ],
        },
    }
    conteudo = f"<script>self.__next_f.push({json.dumps([1, json.dumps(documento)])})</script>"

    class FonteDom(FontePichauAndroid):
        def pagina(self, pagina: int) -> str:
            assert pagina == 1
            return conteudo

    diagnosticar_catalogo(FonteDom())


def teste_execucao_normal_exige_database_url(monkeypatch) -> None:
    monkeypatch.delenv("DATABASE_URL", raising=False)
    with pytest.raises(ConfiguracaoPichauInvalida, match="DATABASE_URL"):
        executar([])


def teste_cria_fonte_no_modo_xvfb(monkeypatch) -> None:
    monkeypatch.setenv("PICHAU_MODO_NAVEGADOR", "xvfb")
    fonte = criar_fonte_pichau()
    assert fonte.headless2 is False
    assert fonte.xvfb is True


def teste_cria_fonte_no_modo_android(monkeypatch) -> None:
    monkeypatch.setenv("PICHAU_MODO_NAVEGADOR", "android")
    monkeypatch.setenv("PICHAU_APPIUM_URL", "http://127.0.0.1:4723/wd/hub")
    monkeypatch.setenv("PICHAU_ESTRATEGIA_LEITURA", "fetch")
    monkeypatch.setenv("PICHAU_ANDROID_ORDENACAO", "name-asc")
    fonte = criar_fonte_pichau()
    assert isinstance(fonte, FontePichauAndroid)
    assert fonte.appium_url.endswith("/wd/hub")
    assert fonte.estrategia_leitura == "fetch"
    assert fonte.ordenacao == "name-asc"


def teste_rejeita_modo_de_navegador_desconhecido(monkeypatch) -> None:
    monkeypatch.setenv("PICHAU_MODO_NAVEGADOR", "outro")
    with pytest.raises(ConfiguracaoPichauInvalida, match="headless2, xvfb ou android"):
        criar_fonte_pichau()


def teste_url_produto_precisa_ser_https_no_dominio_da_fonte() -> None:
    fonte = FontePichauHttp(obter=lambda *_args, **_kwargs: resposta(200, html()))
    with pytest.raises(FalhaAoObterPichau):
        fonte.detalhe("https://exemplo.test/produto")
    with pytest.raises(RespostaPichauInvalida):
        extrair_pagina(
            html().replace("https://www.pichau.com.br", "http://www.pichau.com.br"),
            pagina_esperada=1,
            por_pagina=36,
        )


def teste_fallback_json_ld_e_identidade_por_slug() -> None:
    documento = """
    <script type="application/ld+json">nao-json</script>
    <script type="application/ld+json">
      [{"@type":"Thing"},
       {"@type":"Product", "name":"PC JSON", "url":"https://www.pichau.com.br/pc-json",
        "sku":"JSON-1", "brand":{"name":"Marca"},
        "offers":{"price":"1234.50", "availability":"https://schema.org/InStock"}},
       {"@type":"Product", "name":"PC sem oferta", "url":"https://www.pichau.com.br/pc-sem-oferta"}]
    </script>
    """
    pagina = extrair_pagina(documento, pagina_esperada=1, por_pagina=20)
    assert pagina.total == 2
    assert pagina.produtos[0].sku == "JSON-1"
    assert pagina.produtos[0].disponibilidade == "disponivel"
    assert pagina.produtos[1].disponibilidade == "nao_informado"
    assert (
        id_por_url("https://www.pichau.com.br/pc-gamer-sem-numero") == "pichau-pc-gamer-sem-numero"
    )
    assert normalizar_busca("  Placa de Vídeo  ") == "placa de video"


def teste_paginacao_rejeita_total_incoerente_e_url_fora_da_pagina() -> None:
    with pytest.raises(PaginacaoPichauInvalida, match="menor"):
        extrair_pagina(
            html().replace("de 2 resultados", "de 1 resultados"),
            pagina_esperada=1,
            por_pagina=36,
        )
    with pytest.raises(PaginacaoPichauInvalida, match="corresponde"):
        extrair_pagina(
            html(),
            pagina_esperada=2,
            por_pagina=36,
            base_url="https://www.pichau.com.br/computadores/pichau-gamer?page=1",
        )


def teste_robots_permite_allow_mais_especifico() -> None:
    conteudo = """
    User-agent: *
    Disallow: /computadores/
    Allow: /computadores/pichau-gamer
    """
    assert robots_permite(conteudo, "/computadores/pichau-gamer") is True
    assert robots_permite(conteudo, "/computadores/outra") is False


def teste_repositorio_publica_em_transacao_e_preserva_codigo_parcial() -> None:
    class Cursor:
        def __init__(self) -> None:
            self.chamadas: list[tuple[str, object]] = []
            self.ultima_consulta = ""
            self.ultimos_parametros: object = None

        def __enter__(self) -> Cursor:
            return self

        def __exit__(self, *_args: object) -> None:
            return None

        def execute(self, consulta: str, parametros: object = None) -> None:
            self.chamadas.append((consulta, parametros))
            self.ultima_consulta = consulta
            self.ultimos_parametros = parametros

        def fetchone(self) -> tuple[int]:
            return (42,)

        def fetchall(self) -> list[tuple[int, str]]:
            if "RETURNING id, id_externo" in self.ultima_consulta:
                assert isinstance(self.ultimos_parametros, tuple)
                return [(42, str(self.ultimos_parametros[0]))]
            return []

    class Conexao:
        def __init__(self) -> None:
            self.cursor_obj = Cursor()

        def __enter__(self) -> Conexao:
            return self

        def __exit__(self, *_args: object) -> None:
            return None

        def cursor(self) -> Cursor:
            return self.cursor_obj

    conexao = Conexao()
    repositorio = RepositorioPichauPostgres("postgres://teste", conectar=lambda _: conexao)
    execucao = repositorio.iniciar_execucao(datetime.now(UTC), "teste")
    produto = extrair_pagina(html(), pagina_esperada=1, por_pagina=36).produtos[0]
    agora = datetime.now(UTC)
    repositorio.publicar(
        execucao,
        (produto,),
        ResumoColetaPichau(agora, agora, 2, 1, 2, 1, 1),
    )
    repositorio.falhar(execucao, "parcial")
    consultas = "\n".join(consulta for consulta, _ in conexao.cursor_obj.chamadas)
    assert "presente_no_catalogo=FALSE" in consultas
    assert "estado=CASE WHEN" in consultas


def teste_repositorio_reconcilia_android_por_url_em_lote() -> None:
    class Cursor:
        def __init__(self) -> None:
            self.chamadas: list[tuple[str, object]] = []
            self.ultima_consulta = ""
            self.ultimos_parametros: object = None

        def __enter__(self) -> Cursor:
            return self

        def __exit__(self, *_args: object) -> None:
            return None

        def execute(self, consulta: str, parametros: object = None) -> None:
            self.chamadas.append((consulta, parametros))
            self.ultima_consulta = consulta
            self.ultimos_parametros = parametros

        def fetchone(self) -> tuple[int]:
            return (99,)

        def fetchall(self) -> list[tuple[str, str]]:
            if "SELECT DISTINCT ON (url_produto)" in self.ultima_consulta:
                return [
                    (
                        "https://www.pichau.com.br/pc-gamer-exemplo-12345",
                        "PC-Pichau-Gamer-12345",
                    )
                ]
            if "RETURNING id, id_externo" in self.ultima_consulta:
                return [(99, "PC-Pichau-Gamer-12345")]
            return []

    class Conexao:
        def __init__(self) -> None:
            self.cursor_obj = Cursor()

        def __enter__(self) -> Conexao:
            return self

        def __exit__(self, *_args: object) -> None:
            return None

        def cursor(self) -> Cursor:
            return self.cursor_obj

    conexao = Conexao()
    repositorio = RepositorioPichauPostgres("postgres://teste", conectar=lambda _: conexao)
    agora = datetime.now(UTC)
    produto = PichauProduto(
        id_externo="pichau-pc-gamer-exemplo-12345",
        nome="PC Gamer exemplo",
        url_produto="https://www.pichau.com.br/pc-gamer-exemplo-12345",
    )

    repositorio.publicar(
        99,
        (produto,),
        ResumoColetaPichau(agora, agora, 1, 1, 1, 1, 0),
    )

    insercao = next(
        parametros
        for consulta, parametros in conexao.cursor_obj.chamadas
        if "INSERT INTO pichau_produto" in consulta
    )
    assert insercao[0] == "PC-Pichau-Gamer-12345"
    assert any(
        "SELECT DISTINCT ON (url_produto)" in consulta
        for consulta, _ in conexao.cursor_obj.chamadas
    )


def teste_repositorio_rejeita_colisao_de_identidade_antes_de_escrever() -> None:
    class Cursor:
        def __init__(self) -> None:
            self.chamadas: list[tuple[str, object]] = []
            self.ultima_consulta = ""

        def __enter__(self) -> Cursor:
            return self

        def __exit__(self, *_args: object) -> None:
            return None

        def execute(self, consulta: str, parametros: object = None) -> None:
            self.chamadas.append((consulta, parametros))
            self.ultima_consulta = consulta

        def fetchall(self) -> list[tuple[str, str]]:
            if "SELECT DISTINCT ON (url_produto)" in self.ultima_consulta:
                return [
                    (
                        "https://www.pichau.com.br/pc-gamer-colisao",
                        "SKU-HISTORICO-COLISAO",
                    )
                ]
            return []

    class Conexao:
        def __init__(self) -> None:
            self.cursor_obj = Cursor()

        def __enter__(self) -> Conexao:
            return self

        def __exit__(self, *_args: object) -> None:
            return None

        def cursor(self) -> Cursor:
            return self.cursor_obj

    conexao = Conexao()
    repositorio = RepositorioPichauPostgres("postgres://teste", conectar=lambda _: conexao)
    agora = datetime.now(UTC)
    produtos = tuple(
        PichauProduto(
            id_externo=f"pichau-transitorio-{indice}",
            nome=f"PC Gamer colisao {indice}",
            url_produto="https://www.pichau.com.br/pc-gamer-colisao",
        )
        for indice in (1, 2)
    )

    with pytest.raises(FalhaAoGuardarPichau) as falha:
        repositorio.publicar(
            99,
            produtos,
            ResumoColetaPichau(agora, agora, 2, 2, 2, 0, 0),
        )

    assert falha.value.codigo == "identidade"
    assert not any(
        "INSERT INTO pichau_produto" in consulta for consulta, _ in conexao.cursor_obj.chamadas
    )


def teste_repositorio_publica_produtos_e_medicoes_em_lotes_de_cem() -> None:
    class Cursor:
        def __init__(self) -> None:
            self.chamadas: list[tuple[str, object]] = []
            self.ultima_consulta = ""
            self.ultimos_parametros: object = None

        def __enter__(self) -> Cursor:
            return self

        def __exit__(self, *_args: object) -> None:
            return None

        def execute(self, consulta: str, parametros: object = None) -> None:
            self.chamadas.append((consulta, parametros))
            self.ultima_consulta = consulta
            self.ultimos_parametros = parametros

        def fetchall(self) -> list[tuple[int, str]]:
            if "RETURNING id, id_externo" not in self.ultima_consulta:
                return []
            assert isinstance(self.ultimos_parametros, tuple)
            return [
                (indice + 1, str(self.ultimos_parametros[posicao]))
                for indice, posicao in enumerate(range(0, len(self.ultimos_parametros), 11))
            ]

    class Conexao:
        def __init__(self) -> None:
            self.cursor_obj = Cursor()

        def __enter__(self) -> Conexao:
            return self

        def __exit__(self, *_args: object) -> None:
            return None

        def cursor(self) -> Cursor:
            return self.cursor_obj

    conexao = Conexao()
    repositorio = RepositorioPichauPostgres("postgres://teste", conectar=lambda _: conexao)
    agora = datetime.now(UTC)
    produtos = tuple(
        PichauProduto(
            id_externo=f"SKU-LOTE-{indice}",
            sku=f"SKU-LOTE-{indice}",
            nome=f"PC Gamer lote {indice}",
            url_produto=f"https://www.pichau.com.br/pc-gamer-lote-{indice}",
        )
        for indice in range(101)
    )

    repositorio.publicar(
        99,
        produtos,
        ResumoColetaPichau(agora, agora, 101, 2, 101, 101, 0),
    )

    produtos_sql = [
        parametros
        for consulta, parametros in conexao.cursor_obj.chamadas
        if "INSERT INTO pichau_produto" in consulta
    ]
    medicoes_sql = [
        parametros
        for consulta, parametros in conexao.cursor_obj.chamadas
        if "INSERT INTO pichau_medicao" in consulta
    ]
    assert [len(parametros) for parametros in produtos_sql] == [1100, 11]
    assert [len(parametros) for parametros in medicoes_sql] == [1600, 16]
