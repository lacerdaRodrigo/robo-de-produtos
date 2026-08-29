"""Estruturas de dados do dominio. Nucleo puro: nao faz I/O.

Ver PRD secao 5.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from decimal import Decimal

DOMINIO_LIVELO = "livelo.com.br"


@dataclass(frozen=True, slots=True)
class Parceiro:
    """Um parceiro lido da pagina, ja normalizado. Imutavel (PRD 5.4)."""

    nome: str
    pontos_atuais: Decimal
    moeda: str
    link: str
    id_externo: str = ""
    categorias: tuple[str, ...] = field(default_factory=tuple)
    em_promocao: bool = False
    pontos_anteriores: Decimal | None = None
    pontos_clube: Decimal | None = None
    prefixo_ate: bool = False
    pontos_base: Decimal | None = None
    inicio_promocao: datetime | None = None
    fim_promocao: datetime | None = None
    campanha: str | None = None
    descricao_campanha: str | None = None


@dataclass(frozen=True, slots=True)
class LojaFavorita:
    """Uma loja monitorada, vinda da configuracao (PRD 5.3).

    `multiplicador` e `piso_pontos` sao o limiar proprio da loja (RN28).
    `alerta_ativo` e a preferencia do sino no card; falso desliga apenas o
    disparo, sem remover a loja acompanhada.
    `None` significa "usa o padrao global" — a mesma semantica do NULL nas
    colunas do banco. O adaptador le os tres valores diretamente do Postgres.
    """

    nome: str
    categoria: str
    apelidos: tuple[str, ...] = field(default_factory=tuple)
    multiplicador: Decimal | None = None
    piso_pontos: Decimal | None = None
    alerta_ativo: bool = False


@dataclass(frozen=True, slots=True)
class Preferencias:
    """Padroes globais de alerta (RN28) e o tier do leitor (RN23).

    Os valores default sao os do PRD-V2 §6.1, calibrados contra a medicao de
    2026-08-09: com 2,0 e piso 4, aquele dia produziria 12 alertas entre
    126 favoritas. Existem aqui para o projeto rodar sem banco.
    """

    multiplicador_padrao: Decimal = Decimal("2.0")
    piso_pontos_padrao: Decimal = Decimal("4")
    assinante_clube: bool = False


@dataclass(frozen=True, slots=True)
class PontuacaoDeLoja:
    """Uma favorita como ela estava numa execucao (RF15, RN24, RN30).

    `parceiro is None` significa favorita que nao apareceu na pagina naquela
    rodada (RN19) — a linha continua existindo para o site dizer "nao
    encontrada" em vez de sumir com a loja.
    """

    loja: LojaFavorita
    parceiro: Parceiro | None = None
    valor_de_disparo: Decimal | None = None
    alertou: bool = False


@dataclass(frozen=True, slots=True)
class RetratoDaExecucao:
    """O que a execucao viu, pronto para virar linha no banco e pagina.

    O robo continua sem *ler* estado: ele grava e nunca consulta o proprio
    passado (PRD 1.4 segue valendo para a decisao de alerta). O historico
    existe para o site, nao para a regra de negocio.
    """

    momento: datetime
    parceiros_lidos: int
    versao: str
    catalogo: tuple[Parceiro, ...] = field(default_factory=tuple)
    pontuacoes: tuple[PontuacaoDeLoja, ...] = field(default_factory=tuple)

    @property
    def alertas(self) -> int:
        return sum(1 for p in self.pontuacoes if p.alertou)
