"""Os tres contratos que separam o nucleo do mundo externo.

Ver PRD secao 4.2. Trocar uma implementacao nao toca a logica de negocio.
"""

from __future__ import annotations

from typing import Protocol, runtime_checkable

from robo_livelo.modelos import LojaFavorita, Preferencias, RetratoDaExecucao


class FalhaAoObterPagina(RuntimeError):
    """A pagina nao pode ser obtida apos esgotar as tentativas (RF11)."""


class ConfiguracaoInvalida(RuntimeError):
    """A configuracao esta ausente, vazia ou malformada (PRD 7.2)."""


class FalhaAoGuardar(RuntimeError):
    """O retrato da execucao nao pode ser gravado (V2.3).

    Excecao propria porque a consequencia e outra: catalogo ausente impede
    a rodada, retrato nao gravado so deixa o site velho.
    """


class SiteMudou(RuntimeError):
    """Vieram parceiros de menos: o site provavelmente mudou (RN13, RF12)."""


@runtime_checkable
class FonteDePagina(Protocol):
    """Devolve o HTML cru da pagina de parceiros.

    E a porta que torna barata a troca prevista em C04: o Plano B com
    Playwright substitui apenas esta implementacao.
    """

    def obter_html(self) -> str: ...


@runtime_checkable
class CatalogoFavoritas(Protocol):
    """Fornece as lojas favoritas, seus apelidos e categorias."""

    def listar(self) -> list[LojaFavorita]: ...


@runtime_checkable
class PreferenciasGlobais(Protocol):
    """Fornece os padroes de alerta e o tier do leitor (RN28, RN23).

    Quarta porta, criada na V2.2. Nao virou metodo de `CatalogoFavoritas`
    de proposito: o catalogo responde "quais lojas", isto responde "com que
    regua", e as duas coisas tem origens diferentes na hora de editar pelo
    site — uma e a tabela `loja`, a outra e a tabela `preferencia`.
    """

    def carregar(self) -> Preferencias: ...


@runtime_checkable
class RepositorioDeExecucao(Protocol):
    """Guarda o retrato de cada rodada para o site ler (RF15, RN26).

    Era o "ponto de extensao documentado, nao implementado" do PRD §4.2 da
    V1. A V2.3 e a necessidade que ele esperava: o site precisa da
    pontuacao atual, e ela so existe durante a execucao.

    O robo escreve e nunca le de volta — nenhuma regra de negocio consulta
    o passado, entao PRD §1.4 continua valendo onde importa.
    """

    def registrar(self, retrato: RetratoDaExecucao) -> None: ...
