"""Composicao da coleta Pichau e entrada do workflow."""

from __future__ import annotations

import logging
import os
import sys
import time
from collections.abc import Callable
from dataclasses import replace
from datetime import UTC, datetime
from urllib.parse import urlparse

from . import __version__
from .adaptadores import (
    FontePichauAndroid,
    FontePichauSeleniumBase,
    RepositorioPichauPostgres,
    agora_utc,
)
from .diagnostico import (
    VERSAO_DIAGNOSTICO,
    codigo_operacional,
    resumir_primeira_falha,
    validar_diagnostico,
)
from .extrator import extrair_pagina, tem_payload_catalogo
from .modelos import PichauProduto, ResumoColetaPichau
from .portas import (
    ConfiguracaoPichauInvalida,
    FalhaAoObterPichau,
    FalhaPichau,
    FontePichau,
    PaginacaoPichauInvalida,
)

_log = logging.getLogger(__name__)

CODIGO_SAIDA_CONFIGURACAO = 40
CODIGO_SAIDA_NAVEGADOR = 41
CODIGO_SAIDA_ACESSO = 42
CODIGO_SAIDA_DADOS = 43
CODIGO_SAIDA_BANCO = 44
CODIGO_SAIDA_PARCIAL = 45
RESFRIAMENTO_RECUPERACAO_SEGUNDOS = 10.0
CODIGOS_RECUPERAVEIS = {
    "navegador",
    "rede",
    "http_transitorio",
    "catalogo_incompleto",
}


class _DiagnosticoExecucao:
    """Acumula somente campos seguros e os entrega ao publicador."""

    def __init__(self, repositorio: RepositorioPichauPostgres, execucao_id: int) -> None:
        self.repositorio = repositorio
        self.inicio = time.perf_counter()
        self.dados: dict[str, object] = {
            "versao": VERSAO_DIAGNOSTICO,
            "estado": "iniciando",
            "etapa": "execucao",
            "tentativa_sessao": 1,
            "recuperacao_utilizada": False,
            "execucao_id": execucao_id,
        }
        self._persistir()

    def atualizar(self, **campos: object | None) -> None:
        for chave, valor in campos.items():
            if valor is None:
                self.dados.pop(chave, None)
            else:
                self.dados[chave] = valor
        self._persistir()

    def observar(self, evento: dict[str, object]) -> None:
        seguro = validar_diagnostico(evento)
        if "codigo" not in seguro:
            self.dados.pop("codigo", None)
        if "status_http" not in seguro:
            self.dados.pop("status_http", None)
        self.dados.update(seguro)
        self._persistir()

    def registrar_primeira_falha(self, codigo: str) -> None:
        self.dados["primeira_falha"] = resumir_primeira_falha(self.dados, codigo)
        self._persistir()

    def _persistir(self) -> None:
        self.dados["duracao_ms"] = round((time.perf_counter() - self.inicio) * 1000)
        self.dados = validar_diagnostico(self.dados)
        self.repositorio.atualizar_diagnostico(self.dados)


def codigo_saida_falha(codigo: str) -> int:
    """Traduz falhas esperadas para categorias seguras usadas pela fila."""

    if codigo == "configuracao":
        return CODIGO_SAIDA_CONFIGURACAO
    if codigo == "navegador":
        return CODIGO_SAIDA_NAVEGADOR
    if codigo in {"acesso", "http", "http_transitorio", "rede"}:
        return CODIGO_SAIDA_ACESSO
    if codigo == "banco":
        return CODIGO_SAIDA_BANCO
    if codigo == "parcial":
        return CODIGO_SAIDA_PARCIAL
    return CODIGO_SAIDA_DADOS


def coletar_catalogo(
    fonte: FontePichau,
    *,
    por_pagina: int = 36,
    max_paginas: int = 300,
    dormir: Callable[[float], None] | None = None,
) -> tuple[tuple[PichauProduto, ...], ResumoColetaPichau]:
    """Lê páginas sequenciais e rejeita paginação repetida ou incoerente."""

    iniciada = datetime.now(UTC)
    # A fonte Android usa a maior página que o catálogo público aceita. As
    # demais fontes conservam o contrato histórico de 36 itens por página.
    por_pagina = int(getattr(fonte, "por_pagina", por_pagina))
    produtos: dict[str, PichauProduto] = {}
    fingerprints: set[tuple[str, ...]] = set()
    total_declarado: int | None = None
    paginas_lidas = 0
    itens_lidos = 0
    duplicados = 0
    tentativas = 1
    inicio_coleta = time.perf_counter()
    try:
        for numero in range(1, max_paginas + 1):
            inicio_pagina = time.perf_counter()
            if dormir and numero > 1:
                dormir(1.0)
            html = fonte.pagina(numero)
            pagina = extrair_pagina(
                html,
                pagina_esperada=numero,
                por_pagina=por_pagina,
                base_url=(f"{fonte.url_categoria}{'?page=' + str(numero) if numero > 1 else ''}"),
            )
            fingerprint = tuple(item.id_externo for item in pagina.produtos)
            if fingerprint and fingerprint in fingerprints:
                raise PaginacaoPichauInvalida(
                    "A fonte repetiu uma pagina do catalogo.", codigo="repetida"
                )
            fingerprints.add(fingerprint)
            if total_declarado is None:
                total_declarado = pagina.total
            elif pagina.total != total_declarado:
                raise PaginacaoPichauInvalida(
                    "O total do catalogo mudou durante a coleta.", codigo="incoerente"
                )
            paginas_lidas += 1
            itens_lidos += pagina.itens_lidos
            for produto in pagina.produtos:
                if produto.id_externo in produtos:
                    duplicados += 1
                produtos[produto.id_externo] = produto
            _log.info(
                "Pichau performance: etapa=pagina_processada pagina=%d "
                "itens=%d total=%d duracao_ms=%d",
                numero,
                pagina.itens_lidos,
                pagina.total,
                round((time.perf_counter() - inicio_pagina) * 1000),
            )
            if pagina.ultima:
                break
        else:
            raise PaginacaoPichauInvalida(
                "O catalogo nao encerrou dentro do limite de paginas.", codigo="limite"
            )
        total = total_declarado or 0
        degradada = itens_lidos < total or len(produtos) < total
        resumo = ResumoColetaPichau(
            iniciada_em=iniciada,
            concluida_em=datetime.now(UTC),
            total_declarado=total,
            paginas=paginas_lidas,
            itens_lidos=itens_lidos,
            itens_unicos=len(produtos),
            duplicados=duplicados,
            tentativas=tentativas,
            degradada=degradada,
        )
        _log.info(
            "Pichau performance: etapa=coleta duracao_ms=%d paginas=%d "
            "itens=%d unicos=%d duplicados=%d",
            round((time.perf_counter() - inicio_coleta) * 1000),
            paginas_lidas,
            itens_lidos,
            len(produtos),
            duplicados,
        )
        return tuple(
            sorted(produtos.values(), key=lambda item: (item.nome.casefold(), item.id_externo))
        ), resumo
    except PaginacaoPichauInvalida:
        raise


def coletar_com_recuperacao(
    repositorio: RepositorioPichauPostgres,
    diagnostico: _DiagnosticoExecucao,
    *,
    criar_fonte: Callable[[], FontePichau] | None = None,
    dormir: Callable[[float], None] = time.sleep,
) -> tuple[tuple[PichauProduto, ...], ResumoColetaPichau]:
    """Repete a coleta completa uma vez após falha transitória já retentada."""

    fabrica_fonte = criar_fonte or criar_fonte_pichau
    for tentativa_sessao in (1, 2):
        diagnostico.atualizar(
            estado="iniciando",
            etapa="execucao",
            tentativa_sessao=tentativa_sessao,
            codigo=None,
            status_http=None,
            pagina=None,
            estrategia=None,
            tentativa_pagina=None,
        )
        try:
            fonte = fabrica_fonte()
            if isinstance(fonte, FontePichauAndroid):
                fonte.observar_diagnostico = diagnostico.observar
            with fonte:
                produtos, resumo = coletar_catalogo(fonte, dormir=fonte.esperar)
            resumo = replace(resumo, tentativas=tentativa_sessao)
            diagnostico.atualizar(
                estado="coletando",
                etapa="coleta",
                paginas=resumo.paginas,
                itens=resumo.itens_lidos,
                itens_unicos=resumo.itens_unicos,
                total_declarado=resumo.total_declarado,
                codigo=None,
                status_http=None,
            )
            return produtos, resumo
        except FalhaPichau as erro:
            codigo = codigo_operacional(erro.codigo, erro.status_http)
            diagnostico.atualizar(
                estado="falha",
                codigo=codigo,
                status_http=erro.status_http,
            )
            if tentativa_sessao == 1 and erro.codigo in CODIGOS_RECUPERAVEIS:
                diagnostico.registrar_primeira_falha(codigo)
                diagnostico.atualizar(
                    estado="recuperando",
                    etapa="recuperacao",
                    recuperacao_utilizada=True,
                    codigo=None,
                    status_http=None,
                )
                _log.warning(
                    "Pichau Android: reiniciando a coleta completa; codigo=%s cooldown_s=%d.",
                    codigo,
                    round(RESFRIAMENTO_RECUPERACAO_SEGUNDOS),
                )
                dormir(RESFRIAMENTO_RECUPERACAO_SEGUNDOS)
                continue
            raise
    raise FalhaAoObterPichau(
        "A recuperacao Android excedeu o limite de sessoes.", codigo="navegador"
    )


def criar_fonte_pichau() -> FontePichau:
    modo = os.getenv("PICHAU_MODO_NAVEGADOR", "headless2").strip().lower()
    if modo == "headless2":
        return FontePichauSeleniumBase(headless2=True, xvfb=False)
    if modo == "xvfb":
        return FontePichauSeleniumBase(headless2=False, xvfb=True)
    if modo == "android":
        porta_adb = os.getenv("PICHAU_ANDROID_ADB_PORT", "").strip()
        try:
            adb_port = int(porta_adb) if porta_adb else None
        except ValueError as erro:
            raise ConfiguracaoPichauInvalida(
                "PICHAU_ANDROID_ADB_PORT deve ser um numero.", codigo="configuracao"
            ) from erro
        return FontePichauAndroid(
            appium_url=os.getenv("PICHAU_APPIUM_URL", "http://127.0.0.1:4723"),
            device_name=os.getenv("PICHAU_ANDROID_DEVICE_NAME", "Android"),
            udid=os.getenv("PICHAU_ANDROID_UDID") or None,
            adb_port=adb_port,
            estrategia_leitura=os.getenv("PICHAU_ESTRATEGIA_LEITURA", "dom"),
            ordenacao=os.getenv("PICHAU_ANDROID_ORDENACAO") or None,
        )
    raise ConfiguracaoPichauInvalida(
        "PICHAU_MODO_NAVEGADOR deve ser headless2, xvfb ou android.", codigo="configuracao"
    )


def fila_id_android() -> int | None:
    valor = os.getenv("PICHAU_ANDROID_FILA_ID", "").strip()
    if not valor:
        return None
    if not valor.isdecimal() or int(valor) < 1:
        raise ConfiguracaoPichauInvalida(
            "PICHAU_ANDROID_FILA_ID deve ser um inteiro positivo.", codigo="configuracao"
        )
    return int(valor)


def diagnosticar_catalogo(fonte: FontePichau) -> None:
    """Valida uma pagina sem abrir conexao ou criar execucao no banco."""

    url = fonte.url_categoria
    html = fonte.pagina(1)
    pagina = extrair_pagina(html, pagina_esperada=1, por_pagina=36, base_url=url)
    if not tem_payload_catalogo(html):
        raise FalhaAoObterPichau(
            "O diagnostico nao encontrou products.items na resposta.", codigo="diagnostico"
        )
    if not pagina.produtos:
        raise FalhaAoObterPichau(
            "O diagnostico nao encontrou produtos na primeira pagina.", codigo="diagnostico"
        )
    # O caminho Android/CDP lê a grade renderizada, que não publica SKU no
    # DOM. A publicação reconcilia a identidade por URL; o diagnóstico ainda
    # exige os campos comerciais e a URL segura, mas não inventa SKU.
    exige_sku = not (isinstance(fonte, FontePichauAndroid) and fonte.criar_driver is None)
    faltantes = []
    disponibilidades = {"disponivel", "esgotado", "pre_venda", "nao_informado"}
    for produto in pagina.produtos:
        if exige_sku and not produto.sku:
            faltantes.append("sku")
        analisada = urlparse(produto.url_produto)
        if analisada.scheme != "https" or analisada.hostname not in {
            "pichau.com.br",
            "www.pichau.com.br",
        }:
            faltantes.append("url")
        if produto.preco_pix_valor is None and produto.preco_cartao_valor is None:
            faltantes.append("preco")
        if produto.disponibilidade not in disponibilidades:
            faltantes.append("disponibilidade")
    if faltantes:
        raise FalhaAoObterPichau(
            "O diagnostico encontrou campos comerciais ausentes: "
            + ", ".join(sorted(set(faltantes))),
            codigo="diagnostico",
        )
    _log.info(
        "Diagnostico Pichau aprovado: pagina=1 total=%d itens=%d skus=%d "
        "precos=%d disponibilidades=%s",
        pagina.total,
        len(pagina.produtos),
        sum(1 for produto in pagina.produtos if produto.sku),
        sum(
            1
            for produto in pagina.produtos
            if produto.preco_pix_valor is not None or produto.preco_cartao_valor is not None
        ),
        sorted({produto.disponibilidade for produto in pagina.produtos}),
    )


def executar(argv: list[str] | None = None) -> int:
    logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"))
    argumentos = list(sys.argv[1:] if argv is None else argv)
    if argumentos not in ([], ["--diagnostico"]):
        raise ConfiguracaoPichauInvalida(
            "Uso: python -m robo_pichau.principal [--diagnostico].", codigo="configuracao"
        )
    diagnostico = argumentos == ["--diagnostico"]
    if diagnostico:
        try:
            with criar_fonte_pichau() as fonte:
                diagnosticar_catalogo(fonte)
            return 0
        except FalhaPichau as erro:
            _log.error("Diagnostico Pichau nao aprovado: %s", erro)
            return codigo_saida_falha(erro.codigo)

    database_url = os.getenv("DATABASE_URL")
    if not database_url:
        raise ConfiguracaoPichauInvalida("DATABASE_URL nao configurada.", codigo="configuracao")
    repositorio = RepositorioPichauPostgres(database_url, fila_id=fila_id_android())
    execucao_id = repositorio.iniciar_execucao(agora_utc(), __version__)
    diagnostico_execucao: _DiagnosticoExecucao | None = None
    try:
        diagnostico_execucao = _DiagnosticoExecucao(repositorio, execucao_id)
        produtos, resumo = coletar_com_recuperacao(repositorio, diagnostico_execucao)
        if resumo.degradada:
            diagnostico_execucao.atualizar(
                estado="falha",
                etapa="coleta",
                paginas=resumo.paginas,
                itens=resumo.itens_lidos,
                itens_unicos=resumo.itens_unicos,
                total_declarado=resumo.total_declarado,
                codigo="pichau-parcial",
            )
            repositorio.falhar(execucao_id, "parcial")
            _log.error("Coleta Pichau parcial; snapshot anterior preservado.")
            return CODIGO_SAIDA_PARCIAL
        diagnostico_execucao.atualizar(estado="publicando", etapa="publicacao")
        repositorio.publicar(execucao_id, produtos, resumo)
        diagnostico_execucao.atualizar(
            estado="sucesso",
            etapa="finalizacao",
            codigo=None,
            status_http=None,
        )
        _log.info("Coleta Pichau publicada: %d produtos.", len(produtos))
        return 0
    except FalhaPichau as erro:
        if diagnostico_execucao is not None:
            try:
                diagnostico_execucao.atualizar(
                    estado="falha",
                    codigo=codigo_operacional(erro.codigo, erro.status_http),
                    status_http=erro.status_http,
                )
            except FalhaPichau:
                _log.warning("Pichau: diagnostico final indisponivel; causa original preservada.")
        repositorio.falhar(execucao_id, erro.codigo)
        _log.error("Coleta Pichau nao publicada; codigo=%s.", erro.codigo)
        return codigo_saida_falha(erro.codigo)


def executar_cli(argv: list[str] | None = None) -> int:
    """Executa a CLI sem transformar falha operacional esperada em traceback."""

    try:
        return executar(argv)
    except FalhaPichau as erro:
        _log.error("Coleta Pichau nao iniciada; codigo=%s.", erro.codigo)
        return codigo_saida_falha(erro.codigo)


if __name__ == "__main__":
    raise SystemExit(executar_cli())
