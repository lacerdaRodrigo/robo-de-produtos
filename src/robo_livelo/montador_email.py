"""Nucleo puro: transforma o agrupamento no e-mail pronto.

Regras aplicadas aqui: RN07, RN08, RN10, RN11, RN12, RN14, RN22, RN23,
RF07, RF08, RF18.
"""

from __future__ import annotations

import logging
import re
from datetime import datetime
from decimal import Decimal
from html import escape
from urllib.parse import urlparse

from robo_livelo import __version__
from robo_livelo.modelos import DOMINIO_LIVELO, Mensagem, Parceiro

_log = logging.getLogger(__name__)

ASSUNTO_SEM_PROMOCAO = "Livelo: nenhuma promoção nas suas lojas hoje"

# Catalogo vazio nao e "nao teve promocao": e "nao ha o que procurar". Dizer
# a mesma frase nos dois casos esconderia de voce que o robo esta rodando no
# vazio (O3: falha nunca e silenciosa).
ASSUNTO_SEM_CATALOGO = "Livelo: nenhuma loja cadastrada"

# Paleta curada (redesign 2026-08-13): seis tons distintos o bastante para
# escanear categoria por cor, sem virar arco-iris. Ciclo se repete depois da
# sexta categoria — nunca vimos mais que 7-8 num dia real.
_CORES = [
    "#e11d48",
    "#7c3aed",
    "#0891b2",
    "#d97706",
    "#2563eb",
    "#059669",
]

# Marca "R$ vira ponto" (redesign 2026-08-13, ver docs/EMAIL.md), hospedada
# no site em vez de base64: confirmado ao vivo que o Gmail descarta
# `<img src="data:...">` no corpo de um e-mail recebido (funciona em
# pagina web, nao em e-mail — e por isso nenhum template de e-mail do
# mercado embute logo em base64, todos hospedam). URL fixa, nao e I/O —
# e uma string, igual DOMINIO_LIVELO.
_LOGO_URL = "https://robo-livelo.vercel.app/logo.png"

# CSS unico no <head>: repetir estilo inline em cada cartao e o que fazia o
# HTML antigo pesar quase todo o orcamento do Gmail so com 132 lojas em
# promocao (C05, ver teste_pior_caso_cabe_no_limite_do_gmail). Uma folha so,
# aplicada por classe, deixa o mesmo visual pesando bem menos por loja — e
# por isso as classes sao curtas (.bk, .ib...): cada letra a menos e menos
# um byte multiplicado por ate 132 lojas no pior caso.
#
# Cor por categoria NAO pode virar custom property (`--c`) num `style=`
# inline: confirmado ao vivo em 2026-08-13, o Gmail remove `--c` do
# atributo `style` na sanitizacao (embora aceite `background`/`color`
# normalmente), entao `var(--c)` cai no vazio e o bloco fica sem cor. Por
# isso `background`/`color` aparecem inline em cada elemento que precisa
# da cor da categoria, em vez de herdar de um `--c` no ancestral.
_ESTILO = """
.mc{max-width:540px;margin:0 auto;background:#ffffff;border-radius:18px;
  padding:26px 22px;color:#18131d;font-family:Arial,Helvetica,sans-serif}
.mb{display:flex;align-items:center;justify-content:center;gap:8px;margin:0 0 20px;
  padding-bottom:18px;border-bottom:1px solid #ece7ef}
.mb img{display:block}
.mb b{font-size:15px;font-weight:800;letter-spacing:-.01em;color:#3a3440}
.h1{font-size:20px;margin:0 0 3px;font-weight:800;letter-spacing:-.01em}
.s0{font-size:13px;color:#8a8390;margin:0 0 22px}
.ct{display:flex;align-items:center;gap:9px;margin:26px 0 12px}
.ct:first-of-type{margin-top:0}
.cc{font-size:11.5px;font-weight:800;letter-spacing:.05em;text-transform:uppercase;
  color:#fff;padding:4px 11px;border-radius:20px}
.cn{color:#a49dab;font-size:11.5px;font-weight:600}
.bw{margin-bottom:12px;border-radius:14px;overflow:hidden;
  box-shadow:0 2px 8px -4px rgba(0,0,0,.14)}
.rw{display:flex;align-items:stretch}
.bk{flex:none;width:74px;display:flex;flex-direction:column;align-items:center;
  justify-content:center;color:#fff;font-weight:800;padding:10px 4px;text-align:center}
.bk b{font-size:22px;line-height:1;display:block}
.bk small{display:block;font-size:8.5px;font-weight:700;opacity:.9;letter-spacing:.03em;
  margin-top:2px}
.ib{flex:1;min-width:0;background:#f7f5f8;padding:11px 14px;display:flex;
  flex-direction:column;justify-content:center;gap:3px}
.nm{font-size:14.5px;font-weight:700}
.ut{font-size:11px;color:#a49dab}
.mt{display:flex;flex-wrap:wrap;gap:6px;align-items:center;margin-top:3px}
.bd{font-size:10.5px;font-weight:700;padding:3px 8px;border-radius:20px;line-height:1.4}
.bh{background:#fde2e1;color:#c81e1e}
.bv{background:#e9e6ea;color:#726b79}
.bc{background:#e9e6ea;color:#726b79}
.cta{font-size:12px;font-weight:800;text-decoration:none}
.ds{background:#f7f5f8;padding:0 14px 10px;border-top:1px solid #ece7ef}
.ds summary{list-style:none;cursor:pointer;font-size:11.5px;color:#847d8c;line-height:1.5;
  padding-top:8px}
.ds summary::-webkit-details-marker{display:none}
.ds summary .tg{font-weight:700;white-space:nowrap}
.ds:not([open]) summary .tg{color:#e11d48}
.ds:not([open]) summary .tg::before{content:"… mais"}
.ds[open] summary .tg{color:#847d8c}
.ds[open] summary .tg::before{content:"▲ menos"}
.ds p{margin:2px 0 0;font-size:11.5px;color:#847d8c;line-height:1.5}
.dp{background:#f7f5f8;padding:8px 14px 10px;border-top:1px solid #ece7ef;
  font-size:11.5px;color:#847d8c;line-height:1.5}
.bf{display:flex;align-items:center;justify-content:center;gap:6px;margin-top:20px;
  padding-top:14px;border-top:1px solid #ece7ef}
.bf img{display:block;opacity:.35}
.bf span{font-size:10.5px;color:#c3bcc9}
""".strip()


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


def _legenda_bloco(parceiro: Parceiro) -> str:
    """Legenda curta sob o numero grande do cartao — 'PTS' ou 'ATÉ PTS'."""
    return "ATÉ PTS" if parceiro.prefixo_ate else "PTS"


_FIM_DE_FRASE = re.compile(r"[.!?]+(?=\s|$)")

# C05: o "resto" (por tras do "…mais") tem teto — o regulamento completo ja
# esta a um clique em "Ver oferta", entao o e-mail nao precisa reproduzir a
# letra miuda inteira. So a primeira frase, sempre visivel por inteiro, e
# garantida sem corte.
_LIMITE_RESTO = 60


def _resumo_descricao(texto: str) -> tuple[str, str]:
    """Divide a descricao em primeira frase e o restante, sem sobrepor.

    Usado para o "… mais" do e-mail: mostrar a ideia completa de cara, e so
    esconder o resto atras de um clique — nunca cortar no meio de uma frase.
    O restante nao repete a primeira frase (C05): num catalogo grande, cada
    letra duplicada e byte a mais contra o corte do Gmail.
    """
    encontro = _FIM_DE_FRASE.search(texto)
    if encontro is None:
        return texto.strip(), ""
    fim = encontro.end()
    primeira = texto[:fim].strip()
    resto = texto[fim:].strip()
    if len(resto) > _LIMITE_RESTO:
        corte = resto.rfind(" ", 0, _LIMITE_RESTO)
        resto = resto[: corte if corte > 0 else _LIMITE_RESTO].rstrip(" ,;:") + "…"
    return primeira, resto


def _termina_hoje(parceiro: Parceiro, agora: datetime) -> bool:
    """RN22: promocao que termina no mesmo dia recebe destaque proprio."""
    if parceiro.fim_promocao is None:
        return False
    return parceiro.fim_promocao.astimezone(agora.tzinfo).date() == agora.date()


def _texto_validade(parceiro: Parceiro, agora: datetime) -> str | None:
    """RF18: quanto tempo resta ate o fim da promocao."""
    if parceiro.fim_promocao is None:
        return None
    if _termina_hoje(parceiro, agora):
        return "Termina hoje!"
    fim_local = parceiro.fim_promocao.astimezone(agora.tzinfo)
    return f"Válido até {fim_local:%d/%m}"


CAMPANHA_CLUBE = "CLUB"
CAMPANHA_PROMOCAO_CLUBE = "PROMOTION_CLUB"

ROTULO_EXCLUSIVO_CLUBE = "exclusivo assinantes Clube"
ROTULO_CLUBE_GANHA_MAIS = "assinantes Clube ganham mais"


def _rotulo_clube(parceiro: Parceiro) -> str | None:
    """RN23: separa o que o nao-assinante aproveita do que ele nao aproveita.

    `activeCampaign` foi confirmado contra a pagina real em 2026-08-11 e e a
    fonte preferida:

    - `CLUB`: a base nao se moveu, o ganho existe so para assinante.
    - `PROMOTION_CLUB`: a base subiu para todo mundo e o Clube subiu mais.
      Nao e exclusivo — o alerta serve ao nao-assinante, so nao pelo numero
      maior que aparece ao lado.

    Payload sem campanha (ou com valor novo que a Livelo invente) cai na
    comparacao numerica: base parada com Clube distinto e exclusividade.
    Sem `pontos_base` nao da para provar nada, entao nao marca — o default
    erra para o lado de nao afirmar.
    """
    if parceiro.pontos_clube is None:
        return None

    campanha = (parceiro.campanha or "").strip().upper()
    if campanha == CAMPANHA_CLUBE:
        return ROTULO_EXCLUSIVO_CLUBE
    if campanha == CAMPANHA_PROMOCAO_CLUBE:
        return ROTULO_CLUBE_GANHA_MAIS

    if parceiro.pontos_base is None:
        return None
    return ROTULO_EXCLUSIVO_CLUBE if parceiro.pontos_atuais == parceiro.pontos_base else None


def _assunto(agrupamento: dict[str, list[Parceiro]], *, catalogo_vazio: bool = False) -> str:
    if catalogo_vazio:
        return ASSUNTO_SEM_CATALOGO
    total = sum(len(lojas) for lojas in agrupamento.values())
    if total == 0:
        return ASSUNTO_SEM_PROMOCAO  # RF10
    plural = "promoções" if total > 1 else "promoção"
    return f"Livelo: {total} {plural} nas suas lojas"


def _cabecalho_marca() -> str:
    """Assinatura no topo do e-mail — logo + nome, redesign 2026-08-13."""
    return (
        "<div class='mb'>"
        f"<img src='{_LOGO_URL}' width='30' height='30' alt='' />"
        "<b>Pontuação Livelo</b>"
        "</div>"
    )


def _rodape_marca() -> str:
    """Mesma marca no rodapé, apagada — assina sem competir com a versão."""
    return (
        "<div class='bf'>"
        f"<img src='{_LOGO_URL}' width='16' height='16' alt='' />"
        f"<span>robô-livelo v{escape(__version__)}</span>"
        "</div>"
    )


def _bloco_descricao_html(descricao: str) -> str:
    """'…mais' sem JavaScript: <details>/<summary> puro (funciona no Gmail).

    So esconde algo quando ha algo a esconder — descricao de frase unica
    (sem ponto final seguido de mais texto) nao ganha "mais" nenhum, porque
    nao faria sentido clicar para nao ver nada de novo. O "…mais" usa a cor
    de acento fixa (nao a da categoria): custom property por card nao
    sobrevive a sanitizacao do Gmail, ver comentario de `_ESTILO`.
    """
    primeira, resto = _resumo_descricao(descricao)
    if not resto:
        return f"<div class='dp'>{escape(primeira)}</div>"
    return (
        "<details class='ds'>"
        f"<summary>{escape(primeira)} <span class='tg'></span></summary>"
        f"<p>{escape(resto)}</p>"
        "</details>"
    )


def montar(
    agrupamento: dict[str, list[Parceiro]],
    *,
    agora: datetime,
    catalogo_vazio: bool = False,
) -> Mensagem:
    """Devolve a mensagem pronta, em HTML e em texto simples (RF07).

    `agora` decide RN22 (destaque de "termina hoje") e RF18 (texto de
    validade) — passado explicitamente para o nucleo continuar sem ler o
    relogio por conta propria (ver PRD-V2 7.2).

    `catalogo_vazio` separa duas ausencias que pareceriam iguais: "hoje
    nenhuma das suas lojas subiu" e "voce nao tem loja nenhuma cadastrada".
    A segunda com a frase da primeira faria o robo parecer trabalhando
    quando nao ha o que procurar.
    """
    total = sum(len(lojas) for lojas in agrupamento.values())
    html: list[str] = [
        # RN-visual: <style> precisa morar dentro de <head> — sem head
        # explicito o Gmail (e outros clientes) descarta a folha inteira
        # na sanitizacao e o e-mail vira texto corrido, sem cor nem layout
        # nenhum. Confirmado ao vivo em 2026-08-13.
        f"<html><head><style>{_ESTILO}</style></head>"
        "<body style='font-family:Arial,Helvetica,sans-serif;"
        "background:#f5f5f7;margin:0;padding:24px;'>",
        "<div class='mc'>",
        _cabecalho_marca(),
        "<p class='h1'>Pontuação turbinada</p>",
    ]
    texto: list[str] = ["PONTUAÇÃO TURBINADA NA LIVELO", ""]

    if catalogo_vazio:
        # RF10: o e-mail sai mesmo assim, porque e ele o sinal de vida (MS5).
        # Mas o texto diz a verdade: nao ha catalogo, entao nao houve busca.
        html.append(
            "<p class='s0'>Você não tem nenhuma loja cadastrada, então não há o que "
            "procurar. Cadastre suas lojas no site para voltar a receber os avisos.</p>"
        )
        texto.append(
            "Você não tem nenhuma loja cadastrada, então não há o que procurar. "
            "Cadastre suas lojas no site para voltar a receber os avisos."
        )
    elif total == 0:
        # RF10: o e-mail sai mesmo assim. O silencio passa a significar
        # uma coisa so: o robo parou (MS5).
        html.append("<p class='s0'>Nenhuma das suas lojas está com pontuação turbinada agora.</p>")
        texto.append("Nenhuma das suas lojas está com pontuação turbinada agora.")
    else:
        html.append(f"<p class='s0'>{total} loja(s) com pontuação acima do normal hoje</p>")

    # RN14: categoria sem loja nao aparece. O agrupamento ja filtra, mas a
    # garantia se repete aqui porque e esta camada que decide o que o e-mail
    # mostra — e e ela que responde pela regra.
    com_lojas = [(cat, lojas) for cat, lojas in agrupamento.items() if lojas]

    for indice, (categoria, lojas) in enumerate(com_lojas):
        cor = _CORES[indice % len(_CORES)]
        plural = "loja" if len(lojas) == 1 else "lojas"
        html.append(
            f"<div class='ct'><span class='cc' style='background:{cor}'>"
            f"{escape(categoria)}</span><span class='cn'>{len(lojas)} {plural}</span></div>"
        )
        texto.append(f"## {categoria} ({len(lojas)})")

        for parceiro in lojas:
            # RN07: tudo que veio do site e hostil ate ser escapado.
            nome = escape(parceiro.nome)
            descricao = _descricao(parceiro)
            validade = _texto_validade(parceiro, agora)
            termina_hoje = _termina_hoje(parceiro, agora)

            html.append(
                f"<div class='bw'><div class='rw'>"
                f"<div class='bk' style='background:{cor}'>"
                f"<b>{escape(formatar_pontos(parceiro.pontos_atuais))}</b>"
                f"<small>{escape(_legenda_bloco(parceiro))}</small></div>"
                "<div class='ib'>"
                f"<span class='nm'>{nome}</span>"
                f"<span class='ut'>{escape(descricao)}</span>"
                "<div class='mt'>"
            )
            if validade is not None:  # RF18 / RN22
                classe_validade = "bh" if termina_hoje else "bv"
                html.append(f"<span class='bd {classe_validade}'>{escape(validade)}</span>")
            if parceiro.pontos_clube is not None:  # RN10
                rotulo_clube = f"Clube: {formatar_pontos(parceiro.pontos_clube)} pontos"
                observacao = _rotulo_clube(parceiro)  # RN23
                if observacao is not None:
                    rotulo_clube += f" ({observacao})"
                html.append(f"<span class='bd bc'>{escape(rotulo_clube)}</span>")
            if link_confiavel(parceiro.link):  # RN08
                html.append(
                    f"<a href='{escape(parceiro.link, quote=True)}' class='cta' "
                    f"style='color:{cor}'>Ver oferta →</a>"
                )
            elif parceiro.link:
                _log.warning("Link fora do dominio da Livelo descartado: %r", parceiro.link)

            html.append("</div></div></div>")

            if parceiro.descricao_campanha:
                html.append(_bloco_descricao_html(parceiro.descricao_campanha))

            html.append("</div>")

            linha = f"- {parceiro.nome}: {descricao}"
            if validade is not None:
                linha += f" ({validade})"
            if parceiro.pontos_clube is not None:
                linha += f" | Clube: {formatar_pontos(parceiro.pontos_clube)} pontos"
                observacao = _rotulo_clube(parceiro)
                if observacao is not None:
                    linha += f" ({observacao})"
            if link_confiavel(parceiro.link):
                linha += f"\n  {parceiro.link}"
            if parceiro.descricao_campanha:
                linha += f"\n  {parceiro.descricao_campanha}"
            texto.append(linha)

        texto.append("")

    html.append(_rodape_marca())
    html.append("</div>")
    html.append("</body></html>")
    texto.append(f"-- robô-livelo v{__version__}")
    return Mensagem(
        assunto=_assunto(agrupamento, catalogo_vazio=catalogo_vazio),
        corpo_html="".join(html),
        corpo_texto="\n".join(texto).strip() + "\n",
    )
