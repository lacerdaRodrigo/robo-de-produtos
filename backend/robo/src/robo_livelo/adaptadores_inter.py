"""Adaptadores HTTP e Postgres exclusivos do Shopping Inter."""

from __future__ import annotations

import logging
import time
from datetime import datetime

import requests

from robo_livelo.extrator_inter import normalizar_busca
from robo_livelo.modelos_inter import CashbackFavoritaInter, FavoritaInter, LojaInter, RetratoInter
from robo_livelo.portas_inter import (
    ConfiguracaoInterInvalida,
    FalhaAoGuardarInter,
    FalhaAoObterInter,
)

_log = logging.getLogger(__name__)

URL_INTER = (
    "https://marketplace-api.web.bancointer.com.br/site/affiliate/inter/v1/"
    "departments/ALL-STORES/stores?lang=pt-BR"
)
USER_AGENT_INTER = (
    "radar-beneficios/3 (projeto pessoal; github.com/lacerdaRodrigo/robo-de-produtos)"
)
TAMANHO_MAXIMO_INTER = 5 * 1024 * 1024
STATUS_TRANSITORIOS = {408, 429}


class FonteInterHttp:
    """Uma consulta logica ao catalogo, com retry apenas transitorio."""

    def __init__(
        self,
        url: str = URL_INTER,
        *,
        tentativas: int = 3,
        timeout: float = 30.0,
        tamanho_maximo: int = TAMANHO_MAXIMO_INTER,
        dormir=time.sleep,
        obter=requests.get,
    ) -> None:
        self._url = url
        self._tentativas = tentativas
        self._timeout = timeout
        self._tamanho_maximo = tamanho_maximo
        self._dormir = dormir
        self._obter = obter

    def obter_json(self) -> str:
        for tentativa in range(1, self._tentativas + 1):
            try:
                resposta = self._obter(
                    self._url,
                    timeout=self._timeout,
                    headers={
                        "User-Agent": USER_AGENT_INTER,
                        "Accept": "application/json",
                        "Accept-Language": "pt-BR",
                    },
                )
            except (requests.RequestException, ConnectionError, TimeoutError):
                if tentativa == self._tentativas:
                    raise FalhaAoObterInter(
                        "O Shopping Inter nao respondeu apos tres tentativas.", codigo="rede"
                    ) from None
                _log.warning(
                    "Consulta ao Inter falhou na tentativa %d de %d.",
                    tentativa,
                    self._tentativas,
                )
                self._dormir(2 * tentativa)
                continue

            status = resposta.status_code
            transitorio = status in STATUS_TRANSITORIOS or status >= 500
            if transitorio and tentativa < self._tentativas:
                _log.warning(
                    "Shopping Inter respondeu HTTP %d na tentativa %d de %d.",
                    status,
                    tentativa,
                    self._tentativas,
                )
                self._dormir(2 * tentativa)
                continue
            if status < 200 or status >= 300:
                raise FalhaAoObterInter(f"Shopping Inter respondeu HTTP {status}.", codigo="http")

            conteudo = resposta.content
            if len(conteudo) > self._tamanho_maximo:
                raise FalhaAoObterInter(
                    "Resposta do Shopping Inter excede 5 MiB.", codigo="resposta_grande"
                )
            return resposta.text

        raise FalhaAoObterInter("Consulta ao Shopping Inter falhou.", codigo="rede")


class RepositorioInterPostgres:
    """Catalogo de favoritas e gravacao transacional dos snapshots do Inter."""

    INSERE_TENTATIVA = """
        INSERT INTO execucao_inter (iniciada_em, estado, versao)
        VALUES (%s, 'iniciada', %s)
        RETURNING id
    """
    LISTA_FAVORITAS = """
        SELECT l.id_externo, l.nome
          FROM favorita_inter f
          JOIN loja_inter l ON l.id = f.loja_inter_id
         ORDER BY l.nome
    """
    MARCA_INATIVAS = "UPDATE loja_inter SET ativa = FALSE"
    ATUALIZA_LOJA = """
        INSERT INTO loja_inter (
            id_externo, slug, nome, nome_busca, slug_busca,
            cashback_principal_texto, cashback_principal_valor,
            cashback_secundario_texto, cashback_secundario_valor,
            etiqueta, descricao_principal, descricao_secundaria,
            ativa, vista_em, atualizada_em
        ) VALUES (
            %(id_externo)s, %(slug)s, %(nome)s, %(nome_busca)s, %(slug_busca)s,
            %(principal_texto)s, %(principal_valor)s,
            %(secundario_texto)s, %(secundario_valor)s,
            %(etiqueta)s, %(descricao_principal)s, %(descricao_secundaria)s,
            TRUE, %(vista_em)s, now()
        )
        ON CONFLICT (id_externo) DO UPDATE SET
            slug = EXCLUDED.slug,
            nome = EXCLUDED.nome,
            nome_busca = EXCLUDED.nome_busca,
            slug_busca = EXCLUDED.slug_busca,
            cashback_principal_texto = EXCLUDED.cashback_principal_texto,
            cashback_principal_valor = EXCLUDED.cashback_principal_valor,
            cashback_secundario_texto = EXCLUDED.cashback_secundario_texto,
            cashback_secundario_valor = EXCLUDED.cashback_secundario_valor,
            etiqueta = EXCLUDED.etiqueta,
            descricao_principal = EXCLUDED.descricao_principal,
            descricao_secundaria = EXCLUDED.descricao_secundaria,
            ativa = TRUE,
            vista_em = EXCLUDED.vista_em,
            atualizada_em = now()
    """
    INSERE_CASHBACK = """
        INSERT INTO cashback_inter (
            execucao_inter_id, loja_inter_id, nome,
            cashback_principal_texto, cashback_principal_valor,
            cashback_secundario_texto, cashback_secundario_valor,
            etiqueta, descricao_principal, descricao_secundaria, encontrada
        ) VALUES (
            %(execucao_id)s,
            (SELECT id FROM loja_inter WHERE id_externo = %(id_externo)s),
            %(nome)s, %(principal_texto)s, %(principal_valor)s,
            %(secundario_texto)s, %(secundario_valor)s,
            %(etiqueta)s, %(descricao_principal)s, %(descricao_secundaria)s,
            %(encontrada)s
        )
    """
    CONCLUI_TENTATIVA = """
        UPDATE execucao_inter
           SET concluida_em = now(), estado = 'sucesso',
               lojas_lidas = %s, lojas_validas = %s,
               favoritas_encontradas = %s, codigo_falha = NULL
         WHERE id = %s AND estado = 'iniciada'
    """
    FALHA_TENTATIVA = """
        UPDATE execucao_inter
           SET concluida_em = now(), estado = 'falha', codigo_falha = %s
         WHERE id = %s AND estado = 'iniciada'
    """

    def __init__(self, url: str) -> None:
        if not url.strip():
            raise ConfiguracaoInterInvalida(
                "DATABASE_URL nao configurada para o Inter.", codigo="banco"
            )
        self._url = url

    def iniciar(self, momento: datetime, versao: str) -> int:
        import psycopg

        try:
            with psycopg.connect(self._url) as conexao, conexao.cursor() as cursor:
                cursor.execute(self.INSERE_TENTATIVA, (momento, versao))
                linha = cursor.fetchone()
                if not linha:
                    raise RuntimeError("INSERT sem RETURNING")
                return int(linha[0])
        except (psycopg.Error, RuntimeError) as erro:
            raise FalhaAoGuardarInter(
                f"Falha ao iniciar a execucao do Inter: {type(erro).__name__}.", codigo="banco"
            ) from None

    def listar(self) -> list[FavoritaInter]:
        import psycopg

        try:
            with psycopg.connect(self._url) as conexao, conexao.cursor() as cursor:
                cursor.execute(self.LISTA_FAVORITAS)
                return [
                    FavoritaInter(id_externo=id_externo, nome=nome)
                    for id_externo, nome in cursor.fetchall()
                ]
        except psycopg.Error as erro:
            raise FalhaAoGuardarInter(
                f"Falha ao ler favoritas do Inter: {type(erro).__name__}.", codigo="banco"
            ) from None

    def concluir(
        self,
        execucao_id: int,
        lojas: tuple[LojaInter, ...],
        retrato: RetratoInter,
    ) -> None:
        import psycopg

        try:
            with psycopg.connect(self._url) as conexao, conexao.cursor() as cursor:
                cursor.execute(self.MARCA_INATIVAS)
                cursor.executemany(
                    self.ATUALIZA_LOJA,
                    [_linha_loja(loja, retrato.momento) for loja in lojas],
                )
                cursor.executemany(
                    self.INSERE_CASHBACK,
                    [_linha_cashback(item, execucao_id) for item in retrato.favoritas],
                )
                cursor.execute(
                    self.CONCLUI_TENTATIVA,
                    (
                        retrato.lojas_lidas,
                        retrato.lojas_validas,
                        retrato.favoritas_encontradas,
                        execucao_id,
                    ),
                )
        except psycopg.Error as erro:
            raise FalhaAoGuardarInter(
                f"Falha ao guardar o retrato do Inter: {type(erro).__name__}.", codigo="banco"
            ) from None

    def falhar(self, execucao_id: int, codigo: str) -> None:
        import psycopg

        try:
            with psycopg.connect(self._url) as conexao, conexao.cursor() as cursor:
                cursor.execute(self.FALHA_TENTATIVA, (codigo, execucao_id))
        except psycopg.Error as erro:
            raise FalhaAoGuardarInter(
                f"Falha ao registrar erro do Inter: {type(erro).__name__}.", codigo="banco"
            ) from None


def _linha_loja(loja: LojaInter, momento: datetime) -> dict:
    return {
        "id_externo": loja.id_externo,
        "slug": loja.slug,
        "nome": loja.nome,
        "nome_busca": normalizar_busca(loja.nome),
        "slug_busca": normalizar_busca(loja.slug),
        "principal_texto": loja.cashback_principal_texto,
        "principal_valor": loja.cashback_principal_valor,
        "secundario_texto": loja.cashback_secundario_texto,
        "secundario_valor": loja.cashback_secundario_valor,
        "etiqueta": loja.etiqueta,
        "descricao_principal": loja.descricao_principal,
        "descricao_secundaria": loja.descricao_secundaria,
        "vista_em": momento,
    }


def _linha_cashback(item: CashbackFavoritaInter, execucao_id: int) -> dict:
    loja = item.loja
    return {
        "execucao_id": execucao_id,
        "id_externo": item.favorita.id_externo,
        "nome": item.nome,
        "principal_texto": loja.cashback_principal_texto if loja else None,
        "principal_valor": loja.cashback_principal_valor if loja else None,
        "secundario_texto": loja.cashback_secundario_texto if loja else None,
        "secundario_valor": loja.cashback_secundario_valor if loja else None,
        "etiqueta": loja.etiqueta if loja else None,
        "descricao_principal": loja.descricao_principal if loja else None,
        "descricao_secundaria": loja.descricao_secundaria if loja else None,
        "encontrada": item.encontrada,
    }
