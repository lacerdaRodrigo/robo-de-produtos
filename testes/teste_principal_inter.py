"""CT-182 e CT-189 — orquestracao do Shopping Inter com fakes."""

from __future__ import annotations

from datetime import datetime

import pytest

from robo_livelo.modelos_inter import FavoritaInter
from robo_livelo.portas_inter import FalhaAoObterInter, SiteInterMudou
from robo_livelo.principal_inter import verificar_cashbacks_inter
from testes.conftest import FUSO_BRASILIA

AGORA = datetime(2026, 8, 14, 20, 0, tzinfo=FUSO_BRASILIA)


class FonteFakeInter:
    def __init__(self, conteudo="[]", erro=None):
        self.conteudo = conteudo
        self.erro = erro
        self.chamadas = 0

    def obter_json(self):
        self.chamadas += 1
        if self.erro:
            raise self.erro
        return self.conteudo


class CatalogoFakeInter:
    def __init__(self, favoritas=()):
        self.favoritas = list(favoritas)

    def listar(self):
        return self.favoritas


class RepositorioFakeInter:
    def __init__(self):
        self.iniciadas = []
        self.concluidas = []
        self.falhas = []

    def iniciar(self, momento, versao):
        self.iniciadas.append((momento, versao))
        return 42

    def concluir(self, execucao_id, lojas, retrato):
        self.concluidas.append((execucao_id, lojas, retrato))

    def falhar(self, execucao_id, codigo):
        self.falhas.append((execucao_id, codigo))


def teste_ct182_catalogo_pequeno_preserva_ultimo_sucesso(json_inter_exemplo):
    repositorio = RepositorioFakeInter()
    with pytest.raises(SiteInterMudou):
        verificar_cashbacks_inter(
            FonteFakeInter(json_inter_exemplo),
            CatalogoFakeInter(),
            repositorio,
            limiar=100,
            agora=AGORA,
        )

    assert repositorio.concluidas == []
    assert repositorio.falhas == [(42, "catalogo_pequeno")]


def teste_sucesso_grava_retrato_e_favorita(json_inter_exemplo):
    repositorio = RepositorioFakeInter()
    retrato = verificar_cashbacks_inter(
        FonteFakeInter(json_inter_exemplo),
        CatalogoFakeInter([FavoritaInter("d4bb2c85-5f9a-4fc7-89e0-78b2899a9b5e", "C&A")]),
        repositorio,
        limiar=5,
        agora=AGORA,
        versao="9.9.9",
    )

    assert retrato.lojas_validas == 5
    assert retrato.favoritas_encontradas == 1
    assert len(repositorio.concluidas) == 1
    assert repositorio.falhas == []


def teste_ct189_falha_da_fonte_fica_isolada(json_inter_exemplo):
    del json_inter_exemplo  # prova que a falha acontece antes de qualquer dado Livelo
    repositorio = RepositorioFakeInter()
    fonte = FonteFakeInter(erro=FalhaAoObterInter("sem rede", codigo="rede"))

    with pytest.raises(FalhaAoObterInter):
        verificar_cashbacks_inter(
            fonte,
            CatalogoFakeInter(),
            repositorio,
            agora=AGORA,
        )

    assert fonte.chamadas == 1
    assert repositorio.falhas == [(42, "rede")]
