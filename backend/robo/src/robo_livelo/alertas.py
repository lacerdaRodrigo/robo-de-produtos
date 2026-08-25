"""Nucleo puro: decide o que merece alerta. Ver PRD-V2 secao 6.1.

Regras aplicadas aqui: RN27, RN28, RN29 e a supressao de RN23.

A V1 alertava pela etiqueta "Promocao" da Livelo e errava nos dois
sentidos: avisava sem aumento (`O Boticario` 3 -> 3) e nao avisava havendo
aumento (`Avon` 2 -> 6, sem etiqueta). O criterio passa a comparar com
`parityBau`, a pontuacao normal declarada pela propria Livelo.
"""

from __future__ import annotations

import logging
from collections.abc import Callable
from decimal import Decimal

from robo_livelo.modelos import LojaFavorita, Parceiro, Preferencias

_log = logging.getLogger(__name__)

CAMPANHA_CLUBE = "CLUB"

# RN29: so faz sentido desconfiar quando quase toda a pagina veio com a base
# igual a pontuacao atual. Uma loja assim e normal; 90% delas nao e.
PROPORCAO_SUSPEITA = Decimal("0.9")


def pontuacao_efetiva(parceiro: Parceiro, *, assinante_clube: bool) -> Decimal:
    """Quanto o leitor deste e-mail ganha de fato.

    Assinante enxerga o tier do Clube quando ele existe; quem nao assina
    enxerga a pontuacao aberta (PRD-V2 6.2).
    """
    if assinante_clube and parceiro.pontos_clube is not None:
        return parceiro.pontos_clube
    return parceiro.pontos_atuais


def limiar_da_loja(loja: LojaFavorita, preferencias: Preferencias) -> tuple[Decimal, Decimal]:
    """RN28: sobrescrita da loja quando existir, padrao global quando nao.

    `None` na loja significa "usa o padrao" — a mesma semantica do NULL nas
    colunas do banco, deliberadamente.
    """
    multiplicador = (
        loja.multiplicador if loja.multiplicador is not None else preferencias.multiplicador_padrao
    )
    piso = loja.piso_pontos if loja.piso_pontos is not None else preferencias.piso_pontos_padrao
    return multiplicador, piso


def valor_de_disparo(
    parceiro: Parceiro, loja: LojaFavorita, preferencias: Preferencias
) -> Decimal | None:
    """A partir de quantos pontos esta loja vira alerta (RN30).

    O site exibe este numero ao lado da loja — sem ele, o limiar desregula
    em silencio. `None` quando a base e desconhecida e nao da para calcular.
    """
    if parceiro.pontos_base is None:
        return None
    multiplicador, piso = limiar_da_loja(loja, preferencias)
    return max(parceiro.pontos_base * multiplicador, piso)


def merece_alerta(parceiro: Parceiro, loja: LojaFavorita, preferencias: Preferencias) -> bool:
    """RN27: alerta quando `pontos >= base x multiplicador` E `pontos >= piso`.

    Duas recusas antes da conta:

    - Promocao `CLUB` para quem nao assina o Clube (RN23): a base nao se
      moveu, o ganho e de outra pessoa. `PROMOTION_CLUB` passa normalmente,
      porque nesses a base subiu para todo mundo.
    - Base desconhecida: sem `parityBau` nao da para provar aumento nenhum.
      Nesse caso cai no criterio da V1 (a etiqueta da Livelo) **mais o
      piso**, para nao perder a loja em silencio nem trazer de volta o
      ruido de "promocao" sem aumento.
    """
    pontos = pontuacao_efetiva(parceiro, assinante_clube=preferencias.assinante_clube)
    _, piso = limiar_da_loja(loja, preferencias)

    campanha = (parceiro.campanha or "").strip().upper()
    if campanha == CAMPANHA_CLUBE and not preferencias.assinante_clube:  # RN23
        return False

    disparo = valor_de_disparo(parceiro, loja, preferencias)
    if disparo is None:
        return parceiro.em_promocao and pontos >= piso

    return pontos >= disparo


def criterio_de_alerta(
    preferencias: Preferencias,
) -> Callable[[Parceiro, LojaFavorita], bool]:
    """Fecha as preferencias sobre RN27 para `categorias.agrupar` filtrar."""

    def criterio(parceiro: Parceiro, loja: LojaFavorita) -> bool:
        return merece_alerta(parceiro, loja, preferencias)

    return criterio


def suspeita_de_base_degenerada(parceiros: list[Parceiro], total_de_alertas: int) -> str | None:
    """RN29: silencio que pode nao ser silencio (C07).

    O alerta inteiro depende de `parityBau` ser honesto. Se um dia a Livelo
    passar a preencher a base com o proprio valor promocional, todo parceiro
    vira 1x e **nenhum alerta dispara, sem nada quebrar** — o robo segue
    verde, o e-mail segue chegando vazio e a conclusao errada ("nao teve
    promocao") e indistinguivel da certa.

    A checagem e feita dentro da execucao, sem guardar estado (PRD 1.4): o
    sintoma de C07 e visivel numa rodada so, porque afeta a pagina inteira
    de uma vez. Devolve a mensagem de suspeita, ou `None` quando nao ha
    motivo para desconfiar.
    """
    if total_de_alertas > 0 or not parceiros:
        return None

    com_base = [p for p in parceiros if p.pontos_base is not None]
    if not com_base:
        return (
            f"RN29: nenhum alerta disparou e nenhum dos {len(parceiros)} parceiros "
            "trouxe pontuacao base. Suspeita de mudanca no payload (C07), nao de "
            "ausencia de promocao."
        )

    parados = sum(1 for p in com_base if p.pontos_atuais == p.pontos_base)
    if Decimal(parados) / Decimal(len(com_base)) < PROPORCAO_SUSPEITA:
        return None

    return (
        f"RN29: nenhuma favorita cruzou o limiar e {parados} de {len(com_base)} "
        "parceiros vieram com base igual a pontuacao atual. Suspeita de parityBau "
        'degenerado (C07), nao de "nao teve promocao hoje".'
    )
