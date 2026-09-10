"""Contrato seguro do diagnóstico operacional da coleta Android Pichau."""

from __future__ import annotations

import json
import re
from collections.abc import Mapping

VERSAO_DIAGNOSTICO = 1
TAMANHO_MAXIMO_DIAGNOSTICO = 2 * 1024

ESTADOS_DIAGNOSTICO = {
    "iniciando",
    "coletando",
    "recuperando",
    "publicando",
    "sucesso",
    "falha",
}
ETAPAS_DIAGNOSTICO = {
    "execucao",
    "chrome_limpeza",
    "chrome_abertura",
    "appium_fallback",
    "pagina",
    "coleta",
    "recuperacao",
    "publicacao",
    "finalizacao",
}
ESTRATEGIAS_DIAGNOSTICO = {"fetch", "dom", "rede", "fallback"}

_CHAVES_INTEIRAS = {
    "pagina",
    "tentativa_pagina",
    "tentativa_sessao",
    "duracao_ms",
    "paginas",
    "itens",
    "itens_unicos",
    "total_declarado",
    "status_http",
    "execucao_id",
}
_CHAVES_RAIZ = {
    "versao",
    "estado",
    "etapa",
    "estrategia",
    "recuperacao_utilizada",
    "codigo",
    "primeira_falha",
    *_CHAVES_INTEIRAS,
}
_CHAVES_PRIMEIRA_FALHA = {
    "codigo",
    "etapa",
    "estrategia",
    "pagina",
    "status_http",
}
_CODIGO_SEGURO = re.compile(r"^[a-z0-9][a-z0-9_-]{0,79}$")


class DiagnosticoInvalido(ValueError):
    """O diagnóstico tentou sair do contrato seguro e fechado."""


def _inteiro_seguro(chave: str, valor: object) -> int:
    if isinstance(valor, bool) or not isinstance(valor, int) or valor < 0:
        raise DiagnosticoInvalido(f"campo inteiro invalido: {chave}")
    if valor > 9_223_372_036_854_775_807:
        raise DiagnosticoInvalido(f"campo inteiro fora do limite: {chave}")
    return valor


def _codigo_seguro(valor: object) -> str:
    if not isinstance(valor, str) or not _CODIGO_SEGURO.fullmatch(valor):
        raise DiagnosticoInvalido("codigo de diagnostico invalido")
    return valor


def _validar_primeira_falha(valor: object) -> dict[str, object]:
    if not isinstance(valor, Mapping):
        raise DiagnosticoInvalido("primeira_falha precisa ser objeto")
    desconhecidas = set(valor) - _CHAVES_PRIMEIRA_FALHA
    if desconhecidas:
        raise DiagnosticoInvalido("primeira_falha possui campos desconhecidos")
    resultado: dict[str, object] = {}
    for chave, item in valor.items():
        if chave in {"pagina", "status_http"}:
            resultado[chave] = _inteiro_seguro(chave, item)
        elif chave == "codigo":
            resultado[chave] = _codigo_seguro(item)
        elif chave == "etapa":
            if item not in ETAPAS_DIAGNOSTICO:
                raise DiagnosticoInvalido("etapa da primeira falha invalida")
            resultado[chave] = item
        elif chave == "estrategia":
            if item not in ESTRATEGIAS_DIAGNOSTICO:
                raise DiagnosticoInvalido("estrategia da primeira falha invalida")
            resultado[chave] = item
    if "codigo" not in resultado:
        raise DiagnosticoInvalido("primeira_falha precisa de codigo")
    return resultado


def validar_diagnostico(valor: object) -> dict[str, object]:
    """Copia e valida o JSON antes de persistir ou mostrar no Actions."""

    if valor is None or valor == {}:
        return {}
    if not isinstance(valor, Mapping):
        raise DiagnosticoInvalido("diagnostico precisa ser objeto")
    desconhecidas = set(valor) - _CHAVES_RAIZ
    if desconhecidas:
        raise DiagnosticoInvalido("diagnostico possui campos desconhecidos")

    resultado: dict[str, object] = {}
    for chave, item in valor.items():
        if chave in _CHAVES_INTEIRAS:
            resultado[chave] = _inteiro_seguro(chave, item)
        elif chave == "versao":
            if item != VERSAO_DIAGNOSTICO:
                raise DiagnosticoInvalido("versao de diagnostico invalida")
            resultado[chave] = VERSAO_DIAGNOSTICO
        elif chave == "estado":
            if item not in ESTADOS_DIAGNOSTICO:
                raise DiagnosticoInvalido("estado de diagnostico invalido")
            resultado[chave] = item
        elif chave == "etapa":
            if item not in ETAPAS_DIAGNOSTICO:
                raise DiagnosticoInvalido("etapa de diagnostico invalida")
            resultado[chave] = item
        elif chave == "estrategia":
            if item not in ESTRATEGIAS_DIAGNOSTICO:
                raise DiagnosticoInvalido("estrategia de diagnostico invalida")
            resultado[chave] = item
        elif chave == "recuperacao_utilizada":
            if not isinstance(item, bool):
                raise DiagnosticoInvalido("recuperacao_utilizada precisa ser booleana")
            resultado[chave] = item
        elif chave == "codigo":
            resultado[chave] = _codigo_seguro(item)
        elif chave == "primeira_falha":
            resultado[chave] = _validar_primeira_falha(item)

    serializado = json.dumps(
        resultado,
        ensure_ascii=True,
        separators=(",", ":"),
        sort_keys=True,
    ).encode("utf-8")
    if len(serializado) > TAMANHO_MAXIMO_DIAGNOSTICO:
        raise DiagnosticoInvalido("diagnostico excede 2 KiB")
    return resultado


def sanitizar_diagnostico(valor: object) -> dict[str, object]:
    """Ignora JSON ausente/inválido vindo de linhas antigas sem imprimir seu conteúdo."""

    try:
        return validar_diagnostico(valor)
    except DiagnosticoInvalido:
        return {}


def codigo_operacional(codigo: str, status_http: int | None = None) -> str:
    """Traduz um código interno controlado para a categoria granular da fila."""

    base = codigo.strip().lower().replace("_", "-")
    if not _CODIGO_SEGURO.fullmatch(base):
        base = "dados"
    if codigo == "http_transitorio" and status_http is not None:
        base = f"http-{status_http}"
    return _codigo_seguro(f"pichau-{base}"[:80])


def resumir_primeira_falha(diagnostico: Mapping[str, object], codigo: str) -> dict[str, object]:
    """Recorta somente os campos seguros úteis antes da segunda sessão."""

    resumo: dict[str, object] = {"codigo": _codigo_seguro(codigo)}
    for chave in ("etapa", "estrategia", "pagina", "status_http"):
        if chave in diagnostico:
            resumo[chave] = diagnostico[chave]
    return _validar_primeira_falha(resumo)


def formatar_diagnostico(diagnostico: Mapping[str, object]) -> str:
    """Formata pares ``chave=valor`` em ordem estável, sem conteúdo livre."""

    seguro = validar_diagnostico(diagnostico)
    partes: list[str] = []
    for chave in (
        "versao",
        "estado",
        "etapa",
        "pagina",
        "estrategia",
        "tentativa_pagina",
        "tentativa_sessao",
        "recuperacao_utilizada",
        "duracao_ms",
        "paginas",
        "itens",
        "itens_unicos",
        "total_declarado",
        "status_http",
        "execucao_id",
        "codigo",
    ):
        if chave in seguro:
            valor = seguro[chave]
            if isinstance(valor, bool):
                valor = str(valor).lower()
            partes.append(f"{chave}={valor}")
    primeira = seguro.get("primeira_falha")
    if isinstance(primeira, Mapping):
        for chave in ("codigo", "etapa", "pagina", "estrategia", "status_http"):
            if chave in primeira:
                partes.append(f"primeira_falha_{chave}={primeira[chave]}")
    return " ".join(partes)
