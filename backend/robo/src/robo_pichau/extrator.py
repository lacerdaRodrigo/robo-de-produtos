"""Extracao tolerante de listagens e paginas de produto da Pichau."""

from __future__ import annotations

import json
import re
from dataclasses import replace
from decimal import Decimal, InvalidOperation
from urllib.parse import parse_qs, urljoin, urlparse

from bs4 import BeautifulSoup, Tag

from .modelos import PaginaPichau, PichauProduto
from .portas import PaginacaoPichauInvalida, RespostaPichauInvalida

HOSTS_VALIDOS = {"pichau.com.br", "www.pichau.com.br"}
MOEDA_RE = re.compile(r"R\$\s*[-+]?\d[\d\s.,]*", re.IGNORECASE)
PERCENTUAL_RE = re.compile(r"(\d{1,3})\s*%")
SKU_RE = re.compile(r"(?:sku|c[oó]digo)\s*[:#-]?\s*([A-Za-z0-9][A-Za-z0-9._-]{2,})", re.I)
TOTAL_RE = re.compile(r"(?:de|of)\s+(\d[\d.]*)\s+resultados", re.I)
NEXT_PUSH_RE = re.compile(r"self\.__next_f\.push\((\[.*\])\)\s*$", re.S)


def texto(tag: Tag | None) -> str | None:
    if tag is None:
        return None
    valor = " ".join(tag.get_text(" ", strip=True).split())
    return valor or None


def decimal_brasileiro(valor: str | None) -> Decimal | None:
    """Converte valores pt-BR e os valores com virgula usados em algumas respostas."""

    if not valor:
        return None
    limpo = re.sub(r"[^\d,.-]", "", valor)
    if not limpo:
        return None
    if "," in limpo and "." in limpo:
        if limpo.rfind(",") > limpo.rfind("."):
            limpo = limpo.replace(".", "").replace(",", ".")
        else:
            limpo = limpo.replace(",", "")
    elif "," in limpo:
        limpo = limpo.replace(",", ".")
    elif limpo.count(".") > 1:
        limpo = limpo.replace(".", "")
    try:
        return Decimal(limpo)
    except InvalidOperation:
        return None


def primeiro_preco(texto_bruto: str | None) -> tuple[str | None, Decimal | None]:
    if not texto_bruto:
        return None, None
    encontrado = MOEDA_RE.search(texto_bruto)
    if not encontrado:
        return None, None
    valor = " ".join(encontrado.group(0).split())
    return valor, decimal_brasileiro(valor)


def _url_segura(url: str, base: str = "https://www.pichau.com.br") -> str:
    completa = urljoin(base, url).split("#", 1)[0]
    analisada = urlparse(completa)
    if analisada.scheme != "https" or analisada.hostname not in HOSTS_VALIDOS:
        raise RespostaPichauInvalida("A Pichau devolveu URL de produto insegura.", codigo="url")
    return completa


def id_por_url(url: str, sku: str | None = None) -> str:
    if sku:
        return sku.strip()
    caminho = urlparse(url).path.rstrip("/")
    numeros = re.search(r"(?:-|/)(\d{3,})(?:$|-)", caminho)
    if numeros:
        return f"pichau-{numeros.group(1)}"
    slug = caminho.rsplit("/", 1)[-1]
    slug = re.sub(r"[^A-Za-z0-9_-]+", "-", slug).strip("-")
    if not slug:
        raise RespostaPichauInvalida("Produto sem identificador estavel.", codigo="identidade")
    return f"pichau-{slug[:180]}"


def _primeiro(container: Tag, seletores: tuple[str, ...]) -> Tag | None:
    for seletor in seletores:
        encontrado = container.select_one(seletor)
        if encontrado is not None:
            return encontrado
    return None


def _atributo_ou_texto(
    container: Tag, seletores: tuple[str, ...], atributo: str | None = None
) -> str | None:
    alvo = _primeiro(container, seletores)
    if alvo is None:
        return None
    if atributo:
        valor = alvo.get(atributo)
        if isinstance(valor, str) and valor.strip():
            return " ".join(valor.split())
    return texto(alvo)


def _etiquetas(container: Tag) -> tuple[str, ...]:
    encontrados = container.select(".badge, .tag, .label, [data-label], [data-badge]")
    valores = [
        texto(item) or item.get("data-label") or item.get("data-badge") for item in encontrados
    ]
    valores += [item.strip() for item in container.get("data-tags", "").split(",") if item.strip()]
    return tuple(dict.fromkeys(item for item in valores if item))


def _disponibilidade(container: Tag, bruto: str | None) -> str:
    valor = (bruto or "").lower()
    if any(item in valor for item in ("esgotado", "indisponível", "indisponivel", "out of stock")):
        return "esgotado"
    if any(item in valor for item in ("pré-venda", "pre-venda", "pre venda", "pre_venda")):
        return "pre_venda"
    if any(item in valor for item in ("disponível", "disponivel", "em estoque", "comprar")):
        return "disponivel"
    classe = " ".join(container.get("class", []))
    if "out-of-stock" in classe or "sold-out" in classe:
        return "esgotado"
    return "nao_informado"


def _produto_card(card: Tag, base_url: str) -> PichauProduto | None:
    link_tag = _primeiro(
        card, ("a[data-product-url]", "a.product-link", "a[href*='/pc-gamer']", "a[href]")
    )
    href = link_tag.get("data-product-url") if link_tag else None
    href = href or (link_tag.get("href") if link_tag else None)
    nome = _atributo_ou_texto(
        card,
        ("[data-product-name]", ".product-name", ".product-title", "h2", "h3"),
        "data-product-name",
    )
    if not href or not nome:
        return None
    url = _url_segura(href, base_url)
    sku = card.get("data-sku") or card.get("data-product-sku")
    marca = _atributo_ou_texto(card, ("[data-brand]", ".product-brand", ".brand"), "data-brand")
    conteudo = texto(card) or ""
    sku = sku or (SKU_RE.search(conteudo).group(1) if SKU_RE.search(conteudo) else None)
    original_texto, original = primeiro_preco(
        _atributo_ou_texto(
            card, (".price-old", ".old-price", "[data-price-original]"), "data-price-original"
        )
    )
    pix_texto, pix = primeiro_preco(
        _atributo_ou_texto(
            card, (".price-pix", ".pix-price", "[data-price-pix]", ".price"), "data-price-pix"
        )
    )
    cartao_texto, cartao = primeiro_preco(
        _atributo_ou_texto(
            card, (".price-card", ".card-price", "[data-price-card]"), "data-price-card"
        )
    )
    desconto = _atributo_ou_texto(
        card, (".discount", ".discount-percent", "[data-discount]"), "data-discount"
    )
    if desconto is None:
        percentual = PERCENTUAL_RE.search(conteudo)
        desconto = percentual.group(0) if percentual else None
    desconto_valor = decimal_brasileiro(
        PERCENTUAL_RE.search(desconto).group(1)
        if desconto and PERCENTUAL_RE.search(desconto)
        else None
    )
    parcelamento = _atributo_ou_texto(
        card, (".installment", ".installments", "[data-installments]"), "data-installments"
    )
    sem_juros = None if parcelamento is None else ("sem juros" in parcelamento.lower())
    disponibilidade_texto = _atributo_ou_texto(
        card,
        ("[data-availability]", ".availability", ".stock", ".availability-label"),
        "data-availability",
    )
    return PichauProduto(
        id_externo=id_por_url(url, sku),
        nome=nome,
        url_produto=url,
        sku=sku,
        marca=marca,
        disponibilidade=_disponibilidade(card, disponibilidade_texto or conteudo),
        preco_original_texto=original_texto,
        preco_original_valor=original,
        preco_pix_texto=pix_texto,
        preco_pix_valor=pix,
        desconto_pix_texto=desconto,
        desconto_pix_valor=desconto_valor,
        preco_cartao_texto=cartao_texto,
        preco_cartao_valor=cartao,
        parcelamento=parcelamento,
        valor_parcela_texto=primeiro_preco(parcelamento)[0] if parcelamento else None,
        sem_juros=sem_juros,
        estoque_texto=disponibilidade_texto,
        etiquetas=_etiquetas(card),
    )


def _json_ld(soup: BeautifulSoup) -> list[dict]:
    itens: list[dict] = []
    for script in soup.select('script[type="application/ld+json"]'):
        try:
            valor = json.loads(script.string or script.get_text())
        except (TypeError, json.JSONDecodeError):
            continue
        candidatos = valor if isinstance(valor, list) else [valor]
        itens.extend(item for item in candidatos if isinstance(item, dict))
    return itens


def _catalogo_next(html: str) -> dict | None:
    """Localiza o catálogo serializado pelo Next.js no HTML renderizado."""

    soup = BeautifulSoup(html, "lxml")
    decoder = json.JSONDecoder(parse_float=Decimal)
    for script in soup.find_all("script"):
        conteudo = script.string or script.get_text()
        if not conteudo or "self.__next_f.push(" not in conteudo:
            continue
        encontrado = NEXT_PUSH_RE.search(conteudo)
        if not encontrado:
            continue
        try:
            registro = json.loads(encontrado.group(1))
        except json.JSONDecodeError:
            continue
        if len(registro) < 2 or not isinstance(registro[1], str):
            continue
        payload = registro[1]
        for _ in range(3):
            inicio = payload.find('{"category"')
            if inicio < 0:
                inicio = payload.find('{"query"')
            if inicio >= 0:
                try:
                    documento, _ = decoder.raw_decode(payload[inicio:])
                except json.JSONDecodeError:
                    documento = None
                if (
                    isinstance(documento, dict)
                    and isinstance(documento.get("products"), dict)
                    and isinstance(documento["products"].get("items"), list)
                ):
                    return documento
            payload = payload.replace('\\"', '"')
    return None


def _texto_moeda(valor: Decimal | int | float | None) -> str | None:
    if valor is None:
        return None
    decimal = valor if isinstance(valor, Decimal) else Decimal(str(valor))
    formatado = f"{decimal:,.2f}".replace(",", "#").replace(".", ",").replace("#", ".")
    return f"R$ {formatado}"


def _decimal_valor(valor: object) -> Decimal | None:
    if isinstance(valor, Decimal):
        return valor
    if isinstance(valor, (int, float)) and not isinstance(valor, bool):
        return Decimal(str(valor))
    if isinstance(valor, str):
        return decimal_brasileiro(valor)
    return None


def _produto_next(item: dict, base_url: str) -> PichauProduto | None:
    nome = item.get("name")
    slug = item.get("url_key")
    if not isinstance(nome, str) or not nome.strip() or not isinstance(slug, str):
        return None
    try:
        origem = urlparse(base_url)
        base_origem = f"{origem.scheme}://{origem.netloc}/"
        url = _url_segura(slug, base_origem)
    except RespostaPichauInvalida:
        return None
    precos = item.get("pichau_prices")
    precos = precos if isinstance(precos, dict) else {}
    pix = _decimal_valor(precos.get("avista"))
    original = _decimal_valor(precos.get("base_price"))
    cartao = _decimal_valor(precos.get("final_price"))
    parcelas = precos.get("max_installments")
    valor_parcela = _decimal_valor(precos.get("min_installment_price"))
    desconto = _decimal_valor(precos.get("avista_discount"))
    marca_info = item.get("marcas_info")
    marca = marca_info.get("name") if isinstance(marca_info, dict) else None
    sku = item.get("sku") if isinstance(item.get("sku"), str) else None
    estado_fonte = str(item.get("stock_status") or "").upper()
    if item.get("pichau_prevenda"):
        disponibilidade = "pre_venda"
    elif estado_fonte in {"IN_STOCK", "AVAILABLE"}:
        disponibilidade = "disponivel"
    elif estado_fonte in {"OUT_OF_STOCK", "UNAVAILABLE"}:
        disponibilidade = "esgotado"
    else:
        disponibilidade = "nao_informado"
    etiquetas: list[str] = ["PC Gamer"]
    rotulo = item.get("amasty_label")
    if isinstance(rotulo, dict):
        for grupo in ("product_labels", "category_labels"):
            valores = rotulo.get(grupo)
            if not isinstance(valores, list):
                continue
            etiquetas.extend(
                valor["label"]
                for valor in valores
                if isinstance(valor, dict) and isinstance(valor.get("label"), str)
            )
    etiquetas = list(dict.fromkeys(etiquetas))
    parcelamento = None
    valor_parcela_texto = _texto_moeda(valor_parcela)
    if parcelas is not None and valor_parcela_texto:
        try:
            parcelas_texto = str(int(parcelas))
        except (TypeError, ValueError):
            parcelas_texto = str(parcelas)
        parcelamento = f"{parcelas_texto}x de {valor_parcela_texto}"
    identificador = sku or (f"pichau-{item['id']}" if item.get("id") is not None else None)
    return PichauProduto(
        id_externo=id_por_url(url, identificador),
        nome=nome.strip(),
        url_produto=url,
        sku=sku,
        marca=marca if isinstance(marca, str) else None,
        disponibilidade=disponibilidade,
        preco_original_texto=_texto_moeda(original),
        preco_original_valor=original,
        preco_pix_texto=_texto_moeda(pix),
        preco_pix_valor=pix,
        desconto_pix_texto=f"{desconto}% no Pix" if desconto is not None else None,
        desconto_pix_valor=desconto,
        preco_cartao_texto=_texto_moeda(cartao),
        preco_cartao_valor=cartao,
        parcelamento=parcelamento,
        valor_parcela_texto=valor_parcela_texto,
        sem_juros=None,
        estoque_texto=str(item.get("stock_status")) if item.get("stock_status") else None,
        etiquetas=tuple(etiquetas),
    )


def _produto_json_ld(item: dict, base_url: str) -> PichauProduto | None:
    if (
        item.get("@type") not in ("Product", "ProductGroup")
        or not item.get("name")
        or not item.get("url")
    ):
        return None
    try:
        url = _url_segura(str(item["url"]), base_url)
    except RespostaPichauInvalida:
        return None
    oferta = item.get("offers") if isinstance(item.get("offers"), dict) else {}
    preco = str(oferta.get("price")) if oferta.get("price") is not None else None
    disponibilidade = str(oferta.get("availability", "")).lower()
    estado = (
        "esgotado"
        if "outofstock" in disponibilidade
        else "disponivel"
        if disponibilidade
        else "nao_informado"
    )
    return PichauProduto(
        id_externo=id_por_url(url, str(item.get("sku")) if item.get("sku") else None),
        nome=str(item["name"]).strip(),
        url_produto=url,
        sku=str(item["sku"]) if item.get("sku") else None,
        marca=str(item["brand"].get("name"))
        if isinstance(item.get("brand"), dict) and item["brand"].get("name")
        else None,
        disponibilidade=estado,
        preco_pix_valor=decimal_brasileiro(preco),
        preco_pix_texto=f"R$ {preco}" if preco else None,
    )


def extrair_pagina(
    html: str,
    *,
    pagina_esperada: int,
    por_pagina: int,
    base_url: str = "https://www.pichau.com.br/computadores/pichau-gamer",
) -> PaginaPichau:
    soup = BeautifulSoup(html, "lxml")
    cards: list[Tag] = []
    for seletor in (
        "article.product-card",
        "li.product-item",
        ".product-item",
        "[data-product-id]",
        "[data-product-sku]",
    ):
        cards = soup.select(seletor)
        if cards:
            break
    produtos = [produto for card in cards if (produto := _produto_card(card, base_url))]
    if not produtos:
        produtos = [
            produto for item in _json_ld(soup) if (produto := _produto_json_ld(item, base_url))
        ]
    total: int | None = None
    if not produtos:
        catalogo = _catalogo_next(html)
        if catalogo:
            dados_produtos = catalogo["products"]
            produtos = [
                produto
                for item in dados_produtos["items"]
                if isinstance(item, dict) and (produto := _produto_next(item, base_url)) is not None
            ]
            total_bruto = dados_produtos.get("total_count")
            try:
                total = int(total_bruto) if total_bruto is not None else None
            except (TypeError, ValueError):
                total = None
    if total is None:
        texto_pagina = " ".join(soup.stripped_strings)
        total_match = TOTAL_RE.search(texto_pagina)
        total = int(total_match.group(1).replace(".", "")) if total_match else len(produtos)
    pagina_no_html = parse_qs(urlparse(base_url).query).get("page", [str(pagina_esperada)])[0]
    if pagina_no_html.isdigit() and int(pagina_no_html) != pagina_esperada:
        raise PaginacaoPichauInvalida(
            "A pagina recebida nao corresponde a solicitada.", codigo="pagina"
        )
    if total < len(produtos):
        raise PaginacaoPichauInvalida(
            "A fonte declarou total menor que os itens lidos.", codigo="total"
        )
    ultima = len(produtos) == 0 or pagina_esperada * por_pagina >= total
    return PaginaPichau(pagina_esperada, por_pagina, total, ultima, len(produtos), tuple(produtos))


def extrair_detalhe_produto(html: str, produto: PichauProduto) -> PichauProduto:
    soup = BeautifulSoup(html, "lxml")
    corpo = " ".join(soup.stripped_strings)
    sku_match = SKU_RE.search(corpo)
    sku = produto.sku or (sku_match.group(1) if sku_match else None)
    marca = produto.marca or _atributo_ou_texto(
        soup, ("[data-brand]", ".brand", ".product-brand"), "data-brand"
    )
    preco_texto, preco = primeiro_preco(
        _atributo_ou_texto(soup, ("[data-price-pix]", ".pix-price", ".price"), "data-price-pix")
    )
    disponibilidade = _disponibilidade(soup, corpo)
    return replace(
        produto,
        sku=sku,
        # A identidade escolhida na listagem nao muda so porque a pagina
        # individual revelou um SKU que estava ausente no primeiro retrato.
        id_externo=produto.id_externo,
        marca=marca,
        preco_pix_texto=produto.preco_pix_texto or preco_texto,
        preco_pix_valor=produto.preco_pix_valor or preco,
        disponibilidade=disponibilidade
        if disponibilidade != "nao_informado"
        else produto.disponibilidade,
    )


def normalizar_busca(texto_bruto: str) -> str:
    import unicodedata

    return " ".join(
        unicodedata.normalize("NFKD", texto_bruto)
        .encode("ascii", "ignore")
        .decode()
        .lower()
        .split()
    )
