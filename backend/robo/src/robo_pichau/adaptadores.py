"""Adaptadores HTTP, SeleniumBase e Postgres do coletor Pichau."""

from __future__ import annotations

import logging
import random
import time
from collections.abc import Callable
from datetime import UTC, datetime, timedelta
from urllib.parse import urlencode, urlparse

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
                titulo = self._sessao.get_title().lower()
                if self._tem_desafio(fonte, titulo):
                    self._sessao.uc_gui_click_captcha()
                    self._sessao.sleep(3)
                    fonte = self._sessao.get_page_source()
                    titulo = self._sessao.get_title().lower()
                if self._tem_bloqueio(fonte, titulo):
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
                if tentativa == self.tentativas:
                    raise FalhaAoObterPichau(
                        f"Falha do navegador ao ler {contexto}.", codigo="navegador"
                    ) from erro
                self._esperar(tentativa, contexto)
        raise FalhaAoObterPichau(f"A Pichau falhou ao ler {contexto}.", codigo="acesso")

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
            titulo.startswith(item) for item in self._TITULOS_BLOQUEIO[:1]
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
