"""Adaptadores HTTP, SeleniumBase e Postgres do coletor Pichau."""

from __future__ import annotations

import base64
import json
import logging
import random
import re
import subprocess
import time
from collections.abc import Callable
from concurrent.futures import ThreadPoolExecutor
from datetime import UTC, datetime, timedelta
from itertools import count
from urllib.parse import parse_qs, urlencode, urlparse

import requests

from .diagnostico import codigo_operacional, validar_diagnostico
from .modelos import PichauProduto, ResumoColetaPichau
from .portas import FalhaAoGuardarPichau, FalhaAoObterPichau, FalhaPichau

_log = logging.getLogger(__name__)

URL_CATEGORIA = "https://www.pichau.com.br/computadores/pichau-gamer"
URL_ROBOTS = "https://www.pichau.com.br/robots.txt"
USER_AGENT = "radar-beneficios-pichau/1 (coleta publica; contato no repositorio)"
TAMANHO_MAXIMO = 8 * 1024 * 1024
STATUS_RETRY = {408, 425, 429}
HOSTES_VALIDOS = {"pichau.com.br", "www.pichau.com.br"}
ESTRATEGIAS_LEITURA_ANDROID = {"dom", "fetch", "rede"}
ORDENACOES_ANDROID = {"name-asc", "name-desc", "price-asc", "price-desc"}
TAMANHO_LOTE_PUBLICACAO = 100
# O servidor da Pichau pode levar mais de 18 s para entregar o SSR de uma
# pagina de 200 itens. O timeout continua finito, mas deixa a leitura rapida
# por fetch concluir antes de cair no DOM, que e bem mais caro no Android.
LIMITE_FETCH_ANDROID_MS = 50000
# Chrome Android pode publicar uma resposta DevTools parcial durante o boot.
# Aguarde a estabilizacao antes de acionar uma nova sessao UiAutomator2.
LIMITE_INICIALIZACAO_DEVTOOLS_ANDROID_S = 20.0
RECURSOS_BLOQUEADOS_ANDROID = (
    "*.avif",
    "*.gif",
    "*.jpeg",
    "*.jpg",
    "*.png",
    "*.svg",
    "*.webp",
    "*.woff",
    "*.woff2",
    "*criteo*",
    "*doubleclick*",
    "*facebook*",
    "*freshchat*",
    "*google-analytics*",
    "*googlesyndication*",
    "*googletagmanager*",
    "*useinsider*",
)


def url_para_log(url: str | None) -> str:
    """Retorna somente origem/caminho permitido, sem query ou credenciais."""

    if not isinstance(url, str) or not url:
        return "indisponivel"
    analisada = urlparse(url)
    if (
        analisada.scheme != "https"
        or analisada.hostname not in HOSTES_VALIDOS
        or analisada.username
        or analisada.password
    ):
        return "dominio-nao-permitido"
    return f"https://{analisada.hostname}{analisada.path or '/'}"


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
            url_para_log(alvo),
            url_para_log(self._url_atual()),
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

    _TAREFA_RECENTE = re.compile(r"Task\{[^}\n]* #([1-9][0-9]*) type=standard\b")
    _MAX_TAREFAS_RECENTES = 64

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
        self._executar(["forward", "--remove", f"tcp:{self.porta_local}"], check=False)
        self._executar(
            [
                "forward",
                f"tcp:{self.porta_local}",
                "localabstract:chrome_devtools_remote",
            ]
        )
        self._aberto = True
        self._pagina_aberta = False

    def verificar(self) -> None:
        """Confirma que o Chrome publicou uma página DevTools acessível."""

        self._alvo()

    def abrir_url(self, url: str) -> None:
        """Abre uma URL Pichau no Chrome quando a sessão não tem uma aba."""

        analisada = urlparse(url)
        if analisada.scheme != "https" or analisada.hostname not in HOSTES_VALIDOS:
            raise FalhaAoObterPichau("URL Android fora do dominio permitido.", codigo="url")
        self._executar(
            [
                "shell",
                "am",
                "start",
                "-a",
                "android.intent.action.VIEW",
                "-d",
                url,
                "com.android.chrome",
            ]
        )

    def forcar_parada(self, *, confirmar: bool = False) -> None:
        """Encerra o Chrome e, quando pedido, confirma que o processo sumiu."""

        for tentativa in range(1, 4):
            self._executar(
                ["shell", "am", "force-stop", "com.android.chrome"],
                check=False,
            )
            if not confirmar:
                return
            resultado = self._executar(
                ["shell", "pidof", "com.android.chrome"],
                check=False,
            )
            if resultado.returncode != 0 or not resultado.stdout.strip():
                return
            if tentativa < 3:
                time.sleep(0.5)
        raise FalhaAoObterPichau(
            "O Chrome Android permaneceu ativo depois da coleta.", codigo="navegador"
        )

    def limpar_tarefas_recentes(self, *, confirmar: bool = False) -> None:
        """Remove tarefas recentes como o botão Samsung ``Fechar tudo``."""

        for tentativa in range(1, 4):
            tarefas = self._listar_tarefas_recentes()
            for tarefa_id in tarefas:
                self._executar(
                    ["shell", "am", "stack", "remove", str(tarefa_id)],
                    check=False,
                )
            self._executar(
                ["shell", "input", "keyevent", "KEYCODE_HOME"],
                check=False,
            )
            if not confirmar or not self._listar_tarefas_recentes():
                return
            if tentativa < 3:
                time.sleep(0.5)
        raise FalhaAoObterPichau(
            "O Android manteve tarefas recentes depois da limpeza.",
            codigo="navegador",
        )

    def bloquear_tela(self) -> None:
        """Deixa a Home protegida pela tela bloqueada ao terminar."""

        self._executar(["shell", "input", "keyevent", "KEYCODE_SLEEP"])

    def _listar_tarefas_recentes(self) -> tuple[int, ...]:
        resultado = self._executar(["shell", "dumpsys", "activity", "recents"])
        saida = resultado.stdout
        if isinstance(saida, bytes):
            texto = saida.decode("utf-8", errors="replace")
        else:
            texto = str(saida or "")
        tarefas = tuple(dict.fromkeys(int(item) for item in self._TAREFA_RECENTE.findall(texto)))
        if len(tarefas) > self._MAX_TAREFAS_RECENTES:
            raise FalhaAoObterPichau(
                "O Android retornou tarefas recentes demais para limpar.",
                codigo="navegador",
            )
        return tarefas

    def aguardar_pagina(self, tentativas: int = 15, intervalo: float = 1.0) -> None:
        """Aguarda a aba DevTools depois de relançar o Chrome pelo Appium."""

        ultimo_erro: FalhaPichau | None = None
        for tentativa in range(max(1, tentativas)):
            try:
                self.verificar()
                return
            except FalhaPichau as erro:
                ultimo_erro = erro
                if tentativa + 1 < tentativas:
                    time.sleep(intervalo)
        if ultimo_erro is not None:
            raise ultimo_erro
        raise FalhaAoObterPichau(
            "O Chrome Android nao apresentou uma pagina DevTools.", codigo="navegador"
        )

    def fechar(self) -> None:
        if not self._aberto:
            return
        self._executar(["forward", "--remove", f"tcp:{self.porta_local}"], check=False)
        self._aberto = False

    def obter(self, url: str) -> tuple[str, str, str]:
        socket = self._abrir_socket()
        try:
            self._preparar_pagina(socket)
            # A navegacao e a leitura do DOM sao usadas em todas as paginas.
            # O caminho antigo fazia fetch do SSR e podia transportar mais de
            # 1 MB por pagina antes de o extrator conseguir trabalhar.
            resultado = self._navegar_e_ler(socket, url)
            self._pagina_aberta = True
        finally:
            socket.close()
        valor = resultado.get("result", {}).get("result", {}).get("value")
        if not isinstance(valor, dict):
            raise FalhaAoObterPichau("O CDP Android nao devolveu o documento.", codigo="navegador")
        fonte = valor.get("html")
        titulo = valor.get("title")
        url_final = valor.get("url")
        if not all(isinstance(item, str) for item in (fonte, titulo, url_final)):
            raise FalhaAoObterPichau("O CDP Android devolveu campos invalidos.", codigo="navegador")
        return fonte, titulo, url_final

    def obter_fetch(self, url: str) -> tuple[str, str, str]:
        """Le o payload SSR pela sessao atual, sem renderizar a pagina inteira."""

        socket = self._abrir_socket(timeout=min(self.timeout, LIMITE_FETCH_ANDROID_MS / 1000 + 2.0))
        try:
            self._preparar_pagina(socket)
            resultado = self._obter_por_fetch(socket, url)
        except Exception:
            self._interromper_execucao()
            raise
        finally:
            socket.close()
        valor = resultado.get("result", {}).get("result", {}).get("value")
        if not isinstance(valor, dict):
            raise FalhaAoObterPichau(
                "O CDP Android nao devolveu o payload SSR.", codigo="navegador"
            )
        status = valor.get("status")
        if not isinstance(status, int) or status < 200 or status >= 300:
            codigo = (
                "http_transitorio"
                if isinstance(status, int) and (status in STATUS_RETRY or status >= 500)
                else "acesso"
                if status in {401, 403}
                else "http"
            )
            raise FalhaAoObterPichau(
                f"A leitura SSR respondeu HTTP {status}.",
                codigo=codigo,
                status_http=status if isinstance(status, int) else None,
            )
        if not self._catalogo_pronto(valor, url):
            raise FalhaAoObterPichau(
                "A leitura SSR nao apresentou um catalogo completo.",
                codigo="catalogo_incompleto",
            )
        fonte = valor.get("html")
        titulo = valor.get("title")
        url_final = valor.get("url")
        if not all(isinstance(item, str) for item in (fonte, titulo, url_final)):
            raise FalhaAoObterPichau(
                "O CDP Android devolveu campos SSR invalidos.", codigo="navegador"
            )
        return fonte, titulo, url_final

    def obter_fetch_concorrente(self, urls: list[str]) -> list[tuple[str, str, str]]:
        """Busca varias paginas SSR em paralelo no mesmo Chrome."""

        if not urls:
            return []
        with ThreadPoolExecutor(max_workers=min(5, len(urls))) as executor:
            futuros = [executor.submit(self.obter_fetch, url) for url in urls]
            return [futuro.result() for futuro in futuros]

    def obter_rede(self, url: str) -> tuple[str, str, str]:
        """Le a resposta SSR antes de o Chrome terminar de montar o DOM."""

        socket = self._abrir_socket()
        try:
            self._preparar_pagina(socket)
            resultado = self._navegar_e_obter_resposta(socket, url)
        finally:
            socket.close()
        fonte = resultado.get("html")
        titulo = resultado.get("title")
        url_final = resultado.get("url")
        try:
            status = int(resultado.get("status", 0))
        except (TypeError, ValueError):
            status = 0
        if status < 200 or status >= 300:
            codigo = (
                "http_transitorio"
                if status in STATUS_RETRY or status >= 500
                else "acesso"
                if status in {401, 403}
                else "http"
            )
            raise FalhaAoObterPichau(
                f"A resposta de rede recebeu HTTP {status}.",
                codigo=codigo,
                status_http=status or None,
            )
        if not all(isinstance(item, str) for item in (fonte, titulo, url_final)):
            raise FalhaAoObterPichau(
                "O CDP Android nao devolveu a resposta de rede.", codigo="navegador"
            )
        return fonte, titulo, url_final

    def _preparar_pagina(self, socket) -> None:
        """Mantem a pagina ativa e evita recursos que nao entram no catalogo."""

        self._comando(socket, "Page.enable")
        # O Android congela timers e algumas requisicoes de uma aba que ficou
        # atras do Termux. Isso fazia o fetch expirar e deixava o DOM muito
        # lento. A coleta pode trazer o Chrome para frente sem toque manual.
        self._comando(socket, "Page.bringToFront")
        self._comando(socket, "Network.enable")
        self._comando(socket, "Network.setCacheDisabled", {"cacheDisabled": True})
        self._comando(
            socket,
            "Network.setBlockedURLs",
            {"urls": RECURSOS_BLOQUEADOS_ANDROID},
        )

    def _navegar_e_obter_resposta(self, socket, url: str) -> dict[str, str]:
        identificador_navegacao = next(self._ids)
        socket.send(
            json.dumps(
                {
                    "id": identificador_navegacao,
                    "method": "Page.navigate",
                    "params": {"url": url},
                }
            )
        )
        request_id: str | None = None
        resposta_url: str | None = None
        resposta_status: int | None = None
        limite = time.monotonic() + self.timeout
        while time.monotonic() < limite:
            try:
                mensagem = socket.recv()
            except Exception as erro:
                raise FalhaAoObterPichau(
                    "O CDP Android nao recebeu a resposta da Pichau.", codigo="navegador"
                ) from erro
            if isinstance(mensagem, bytes):
                mensagem = mensagem.decode("utf-8")
            evento = json.loads(mensagem)
            if evento.get("id") == identificador_navegacao:
                if "error" in evento:
                    raise FalhaAoObterPichau(
                        "O Chrome Android recusou a navegacao.", codigo="navegador"
                    )
                continue
            if evento.get("method") == "Network.responseReceived":
                parametros = evento.get("params", {})
                resposta = parametros.get("response", {})
                url_evento = resposta.get("url")
                if (
                    parametros.get("type") == "Document"
                    and isinstance(url_evento, str)
                    and self._url_rede_corresponde(url_evento, url)
                ):
                    request_id = parametros.get("requestId")
                    resposta_url = url_evento
                    resposta_status = resposta.get("status")
            elif (
                evento.get("method") == "Network.loadingFinished"
                and request_id is not None
                and evento.get("params", {}).get("requestId") == request_id
            ):
                corpo = self._comando(
                    socket,
                    "Network.getResponseBody",
                    {"requestId": request_id},
                )
                valor = corpo.get("result", {})
                fonte = valor.get("body")
                if valor.get("base64Encoded") and isinstance(fonte, str):
                    fonte = base64.b64decode(fonte).decode("utf-8")
                if not isinstance(fonte, str):
                    raise FalhaAoObterPichau(
                        "O CDP Android devolveu corpo de rede invalido.", codigo="navegador"
                    )
                titulo = (
                    self._comando(
                        socket,
                        "Runtime.evaluate",
                        {"expression": "document.title", "returnByValue": True},
                    )
                    .get("result", {})
                    .get("result", {})
                    .get("value", "")
                )
                return {
                    "html": fonte,
                    "title": titulo if isinstance(titulo, str) else "",
                    "url": resposta_url or url,
                    "status": str(resposta_status or 0),
                }
        raise FalhaAoObterPichau(
            "A resposta de rede da Pichau excedeu o tempo limite.", codigo="rede"
        )

    @staticmethod
    def _url_rede_corresponde(atual: str, esperado: str) -> bool:
        url_atual = urlparse(atual)
        url_esperado = urlparse(esperado)
        if (
            url_atual.scheme != url_esperado.scheme
            or url_atual.netloc != url_esperado.netloc
            or url_atual.path.rstrip("/") != url_esperado.path.rstrip("/")
        ):
            return False
        return parse_qs(url_atual.query).get("page", [None]) == parse_qs(url_esperado.query).get(
            "page", [None]
        )

    def _abrir_socket(self, *, timeout: float | None = None):
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

            return websocket.create_connection(
                alvo,
                timeout=self.timeout if timeout is None else timeout,
                enable_multithread=False,
                # O endpoint DevTools do Chrome Android rejeita o Origin
                # padrao enviado pelo websocket-client.
                suppress_origin=True,
            )
        except ImportError as erro:
            raise FalhaAoObterPichau(
                "websocket-client nao instalado para o CDP Android.", codigo="configuracao"
            ) from erro

    def _obter_por_fetch(self, socket, url: str) -> dict:
        expressao = f"""
            (async () => {{
                const controlador = new AbortController();
                const limite = setTimeout(() => controlador.abort(), {LIMITE_FETCH_ANDROID_MS});
                let resposta;
                try {{
                    resposta = await fetch({json.dumps(url)}, {{
                        credentials: "include",
                        cache: "no-store",
                        signal: controlador.signal,
                        headers: {{"Accept": "text/html,application/xhtml+xml"}}
                    }});
                }} catch (_) {{
                    return {{
                        status: 599,
                        html: "",
                        title: document.title,
                        url: location.href
                    }};
                }} finally {{
                    clearTimeout(limite);
                }}
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
                const consulta = new URL({json.dumps(url)}).searchParams;
                const pagina = Number(consulta.get("page") || "1");
                const porPagina = Number(consulta.get("pageSize") || "36");
                const total = Number(catalogo?.products?.total_count || 0);
                const itemCount = catalogo?.products?.items instanceof Array
                    ? catalogo.products.items.length : 0;
                const rangeStart = total > 0 ? ((pagina - 1) * porPagina) + 1 : 0;
                const rangeEnd = total > 0 ? Math.min(pagina * porPagina, total) : 0;
                return {{
                    status: resposta.status,
                    html,
                    title: document.title,
                    url: resposta.url,
                    item_count: itemCount,
                    total_count: total,
                    range_start: rangeStart,
                    range_end: rangeEnd
                }};
            }})()
        """
        return self._comando(
            socket,
            "Runtime.evaluate",
            {"expression": expressao, "returnByValue": True, "awaitPromise": True},
        )

    def _interromper_execucao(self) -> None:
        """Cancela uma avaliação CDP que perdeu o prazo, evitando fila no Chrome."""

        try:
            socket = self._abrir_socket(timeout=min(self.timeout, 5.0))
            try:
                self._comando(socket, "Runtime.terminateExecution")
            finally:
                socket.close()
        except Exception:
            _log.debug("Pichau Android: nao foi possivel interromper avaliacao CDP.", exc_info=True)

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
        if resultado is None or not self._catalogo_pronto(
            resultado.get("result", {}).get("result", {}).get("value"), url
        ):
            raise FalhaAoObterPichau(
                "O Chrome Android nao renderizou todos os itens da pagina.",
                codigo="catalogo_incompleto",
            )
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
                    const etiquetas = Array.from(card.querySelectorAll('[class*="tag"]'))
                        .map((tag) => (tag.innerText || "").trim())
                        .filter(Boolean);
                    const texto = card.innerText || "";
                    return {
                        // Sem SKU no DOM, deixe o extrator usar o slug inteiro
                        // da URL como identidade estável.
                        id: null,
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
        if not cls._resposta_catalogo_suficiente(valor) or not cls._url_corresponde(valor, alvo):
            return False
        if not isinstance(valor, dict):
            return False
        try:
            itens = int(valor.get("item_count", 0))
            total = int(valor.get("total_count", 0))
            consulta = parse_qs(urlparse(alvo).query)
            pagina = int(consulta.get("page", ["1"])[0])
            por_pagina = int(consulta.get("pageSize", ["36"])[0])
            faixa_inicio = int(valor.get("range_start", 0))
            faixa_fim = int(valor.get("range_end", 0))
        except (TypeError, ValueError):
            return False
        if por_pagina < 1:
            return False
        esperado_inicio = (pagina - 1) * por_pagina + 1
        esperado_fim = min(pagina * por_pagina, total)
        if (faixa_inicio, faixa_fim) != (esperado_inicio, esperado_fim):
            return False
        quantidade_esperada = max(0, esperado_fim - esperado_inicio + 1)
        return itens >= quantidade_esperada

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
        limite = time.monotonic() + min(self.timeout, LIMITE_INICIALIZACAO_DEVTOOLS_ANDROID_S)
        ultimo_erro: Exception | None = None
        while True:
            try:
                resposta = requests.get(
                    f"http://127.0.0.1:{self.porta_local}/json",
                    timeout=min(self.timeout, 2.0),
                )
                resposta.raise_for_status()
                itens = resposta.json()
                if not isinstance(itens, list):
                    raise ValueError("resposta DevTools nao e uma lista")
                for item in itens:
                    if item.get("type") == "page" and isinstance(
                        item.get("webSocketDebuggerUrl"), str
                    ):
                        return item["webSocketDebuggerUrl"]
                ultimo_erro = FalhaAoObterPichau(
                    "O Chrome Android nao apresentou uma pagina DevTools.", codigo="navegador"
                )
            except (requests.RequestException, ValueError) as erro:
                # Durante a inicializacao o endpoint pode responder com JSON
                # parcial. Isso e transitivo; nao deve abortar a coleta.
                ultimo_erro = erro

            if time.monotonic() >= limite:
                if isinstance(ultimo_erro, FalhaPichau):
                    raise ultimo_erro
                raise FalhaAoObterPichau(
                    "O endpoint DevTools do Chrome Android nao respondeu.",
                    codigo="navegador",
                ) from ultimo_erro
            time.sleep(0.5)

    def _comando(self, socket, metodo: str, parametros: dict | None = None) -> dict:
        identificador = next(self._ids)
        socket.send(json.dumps({"id": identificador, "method": metodo, "params": parametros or {}}))
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

    def _executar(
        self, argumentos: list[str], *, check: bool = True
    ) -> subprocess.CompletedProcess[bytes]:
        comando = ["adb"]
        if self.adb_port is not None:
            comando.extend(["-P", str(self.adb_port)])
        comando.extend(["-s", self.udid, *argumentos])
        try:
            return subprocess.run(
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
    # A listagem Pichau aceita 200 itens e reduz a janela em que o catálogo
    # pode se mover entre páginas durante a coleta.
    _POR_PAGINA = 200

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
        estrategia_leitura: str = "dom",
        ordenacao: str | None = None,
        observar_diagnostico: Callable[[dict[str, object]], None] | None = None,
    ) -> None:
        self.url_categoria = url_categoria
        self.por_pagina = self._POR_PAGINA
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
        self.observar_diagnostico = observar_diagnostico
        self._driver = None
        self._paginas_prefetch: dict[int, str] = {}
        estrategia = estrategia_leitura.strip().lower()
        if estrategia not in ESTRATEGIAS_LEITURA_ANDROID:
            raise FalhaAoObterPichau(
                "PICHAU_ESTRATEGIA_LEITURA deve ser dom, fetch ou rede.", codigo="configuracao"
            )
        self.estrategia_leitura = estrategia
        ordenacao_normalizada = (ordenacao or "").strip().lower()
        if ordenacao_normalizada and ordenacao_normalizada not in ORDENACOES_ANDROID:
            raise FalhaAoObterPichau(
                "PICHAU_ANDROID_ORDENACAO deve ser name-asc, name-desc, price-asc ou price-desc.",
                codigo="configuracao",
            )
        self.ordenacao = ordenacao_normalizada or None

    def __enter__(self) -> FontePichauAndroid:
        try:
            if self.cdp is None:
                self.cdp = _ChromeDevTools(
                    udid=self.udid,
                    adb_port=self.adb_port,
                    timeout=self.timeout,
                )
            self._emitir_diagnostico(estado="iniciando", etapa="chrome_limpeza")
            self._limpar_estado_android()
            try:
                self._abrir_chrome_direto()
            except FalhaPichau as erro_direto:
                _log.warning(
                    "Pichau Android: abertura ADB/CDP falhou; usando fallback Appium; codigo=%s.",
                    erro_direto.codigo,
                )
                self._emitir_diagnostico(
                    estado="iniciando",
                    etapa="appium_fallback",
                    codigo=codigo_operacional(
                        erro_direto.codigo,
                        erro_direto.status_http,
                    ),
                )
                try:
                    self.cdp.fechar()
                    self._limpar_estado_android()
                except FalhaPichau as erro_limpeza:
                    _log.warning(
                        "Pichau Android: limpeza antes do fallback Appium falhou; codigo=%s.",
                        erro_limpeza.codigo,
                    )
                self._driver = self._abrir_driver()
                # A sessão é nativa (UiAutomator2), não um contexto Web. As
                # navegações seguintes usam o CDP e seus limites finitos.
                self.cdp.abrir()
                self.cdp.abrir_url(self.url_categoria)
                self.cdp.aguardar_pagina()
        except Exception as erro:
            self._limpar_navegador(preservar=erro)
            if isinstance(erro, FalhaPichau):
                raise
            raise FalhaAoObterPichau(
                "Nao foi possivel iniciar o navegador Android por Appium.", codigo="navegador"
            ) from erro
        return self

    def __exit__(self, tipo, valor, traceback) -> None:
        self._limpar_navegador(preservar=valor if tipo is not None else None)

    def _abrir_chrome_direto(self) -> None:
        if self.cdp is None:
            raise FalhaAoObterPichau("Ponte CDP Android ausente.", codigo="navegador")
        self._emitir_diagnostico(estado="iniciando", etapa="chrome_abertura")
        self.cdp.abrir_url(self.url_categoria)
        self.cdp.abrir()
        self.cdp.aguardar_pagina()

    def _limpar_navegador(self, *, preservar: BaseException | None) -> None:
        """Encerra sessão, Chrome e ponte sem mascarar uma falha anterior."""

        falha_limpeza: FalhaPichau | None = None
        self._encerrar_driver()
        if self.cdp is not None:
            try:
                self._emitir_diagnostico(estado="iniciando", etapa="chrome_limpeza")
            except FalhaPichau as erro:
                falha_limpeza = erro
            try:
                self._limpar_estado_android(bloquear=True)
            except FalhaPichau as erro:
                falha_limpeza = falha_limpeza or erro
            finally:
                try:
                    self.cdp.fechar()
                except FalhaPichau as erro:
                    falha_limpeza = falha_limpeza or erro
        if falha_limpeza is not None:
            if preservar is not None:
                _log.warning(
                    "Pichau Android: limpeza falhou sem substituir a causa; codigo=%s.",
                    falha_limpeza.codigo,
                )
                return
            raise falha_limpeza

    def _limpar_estado_android(self, *, bloquear: bool = False) -> None:
        if self.cdp is None:
            return
        falha: FalhaPichau | None = None
        try:
            try:
                self.cdp.forcar_parada()
            except FalhaPichau as erro:
                _log.warning(
                    "Pichau Android: force-stop inicial falhou; tentando remover tarefas; "
                    "codigo=%s.",
                    erro.codigo,
                )
            self.cdp.limpar_tarefas_recentes(confirmar=True)
            self.cdp.forcar_parada(confirmar=True)
        except FalhaPichau as erro:
            falha = erro
        if bloquear:
            try:
                self.cdp.bloquear_tela()
            except FalhaPichau as erro:
                falha = falha or erro
        if falha is not None:
            raise falha

    def pagina(self, pagina: int) -> str:
        if pagina < 1:
            raise FalhaAoObterPichau("Numero de pagina invalido.", codigo="pagina")
        if pagina in self._paginas_prefetch:
            return self._paginas_prefetch.pop(pagina)
        url = self._url_pagina(pagina)
        fonte = self._obter(url, "catalogo", pagina)
        if pagina == 1 and self.estrategia_leitura == "fetch" and self.cdp is not None:
            self._precarregar_paginas(fonte, url)
        return fonte

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
                "appium:forceAppLaunch": True,
                "appium:shouldTerminateApp": True,
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
            "appium:forceAppLaunch": True,
            "appium:shouldTerminateApp": True,
            "appium:newCommandTimeout": max(120, int(self.timeout * 2)),
        }
        if self.udid:
            capacidades["appium:udid"] = self.udid
        if self.adb_port is not None:
            capacidades["appium:adbPort"] = self.adb_port
        opcoes = UiAutomator2Options()
        opcoes.load_capabilities(capacidades)
        return webdriver.Remote(command_executor=self.appium_url, options=opcoes)

    def _obter(
        self,
        url: str,
        contexto: str,
        pagina: int | None,
        *,
        permitir_fallback_dom: bool = True,
        tentativas: int | None = None,
    ) -> str:
        self._exigir_driver()
        limite_tentativas = self.tentativas if tentativas is None else max(1, tentativas)
        for tentativa in range(1, limite_tentativas + 1):
            inicio = time.perf_counter()
            estrategia = "dom"
            self._emitir_diagnostico(
                estado="coletando",
                etapa="pagina",
                pagina=pagina,
                estrategia=estrategia,
                tentativa_pagina=tentativa,
            )
            try:
                if self.cdp is None:
                    self._driver.get(url)
                    self.dormir(3.0)
                    fonte = self._driver.page_source
                    titulo = str(getattr(self._driver, "title", ""))
                else:
                    if contexto == "catalogo" and self.estrategia_leitura == "rede":
                        try:
                            fonte, titulo, url_final = self.cdp.obter_rede(url)
                            estrategia = "rede"
                        except FalhaPichau as erro_rede:
                            _log.warning(
                                "Pichau Android: rede falhou na pagina %s; "
                                "fallback para DOM; codigo=%s.",
                                pagina,
                                erro_rede.codigo,
                            )
                            fonte, titulo, url_final = self.cdp.obter(url)
                            estrategia = "rede_dom_fallback"
                        except Exception as erro_rede:
                            _log.warning(
                                "Pichau Android: rede falhou na pagina %s; "
                                "fallback para DOM; tipo=%s.",
                                pagina,
                                type(erro_rede).__name__,
                            )
                            fonte, titulo, url_final = self.cdp.obter(url)
                            estrategia = "rede_dom_fallback"
                    elif contexto == "catalogo" and self.estrategia_leitura == "fetch":
                        try:
                            fonte, titulo, url_final = self.cdp.obter_fetch(url)
                            estrategia = "fetch"
                        except FalhaPichau as erro_fetch:
                            if not permitir_fallback_dom:
                                raise
                            _log.warning(
                                "Pichau Android: fetch falhou na pagina %s; "
                                "fallback para DOM; codigo=%s.",
                                pagina,
                                erro_fetch.codigo,
                            )
                            fonte, titulo, url_final = self.cdp.obter(url)
                            estrategia = "dom_fallback"
                        except Exception as erro_fetch:
                            if not permitir_fallback_dom:
                                raise
                            _log.warning(
                                "Pichau Android: fetch falhou na pagina %s; "
                                "fallback para DOM; tipo=%s.",
                                pagina,
                                type(erro_fetch).__name__,
                            )
                            fonte, titulo, url_final = self.cdp.obter(url)
                            estrategia = "dom_fallback"
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
                _log.info(
                    "Pichau Android performance: etapa=pagina pagina=%s "
                    "estrategia=%s duracao_ms=%d bytes=%d",
                    pagina,
                    estrategia,
                    round((time.perf_counter() - inicio) * 1000),
                    len(fonte.encode("utf-8")),
                )
                self._emitir_diagnostico(
                    estado="coletando",
                    etapa="pagina",
                    pagina=pagina,
                    estrategia=self._estrategia_diagnostico(estrategia),
                    tentativa_pagina=tentativa,
                    status_http=200,
                )
                return fonte
            except FalhaPichau as erro:
                self._emitir_diagnostico(
                    estado="coletando",
                    etapa="pagina",
                    pagina=pagina,
                    estrategia=self._estrategia_diagnostico(estrategia),
                    tentativa_pagina=tentativa,
                    status_http=erro.status_http,
                    codigo=codigo_operacional(erro.codigo, erro.status_http),
                )
                if tentativa == limite_tentativas:
                    raise
                self._esperar(tentativa, contexto, limite_tentativas)
            except Exception as erro:
                _log.warning(
                    "Pichau Android: falha tecnica em %s; tentativa %d de %d; tipo=%s.",
                    contexto,
                    tentativa,
                    limite_tentativas,
                    type(erro).__name__,
                )
                if tentativa == limite_tentativas:
                    falha = FalhaAoObterPichau(
                        f"Falha do navegador Android ao ler {contexto}.", codigo="navegador"
                    )
                    self._emitir_diagnostico(
                        estado="coletando",
                        etapa="pagina",
                        pagina=pagina,
                        estrategia=self._estrategia_diagnostico(estrategia),
                        tentativa_pagina=tentativa,
                        codigo=codigo_operacional(falha.codigo),
                    )
                    raise falha from erro
                self._esperar(tentativa, contexto, limite_tentativas)
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
            "bytes=%d next_payload=%s "
            "desafio=%s turnstile=%s recaptcha=%s hcaptcha=%s manutencao=%s "
            "access_denied=%s just_a_moment=%s",
            contexto,
            pagina,
            tentativa,
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

    @staticmethod
    def _estrategia_diagnostico(estrategia: str) -> str:
        return "fallback" if "fallback" in estrategia else estrategia

    def _emitir_diagnostico(self, **campos: object) -> None:
        if self.observar_diagnostico is None:
            return
        evento = {chave: valor for chave, valor in campos.items() if valor is not None}
        # O observador recebe somente o mesmo vocabulário fechado que poderá
        # chegar à fila; qualquer regressão falha antes de transportar dados.
        evento.setdefault("versao", 1)
        self.observar_diagnostico(validar_diagnostico(evento))

    def _precarregar_paginas(self, fonte: str, url: str) -> None:
        """Busca as paginas restantes em paralelo depois de descobrir o total."""

        from .extrator import extrair_pagina

        primeira = extrair_pagina(
            fonte,
            pagina_esperada=1,
            por_pagina=self.por_pagina,
            base_url=url,
        )
        paginas = (primeira.total + self.por_pagina - 1) // self.por_pagina
        if paginas <= 1:
            return
        inicio = time.perf_counter()
        numeros = list(range(2, paginas + 1))

        def carregar(numero: int) -> tuple[int, str] | None:
            try:
                # O fetch pode ocorrer em paralelo porque não navega a aba. O
                # DOM controla uma única aba do Chrome e precisa permanecer
                # sequencial; páginas instáveis serão lidas por pagina().
                return numero, self._obter(
                    self._url_pagina(numero),
                    "catalogo",
                    numero,
                    permitir_fallback_dom=False,
                    tentativas=1,
                )
            except FalhaPichau as erro:
                _log.warning(
                    "Pichau Android: prefetch adiado para leitura sequencial; pagina=%d codigo=%s.",
                    numero,
                    erro.codigo,
                )
                return None
            except Exception as erro:
                _log.warning(
                    "Pichau Android: prefetch adiado para leitura sequencial; pagina=%d tipo=%s.",
                    numero,
                    type(erro).__name__,
                )
                return None

        with ThreadPoolExecutor(max_workers=min(5, len(numeros))) as executor:
            futuros = [executor.submit(carregar, numero) for numero in numeros]
            resultados = [
                resultado for futuro in futuros if (resultado := futuro.result()) is not None
            ]
        self._paginas_prefetch = dict(resultados)
        _log.info(
            "Pichau Android performance: etapa=prefetch paginas=%d pendentes=%d "
            "duracao_ms=%d estrategia=fetch",
            len(resultados),
            len(numeros) - len(resultados),
            round((time.perf_counter() - inicio) * 1000),
        )

    def _validar_catalogo(self, fonte: str, pagina: int, url: str) -> None:
        from .extrator import extrair_pagina

        pagina_extraida = extrair_pagina(
            fonte,
            pagina_esperada=pagina,
            por_pagina=self.por_pagina,
            base_url=url,
        )
        if not pagina_extraida.produtos:
            raise FalhaAoObterPichau(
                "A resposta nao apresentou um catalogo Pichau valido.",
                codigo="catalogo_incompleto",
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

    def _esperar(self, tentativa: int, contexto: str, limite_tentativas: int | None = None) -> None:
        _log.warning(
            "Pichau Android: %s; tentativa %d de %d.",
            contexto,
            tentativa,
            limite_tentativas or self.tentativas,
        )
        self.esperar()

    def _url_pagina(self, pagina: int) -> str:
        parametros = {"pageSize": self.por_pagina}
        if self.ordenacao:
            parametros["sort"] = self.ordenacao
        if pagina > 1:
            parametros["page"] = pagina
        separador = "&" if "?" in self.url_categoria else "?"
        return f"{self.url_categoria}{separador}{urlencode(parametros)}"

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

    def __init__(self, url: str, *, fila_id: int | None = None, conectar=None) -> None:
        if not url:
            raise FalhaAoGuardarPichau("DATABASE_URL nao configurada.", codigo="configuracao")
        if fila_id is not None and (isinstance(fila_id, bool) or fila_id < 1):
            raise FalhaAoGuardarPichau("ID da fila Android invalido.", codigo="configuracao")
        self.url = url
        self.fila_id = fila_id
        if conectar is None:
            import psycopg

            conectar = psycopg.connect
        self.conectar = conectar

    def atualizar_diagnostico(self, diagnostico: dict[str, object]) -> None:
        """Atualiza somente a linha em execução recebida do worker Android."""

        if self.fila_id is None:
            return
        seguro = validar_diagnostico(diagnostico)
        serializado = json.dumps(seguro, ensure_ascii=True, separators=(",", ":"), sort_keys=True)
        try:
            with self.conectar(self.url) as conexao, conexao.cursor() as cursor:
                cursor.execute(
                    """
                    UPDATE pichau_android_fila
                       SET diagnostico = %s::jsonb
                     WHERE id = %s AND estado = 'executando'
                    """,
                    (serializado, self.fila_id),
                )
        except Exception as erro:
            raise FalhaAoGuardarPichau(
                "Nao foi possivel atualizar o diagnostico Pichau.", codigo="banco"
            ) from erro

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
                inicio_publicacao = time.perf_counter()
                ids_publicados: list[str] = []
                identidades_por_url: dict[str, str] = {}
                if any(produto.sku is None for produto in produtos):
                    # Uma única leitura substitui uma consulta por produto no
                    # caminho DOM Android, sem perder a preferência pela
                    # identidade histórica que possui SKU.
                    cursor.execute(
                        """
                            SELECT DISTINCT ON (url_produto) url_produto, id_externo
                              FROM pichau_produto
                             WHERE categoria_externa=%s
                             ORDER BY url_produto,
                                      CASE WHEN sku IS NULL THEN 1 ELSE 0 END,
                                      id
                        """,
                        ("PC Gamer",),
                    )
                    for url_produto, id_existente in cursor.fetchall():
                        if isinstance(url_produto, str) and isinstance(id_existente, str):
                            identidades_por_url[url_produto] = id_existente
                produtos_resolvidos: list[tuple[str, PichauProduto]] = []
                identidades_vistas: set[str] = set()
                for produto in produtos:
                    id_externo = produto.id_externo
                    if produto.sku is None:
                        # A listagem DOM do Android não expõe SKU. Quando a
                        # URL já foi catalogada por uma coleta SSR, reutilize
                        # a identidade histórica para não criar uma segunda
                        # linha do mesmo produto.
                        id_externo = identidades_por_url.get(produto.url_produto, id_externo)
                    if id_externo in identidades_vistas:
                        raise FalhaAoGuardarPichau(
                            "A coleta resultou em identidades Pichau duplicadas.",
                            codigo="identidade",
                        )
                    identidades_vistas.add(id_externo)
                    ids_publicados.append(id_externo)
                    produtos_resolvidos.append((id_externo, produto))
                ids_por_externo: dict[str, int] = {}
                inicio_produtos = time.perf_counter()
                for lote in _lotes(produtos_resolvidos):
                    valores = [
                        (
                            id_externo,
                            produto.sku,
                            produto.nome,
                            _busca(produto.nome),
                            produto.marca,
                            _busca(produto.marca or ""),
                            produto.categoria_externa,
                            produto.url_produto,
                            produto.disponibilidade,
                            True,
                            concluida,
                        )
                        for id_externo, produto in lote
                    ]
                    cursor.execute(
                        f"""
                            INSERT INTO pichau_produto (
                              id_externo, sku, nome, nome_busca, marca, marca_busca,
                              categoria_externa,
                              url_produto, disponibilidade, presente_no_catalogo, visto_em
                            ) VALUES {_placeholders(len(valores), 11)}
                            ON CONFLICT (id_externo) DO UPDATE SET
                              sku=COALESCE(EXCLUDED.sku, pichau_produto.sku),
                              nome=EXCLUDED.nome, nome_busca=EXCLUDED.nome_busca,
                              marca=COALESCE(EXCLUDED.marca, pichau_produto.marca),
                              categoria_externa=EXCLUDED.categoria_externa,
                              url_produto=EXCLUDED.url_produto,
                              disponibilidade=EXCLUDED.disponibilidade,
                              presente_no_catalogo=TRUE, visto_em=EXCLUDED.visto_em,
                              atualizado_em=now()
                            RETURNING id, id_externo
                            """,
                        _achatar(valores),
                    )
                    retornos = cursor.fetchall()
                    if len(retornos) != len(lote):
                        raise FalhaAoGuardarPichau(
                            "A publicação Pichau não retornou todos os produtos.",
                            codigo="banco",
                        )
                    for produto_id, id_lote in retornos:
                        ids_por_externo[str(id_lote)] = int(produto_id)
                _log.info(
                    "Pichau performance: etapa=publicar_produtos duracao_ms=%d itens=%d lotes=%d",
                    round((time.perf_counter() - inicio_produtos) * 1000),
                    len(produtos_resolvidos),
                    (len(produtos_resolvidos) + TAMANHO_LOTE_PUBLICACAO - 1)
                    // TAMANHO_LOTE_PUBLICACAO,
                )

                inicio_medicoes = time.perf_counter()
                for lote in _lotes(produtos_resolvidos):
                    valores = []
                    for id_externo, produto in lote:
                        produto_id = ids_por_externo.get(id_externo)
                        if produto_id is None:
                            raise FalhaAoGuardarPichau(
                                "A publicação Pichau perdeu a identidade de um produto.",
                                codigo="banco",
                            )
                        valores.append(
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
                            )
                        )
                    cursor.execute(
                        f"""
                            INSERT INTO pichau_medicao (
                              execucao_id, produto_id, momento, preco_original,
                              preco_original_texto,
                              preco_pix, preco_pix_texto, desconto_pix, desconto_pix_texto,
                              preco_cartao, preco_cartao_texto, parcelamento, valor_parcela_texto,
                              sem_juros, estoque_texto, etiquetas
                            ) VALUES {_placeholders(len(valores), 16)}
                            """,
                        _achatar(valores),
                    )
                _log.info(
                    "Pichau performance: etapa=publicar_medicoes duracao_ms=%d itens=%d lotes=%d",
                    round((time.perf_counter() - inicio_medicoes) * 1000),
                    len(produtos_resolvidos),
                    (len(produtos_resolvidos) + TAMANHO_LOTE_PUBLICACAO - 1)
                    // TAMANHO_LOTE_PUBLICACAO,
                )
                cursor.execute(
                    "UPDATE pichau_produto SET presente_no_catalogo=FALSE, "
                    "atualizado_em=now() WHERE categoria_externa='PC Gamer' "
                    "AND id_externo <> ALL(%s)",
                    (ids_publicados,),
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
                _log.info(
                    "Pichau performance: etapa=publicacao duracao_ms=%d itens=%d",
                    round((time.perf_counter() - inicio_publicacao) * 1000),
                    len(produtos_resolvidos),
                )
        except FalhaAoGuardarPichau:
            raise
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


def _lotes(valores: list[tuple], tamanho: int = TAMANHO_LOTE_PUBLICACAO):
    for inicio in range(0, len(valores), tamanho):
        yield valores[inicio : inicio + tamanho]


def _placeholders(quantidade: int, colunas: int) -> str:
    linha = "(" + ",".join(["%s"] * colunas) + ")"
    return ",".join([linha] * quantidade)


def _achatar(valores: list[tuple]) -> tuple:
    return tuple(item for linha in valores for item in linha)


def agora_utc() -> datetime:
    return datetime.now(UTC)
