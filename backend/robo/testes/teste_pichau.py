from __future__ import annotations

import json
import sys
from datetime import UTC, datetime
from decimal import Decimal
from pathlib import Path
from types import SimpleNamespace

import pytest

from robo_pichau.adaptadores import (
    FontePichauHttp,
    FontePichauSeleniumBase,
    RepositorioPichauPostgres,
    robots_permite,
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
from robo_pichau.portas import FalhaAoObterPichau, PaginacaoPichauInvalida, RespostaPichauInvalida
from robo_pichau.principal import coletar_catalogo

FIXTURE = Path(__file__).parent / "fixtures" / "pichau_catalogo.html"


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

        def __enter__(self) -> Cursor:
            return self

        def __exit__(self, *_args: object) -> None:
            return None

        def execute(self, consulta: str, parametros: object = None) -> None:
            self.chamadas.append((consulta, parametros))

        def fetchone(self) -> tuple[int]:
            return (42,)

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
