"""CT-117 a CT-129 — RN27, RN28, RN29 e a supressao de RN23.

Os exemplos numericos vem da medicao real de 2026-08-09 e 2026-08-11
registrada no PRD-V2 §6.1: sao os casos que a V1 errava nos dois sentidos.
"""

from __future__ import annotations

from decimal import Decimal

import pytest

from robo_livelo.alertas import (
    criterio_de_alerta,
    merece_alerta,
    pontuacao_efetiva,
    suspeita_de_base_degenerada,
    valor_de_disparo,
)
from robo_livelo.modelos import LojaFavorita, Preferencias
from testes.conftest import faz_parceiro

PADRAO = Preferencias()  # 2,0x e piso 4, os defaults do PRD-V2 6.1
ASSINANTE = Preferencias(assinante_clube=True)


def loja(nome: str = "Natura", **campos) -> LojaFavorita:
    return LojaFavorita(nome=nome, categoria="Beleza", **campos)


def teste_ct117_cruza_multiplicador_e_piso_dispara():
    """RN27: `Crocs` 2 -> 7. Dobrou com folga e passa do piso."""
    parceiro = faz_parceiro("Crocs", "7", base="2")
    assert merece_alerta(parceiro, loja("Crocs"), PADRAO) is True


def teste_ct118_dobrou_mas_nao_passa_do_piso():
    """RN27: `Mercado Livre` 1 -> 2. Dobrou, mas sao 2 pontos."""
    parceiro = faz_parceiro("Mercado Livre", "2", base="1")
    assert merece_alerta(parceiro, loja("Mercado Livre"), PADRAO) is False


@pytest.mark.parametrize(("nome", "pontos"), [("Claro", "6"), ("Natura", "4")])
def teste_ct119_pontuacao_alta_permanente_nao_dispara(nome, pontos):
    """RN27: alto e permanente nao e oportunidade.

    `Claro` da 6 com base 6 e `Natura` da 4 com base 4. Um limiar absoluto
    de 5 mandaria a Claro todo dia — e a prova de que o multiplo e melhor.
    """
    parceiro = faz_parceiro(nome, pontos, base=pontos)
    assert merece_alerta(parceiro, loja(nome), PADRAO) is False


def teste_ct120_aumento_sem_etiqueta_dispara():
    """RN27 invertendo RN02: `Avon` 2 -> 6, salto de 3x sem etiqueta nenhuma.

    Era o falso negativo da V1 — o alerta que nunca chegava.
    """
    parceiro = faz_parceiro("Avon", "6", base="2", em_promocao=False)
    assert merece_alerta(parceiro, loja("Avon"), PADRAO) is True


def teste_ct121_etiqueta_sem_aumento_nao_dispara():
    """RN27: `O Boticário` 3 -> 3 com etiqueta de promocao.

    Era o falso positivo da V1 — alerta sem aumento real.
    """
    parceiro = faz_parceiro("O Boticário", "3", base="3", em_promocao=True)
    assert merece_alerta(parceiro, loja("O Boticário"), PADRAO) is False


def teste_ct122_sobrescrita_da_loja_vence_o_padrao_global():
    """RN28: `None` na loja usa o padrao; valor na loja manda."""
    parceiro = faz_parceiro("Bibi", "3", base="2")

    assert merece_alerta(parceiro, loja("Bibi"), PADRAO) is False
    # Exigente com multiplicador, mas piso baixo: 3 >= 2x1,5 e 3 >= 2.
    tolerante = loja("Bibi", multiplicador=Decimal("1.5"), piso_pontos=Decimal("2"))
    assert merece_alerta(parceiro, tolerante, PADRAO) is True
    # So o piso alto ja segura, mesmo com o multiplicador frouxo.
    exigente = loja("Bibi", multiplicador=Decimal("1.5"), piso_pontos=Decimal("10"))
    assert merece_alerta(parceiro, exigente, PADRAO) is False


def teste_ct123_promocao_do_clube_nao_alerta_quem_nao_assina():
    """RN23: `CLUB` e ganho de outra pessoa; `PROMOTION_CLUB` e dos dois."""
    so_clube = faz_parceiro("Aliexpress", "1", base="1", clube="9", campanha="CLUB")
    dos_dois = faz_parceiro("Sephora", "6", base="1", clube="10", campanha="PROMOTION_CLUB")

    assert merece_alerta(so_clube, loja("Aliexpress"), PADRAO) is False
    assert merece_alerta(dos_dois, loja("Sephora"), PADRAO) is True


def teste_ct124_assinante_do_clube_enxerga_o_tier():
    """RN23: para o assinante, a pontuacao que vale e a do Clube."""
    parceiro = faz_parceiro("O Boticário", "3", base="3", clube="10", campanha="CLUB")

    assert pontuacao_efetiva(parceiro, assinante_clube=False) == Decimal("3")
    assert pontuacao_efetiva(parceiro, assinante_clube=True) == Decimal("10")
    assert merece_alerta(parceiro, loja("O Boticário"), PADRAO) is False
    assert merece_alerta(parceiro, loja("O Boticário"), ASSINANTE) is True


def teste_ct125_sem_base_cai_no_criterio_da_v1_mais_o_piso():
    """Sem `parityBau` nao da para provar aumento — mas sumir em silencio e pior."""
    com_etiqueta = faz_parceiro("Natura", "5", base=None, em_promocao=True)
    sem_etiqueta = faz_parceiro("Natura", "5", base=None, em_promocao=False)
    abaixo_do_piso = faz_parceiro("Natura", "2", base=None, em_promocao=True)

    assert merece_alerta(com_etiqueta, loja(), PADRAO) is True
    assert merece_alerta(sem_etiqueta, loja(), PADRAO) is False
    assert merece_alerta(abaixo_do_piso, loja(), PADRAO) is False


def teste_ct126_valor_de_disparo_e_o_maior_entre_multiplo_e_piso():
    """RN30: e o numero que o site exibe ao lado da loja."""
    # Base baixa: quem manda e o piso.
    assert valor_de_disparo(faz_parceiro("Bibi", "1", base="1"), loja(), PADRAO) == Decimal("4")
    # Base alta: quem manda e o multiplo.
    assert valor_de_disparo(faz_parceiro("Claro", "6", base="6"), loja(), PADRAO) == Decimal("12")
    # Sem base nao ha o que exibir.
    assert valor_de_disparo(faz_parceiro("Natura", "5", base=None), loja(), PADRAO) is None


def teste_ct127_silencio_com_pagina_degenerada_vira_suspeita():
    """RN29/C07: `parityBau` chegar igual ao valor promocional zera tudo."""
    parceiros = [faz_parceiro(f"Loja {i}", "5", base="5") for i in range(20)]
    suspeita = suspeita_de_base_degenerada(parceiros, total_de_alertas=0)
    assert suspeita is not None
    assert "RN29" in suspeita and "C07" in suspeita


def teste_ct128_silencio_com_pagina_normal_nao_vira_suspeita():
    """Contraprova de CT-127: dia fraco de verdade nao pode virar alarme."""
    parceiros = [faz_parceiro(f"Loja {i}", "5", base="3") for i in range(20)]
    assert suspeita_de_base_degenerada(parceiros, total_de_alertas=0) is None


def teste_ct129_havendo_alerta_nao_ha_suspeita():
    parceiros = [faz_parceiro(f"Loja {i}", "5", base="5") for i in range(20)]
    assert suspeita_de_base_degenerada(parceiros, total_de_alertas=1) is None


def teste_pagina_sem_base_nenhuma_tambem_e_suspeita():
    """Payload que parou de trazer `parityBau` some com o alerta do mesmo jeito."""
    parceiros = [faz_parceiro(f"Loja {i}", "5", base=None) for i in range(20)]
    suspeita = suspeita_de_base_degenerada(parceiros, total_de_alertas=0)
    assert suspeita is not None and "payload" in suspeita


def teste_pagina_vazia_nao_gera_suspeita():
    """Sem parceiro nenhum quem falha e o limiar RN13, nao RN29."""
    assert suspeita_de_base_degenerada([], total_de_alertas=0) is None


def teste_criterio_de_alerta_fecha_as_preferencias():
    """O criterio entregue ao `categorias.agrupar` carrega a regua consigo."""
    criterio = criterio_de_alerta(PADRAO)
    assert criterio(faz_parceiro("Crocs", "7", base="2"), loja("Crocs")) is True
    assert criterio(faz_parceiro("Claro", "6", base="6"), loja("Claro")) is False
