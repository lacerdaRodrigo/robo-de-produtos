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

# Marca "R$ vira ponto" (redesign 2026-08-13, ver docs/EMAIL.md): PNG 96x96
# com fundo transparente, embutido em base64 porque o Gmail nao renderiza
# <svg> inline em e-mail de forma confiavel. Peso unico (nao e por card),
# gerado a partir de site/public/logo.svg — mesmo arquivo do cabecalho do
# site, so que rasterizado.
_LOGO_PNG_BASE64 = (
    "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"
    "9C/bJIYAAAAASUVORK5CYII="
)

# CSS unico no <head>: repetir estilo inline em cada cartao e o que fazia o
# HTML antigo pesar quase todo o orcamento do Gmail so com 132 lojas em
# promocao (C05, ver teste_pior_caso_cabe_no_limite_do_gmail). Uma folha so,
# aplicada por classe, deixa o mesmo visual pesando bem menos por loja — e
# por isso as classes sao curtas (.bk, .ib...): cada letra a menos e menos
# um byte multiplicado por ate 132 lojas no pior caso.
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
  justify-content:center;background:var(--c);color:#fff;font-weight:800;padding:10px 4px;
  text-align:center}
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
.cta{font-size:12px;font-weight:800;text-decoration:none;color:var(--c)}
.ds{background:#f7f5f8;padding:0 14px 10px;border-top:1px solid #ece7ef}
.ds summary{list-style:none;cursor:pointer;font-size:11.5px;color:#847d8c;line-height:1.5;
  padding-top:8px}
.ds summary::-webkit-details-marker{display:none}
.ds summary .tg{font-weight:700;white-space:nowrap}
.ds:not([open]) summary .tg{color:var(--c,#e11d48)}
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
        f"<img src='data:image/png;base64,{_LOGO_PNG_BASE64}' width='30' height='30' alt='' />"
        "<b>Pontuação Livelo</b>"
        "</div>"
    )


def _rodape_marca() -> str:
    """Mesma marca no rodapé, apagada — assina sem competir com a versão."""
    return (
        "<div class='bf'>"
        f"<img src='data:image/png;base64,{_LOGO_PNG_BASE64}' width='16' height='16' alt='' />"
        f"<span>robô-livelo v{escape(__version__)}</span>"
        "</div>"
    )


def _bloco_descricao_html(descricao: str) -> str:
    """'…mais' sem JavaScript: <details>/<summary> puro (funciona no Gmail).

    So esconde algo quando ha algo a esconder — descricao de frase unica
    (sem ponto final seguido de mais texto) nao ganha "mais" nenhum, porque
    nao faria sentido clicar para nao ver nada de novo. A cor do "…mais"
    vem do `--c` do `.bw` ancestral (CSS herda custom property sozinho —
    nao precisa repetir aqui).
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
                f"<div class='bw' style='--c:{cor}'><div class='rw'>"
                "<div class='bk'>"
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
                    f"<a href='{escape(parceiro.link, quote=True)}' class='cta'>Ver oferta →</a>"
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
