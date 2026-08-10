"""Os tres contratos que separam o nucleo do mundo externo.

Ver PRD secao 4.2. Trocar uma implementacao nao toca a logica de negocio.
"""

from __future__ import annotations

from typing import Protocol, runtime_checkable

from robo_livelo.modelos import LojaFavorita, Mensagem


class FalhaAoObterPagina(RuntimeError):
    """A pagina nao pode ser obtida apos esgotar as tentativas (RF11)."""


class FalhaAoNotificar(RuntimeError):
    """A mensagem nao pode ser entregue."""


class ConfiguracaoInvalida(RuntimeError):
    """A configuracao esta ausente, vazia ou malformada (PRD 7.2)."""


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
class Notificador(Protocol):
    """Entrega a mensagem montada."""

    def enviar(self, mensagem: Mensagem) -> None: ...


@runtime_checkable
class CatalogoFavoritas(Protocol):
    """Fornece as lojas favoritas, seus apelidos e categorias."""

    def listar(self) -> list[LojaFavorita]: ...
