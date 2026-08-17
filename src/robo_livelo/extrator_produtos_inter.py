"""Nucleo puro da V4: JSON paginado do Inter vira ofertas imutaveis."""

from __future__ import annotations

import json
import re
import unicodedata
from decimal import Decimal, InvalidOperation
from urllib.parse import urlsplit

from robo_livelo.modelos_produtos_inter import (
    LojaDiretaInter,
    PaginaProdutosInter,
    ProdutoDiretoInter,
)

MAX_ID = 200
MAX_TEXTO = 500
MAX_NOME = 1_000
MAX_ETIQUETAS = 20
MAX_PRECO = Decimal("10000000")


class RespostaProdutosInterInvalida(ValueError):
    """A resposta nao tem a estrutura minima publica observada no PRD-V4."""


def extrair_lojas_diretas(conteudo: str) -> tuple[LojaDiretaInter, ...]:
    """Valida o catalogo publico de vendedores sem reaproveitar a V3."""

    try:
        bruto = json.loads(conteudo)
    except (json.JSONDecodeError, TypeError) as erro:
        raise RespostaProdutosInterInvalida("JSON de lojas diretas invalido.") from erro
    itens = bruto.get("data") if isinstance(bruto, dict) else bruto
    if not isinstance(itens, list):
        raise RespostaProdutosInterInvalida("O catalogo de lojas diretas nao e uma lista.")

    lojas: list[LojaDiretaInter] = []
    ids: set[str] = set()
    slugs: set[str] = set()
    for item in itens:
        if not isinstance(item, dict):
            continue
        try:
            loja = LojaDiretaInter(
                id_externo=_texto_obrigatorio(item, "id", MAX_ID),
                slug=_texto_obrigatorio(item, "slug", MAX_ID),
                nome=_texto_obrigatorio(item, "name", MAX_NOME),
            )
        except (KeyError, TypeError, ValueError):
            continue
        if loja.id_externo in ids or loja.slug in slugs:
            raise RespostaProdutosInterInvalida(
                "Catalogo de lojas diretas tem identidade duplicada."
            )
        ids.add(loja.id_externo)
        slugs.add(loja.slug)
        lojas.append(loja)
    return tuple(lojas)


def normalizar_busca_produtos(texto: str) -> str:
    """Normaliza busca local (RN67/RN68), sem depender do banco."""

    decomposto = unicodedata.normalize("NFKD", texto)
    sem_marcas = "".join(char for char in decomposto if not unicodedata.combining(char))
    palavras = re.findall(r"[a-z0-9]+", sem_marcas.lower())
    sinonimos = {"celular": "smartphone", "smartphone": "smartphone"}
    ignoradas = {"a", "as", "da", "das", "de", "do", "dos", "e", "o", "os", "para", "por"}
    return " ".join(
        sinonimos.get(palavra, palavra) for palavra in palavras if palavra not in ignoradas
    )


def extrair_pagina_produtos(conteudo: str, *, id_loja: str) -> PaginaProdutosInter:
    """Decodifica uma pagina sem rede e descarta itens isolados invalidos.

    A raiz e a paginacao invalidas falham a tentativa inteira. Um item ruim
    nao derruba uma loja toda, mas itens de outro vendedor nunca entram no
    catalogo solicitado (RF40, RN54 e RNF28).
    """

    try:
        bruto = json.loads(conteudo, parse_float=Decimal)
    except (json.JSONDecodeError, TypeError) as erro:
        raise RespostaProdutosInterInvalida("JSON de produtos do Inter invalido.") from erro
    if not isinstance(bruto, dict):
        raise RespostaProdutosInterInvalida("A resposta de produtos nao e um objeto.")

    raiz = bruto.get("data") if isinstance(bruto.get("data"), dict) else bruto
    paginacao = raiz.get("pagination")
    if not isinstance(paginacao, dict):
        raise RespostaProdutosInterInvalida("A resposta de produtos nao tem paginacao.")
    itens = raiz.get("products", raiz.get("content"))
    if not isinstance(itens, list):
        raise RespostaProdutosInterInvalida("A resposta de produtos nao tem lista de itens.")

    offset = _inteiro(paginacao.get("offset"), "offset")
    limite = _inteiro(paginacao.get("limit"), "limit")
    total = _inteiro(paginacao.get("total"), "total")
    ultima = paginacao.get("isLastPage", paginacao.get("last"))
    if not isinstance(ultima, bool):
        raise RespostaProdutosInterInvalida("A paginacao nao informou isLastPage.")
    if offset < 0 or limite <= 0 or total < 0:
        raise RespostaProdutosInterInvalida("A paginacao tem valor negativo ou limite nulo.")

    produtos: list[ProdutoDiretoInter] = []
    for item in itens:
        if not isinstance(item, dict):
            continue
        try:
            produto = _extrair_produto(item, id_loja)
        except (KeyError, TypeError, ValueError, InvalidOperation):
            continue
        if produto is not None:
            produtos.append(produto)

    return PaginaProdutosInter(
        offset=offset,
        limite=limite,
        total=total,
        ultima=ultima,
        itens_lidos=len(itens),
        produtos=tuple(produtos),
    )


def _extrair_produto(item: dict[str, object], id_loja: str) -> ProdutoDiretoInter | None:
    vendedor = item.get("sellerId")
    if vendedor is not None and str(vendedor).strip() != id_loja:
        return None
    return ProdutoDiretoInter(
        id_externo=_texto_obrigatorio(item, "id", MAX_ID),
        nome=_texto_obrigatorio(item, "name", MAX_NOME),
        caminho=_caminho_seguro(_texto_obrigatorio(item, "slug", MAX_NOME)),
        marca=_texto_opcional(item.get("brand"), MAX_TEXTO),
        categoria=_texto_opcional(item.get("categoryName"), MAX_TEXTO),
        preco_cheio_texto=_texto_opcional(item.get("listPrice"), MAX_TEXTO),
        preco_cheio_valor=_decimal(item.get("listPriceValue")),
        preco_atual_texto=_texto_opcional(item.get("price"), MAX_TEXTO),
        preco_atual_valor=_decimal(item.get("priceValue")),
        desconto_texto=_texto_opcional(item.get("discountPrice"), MAX_TEXTO),
        desconto_valor=_decimal(item.get("discountPriceValue")),
        desconto_percentual_texto=_texto_opcional(item.get("discountPercentage"), MAX_TEXTO),
        desconto_percentual_valor=_decimal(item.get("discountPercentageValue"), percentual=True),
        cashback_texto=_texto_opcional(item.get("fullCashback"), MAX_TEXTO),
        cashback_valor=_decimal(item.get("fullCashbackValue")),
        cashback_percentual_texto=_texto_opcional(item.get("fullCashbackPercentage"), MAX_TEXTO),
        cashback_percentual_valor=_decimal(
            item.get("fullCashbackPercentageValue"), percentual=True
        ),
        preco_liquido_texto=_texto_opcional(item.get("fullLiquidPrice"), MAX_TEXTO),
        preco_liquido_valor=_decimal(item.get("fullLiquidPriceValue")),
        parcelamento=_texto_opcional(item.get("fullInstallmentsDescription"), MAX_TEXTO),
        estoque=_texto_opcional(item.get("stock"), MAX_TEXTO),
        etiquetas=_etiquetas(item.get("tags")),
    )


def _inteiro(valor: object, campo: str) -> int:
    if isinstance(valor, bool):
        raise RespostaProdutosInterInvalida(f"{campo} nao e inteiro.")
    try:
        inteiro = int(valor)
    except (TypeError, ValueError) as erro:
        raise RespostaProdutosInterInvalida(f"{campo} nao e inteiro.") from erro
    if str(inteiro) != str(valor).strip() and not isinstance(valor, int):
        raise RespostaProdutosInterInvalida(f"{campo} nao e inteiro.")
    return inteiro


def _texto_obrigatorio(item: dict[str, object], chave: str, limite: int) -> str:
    texto = _texto_opcional(item.get(chave), limite)
    if texto is None:
        raise KeyError(chave)
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


def _decimal(valor: object, *, percentual: bool = False) -> Decimal | None:
    if valor is None:
        return None
    if isinstance(valor, bool):
        raise TypeError("booleano nao e valor monetario")
    numero = Decimal(str(valor))
    limite = Decimal("100") if percentual else MAX_PRECO
    if not numero.is_finite() or numero < 0 or numero > limite:
        raise ValueError("valor fora do intervalo")
    numero = numero.normalize()
    if max(0, -numero.as_tuple().exponent) > 2:
        raise ValueError("valor tem mais de duas casas")
    return numero


def _etiquetas(valor: object) -> tuple[str, ...]:
    if valor is None:
        return ()
    if not isinstance(valor, list) or len(valor) > MAX_ETIQUETAS:
        raise TypeError("etiquetas invalidas")
    etiquetas = tuple(
        texto for item in valor if (texto := _texto_opcional(item, MAX_TEXTO)) is not None
    )
    return etiquetas


def _caminho_seguro(caminho: str) -> str:
    partes = urlsplit(caminho)
    if (
        partes.scheme
        or partes.netloc
        or not caminho.startswith("/")
        or caminho.startswith("//")
        or ".." in partes.path.split("/")
    ):
        raise ValueError("caminho de produto inseguro")
    return caminho
