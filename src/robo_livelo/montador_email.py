"""Nucleo puro: transforma o agrupamento no e-mail pronto.

Regras aplicadas aqui: RN07, RN08, RN10, RN11, RN12, RN14, RF07, RF08.
"""

from __future__ import annotations

import logging
from decimal import Decimal
from html import escape
from urllib.parse import urlparse

from robo_livelo import __version__
from robo_livelo.modelos import DOMINIO_LIVELO, Mensagem, Parceiro

_log = logging.getLogger(__name__)

ASSUNTO_SEM_PROMOCAO = "Livelo: nenhuma promoção nas suas lojas hoje"

_CORES = [
    "#df0979",
    "#7b2ff7",
    "#0a9396",
    "#ee9b00",
    "#4361ee",
    "#2a9d8f",
    "#c1121f",
    "#5f0f40",
]


def link_confiavel(link: str) -> bool:
    """PRD 9.2: so entra no e-mail link que aponte para a Livelo.

    RN08 vira controle de seguranca aqui. Sem esta checagem, uma alteracao
    na pagina colocaria um link arbitrario num e-mail que o autor confia.
    """
    try:
        endereco = urlparse(link)
    except ValueError:
        return False
    if endereco.scheme not in ("http", "https"):
        return False
    host = (endereco.hostname or "").lower()
    return host == DOMINIO_LIVELO or host.endswith("." + DOMINIO_LIVELO)


def formatar_pontos(valor: Decimal) -> str:
    """Escreve o numero como gente le. Decimal evita 2.9000000000000004."""
    normalizado = valor.normalize()
    texto = format(normalizado, "f")
    return texto.replace(".", ",")


def _descricao(parceiro: Parceiro) -> str:
    """Monta 'Ate 4 pontos por R$ 1', preservando RN11 e RN12."""
    prefixo = "Até " if parceiro.prefixo_ate else ""
    return f"{prefixo}{formatar_pontos(parceiro.pontos_atuais)} pontos por {parceiro.moeda} 1"


def _texto_anterior(parceiro: Parceiro) -> str:
    if parceiro.pontos_anteriores is None:
        return ""
    return f"eram {formatar_pontos(parceiro.pontos_anteriores)}"


def _assunto(agrupamento: dict[str, list[Parceiro]]) -> str:
    total = sum(len(lojas) for lojas in agrupamento.values())
    if total == 0:
        return ASSUNTO_SEM_PROMOCAO  # RF10
    plural = "promoções" if total > 1 else "promoção"
    return f"Livelo: {total} {plural} nas suas lojas"


def montar(agrupamento: dict[str, list[Parceiro]]) -> Mensagem:
    """Devolve a mensagem pronta, em HTML e em texto simples (RF07)."""
    total = sum(len(lojas) for lojas in agrupamento.values())
    html: list[str] = [
        "<html><body style='font-family:Arial,Helvetica,sans-serif;"
        "background:#f5f5f7;margin:0;padding:24px;'>",
        "<div style='max-width:640px;margin:0 auto;background:#ffffff;"
        "border-radius:12px;padding:24px;'>",
        "<h1 style='font-size:20px;margin:0 0 4px;color:#1d1d1f;'>Pontuação turbinada</h1>",
    ]
    texto: list[str] = ["PONTUAÇÃO TURBINADA NA LIVELO", ""]

    if total == 0:
        # RF10: o e-mail sai mesmo assim. O silencio passa a significar
        # uma coisa so: o robo parou (MS5).
        html.append(
            "<p style='color:#6e6e73;font-size:14px;'>Nenhuma das suas lojas está "
            "com pontuação turbinada agora.</p>"
        )
        texto.append("Nenhuma das suas lojas está com pontuação turbinada agora.")
    else:
        html.append(
            f"<p style='color:#6e6e73;font-size:14px;margin:0 0 20px;'>"
            f"{total} loja(s) com pontuação acima do normal.</p>"
        )

    # RN14: categoria sem loja nao aparece. O agrupamento ja filtra, mas a
    # garantia se repete aqui porque e esta camada que decide o que o e-mail
    # mostra — e e ela que responde pela regra.
    com_lojas = [(cat, lojas) for cat, lojas in agrupamento.items() if lojas]

    for indice, (categoria, lojas) in enumerate(com_lojas):
        cor = _CORES[indice % len(_CORES)]
        html.append(
            f"<h2 style='font-size:15px;color:{cor};margin:24px 0 8px;"
            f"border-left:4px solid {cor};padding-left:8px;'>{escape(categoria)}</h2>"
        )
        texto.append(f"## {categoria}")

        for parceiro in lojas:
            # RN07: tudo que veio do site e hostil ate ser escapado.
            nome = escape(parceiro.nome)
            descricao = escape(_descricao(parceiro))
            anterior = escape(_texto_anterior(parceiro))

            html.append(
                "<div style='border:1px solid #e5e5ea;border-radius:10px;"
                "padding:12px 14px;margin-bottom:8px;'>"
                f"<strong style='font-size:15px;color:#1d1d1f;'>{nome}</strong><br>"
                f"<span style='font-size:14px;color:{cor};font-weight:bold;'>{descricao}</span>"
            )
            if anterior:
                html.append(f" <span style='font-size:12px;color:#8e8e93;'>({anterior})</span>")
            if parceiro.pontos_clube is not None:  # RN10
                clube = escape(f"Clube: {formatar_pontos(parceiro.pontos_clube)} pontos")
                html.append(f"<br><span style='font-size:13px;color:#6e6e73;'>{clube}</span>")

            if link_confiavel(parceiro.link):  # RN08
                html.append(
                    f"<br><a href='{escape(parceiro.link, quote=True)}' "
                    f"style='display:inline-block;margin-top:8px;font-size:13px;"
                    f"color:#ffffff;background:{cor};padding:6px 14px;"
                    f"border-radius:6px;text-decoration:none;'>Ver oferta</a>"
                )
            elif parceiro.link:
                _log.warning("Link fora do dominio da Livelo descartado: %r", parceiro.link)

            html.append("</div>")

            linha = f"- {parceiro.nome}: {_descricao(parceiro)}"
            if anterior:
                linha += f" ({_texto_anterior(parceiro)})"
            if parceiro.pontos_clube is not None:
                linha += f" | Clube: {formatar_pontos(parceiro.pontos_clube)} pontos"
            if link_confiavel(parceiro.link):
                linha += f"\n  {parceiro.link}"
            texto.append(linha)

        texto.append("")

    # Versao no rodape: quando algo vier errado, da pra saber o que gerou.
    html.append(
        f"<p style='margin-top:24px;font-size:11px;color:#a1a1a6;text-align:center;'>"
        f"robô-livelo v{escape(__version__)}</p>"
    )
    html.append("</div></body></html>")
    texto.append(f"-- robô-livelo v{__version__}")
    return Mensagem(
        assunto=_assunto(agrupamento),
        corpo_html="".join(html),
        corpo_texto="\n".join(texto).strip() + "\n",
    )
