"""Adaptadores HTTP, SeleniumBase e Postgres do coletor Pichau."""

from __future__ import annotations

import json
import logging
import random
import subprocess
import time
from collections.abc import Callable
from datetime import UTC, datetime, timedelta
from itertools import count
from urllib.parse import parse_qs, urlencode, urlparse

import requests

from .modelos import PichauProduto, ResumoColetaPichau
from .portas import FalhaAoGuardarPichau, FalhaAoObterPichau, FalhaPichau

_log = logging.getLogger(__name__)

URL_CATEGORIA = "https://www.pichau.com.br/computadores/pichau-gamer"
URL_ROBOTS = "https://www.pichau.com.br/robots.txt"
USER_AGENT = "radar-beneficios-pichau/1 (coleta publica; contato no repositorio)"
TAMANHO_MAXIMO = 8 * 1024 * 1024
STATUS_RETRY = {408, 425, 429}
HOSTES_VALIDOS = {"pichau.com.br", "www.pichau.com.br"}


def robots_permite(conteudo: str, caminho: str, user_agent: str = USER_AGENT) -> bool:
    """Interpreta o subconjunto necessario do robots.txt sem assumir permissao."""

    grupos: list[tuple[list[str], list[str]]] = []
    agentes: list[str] = []
    permite: list[str] = []
    bloqueia: list[str] = []
    lendo = False
    for linha in conteudo.splitlines():
        parte = linha.split("#", 1)[0].strip()
        if not parte or ":" not in parte:
            continue
        chave, valor = (item.strip() for item in parte.split(":", 1))
        chave = chave.lower()
        if chave == "user-agent":
            if lendo and agentes:
                grupos.append((agentes, permite + [f"!{item}" for item in bloqueia]))
            agentes, permite, bloqueia = [valor.lower()], [], []
            lendo = True
        elif lendo and chave == "allow":
            permite.append(valor or "/")
        elif lendo and chave == "disallow":
            bloqueia.append(valor or "/")
    if lendo and agentes:
        grupos.append((agentes, permite + [f"!{item}" for item in bloqueia]))

    aplicaveis = [
        regras
        for agentes_grupo, regras in grupos
        if "*" in agentes_grupo or any(agent in user_agent.lower() for agent in agentes_grupo)
    ]
    if not aplicaveis:
        return True
    regras = [regra for grupo in aplicaveis for regra in grupo]
    bloqueios = [regra[1:] for regra in regras if regra.startswith("!")]
    autorizacoes = [regra for regra in regras if not regra.startswith("!")]
    bloqueado = max((len(regra) for regra in bloqueios if caminho.startswith(regra)), default=-1)
    permitido = max((len(regra) for regra in autorizacoes if caminho.startswith(regra)), default=-1)
    return permitido >= bloqueado


class FontePichauHttp:
    def __init__(
        self,
        url_categoria: str = URL_CATEGORIA,
        *,
        tentativas: int = 3,
        timeout: float = 30.0,
        tamanho_maximo: int = TAMANHO_MAXIMO,
        dormir: Callable[[float], None] = time.sleep,
        obter: Callable[..., requests.Response] = requests.get,
    ) -> None:
        self.url_categoria = url_categoria
        self.tentativas = max(1, tentativas)
        self.timeout = timeout
        self.tamanho_maximo = tamanho_maximo
        self.dormir = dormir
        self.obter = obter

    def pagina(self, pagina: int) -> str:
        url = self.url_categoria
        if pagina > 1:
            url = f"{url}?{urlencode({'page': pagina})}"
        return self._obter(url, "catalogo")

    def detalhe(self, url_produto: str) -> str:
        analisada = urlparse(url_produto)
        if analisada.scheme != "https" or analisada.hostname not in HOSTES_VALIDOS:
            raise FalhaAoObterPichau("URL de produto fora do dominio permitido.", codigo="url")
        return self._obter(url_produto, "produto")

    def robots(self) -> str:
        return self._obter(URL_ROBOTS, "robots.txt")

    def _obter(self, url: str, contexto: str) -> str:
        for tentativa in range(1, self.tentativas + 1):
            try:
                resposta = self.obter(
                    url,
                    timeout=self.timeout,
                    headers={
                        "User-Agent": USER_AGENT,
                        "Accept": (
                            "text/html,application/xhtml+xml,application/json;q=0.9,*/*;q=0.8"
                        ),
                        "Accept-Language": "pt-BR,pt;q=0.9",
                    },
                )
            except (requests.RequestException, ConnectionError, TimeoutError):
                if tentativa == self.tentativas:
                    raise FalhaAoObterPichau(
                        f"A fonte Pichau nao respondeu ao {contexto}.", codigo="rede"
                    ) from None
                self._esperar(tentativa, contexto)
                continue
            if (
                resposta.status_code in STATUS_RETRY or resposta.status_code >= 500
            ) and tentativa < self.tentativas:
                self._esperar(tentativa, f"{contexto} HTTP {resposta.status_code}")
                continue
            if resposta.status_code in (401, 403):
                raise FalhaAoObterPichau(
                    "A fonte Pichau recusou a coleta publica.", codigo="acesso"
                )
            if resposta.status_code < 200 or resposta.status_code >= 300:
                raise FalhaAoObterPichau(
                    f"A fonte Pichau respondeu HTTP {resposta.status_code}.", codigo="http"
                )
            if len(resposta.content) > self.tamanho_maximo:
                raise FalhaAoObterPichau(
                    "Resposta da Pichau excede o limite seguro.", codigo="resposta_grande"
                )
            return resposta.text
        raise FalhaAoObterPichau(f"A fonte Pichau falhou ao ler {contexto}.", codigo="rede")

    def _esperar(self, tentativa: int, contexto: str) -> None:
        _log.warning("Pichau: %s; tentativa %d de %d.", contexto, tentativa, self.tentativas)
        self.dormir(min(30.0, 2.0 * tentativa))


class FontePichauSeleniumBase:
    """Abre o catálogo público em UC/CDP e devolve o HTML renderizado.

    O navegador fica isolado por execução do workflow. A classe não acessa
    áreas autenticadas, não salva imagens e encerra após três falhas seguidas
    na mesma página.
    """

    _TITULOS_BLOQUEIO = ("just a moment", "site em manutenção", "access denied")
    _MARCADORES_DESAFIO = ("cf-turnstile", "g-recaptcha", "hcaptcha")

    def __init__(
        self,
        url_categoria: str = URL_CATEGORIA,
        *,
        tentativas: int = 3,
        timeout: float = 60.0,
        tamanho_maximo: int = TAMANHO_MAXIMO,
        dormir: Callable[[float], None] = time.sleep,
        headless2: bool = True,
        xvfb: bool = False,
    ) -> None:
        self.url_categoria = url_categoria
        self.tentativas = max(1, min(3, tentativas))
        self.timeout = timeout
        self.tamanho_maximo = tamanho_maximo
        self.dormir = dormir
        self.headless2 = headless2
        self.xvfb = xvfb
        self._sessao = None
        self._contexto = None

    def __enter__(self) -> FontePichauSeleniumBase:
        try:
            from seleniumbase import SB

            self._contexto = SB(
                uc=True,
                test=True,
                locale="pt-BR",
                headless2=self.headless2,
                xvfb=self.xvfb,
            )
            self._sessao = self._contexto.__enter__()
            self._sessao.driver.set_page_load_timeout(self.timeout)
        except Exception as erro:
            if self._contexto is not None:
                self._contexto.__exit__(type(erro), erro, erro.__traceback__)
            self._sessao = None
            self._contexto = None
            raise FalhaAoObterPichau(
                "Nao foi possivel iniciar o navegador SeleniumBase.", codigo="navegador"
            ) from erro
        return self

    def __exit__(self, tipo, valor, traceback) -> None:
        if self._contexto is not None:
            self._contexto.__exit__(tipo, valor, traceback)
            self._sessao = None
            self._contexto = None

    def pagina(self, pagina: int) -> str:
        if pagina < 1:
            raise FalhaAoObterPichau("Numero de pagina invalido.", codigo="pagina")
        url = self.url_categoria
        if pagina > 1:
            separador = "&" if "?" in url else "?"
            url = f"{url}{separador}{urlencode({'page': pagina})}"
        return self._obter(url, "catalogo", pagina)

    def detalhe(self, url_produto: str) -> str:
        analisada = urlparse(url_produto)
        if analisada.scheme != "https" or analisada.hostname not in HOSTES_VALIDOS:
            raise FalhaAoObterPichau("URL de produto fora do dominio permitido.", codigo="url")
        return self._obter(url_produto, "produto", None)

    def esperar(self, _segundos: float | None = None) -> None:
        """Aplica o intervalo autorizado entre páginas ou tentativas."""

        self.dormir(random.uniform(2.0, 5.0))

    def _obter(self, url: str, contexto: str, pagina: int | None) -> str:
        self._exigir_sessao()
        for tentativa in range(1, self.tentativas + 1):
            try:
                self._sessao.uc_open_with_reconnect(url, reconnect_time=4)
                self._sessao.sleep(3)
                fonte = self._sessao.get_page_source()
                titulo_original = self._sessao.get_title()
                titulo = titulo_original.lower()
                desafio = self._tem_desafio(fonte, titulo)
                self._diagnosticar(
                    contexto=contexto,
                    pagina=pagina,
                    tentativa=tentativa,
                    fase="resposta_inicial",
                    alvo=url,
                    fonte=fonte,
                    titulo=titulo_original,
                    desafio=desafio,
                )
                if desafio:
                    self._sessao.uc_gui_click_captcha()
                    self._sessao.sleep(3)
                    fonte = self._sessao.get_page_source()
                    titulo_original = self._sessao.get_title()
                    titulo = titulo_original.lower()
                    self._diagnosticar(
                        contexto=contexto,
                        pagina=pagina,
                        tentativa=tentativa,
                        fase="apos_desafio",
                        alvo=url,
                        fonte=fonte,
                        titulo=titulo_original,
                        desafio=self._tem_desafio(fonte, titulo),
                    )
                if self._tem_bloqueio(fonte, titulo):
                    self._diagnosticar(
                        contexto=contexto,
                        pagina=pagina,
                        tentativa=tentativa,
                        fase="bloqueio_detectado",
                        alvo=url,
                        fonte=fonte,
                        titulo=titulo_original,
                        desafio=self._tem_desafio(fonte, titulo),
                    )
                    raise FalhaAoObterPichau(
                        "A Pichau exibiu um bloqueio ou pagina de manutencao.", codigo="acesso"
                    )
                if len(fonte.encode("utf-8")) > self.tamanho_maximo:
                    raise FalhaAoObterPichau(
                        "Resposta da Pichau excede o limite seguro.", codigo="resposta_grande"
                    )
                if contexto == "catalogo":
                    self._validar_catalogo(fonte, pagina or 1, url)
                return fonte
            except FalhaPichau:
                if tentativa == self.tentativas:
                    raise
                self._esperar(tentativa, contexto)
            except Exception as erro:
                _log.warning(
                    "Pichau SeleniumBase: falha tecnica em %s; tentativa %d de %d; tipo=%s.",
                    contexto,
                    tentativa,
                    self.tentativas,
                    type(erro).__name__,
                )
                if tentativa == self.tentativas:
                    raise FalhaAoObterPichau(
                        f"Falha do navegador ao ler {contexto}.", codigo="navegador"
                    ) from erro
                self._esperar(tentativa, contexto)
        raise FalhaAoObterPichau(f"A Pichau falhou ao ler {contexto}.", codigo="acesso")

    def _diagnosticar(
        self,
        *,
        contexto: str,
        pagina: int | None,
        tentativa: int,
        fase: str,
        alvo: str,
        fonte: str,
        titulo: str,
        desafio: bool,
    ) -> None:
        """Registra metadados seguros, nunca o HTML, cookies ou headers."""

        conteudo = fonte.casefold()
        manutencao = "site em manutenção" in titulo.casefold()
        bloqueio = "access denied" in titulo.casefold()
        just_a_moment = "just a moment" in titulo.casefold()
        _log.info(
            "Pichau SeleniumBase diagnostico: contexto=%s pagina=%s tentativa=%d "
            "fase=%s url_alvo=%s url_final=%s titulo=%r bytes=%d "
            "next_payload=%s desafio=%s turnstile=%s recaptcha=%s hcaptcha=%s "
            "manutencao=%s access_denied=%s just_a_moment=%s",
            contexto,
            pagina,
            tentativa,
            fase,
            alvo,
            self._url_atual(),
            titulo,
            len(fonte.encode("utf-8")),
            "self.__next_f.push(" in conteudo,
            desafio,
            "cf-turnstile" in conteudo,
            "g-recaptcha" in conteudo,
            "hcaptcha" in conteudo,
            manutencao,
            bloqueio,
            just_a_moment,
        )

    def _url_atual(self) -> str:
        try:
            return str(self._sessao.driver.current_url)
        except Exception:
            return "indisponivel"

    def _exigir_sessao(self) -> None:
        if self._sessao is None:
            raise FalhaAoObterPichau(
                "A fonte SeleniumBase precisa ser usada dentro de um contexto.",
                codigo="navegador",
            )

    def _validar_catalogo(self, fonte: str, pagina: int, url: str) -> None:
        from .extrator import extrair_pagina

        if "self.__next_f.push(" in fonte:
            return
        pagina_extraida = extrair_pagina(
            fonte,
            pagina_esperada=pagina,
            por_pagina=36,
            base_url=url,
        )
        if not pagina_extraida.produtos:
            raise FalhaAoObterPichau(
                "A resposta nao apresentou um catalogo Pichau valido.", codigo="acesso"
            )

    def _tem_desafio(self, fonte: str, titulo: str) -> bool:
        conteudo = fonte.lower()
        return any(marcador in conteudo for marcador in self._MARCADORES_DESAFIO) or any(
            titulo.casefold().startswith(item) for item in self._TITULOS_BLOQUEIO[:1]
        )

    def _tem_bloqueio(self, fonte: str, titulo: str) -> bool:
        conteudo = fonte.lower()
        return any(item in titulo for item in self._TITULOS_BLOQUEIO[1:]) or (
            "just a moment" in titulo and "self.__next_f.push" not in conteudo
        )

    def _esperar(self, tentativa: int, contexto: str) -> None:
        _log.warning(
            "Pichau SeleniumBase: %s; tentativa %d de %d.",
            contexto,
            tentativa,
            self.tentativas,
        )
        self.esperar()


class _ChromeDevTools:
    """Ponte efemera ADB/CDP para ler o DOM do Chrome Android."""

    def __init__(
        self,
        *,
        udid: str | None,
        adb_port: int | None,
        timeout: float,
        porta_local: int = 9222,
    ) -> None:
        if not udid:
            raise FalhaAoObterPichau(
                "PICHAU_ANDROID_UDID e obrigatorio para o CDP Android.", codigo="configuracao"
            )
        self.udid = udid
        self.adb_port = adb_port
        self.timeout = timeout
        self.porta_local = porta_local
        self._aberto = False
        self._ids = count(1)
        self._pagina_aberta = False

    def abrir(self) -> None:
        self._executar(
            ["forward", "--remove", f"tcp:{self.porta_local}"], check=False
        )
        self._executar(
            [
                "forward",
                f"tcp:{self.porta_local}",
                "localabstract:chrome_devtools_remote",
            ]
        )
        self._aberto = True
        self._pagina_aberta = False

    def fechar(self) -> None:
        if not self._aberto:
            return
        self._executar(
            ["forward", "--remove", f"tcp:{self.porta_local}"], check=False
        )
        self._aberto = False

    def obter(self, url: str) -> tuple[str, str, str]:
        try:
            alvo = self._alvo()
        except FalhaPichau:
            # O aparelho pode ter deixado o Chrome em segundo plano ou
            # fechado o processo. Reabre somente o aplicativo, sem Appium.
            self._executar(
                [
                    "shell",
                    "am",
                    "start",
                    "-n",
                    "com.android.chrome/com.google.android.apps.chrome.Main",
                ],
                check=False,
            )
            time.sleep(1.0)
            alvo = self._alvo()
        try:
            import websocket

            socket = websocket.create_connection(
                alvo,
                timeout=self.timeout,
                enable_multithread=False,
                # O endpoint DevTools do Chrome Android rejeita o Origin
                # padrao enviado pelo websocket-client.
                suppress_origin=True,
            )
        except ImportError as erro:
            raise FalhaAoObterPichau(
                "websocket-client nao instalado para o CDP Android.", codigo="configuracao"
            ) from erro
        try:
            self._comando(socket, "Page.enable")
            # A navegacao e a leitura do DOM sao usadas em todas as paginas.
            # O caminho antigo fazia fetch do SSR e podia transportar mais de
            # 1 MB por pagina antes de o extrator conseguir trabalhar.
            resultado = self._navegar_e_ler(socket, url)
            self._pagina_aberta = True
        finally:
            socket.close()
        valor = resultado.get("result", {}).get("result", {}).get("value")
        if not isinstance(valor, dict):
            raise FalhaAoObterPichau(
                "O CDP Android nao devolveu o documento.", codigo="navegador"
            )
        fonte = valor.get("html")
        titulo = valor.get("title")
        url_final = valor.get("url")
        if not all(isinstance(item, str) for item in (fonte, titulo, url_final)):
            raise FalhaAoObterPichau(
                "O CDP Android devolveu campos invalidos.", codigo="navegador"
            )
        return fonte, titulo, url_final

    def _obter_por_fetch(self, socket, url: str) -> dict:
        expressao = f"""
            (async () => {{
                const resposta = await fetch({json.dumps(url)}, {{
                    credentials: "include",
                    cache: "no-store",
                    headers: {{"Accept": "text/html,application/xhtml+xml"}}
                }});
                const documento = new DOMParser().parseFromString(
                    await resposta.text(), "text/html"
                );
                // A listagem e SSR/Next.js: nao ha um endpoint JSON publico
                // separado. Parseamos o RSC dentro do Chrome e devolvemos
                // somente os campos consumidos pelo extrator Python. Assim
                // o CDP nao transporta HTML, scripts estaticos ou imagens.
                let catalogo = null;
                for (const script of Array.from(documento.scripts)) {{
                    const conteudo = script.textContent || "";
                    if (!conteudo.includes("self.__next_f.push(")) continue;
                    const encontrado = conteudo.match(
                        /self\\.__next_f\\.push\\((\\[.*\\])\\)\\s*$/s
                    );
                    if (!encontrado) continue;
                    let registro;
                    try {{
                        registro = JSON.parse(encontrado[1]);
                    }} catch (_) {{
                        continue;
                    }}
                    if (!Array.isArray(registro) || typeof registro[1] !== "string") continue;
                    let payload = registro[1];
                    for (let tentativa = 0; tentativa < 3 && !catalogo; tentativa += 1) {{
                        const inicioCategoria = payload.indexOf('{{"category"');
                        const inicioConsulta = payload.indexOf('{{"query"');
                        const inicio = inicioCategoria >= 0 && inicioConsulta >= 0
                            ? Math.min(inicioCategoria, inicioConsulta)
                            : Math.max(inicioCategoria, inicioConsulta);
                        if (inicio < 0) {{
                            payload = payload.replaceAll('\\\\"', '"');
                            continue;
                        }}
                        let profundidade = 0;
                        let emString = false;
                        let escapado = false;
                        for (let posicao = inicio; posicao < payload.length; posicao += 1) {{
                            const caractere = payload[posicao];
                            if (emString) {{
                                if (escapado) escapado = false;
                                else if (caractere === "\\\\") escapado = true;
                                else if (caractere === '"') emString = false;
                                continue;
                            }}
                            if (caractere === '"') emString = true;
                            else if (caractere === '{{') profundidade += 1;
                            else if (caractere === '}}') {{
                                profundidade -= 1;
                                if (profundidade !== 0) continue;
                                try {{
                                    const candidato = JSON.parse(
                                        payload.slice(inicio, posicao + 1)
                                    );
                                    if (candidato?.products?.items instanceof Array) {{
                                        catalogo = candidato;
                                    }}
                                }} catch (_) {{}}
                                break;
                            }}
                        }}
                        if (!catalogo) payload = payload.replaceAll('\\\\"', '"');
                    }}
                    if (catalogo) break;
                }}

                let html = "";
                if (catalogo?.products?.items instanceof Array) {{
                    const campos = [
                        "id", "sku", "name", "url_key", "stock_status",
                        "pichau_prices", "marcas_info", "pichau_prevenda", "amasty_label"
                    ];
                    const itens = catalogo.products.items
                        .filter((item) => item && typeof item === "object")
                        .map((item) => Object.fromEntries(
                            campos
                                .filter((campo) => item[campo] !== undefined)
                                .map((campo) => [campo, item[campo]])
                        ));
                    const minimo = {{
                        category: catalogo.category || {{}},
                        products: {{
                            total_count: catalogo.products.total_count,
                            items: itens
                        }}
                    }};
                    html = `<script>self.__next_f.push(${{JSON.stringify([
                        1, JSON.stringify(minimo)
                    ])}})</script>`;
                }}
                return {{
                    status: resposta.status,
                    html,
                    title: document.title,
                    url: resposta.url
                }};
            }})()
        """
        return self._comando(
            socket,
            "Runtime.evaluate",
            {"expression": expressao, "returnByValue": True, "awaitPromise": True},
        )

    def _navegar_e_ler(self, socket, url: str) -> dict:
        self._comando(socket, "Page.navigate", {"url": url})
        resultado = None
        for _ in range(30):
            time.sleep(0.5)
            # Os cards ja estao no DOM renderizado. Extraimos os campos
            # necessarios dentro do Chrome e devolvemos um script Next minimo,
            # evitando transportar HTML, scripts estaticos ou imagens.
            resultado = self._obter_por_dom(socket)
            valor = resultado.get("result", {}).get("result", {}).get("value")
            # Um self.__next_f.push isolado nao prova que o catalogo foi
            # hidratado; aguarde a estrutura JSON de products/items.
            if self._catalogo_pronto(valor, url):
                break
        return resultado

    def _obter_por_dom(self, socket) -> dict:
        expressao = """
            (() => {
                const moeda = (texto) => {
                    const encontrado = String(texto || "").match(
                        /R\\$\\s*[\\d.\\u00a0]+,\\d{2}/
                    );
                    return encontrado ? encontrado[0].replaceAll("\\u00a0", " ") : null;
                };
                const numeroMoeda = (texto) => {
                    const valor = moeda(texto);
                    if (!valor) return null;
                    const numero = Number(
                        valor.replace("R$", "").replaceAll(" ", "")
                            .replaceAll(".", "").replace(",", ".")
                    );
                    return Number.isFinite(numero) ? numero : null;
                };
                const itens = Array.from(document.querySelectorAll(
                    '[class*="itemsListGrid"] [class*="product_item"]'
                )).map((card) => {
                    const link = card.closest('a[data-cy="list-product"]');
                    const href = link?.href || "";
                    const titulo = card.querySelector('[class*="product_info_title"]');
                    const nome = (titulo?.innerText || card.querySelector("img")?.alt || "")
                        .trim();
                    const pixTexto = card.querySelector('[class*="pixPrice"]')?.innerText || "";
                    const originalTexto = card.querySelector(
                        '[class*="dePorPrice"]'
                    )?.innerText || "";
                    const parcelaTexto = card.querySelector(
                        '[class*="priceParcelado"]'
                    )?.innerText || "";
                    const parcelado = card.querySelector('[class*="parcelado"]')?.innerText || "";
                    const parcelasMatch = parcelado.match(/(\\d+)x/);
                    const parcelas = parcelasMatch ? Number(parcelasMatch[1]) : null;
                    const parcela = numeroMoeda(parcelaTexto || parcelado);
                    const final = parcela !== null && parcelas ? parcela * parcelas : null;
                    const idMatch = href.match(/-(\\d+)(?:[/?#]|$)/);
                    const etiquetas = Array.from(card.querySelectorAll('[class*="tag"]'))
                        .map((tag) => (tag.innerText || "").trim())
                        .filter(Boolean);
                    const texto = card.innerText || "";
                    return {
                        id: idMatch ? Number(idMatch[1]) : null,
                        sku: null,
                        name: nome,
                        url_key: href,
                        stock_status: /esgotado|indispon[ií]vel/i.test(texto)
                            ? "OUT_OF_STOCK" : "IN_STOCK",
                        pichau_prices: {
                            base_price: numeroMoeda(originalTexto),
                            avista: numeroMoeda(pixTexto),
                            final_price: final,
                            max_installments: parcelas,
                            min_installment_price: parcela
                        },
                        marcas_info: {},
                        pichau_prevenda: /pr[eé]-?venda/i.test(texto),
                        amasty_label: {
                            product_labels: etiquetas.map((label) => ({label}))
                        }
                    };
                }).filter((item) => item.name && item.url_key);
                const exibicao = (document.body?.innerText || "").match(
                    /Exibindo\\s+([\\d.]+)-([\\d.]+)\\s+de\\s+([\\d.]+)\\s+resultados/i
                );
                const total = exibicao
                    ? Number(exibicao[3].replaceAll(".", ""))
                    : itens.length;
                let html = "";
                if (itens.length) {
                    const minimo = {
                        category: {},
                        products: {total_count: total, items: itens}
                    };
                    html = `<script>self.__next_f.push(${
                        JSON.stringify([1, JSON.stringify(minimo)])
                    })</script>`;
                }
                return {
                    status: 200,
                    html,
                    title: document.title,
                    url: location.href,
                    item_count: itens.length,
                    total_count: total,
                    range_start: exibicao ? Number(exibicao[1].replaceAll(".", "")) : null,
                    range_end: exibicao ? Number(exibicao[2].replaceAll(".", "")) : null
                };
            })()
        """
        return self._comando(
            socket,
            "Runtime.evaluate",
            {"expression": expressao, "returnByValue": True, "awaitPromise": True},
        )

    @staticmethod
    def _expressao_documento() -> str:
        return """
            (() => {
                const scripts = Array.from(document.scripts)
                    .filter((script) => script.textContent.includes("self.__next_f.push("))
                    .map((script) => `<script>${script.textContent}</script>`)
                    .join("");
                return {
                    html: scripts || (document.documentElement
                        ? document.documentElement.outerHTML : ""),
                    title: document.title,
                    url: location.href
                };
            })()
        """

    @staticmethod
    def _resposta_catalogo_suficiente(valor: object) -> bool:
        if not isinstance(valor, dict) or not isinstance(valor.get("html"), str):
            return False
        html = valor["html"]
        tem_produtos = '"products":' in html or '\\"products\\":' in html
        tem_itens = '"items":' in html or '\\"items\\":' in html
        return tem_produtos and tem_itens

    @classmethod
    def _catalogo_pronto(cls, valor: object, alvo: str) -> bool:
        if not cls._resposta_catalogo_suficiente(valor) or not cls._url_corresponde(
            valor, alvo
        ):
            return False
        if not isinstance(valor, dict):
            return False
        try:
            itens = int(valor.get("item_count", 0))
            total = int(valor.get("total_count", 0))
            pagina = int(parse_qs(urlparse(alvo).query).get("page", ["1"])[0])
            faixa_inicio = int(valor.get("range_start", 0))
            faixa_fim = int(valor.get("range_end", 0))
        except (TypeError, ValueError):
            return False
        esperado_inicio = (pagina - 1) * 36 + 1
        esperado_fim = min(pagina * 36, total)
        if (faixa_inicio, faixa_fim) != (esperado_inicio, esperado_fim):
            return False
        return itens >= 36 or pagina * 36 >= total

    @staticmethod
    def _url_corresponde(valor: object, alvo: str) -> bool:
        if not isinstance(valor, dict) or not isinstance(valor.get("url"), str):
            return False
        atual = urlparse(valor["url"])
        esperado = urlparse(alvo)
        if atual.scheme != esperado.scheme or atual.netloc != esperado.netloc:
            return False
        if atual.path.rstrip("/") != esperado.path.rstrip("/"):
            return False
        return parse_qs(atual.query).get("page", [None]) == parse_qs(esperado.query).get(
            "page", [None]
        )

    def _alvo(self) -> str:
        try:
            resposta = requests.get(
                f"http://127.0.0.1:{self.porta_local}/json",
                timeout=self.timeout,
            )
        except requests.RequestException as erro:
            raise FalhaAoObterPichau(
                "O endpoint DevTools do Chrome Android nao respondeu.", codigo="navegador"
            ) from erro
        resposta.raise_for_status()
        for item in resposta.json():
            if item.get("type") == "page" and isinstance(item.get("webSocketDebuggerUrl"), str):
                return item["webSocketDebuggerUrl"]
        raise FalhaAoObterPichau(
            "O Chrome Android nao apresentou uma pagina DevTools.", codigo="navegador"
        )

    def _comando(self, socket, metodo: str, parametros: dict | None = None) -> dict:
        identificador = next(self._ids)
        socket.send(
            json.dumps({"id": identificador, "method": metodo, "params": parametros or {}})
        )
        while True:
            mensagem = socket.recv()
            if isinstance(mensagem, bytes):
                mensagem = mensagem.decode("utf-8")
            resposta = json.loads(mensagem)
            if resposta.get("id") != identificador:
                continue
            if "error" in resposta:
                raise FalhaAoObterPichau(
                    "O Chrome Android recusou um comando CDP.", codigo="navegador"
                )
            return resposta

    def _executar(self, argumentos: list[str], *, check: bool = True) -> None:
        comando = ["adb"]
        if self.adb_port is not None:
            comando.extend(["-P", str(self.adb_port)])
        comando.extend(["-s", self.udid, *argumentos])
        try:
            subprocess.run(
                comando,
                check=check,
                capture_output=True,
                timeout=self.timeout,
            )
        except (OSError, subprocess.SubprocessError) as erro:
            raise FalhaAoObterPichau(
                "Nao foi possivel preparar a ponte ADB do Chrome Android.",
                codigo="navegador",
            ) from erro


class FontePichauAndroid:
    """Abre o Chrome Android por Appium/CDP e devolve somente o HTML em memoria.

    Este adaptador e deliberadamente separado do SeleniumBase usado pelo
    workflow hospedado. O servidor Appium deve estar no proprio aparelho; a
    URL remota nao e aceita para evitar transformar a credencial do coletor em
    um cliente de um servidor WebDriver externo. O UiAutomator2 abre o Chrome
    como aplicativo nativo. A leitura do DOM usa o DevTools local, pois o
    ChromeDriver oficial nao publica binario Linux ARM32 para este aparelho.
    """

    _TITULOS_BLOQUEIO = ("just a moment", "site em manutenção", "access denied")
    _MARCADORES_DESAFIO = ("cf-turnstile", "g-recaptcha", "hcaptcha")

    def __init__(
        self,
        url_categoria: str = URL_CATEGORIA,
        *,
        appium_url: str = "http://127.0.0.1:4723",
        device_name: str = "Android",
        udid: str | None = None,
        adb_port: int | None = None,
        tentativas: int = 3,
        timeout: float = 60.0,
        tamanho_maximo: int = TAMANHO_MAXIMO,
        dormir: Callable[[float], None] = time.sleep,
        criar_driver: Callable[..., object] | None = None,
        cdp: _ChromeDevTools | None = None,
    ) -> None:
        self.url_categoria = url_categoria
        self.appium_url = self._validar_url_appium(appium_url)
        self.device_name = device_name
        self.udid = udid
        if adb_port is not None and not 1 <= adb_port <= 65535:
            raise FalhaAoObterPichau("Porta ADB invalida.", codigo="configuracao")
        self.adb_port = adb_port
        self.tentativas = max(1, min(3, tentativas))
        self.timeout = timeout
        self.tamanho_maximo = tamanho_maximo
        self.dormir = dormir
        self.criar_driver = criar_driver
        self.cdp = cdp
        self._driver = None

    def __enter__(self) -> FontePichauAndroid:
        try:
            if self.criar_driver is not None:
                self._driver = self._abrir_driver()
                self._driver.set_page_load_timeout(self.timeout)
            else:
                # O Chrome ja e o executor da coleta. Evitar criar uma nova
                # sessao UiAutomator2 a cada job remove minutos de boot no
                # ARM32; Appium continua disponivel para configuracao e
                # diagnostico, mas nao bloqueia o caminho CDP recorrente.
                if self.cdp is None:
                    self.cdp = _ChromeDevTools(
                        udid=self.udid,
                        adb_port=self.adb_port,
                        timeout=self.timeout,
                    )
                self.cdp.abrir()
        except Exception as erro:
            self._encerrar_driver()
            if isinstance(erro, FalhaPichau):
                raise
            raise FalhaAoObterPichau(
                "Nao foi possivel iniciar o navegador Android por Appium.", codigo="navegador"
            ) from erro
        return self

    def __exit__(self, tipo, valor, traceback) -> None:
        try:
            if self.cdp is not None:
                self.cdp.fechar()
        except FalhaPichau as erro:
            _log.warning(
                "Pichau Android: falha ao remover ponte CDP; codigo=%s.", erro.codigo
            )
        finally:
            self._encerrar_driver()

    def pagina(self, pagina: int) -> str:
        if pagina < 1:
            raise FalhaAoObterPichau("Numero de pagina invalido.", codigo="pagina")
        url = self._url_pagina(pagina)
        return self._obter(url, "catalogo", pagina)

    def detalhe(self, url_produto: str) -> str:
        analisada = urlparse(url_produto)
        if analisada.scheme != "https" or analisada.hostname not in HOSTES_VALIDOS:
            raise FalhaAoObterPichau("URL de produto fora do dominio permitido.", codigo="url")
        return self._obter(url_produto, "produto", None)

    def esperar(self, _segundos: float | None = None) -> None:
        """Aplica o intervalo autorizado entre paginas ou tentativas."""

        self.dormir(random.uniform(1.0, 2.0))

    def _abrir_driver(self):
        if self.criar_driver is not None:
            capacidades = {
                "platformName": "Android",
                "appium:automationName": "UiAutomator2",
                "appium:deviceName": self.device_name,
                "appium:appPackage": "com.android.chrome",
                "appium:appActivity": "com.google.android.apps.chrome.Main",
                "appium:noReset": True,
                "appium:newCommandTimeout": max(120, int(self.timeout * 2)),
            }
            if self.udid:
                capacidades["appium:udid"] = self.udid
            if self.adb_port is not None:
                capacidades["appium:adbPort"] = self.adb_port
            return self.criar_driver(self.appium_url, capacidades)

        try:
            from appium import webdriver
            from appium.options.android import UiAutomator2Options
        except ImportError as erro:
            raise FalhaAoObterPichau(
                "Appium-Python-Client nao instalado para o modo Android.", codigo="configuracao"
            ) from erro

        capacidades = {
            "platformName": "Android",
            "appium:automationName": "UiAutomator2",
            "appium:deviceName": self.device_name,
            "appium:appPackage": "com.android.chrome",
            "appium:appActivity": "com.google.android.apps.chrome.Main",
            "appium:noReset": True,
            "appium:newCommandTimeout": max(120, int(self.timeout * 2)),
        }
        if self.udid:
            capacidades["appium:udid"] = self.udid
        if self.adb_port is not None:
            capacidades["appium:adbPort"] = self.adb_port
        opcoes = UiAutomator2Options()
        opcoes.load_capabilities(capacidades)
        return webdriver.Remote(command_executor=self.appium_url, options=opcoes)

    def _obter(self, url: str, contexto: str, pagina: int | None) -> str:
        self._exigir_driver()
        for tentativa in range(1, self.tentativas + 1):
            try:
                if self.cdp is None:
                    self._driver.get(url)
                    self.dormir(3.0)
                    fonte = self._driver.page_source
                    titulo = str(getattr(self._driver, "title", ""))
                else:
                    fonte, titulo, url_final = self.cdp.obter(url)
                if not isinstance(fonte, str):
                    raise FalhaAoObterPichau(
                        "O navegador Android nao devolveu HTML.", codigo="navegador"
                    )
                desafio = self._tem_desafio(fonte, titulo)
                self._diagnosticar(
                    contexto=contexto,
                    pagina=pagina,
                    tentativa=tentativa,
                    alvo=url,
                    fonte=fonte,
                    titulo=titulo,
                    desafio=desafio,
                    url_final=url_final if self.cdp is not None else self._url_atual(),
                )
                if desafio or self._tem_bloqueio(fonte, titulo):
                    raise FalhaAoObterPichau(
                        "A Pichau exibiu um bloqueio ou pagina de manutencao.", codigo="acesso"
                    )
                if len(fonte.encode("utf-8")) > self.tamanho_maximo:
                    raise FalhaAoObterPichau(
                        "Resposta da Pichau excede o limite seguro.", codigo="resposta_grande"
                    )
                if contexto == "catalogo":
                    self._validar_catalogo(fonte, pagina or 1, url)
                return fonte
            except FalhaPichau:
                if tentativa == self.tentativas:
                    raise
                self._esperar(tentativa, contexto)
            except Exception as erro:
                _log.warning(
                    "Pichau Android: falha tecnica em %s; tentativa %d de %d; tipo=%s.",
                    contexto,
                    tentativa,
                    self.tentativas,
                    type(erro).__name__,
                )
                if tentativa == self.tentativas:
                    raise FalhaAoObterPichau(
                        f"Falha do navegador Android ao ler {contexto}.", codigo="navegador"
                    ) from erro
                self._esperar(tentativa, contexto)
        raise FalhaAoObterPichau(f"A Pichau falhou ao ler {contexto}.", codigo="acesso")

    def _diagnosticar(
        self,
        *,
        contexto: str,
        pagina: int | None,
        tentativa: int,
        alvo: str,
        fonte: str,
        titulo: str,
        desafio: bool,
        url_final: str | None = None,
    ) -> None:
        """Registra apenas metadados, nunca HTML, cookies ou cabecalhos."""

        conteudo = fonte.casefold()
        _log.info(
            "Pichau Android diagnostico: contexto=%s pagina=%s tentativa=%d "
            "url_alvo=%s url_final=%s titulo=%r bytes=%d next_payload=%s "
            "desafio=%s turnstile=%s recaptcha=%s hcaptcha=%s manutencao=%s "
            "access_denied=%s just_a_moment=%s",
            contexto,
            pagina,
            tentativa,
            alvo,
            url_final if url_final is not None else self._url_atual(),
            titulo,
            len(fonte.encode("utf-8")),
            "self.__next_f.push(" in conteudo,
            desafio,
            "cf-turnstile" in conteudo,
            "g-recaptcha" in conteudo,
            "hcaptcha" in conteudo,
            "site em manutenção" in titulo.casefold(),
            "access denied" in titulo.casefold(),
            "just a moment" in titulo.casefold(),
        )

    def _validar_catalogo(self, fonte: str, pagina: int, url: str) -> None:
        from .extrator import extrair_pagina

        pagina_extraida = extrair_pagina(
            fonte,
            pagina_esperada=pagina,
            por_pagina=36,
            base_url=url,
        )
        if not pagina_extraida.produtos:
            raise FalhaAoObterPichau(
                "A resposta nao apresentou um catalogo Pichau valido.", codigo="acesso"
            )

    def _tem_desafio(self, fonte: str, titulo: str) -> bool:
        conteudo = fonte.lower()
        return any(marcador in conteudo for marcador in self._MARCADORES_DESAFIO) or any(
            titulo.casefold().startswith(item) for item in self._TITULOS_BLOQUEIO[:1]
        )

    def _tem_bloqueio(self, fonte: str, titulo: str) -> bool:
        conteudo = fonte.lower()
        return any(item in titulo.lower() for item in self._TITULOS_BLOQUEIO[1:]) or (
            "just a moment" in titulo.lower() and "self.__next_f.push(" not in conteudo
        )

    def _esperar(self, tentativa: int, contexto: str) -> None:
        _log.warning(
            "Pichau Android: %s; tentativa %d de %d.", contexto, tentativa, self.tentativas
        )
        self.esperar()

    def _url_pagina(self, pagina: int) -> str:
        if pagina == 1:
            return self.url_categoria
        separador = "&" if "?" in self.url_categoria else "?"
        return f"{self.url_categoria}{separador}{urlencode({'page': pagina})}"

    def _url_atual(self) -> str:
        try:
            return str(self._driver.current_url)
        except Exception:
            return "indisponivel"

    def _exigir_driver(self) -> None:
        if self._driver is None and self.cdp is None:
            raise FalhaAoObterPichau(
                "A fonte Android precisa ser usada dentro de um contexto.", codigo="navegador"
            )

    def _encerrar_driver(self) -> None:
        driver, self._driver = self._driver, None
        if driver is None:
            return
        try:
            driver.quit()
        except Exception as erro:
            _log.warning(
                "Pichau Android: falha ao encerrar navegador; tipo=%s.", type(erro).__name__
            )

    @staticmethod
    def _validar_url_appium(url: str) -> str:
        analisada = urlparse(url)
        if (
            analisada.scheme not in {"http", "https"}
            or analisada.hostname not in {"127.0.0.1", "localhost", "::1"}
            or analisada.username
            or analisada.password
        ):
            raise FalhaAoObterPichau(
                "PICHAU_APPIUM_URL deve apontar para o Appium local.", codigo="configuracao"
            )
        return url.rstrip("/")


class RepositorioPichauPostgres:
    """Publica somente snapshots completos; falhas preservam o ultimo snapshot."""

    def __init__(self, url: str, *, conectar=None) -> None:
        if not url:
            raise FalhaAoGuardarPichau("DATABASE_URL nao configurada.", codigo="configuracao")
        self.url = url
        if conectar is None:
            import psycopg

            conectar = psycopg.connect
        self.conectar = conectar

    def iniciar_execucao(self, momento: datetime, versao: str) -> int:
        try:
            with self.conectar(self.url) as conexao, conexao.cursor() as cursor:
                cursor.execute(
                    """
                        INSERT INTO pichau_execucao (iniciada_em, estado, versao)
                        VALUES (%s, 'iniciada', %s) RETURNING id
                        """,
                    (momento, versao),
                )
                return int(cursor.fetchone()[0])
        except Exception as erro:
            raise FalhaAoGuardarPichau(
                "Nao foi possivel iniciar a execucao Pichau.", codigo="banco"
            ) from erro

    def publicar(
        self, execucao_id: int, produtos: tuple[PichauProduto, ...], resumo: ResumoColetaPichau
    ) -> None:
        concluida = resumo.concluida_em
        try:
            with self.conectar(self.url) as conexao, conexao.cursor() as cursor:
                for produto in produtos:
                    cursor.execute(
                        """
                            INSERT INTO pichau_produto (
                              id_externo, sku, nome, nome_busca, marca, marca_busca,
                              categoria_externa,
                              url_produto, disponibilidade, presente_no_catalogo, visto_em
                            ) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,TRUE,%s)
                            ON CONFLICT (id_externo) DO UPDATE SET
                              sku=EXCLUDED.sku, nome=EXCLUDED.nome, nome_busca=EXCLUDED.nome_busca,
                              marca=EXCLUDED.marca, categoria_externa=EXCLUDED.categoria_externa,
                              url_produto=EXCLUDED.url_produto,
                              disponibilidade=EXCLUDED.disponibilidade,
                              presente_no_catalogo=TRUE, visto_em=EXCLUDED.visto_em,
                              atualizado_em=now()
                            RETURNING id
                            """,
                        (
                            produto.id_externo,
                            produto.sku,
                            produto.nome,
                            _busca(produto.nome),
                            produto.marca,
                            _busca(produto.marca or ""),
                            produto.categoria_externa,
                            produto.url_produto,
                            produto.disponibilidade,
                            concluida,
                        ),
                    )
                    produto_id = int(cursor.fetchone()[0])
                    cursor.execute(
                        """
                            INSERT INTO pichau_medicao (
                              execucao_id, produto_id, momento, preco_original,
                              preco_original_texto,
                              preco_pix, preco_pix_texto, desconto_pix, desconto_pix_texto,
                              preco_cartao, preco_cartao_texto, parcelamento, valor_parcela_texto,
                              sem_juros, estoque_texto, etiquetas
                            ) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
                            """,
                        (
                            execucao_id,
                            produto_id,
                            concluida,
                            produto.preco_original_valor,
                            produto.preco_original_texto,
                            produto.preco_pix_valor,
                            produto.preco_pix_texto,
                            produto.desconto_pix_valor,
                            produto.desconto_pix_texto,
                            produto.preco_cartao_valor,
                            produto.preco_cartao_texto,
                            produto.parcelamento,
                            produto.valor_parcela_texto,
                            produto.sem_juros,
                            produto.estoque_texto,
                            list(produto.etiquetas),
                        ),
                    )
                cursor.execute(
                    "UPDATE pichau_produto SET presente_no_catalogo=FALSE, "
                    "atualizado_em=now() WHERE categoria_externa='PC Gamer' "
                    "AND id_externo <> ALL(%s)",
                    ([produto.id_externo for produto in produtos],),
                )
                cursor.execute(
                    """
                        UPDATE pichau_execucao
                           SET concluida_em=%s, estado='sucesso', qualidade=%s,
                               total_declarado=%s, itens_lidos=%s, itens_unicos=%s,
                               duplicados=%s, paginas=%s, tentativas=%s
                         WHERE id=%s
                        """,
                    (
                        concluida,
                        "degradada" if resumo.degradada else "completa",
                        resumo.total_declarado,
                        resumo.itens_lidos,
                        resumo.itens_unicos,
                        resumo.duplicados,
                        resumo.paginas,
                        resumo.tentativas,
                        execucao_id,
                    ),
                )
                cursor.execute(
                    "DELETE FROM pichau_medicao WHERE momento < %s",
                    (concluida - timedelta(days=30),),
                )
        except Exception as erro:
            raise FalhaAoGuardarPichau(
                "Nao foi possivel publicar o snapshot Pichau.", codigo="banco"
            ) from erro

    def falhar(self, execucao_id: int, codigo: str) -> None:
        try:
            with self.conectar(self.url) as conexao, conexao.cursor() as cursor:
                cursor.execute(
                    "UPDATE pichau_execucao SET concluida_em=now(), "
                    "estado=CASE WHEN %s = 'parcial' THEN 'parcial' ELSE 'falha' END, "
                    "codigo_falha=%s WHERE id=%s",
                    (codigo[:80], codigo[:80], execucao_id),
                )
        except Exception as erro:
            raise FalhaAoGuardarPichau(
                "Nao foi possivel registrar falha Pichau.", codigo="banco"
            ) from erro


def _busca(valor: str) -> str:
    import unicodedata

    return " ".join(
        unicodedata.normalize("NFKD", valor).encode("ascii", "ignore").decode().lower().split()
    )


def agora_utc() -> datetime:
    return datetime.now(UTC)
