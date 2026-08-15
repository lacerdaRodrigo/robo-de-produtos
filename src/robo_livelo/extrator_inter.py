"""Nucleo puro: resposta JSON do Shopping Inter vira objetos de dominio."""

from __future__ import annotations

import json
import re
import unicodedata
from dataclasses import dataclass
from decimal import Decimal, InvalidOperation

from robo_livelo.modelos_inter import LojaInter

MAX_ID = 200
MAX_NOME = 200
MAX_SLUG = 200
MAX_ROTULO = 300
MAX_DESCRICAO = 20_000
MAX_CASHBACK = Decimal("1000")


class RespostaInterInvalida(ValueError):
    """A resposta nao respeita o contrato defensivo definido no PRD-V3."""


class ConflitoIdentidadeInter(RespostaInterInvalida):
    """ID ou slug duplicado torna inseguro atualizar o catalogo."""


@dataclass(frozen=True, slots=True)
class ExtracaoInter:
    """Resultado com contagem bruta e itens validos separados."""

    lojas_lidas: int
    lojas: tuple[LojaInter, ...]

    @property
    def lojas_validas(self) -> int:
        return len(self.lojas)


def normalizar_busca(texto: str) -> str:
    """Normalizacao identica ao contrato do site, sem extensao do Postgres."""

    decomposto = unicodedata.normalize("NFKD", texto)
    sem_marcas = "".join(c for c in decomposto if not unicodedata.combining(c))
    return re.sub(r"\s+", " ", sem_marcas.lower().strip())


def extrair_lojas(conteudo: str) -> ExtracaoInter:
    """Decodifica uma resposta completa sem fazer I/O.

    Item isolado malformado e descartado. Formato de raiz ou identidade
    duplicada invalida a resposta inteira, porque nao ha como escolher a
    loja correta sem adivinhar (RN34/RN43).
    """

    try:
        bruto = json.loads(conteudo, parse_float=Decimal)
    except (json.JSONDecodeError, TypeError) as erro:
        raise RespostaInterInvalida("JSON do Shopping Inter invalido.") from erro
    if not isinstance(bruto, list):
        raise RespostaInterInvalida("A resposta do Shopping Inter nao e uma lista.")

    lojas: list[LojaInter] = []
    ids: set[str] = set()
    slugs: set[str] = set()
    for item in bruto:
        if not isinstance(item, dict):
            continue
        try:
            loja = _extrair_loja(item)
        except (KeyError, TypeError, ValueError, InvalidOperation):
            continue

        if loja.id_externo in ids:
            raise ConflitoIdentidadeInter(f"ID de loja duplicado: {loja.id_externo!r}.")
        if loja.slug in slugs:
            raise ConflitoIdentidadeInter(f"Slug de loja duplicado: {loja.slug!r}.")
        ids.add(loja.id_externo)
        slugs.add(loja.slug)
        lojas.append(loja)

    return ExtracaoInter(lojas_lidas=len(bruto), lojas=tuple(lojas))


def _extrair_loja(item: dict) -> LojaInter:
    if "fullCashbackValue" not in item:
        raise KeyError("fullCashbackValue")
    return LojaInter(
        id_externo=_texto_obrigatorio(item, "id", MAX_ID),
        slug=_texto_obrigatorio(item, "slug", MAX_SLUG),
        nome=_texto_obrigatorio(item, "name", MAX_NOME),
        cashback_principal_texto=_texto_obrigatorio(item, "fullCashback", MAX_ROTULO),
        cashback_principal_valor=_decimal(item.get("fullCashbackValue"), aceita_nulo=True),
        cashback_secundario_texto=_texto_opcional(item.get("partialCashback"), MAX_ROTULO),
        cashback_secundario_valor=_decimal(item.get("partialCashbackValue"), aceita_nulo=True),
        etiqueta=_texto_opcional(item.get("promotionTag"), MAX_ROTULO),
        descricao_principal=_texto_opcional(item.get("redirectWarning"), MAX_DESCRICAO),
        descricao_secundaria=_texto_opcional(
            item.get("redirectWarningBasicAccount"), MAX_DESCRICAO
        ),
    )


def _texto_obrigatorio(item: dict, chave: str, limite: int) -> str:
    if chave not in item:
        raise KeyError(chave)
    texto = _texto_opcional(item[chave], limite)
    if texto is None:
        raise ValueError(f"{chave} vazio")
    return texto


def _texto_opcional(valor: object, limite: int) -> str | None:
    if valor is None:
        return None
    if not isinstance(valor, str):
        raise TypeError("texto esperado")
    limpo = "".join(
        caractere
        for caractere in valor.replace("\r\n", "\n").replace("\r", "\n")
        if caractere in "\n\t" or not unicodedata.category(caractere).startswith("C")
    ).strip()
    if not limpo:
        return None
    if len(limpo) > limite:
        raise ValueError("texto excede limite")
    return limpo


def _decimal(valor: object, *, aceita_nulo: bool) -> Decimal | None:
    if valor is None and aceita_nulo:
        return None
    if isinstance(valor, bool):
        raise TypeError("booleano nao e cashback")
    numero = Decimal(str(valor))
    if not numero.is_finite() or numero < 0 or numero > MAX_CASHBACK:
        raise ValueError("cashback fora do intervalo")
    normalizado = numero.normalize()
    casas = max(0, -normalizado.as_tuple().exponent)
    if casas > 2:
        raise ValueError("cashback tem mais de duas casas")
    return normalizado
