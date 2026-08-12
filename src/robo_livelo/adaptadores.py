"""Implementacoes das portas. E a unica camada que faz I/O.

Ver PRD secao 4.2. Trocar qualquer classe daqui nao toca o nucleo.
"""

from __future__ import annotations

import logging
import smtplib
import time
import tomllib
from decimal import Decimal, InvalidOperation
from email.message import EmailMessage
from pathlib import Path

import requests

from robo_livelo.modelos import (
    LojaFavorita,
    Mensagem,
    PontuacaoDeLoja,
    Preferencias,
    RetratoDaExecucao,
)
from robo_livelo.montador_email import link_confiavel
from robo_livelo.portas import (
    CatalogoFavoritas,
    ConfiguracaoInvalida,
    FalhaAoGuardar,
    FalhaAoNotificar,
    FalhaAoObterPagina,
    PreferenciasGlobais,
)

_log = logging.getLogger(__name__)

URL_PARCEIROS = "https://www.livelo.com.br/juntar-pontos/todos-os-parceiros"

# RNF02: identificacao honesta, sem disfarce. Nao existe evasao neste projeto.
USER_AGENT = "robo-livelo/1.0 (projeto pessoal; github.com/rodrigo/robo-livelo)"

TAMANHO_MAXIMO = 5 * 1024 * 1024  # PRD 9.2: a pagina real pesa ~1,4 MB


class PaginaLiveloHttp:
    """Baixa a pagina publica de parceiros (RF01, RF11, RNF02)."""

    def __init__(
        self,
        url: str = URL_PARCEIROS,
        tentativas: int = 3,
        timeout: float = 30.0,
        espera_inicial: float = 2.0,
        tamanho_maximo: int = TAMANHO_MAXIMO,
        dormir=time.sleep,
    ) -> None:
        self._url = url
        self._tentativas = tentativas
        self._timeout = timeout
        self._espera_inicial = espera_inicial
        self._tamanho_maximo = tamanho_maximo
        self._dormir = dormir

    def obter_html(self) -> str:
        ultimo_erro: Exception | None = None

        for tentativa in range(1, self._tentativas + 1):
            try:
                resposta = requests.get(
                    self._url,
                    timeout=self._timeout,
                    headers={"User-Agent": USER_AGENT, "Accept-Language": "pt-BR"},
                )
                resposta.raise_for_status()

                conteudo = resposta.content
                if len(conteudo) > self._tamanho_maximo:
                    raise FalhaAoObterPagina(
                        f"Resposta de {len(conteudo)} bytes excede o limite "
                        f"de {self._tamanho_maximo}."
                    )
                return resposta.text

            except FalhaAoObterPagina:
                raise
            except Exception as erro:  # noqa: BLE001 - qualquer falha de rede vale retry
                ultimo_erro = erro
                _log.warning("Tentativa %d de %d falhou: %s", tentativa, self._tentativas, erro)
                if tentativa < self._tentativas:
                    self._dormir(self._espera_inicial * tentativa)

        raise FalhaAoObterPagina(
            f"Nao foi possivel obter a pagina apos {self._tentativas} tentativas."
        ) from ultimo_erro


def _limiar_opcional(bruta: dict, chave: str, nome_loja: str) -> Decimal | None:
    """Le multiplicador/piso_pontos do TOML, se a loja tiver os seus (RN28).

    Ausente e o caso normal: significa "usa o padrao global". Presente e
    ilegivel e erro de configuracao, nao um None silencioso — limiar errado
    por engano de digitacao viraria alerta errado depois.
    """
    if chave not in bruta:
        return None
    try:
        valor = Decimal(str(bruta[chave]))
    except InvalidOperation as erro:
        raise ConfiguracaoInvalida(
            f"Loja {nome_loja!r}: {chave} nao e um numero: {bruta[chave]!r}"
        ) from erro
    if valor <= 0 and chave == "multiplicador":
        raise ConfiguracaoInvalida(f"Loja {nome_loja!r}: multiplicador precisa ser maior que zero.")
    if valor < 0:
        raise ConfiguracaoInvalida(f"Loja {nome_loja!r}: {chave} nao pode ser negativo.")
    return valor


class CatalogoArquivo:
    """Le as lojas favoritas do arquivo de configuracao (RNF09, PRD 5.3)."""

    def __init__(self, caminho: str | Path) -> None:
        self._caminho = Path(caminho)

    def listar(self) -> list[LojaFavorita]:
        if not self._caminho.is_file():
            raise ConfiguracaoInvalida(f"Configuracao nao encontrada em {self._caminho}.")

        try:
            dados = tomllib.loads(self._caminho.read_text(encoding="utf-8"))
        except tomllib.TOMLDecodeError as erro:
            raise ConfiguracaoInvalida(f"Configuracao malformada: {erro}") from erro

        lojas: list[LojaFavorita] = []
        grafias_vistas: dict[str, str] = {}

        for bruta in dados.get("loja", []):
            nome = str(bruta.get("nome", "")).strip()
            categoria = str(bruta.get("categoria", "")).strip()
            if not nome or not categoria:
                raise ConfiguracaoInvalida(f"Loja sem nome ou sem categoria: {bruta!r}")

            apelidos = tuple(str(a).strip() for a in bruta.get("apelidos", []) if str(a).strip())

            for grafia in (nome, *apelidos):
                chave = grafia.casefold()
                if chave in grafias_vistas:
                    raise ConfiguracaoInvalida(
                        f"Grafia {grafia!r} repetida entre {grafias_vistas[chave]!r} e {nome!r}."
                    )
                grafias_vistas[chave] = nome

            lojas.append(
                LojaFavorita(
                    nome=nome,
                    categoria=categoria,
                    apelidos=apelidos,
                    multiplicador=_limiar_opcional(bruta, "multiplicador", nome),
                    piso_pontos=_limiar_opcional(bruta, "piso_pontos", nome),
                )
            )

        if not lojas:
            raise ConfiguracaoInvalida("Nenhuma loja favorita configurada.")

        return lojas


class NotificadorEmail:
    """Envia por SMTP com SSL (RF09, RN17).

    Nenhuma credencial aparece em log nem em excecao: o log do Actions e
    publico (RNF05, PRD 9.1).
    """

    def __init__(
        self,
        remetente: str,
        senha: str,
        destino: str,
        servidor: str = "smtp.gmail.com",
        porta: int = 465,
        conexao=None,
    ) -> None:
        self._remetente = remetente
        self._senha = senha
        self._destino = destino
        self._servidor = servidor
        self._porta = porta
        self._conexao = conexao or smtplib.SMTP_SSL

    def enviar(self, mensagem: Mensagem) -> None:
        email = EmailMessage()
        email["Subject"] = mensagem.assunto
        email["From"] = self._remetente
        email["To"] = self._destino  # RN17: um so destinatario, sem CC nem BCC
        email.set_content(mensagem.corpo_texto)
        email.add_alternative(mensagem.corpo_html, subtype="html")

        try:
            with self._conexao(self._servidor, self._porta) as smtp:
                smtp.login(self._remetente, self._senha)
                smtp.send_message(email)
        except smtplib.SMTPAuthenticationError as erro:
            # Mensagem propria: a original pode ecoar credencial.
            raise FalhaAoNotificar(
                "Autenticacao recusada pelo servidor de e-mail. "
                "Verifique a Senha de Aplicativo do Gmail."
            ) from erro.__class__(erro.smtp_code, b"")
        except Exception as erro:
            raise FalhaAoNotificar(f"Falha ao enviar o e-mail: {type(erro).__name__}") from None


class CatalogoPostgres:
    """Le as lojas favoritas do Postgres (PRD V2, secao 7.1.1).

    Mesma porta que CatalogoArquivo implementa. O nucleo nao sabe de onde
    o catalogo veio, entao trocar arquivo por banco nao toca uma linha de
    regra de negocio — era exatamente para isto que a porta existia.
    """

    CONSULTA = """
        SELECT l.nome, l.categoria, COALESCE(
                   ARRAY_AGG(a.texto) FILTER (WHERE a.texto IS NOT NULL),
                   ARRAY[]::TEXT[]
               ) AS apelidos,
               l.multiplicador, l.piso_pontos
          FROM loja l
          LEFT JOIN apelido a ON a.loja_id = l.id
         GROUP BY l.id, l.nome, l.categoria, l.multiplicador, l.piso_pontos
         ORDER BY l.categoria, l.nome
    """

    def __init__(self, url: str) -> None:
        if not url:
            raise ConfiguracaoInvalida("DATABASE_URL nao configurada.")
        self._url = url

    def listar(self) -> list[LojaFavorita]:
        import psycopg  # importado aqui para nao exigir o driver em quem usa arquivo

        try:
            with psycopg.connect(self._url) as conexao, conexao.cursor() as cursor:
                cursor.execute(self.CONSULTA)
                linhas = cursor.fetchall()
        except psycopg.Error as erro:
            # Mensagem propria: a original pode carregar a senha da URL.
            raise ConfiguracaoInvalida(
                f"Falha ao consultar o catalogo no banco: {type(erro).__name__}"
            ) from None

        if not linhas:
            raise ConfiguracaoInvalida("Nenhuma loja favorita cadastrada no banco.")

        # NUMERIC volta como Decimal do psycopg — nada de float aqui (PRD 5.4).
        return [
            LojaFavorita(
                nome=nome,
                categoria=categoria,
                apelidos=tuple(apelidos),
                multiplicador=multiplicador,
                piso_pontos=piso_pontos,
            )
            for nome, categoria, apelidos, multiplicador, piso_pontos in linhas
        ]


class RepositorioNulo:
    """Nao guarda nada, e diz isso uma vez no log.

    E o que roda em quem clonou o projeto sem Neon: o robo continua
    mandando e-mail, so nao alimenta site nenhum.
    """

    def registrar(self, retrato: RetratoDaExecucao) -> None:
        _log.info("Sem banco: retrato da execucao nao foi guardado.")


class RepositorioPostgres:
    """Guarda o retrato da execucao (PRD V2 RF15, migracao 002).

    Uma transacao por rodada: ou o retrato inteiro entra, ou nao entra
    nada. Retrato pela metade no banco viraria pagina mentindo, que e pior
    que pagina velha — a velha pelo menos se denuncia pelo carimbo (RN26).
    """

    INSERE_EXECUCAO = """
        INSERT INTO execucao (momento, parceiros_lidos, alertas, versao)
        VALUES (%s, %s, %s, %s)
        RETURNING id
    """

    INSERE_PONTUACAO = """
        INSERT INTO pontuacao (
            execucao_id, loja_id, nome, pontos_atuais, pontos_base, pontos_clube,
            valor_de_disparo, moeda, prefixo_ate, em_promocao, alertou, campanha,
            fim_promocao, link
        )
        VALUES (
            %(execucao_id)s,
            (SELECT id FROM loja WHERE nome = %(nome)s),
            %(nome)s, %(pontos_atuais)s, %(pontos_base)s, %(pontos_clube)s,
            %(valor_de_disparo)s, %(moeda)s, %(prefixo_ate)s, %(em_promocao)s,
            %(alertou)s, %(campanha)s, %(fim_promocao)s, %(link)s
        )
    """

    def __init__(self, url: str) -> None:
        if not url:
            raise ConfiguracaoInvalida("DATABASE_URL nao configurada.")
        self._url = url

    def registrar(self, retrato: RetratoDaExecucao) -> None:
        import psycopg

        try:
            with psycopg.connect(self._url) as conexao, conexao.cursor() as cursor:
                cursor.execute(
                    self.INSERE_EXECUCAO,
                    (retrato.momento, retrato.parceiros_lidos, retrato.alertas, retrato.versao),
                )
                (execucao_id,) = cursor.fetchone()
                cursor.executemany(
                    self.INSERE_PONTUACAO,
                    [_linha_de_pontuacao(p, execucao_id) for p in retrato.pontuacoes],
                )
        except psycopg.Error as erro:
            # Mensagem propria: a original pode carregar a senha da URL.
            raise FalhaAoGuardar(
                f"Falha ao guardar o retrato da execucao: {type(erro).__name__}"
            ) from None


def _linha_de_pontuacao(pontuacao: PontuacaoDeLoja, execucao_id: int) -> dict:
    parceiro = pontuacao.parceiro
    return {
        "execucao_id": execucao_id,
        # RN01: grava o nome canonico do catalogo, nao a grafia do site.
        "nome": pontuacao.loja.nome,
        "pontos_atuais": parceiro.pontos_atuais if parceiro else None,
        "pontos_base": parceiro.pontos_base if parceiro else None,
        "pontos_clube": parceiro.pontos_clube if parceiro else None,
        "valor_de_disparo": pontuacao.valor_de_disparo,
        "moeda": (parceiro.moeda if parceiro else None) or "R$",
        "prefixo_ate": bool(parceiro and parceiro.prefixo_ate),
        "em_promocao": bool(parceiro and parceiro.em_promocao),
        "alertou": pontuacao.alertou,
        "campanha": parceiro.campanha if parceiro else None,
        "fim_promocao": parceiro.fim_promocao if parceiro else None,
        # RN08 vale para o site tambem: link que nao e da Livelo nao entra.
        "link": (parceiro.link if parceiro and link_confiavel(parceiro.link) else None),
    }


class PreferenciasPadrao:
    """Os padroes do PRD-V2 §6.1, sem banco nenhum.

    E o que roda em quem clonou o projeto e nao tem Neon, e a reserva de
    quem tem.
    """

    def carregar(self) -> Preferencias:
        return Preferencias()


class PreferenciasPostgres:
    """Le os padroes globais da tabela `preferencia` (PRD V2 §8.1)."""

    CONSULTA = "SELECT chave, valor FROM preferencia"

    def __init__(self, url: str) -> None:
        if not url:
            raise ConfiguracaoInvalida("DATABASE_URL nao configurada.")
        self._url = url

    def carregar(self) -> Preferencias:
        import psycopg

        try:
            with psycopg.connect(self._url) as conexao, conexao.cursor() as cursor:
                cursor.execute(self.CONSULTA)
                linhas = dict(cursor.fetchall())
        except psycopg.Error as erro:
            # Mensagem propria: a original pode carregar a senha da URL.
            raise ConfiguracaoInvalida(
                f"Falha ao consultar as preferencias no banco: {type(erro).__name__}"
            ) from None

        padrao = Preferencias()
        return Preferencias(
            multiplicador_padrao=_decimal_de_preferencia(
                linhas, "multiplicador_padrao", padrao.multiplicador_padrao
            ),
            piso_pontos_padrao=_decimal_de_preferencia(
                linhas, "piso_pontos_padrao", padrao.piso_pontos_padrao
            ),
            assinante_clube=str(linhas.get("assinante_clube", "")).strip().lower() == "true",
        )


def _decimal_de_preferencia(linhas: dict, chave: str, reserva: Decimal) -> Decimal:
    """Preferencia ausente ou ilegivel cai no padrao, com aviso no log.

    Aqui a escolha e o contrario da do catalogo: uma preferencia quebrada
    nao pode derrubar a execucao inteira, porque existe um valor sensato
    para seguir. Ficar em silencio e que nao pode.
    """
    if chave not in linhas:
        return reserva
    try:
        return Decimal(str(linhas[chave]))
    except InvalidOperation:
        _log.warning(
            "Preferencia %r ilegivel no banco (%r). Usando o padrao %s.",
            chave,
            linhas[chave],
            reserva,
        )
        return reserva


class PreferenciasComReserva:
    """Mesmo motivo de `CatalogoComReserva`: o Neon nao pode derrubar a rodada."""

    def __init__(self, principal: PreferenciasGlobais, reserva: PreferenciasGlobais) -> None:
        self._principal = principal
        self._reserva = reserva

    def carregar(self) -> Preferencias:
        try:
            return self._principal.carregar()
        except ConfiguracaoInvalida as erro:
            _log.warning("Preferencias do banco indisponiveis (%s). Usando os padroes.", erro)
            return self._reserva.carregar()


class CatalogoComReserva:
    """Tenta o catalogo principal e cai para a reserva se ele falhar.

    A troca do TOML pelo banco so e segura assim: o Neon e um servico de
    terceiro num plano gratuito, e ficar sem catalogo derrubaria a execucao
    inteira por um motivo que nao tem nada a ver com a Livelo. O aviso vai
    em WARNING justamente para a queda nao passar despercebida — rodar de
    reserva por semanas sem ninguem notar seria pior do que falhar.
    """

    def __init__(self, principal: CatalogoFavoritas, reserva: CatalogoFavoritas) -> None:
        self._principal = principal
        self._reserva = reserva

    def listar(self) -> list[LojaFavorita]:
        try:
            return self._principal.listar()
        except ConfiguracaoInvalida as erro:
            _log.warning("Catalogo principal indisponivel (%s). Usando a reserva.", erro)
            return self._reserva.listar()
