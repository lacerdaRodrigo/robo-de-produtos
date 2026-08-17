"""Adaptadores HTTP e Postgres exclusivos do catalogo de produtos da V4."""

from __future__ import annotations

import logging
import time
from datetime import datetime

import requests

from robo_livelo.extrator_produtos_inter import normalizar_busca_produtos
from robo_livelo.modelos_produtos_inter import (
    LojaDiretaInter,
    ProdutoDiretoInter,
    ResumoColetaProdutosInter,
)
from robo_livelo.portas_produtos_inter import (
    ConfiguracaoProdutosInterInvalida,
    FalhaAoGuardarProdutosInter,
    FalhaAoObterProdutosInter,
)

_log = logging.getLogger(__name__)

URL_LOJAS_DIRETAS = (
    "https://marketplace-api.web.bancointer.com.br/site/affiliate/inter/v1/ecommerce/"
    "sellers?lang=pt-BR"
)
URL_PRODUTOS_DIRETOS = (
    "https://marketplace-api.web.bancointer.com.br/site/affiliate/inter/v1/ecommerce/"
    "products/search"
)
USER_AGENT_PRODUTOS_INTER = (
    "radar-beneficios/4 (projeto pessoal; github.com/lacerdaRodrigo/robo-livelo)"
)
TAMANHO_MAXIMO_PRODUTOS_INTER = 5 * 1024 * 1024
STATUS_TRANSITORIOS = {408, 429}


class FonteLojasDiretasInterHttp:
    """Le uma vez o catalogo publico de vendedores diretos (RF34)."""

    def __init__(
        self,
        url: str = URL_LOJAS_DIRETAS,
        *,
        tentativas: int = 3,
        timeout: float = 30.0,
        tamanho_maximo: int = TAMANHO_MAXIMO_PRODUTOS_INTER,
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
                    headers=_cabecalhos(),
                )
            except (requests.RequestException, ConnectionError, TimeoutError):
                if tentativa == self._tentativas:
                    raise FalhaAoObterProdutosInter(
                        "O catalogo de lojas diretas nao respondeu.", codigo="rede"
                    ) from None
                self._esperar(tentativa, "catalogo de lojas")
                continue
            if _repetir_ou_falhar(resposta, tentativa, self._tentativas, self._dormir):
                continue
            _validar_resposta(resposta, self._tamanho_maximo)
            return resposta.text
        raise FalhaAoObterProdutosInter("O catalogo de lojas falhou.", codigo="rede")

    def _esperar(self, tentativa: int, contexto: str) -> None:
        _log.warning(
            "Falha ao consultar %s; tentativa %d de %d.", contexto, tentativa, self._tentativas
        )
        self._dormir(2 * tentativa)


class FonteProdutosInterHttp:
    """Consulta sequencial de uma pagina da fonte publica de produtos."""

    def __init__(
        self,
        url: str = URL_PRODUTOS_DIRETOS,
        *,
        tentativas: int = 3,
        timeout: float = 30.0,
        tamanho_maximo: int = TAMANHO_MAXIMO_PRODUTOS_INTER,
        dormir=time.sleep,
        postar=requests.post,
    ) -> None:
        self._url = url
        self._tentativas = tentativas
        self._timeout = timeout
        self._tamanho_maximo = tamanho_maximo
        self._dormir = dormir
        self._postar = postar

    def pagina(self, loja: LojaDiretaInter, search_id: str, offset: int, limite: int) -> str:
        corpo = {
            "aggregate": True,
            "slug": loja.slug,
            "searchText": "",
            "sort": "NAME_ASCENDENT",
            "pagination": {"offset": offset, "limit": limite},
            "featureFilters": [],
            "searchId": search_id,
        }
        for tentativa in range(1, self._tentativas + 1):
            try:
                resposta = self._postar(
                    self._url,
                    json=corpo,
                    timeout=self._timeout,
                    headers=_cabecalhos(),
                )
            except (requests.RequestException, ConnectionError, TimeoutError):
                if tentativa == self._tentativas:
                    raise FalhaAoObterProdutosInter(
                        "A pagina de produtos do Inter nao respondeu.", codigo="rede"
                    ) from None
                _log.warning(
                    "Pagina de produtos falhou; tentativa %d de %d.", tentativa, self._tentativas
                )
                self._dormir(2 * tentativa)
                continue
            if _repetir_ou_falhar(resposta, tentativa, self._tentativas, self._dormir):
                continue
            _validar_resposta(resposta, self._tamanho_maximo)
            return resposta.text
        raise FalhaAoObterProdutosInter("A pagina de produtos falhou.", codigo="rede")


def _cabecalhos() -> dict[str, str]:
    return {
        "User-Agent": USER_AGENT_PRODUTOS_INTER,
        "Accept": "application/json",
        "Accept-Language": "pt-BR",
    }


def _repetir_ou_falhar(resposta: requests.Response, tentativa: int, total: int, dormir) -> bool:
    status = resposta.status_code
    transitorio = status in STATUS_TRANSITORIOS or status >= 500
    if transitorio and tentativa < total:
        _log.warning("Shopping Inter respondeu HTTP %d; tentando novamente.", status)
        dormir(2 * tentativa)
        return True
    if status < 200 or status >= 300:
        raise FalhaAoObterProdutosInter(f"Shopping Inter respondeu HTTP {status}.", codigo="http")
    return False


def _validar_resposta(resposta: requests.Response, tamanho_maximo: int) -> None:
    if len(resposta.content) > tamanho_maximo:
        raise FalhaAoObterProdutosInter(
            "Resposta de produtos do Inter excede 5 MiB.", codigo="resposta_grande"
        )


class RepositorioProdutosInterPostgres:
    """Selecao, snapshots e historico de 30 dias em transacao por loja."""

    SINCRONIZA_LOJA = """
        INSERT INTO loja_direta_inter (
            id_externo, slug, nome, nome_busca, slug_busca, ativa, vista_em
        ) VALUES (%(id_externo)s, %(slug)s, %(nome)s, %(nome_busca)s, %(slug_busca)s, TRUE, now())
        ON CONFLICT (id_externo) DO UPDATE SET
            slug = EXCLUDED.slug, nome = EXCLUDED.nome,
            nome_busca = EXCLUDED.nome_busca, slug_busca = EXCLUDED.slug_busca,
            ativa = TRUE, vista_em = now(), atualizada_em = now()
    """
    MARCA_LOJAS_AUSENTES = "UPDATE loja_direta_inter SET ativa = FALSE"
    LISTA_SELECIONADAS = """
        SELECT id_externo, slug, nome, selecionada, ativa
          FROM loja_direta_inter
         WHERE selecionada = TRUE AND ativa = TRUE
         ORDER BY nome
    """
    INICIA_LOJA = """
        INSERT INTO execucao_loja_produtos_inter (
            loja_direta_inter_id, iniciada_em, estado, versao
        ) VALUES (
            (SELECT id FROM loja_direta_inter WHERE id_externo = %s AND selecionada = TRUE),
            %s, 'iniciada', %s
        ) RETURNING id
    """
    INATIVA_PRODUTOS = """
        UPDATE produto_direto_inter
           SET ativo = FALSE, atualizado_em = now()
         WHERE loja_direta_inter_id = %s AND ativo = TRUE
    """
    UPSERT_PRODUTO = """
        INSERT INTO produto_direto_inter (
            loja_direta_inter_id, id_externo, nome, nome_busca, marca, categoria, caminho,
            preco_cheio_texto, preco_cheio_valor, preco_atual_texto, preco_atual_valor,
            desconto_texto, desconto_valor, desconto_percentual_texto, desconto_percentual_valor,
            cashback_texto, cashback_valor, cashback_percentual_texto, cashback_percentual_valor,
            preco_liquido_texto, preco_liquido_valor, parcelamento, estoque, etiquetas,
            ativo, atualizado_em
        ) VALUES (
            %(loja_id)s, %(id_externo)s, %(nome)s, %(nome_busca)s, %(marca)s, %(categoria)s,
            %(caminho)s, %(preco_cheio_texto)s, %(preco_cheio_valor)s,
            %(preco_atual_texto)s, %(preco_atual_valor)s, %(desconto_texto)s, %(desconto_valor)s,
            %(desconto_percentual_texto)s, %(desconto_percentual_valor)s,
            %(cashback_texto)s, %(cashback_valor)s, %(cashback_percentual_texto)s,
            %(cashback_percentual_valor)s, %(preco_liquido_texto)s, %(preco_liquido_valor)s,
            %(parcelamento)s, %(estoque)s, %(etiquetas)s, TRUE, now()
        ) ON CONFLICT (loja_direta_inter_id, id_externo) DO UPDATE SET
            nome = EXCLUDED.nome, nome_busca = EXCLUDED.nome_busca, marca = EXCLUDED.marca,
            categoria = EXCLUDED.categoria, caminho = EXCLUDED.caminho,
            preco_cheio_texto = EXCLUDED.preco_cheio_texto,
            preco_cheio_valor = EXCLUDED.preco_cheio_valor,
            preco_atual_texto = EXCLUDED.preco_atual_texto,
            preco_atual_valor = EXCLUDED.preco_atual_valor,
            desconto_texto = EXCLUDED.desconto_texto, desconto_valor = EXCLUDED.desconto_valor,
            desconto_percentual_texto = EXCLUDED.desconto_percentual_texto,
            desconto_percentual_valor = EXCLUDED.desconto_percentual_valor,
            cashback_texto = EXCLUDED.cashback_texto, cashback_valor = EXCLUDED.cashback_valor,
            cashback_percentual_texto = EXCLUDED.cashback_percentual_texto,
            cashback_percentual_valor = EXCLUDED.cashback_percentual_valor,
            preco_liquido_texto = EXCLUDED.preco_liquido_texto,
            preco_liquido_valor = EXCLUDED.preco_liquido_valor,
            parcelamento = EXCLUDED.parcelamento, estoque = EXCLUDED.estoque,
            etiquetas = EXCLUDED.etiquetas, ativo = TRUE, atualizado_em = now()
        RETURNING id
    """
    INSERE_MEDICAO = """
        INSERT INTO medicao_produto_inter (
            produto_direto_inter_id, execucao_loja_produtos_inter_id, momento,
            preco_atual_valor, cashback_valor, preco_liquido_valor
        ) VALUES (%s, %s, %s, %s, %s, %s)
    """
    CONCLUI_LOJA = """
        UPDATE execucao_loja_produtos_inter
           SET concluida_em = %s, estado = 'sucesso', total_declarado = %s,
               paginas = %s, itens_lidos = %s, itens_unicos = %s, duplicados = %s,
               codigo_falha = NULL
         WHERE id = %s AND estado = 'iniciada'
    """
    FALHA_LOJA = """
        UPDATE execucao_loja_produtos_inter
           SET concluida_em = now(), estado = 'falha', codigo_falha = %s
         WHERE id = %s AND estado = 'iniciada'
    """
    EXPURGA_MEDICOES = (
        "DELETE FROM medicao_produto_inter WHERE momento < now() - interval '30 days'"
    )

    def __init__(self, url: str) -> None:
        if not url.strip():
            raise ConfiguracaoProdutosInterInvalida(
                "DATABASE_URL nao configurada para produtos do Inter.", codigo="banco"
            )
        self._url = url

    def sincronizar_lojas(self, lojas: tuple[LojaDiretaInter, ...]) -> None:
        import psycopg

        try:
            with psycopg.connect(self._url) as conexao, conexao.cursor() as cursor:
                cursor.execute(self.MARCA_LOJAS_AUSENTES)
                cursor.executemany(self.SINCRONIZA_LOJA, [_linha_loja(loja) for loja in lojas])
        except psycopg.Error as erro:
            raise FalhaAoGuardarProdutosInter(
                f"Falha ao sincronizar lojas diretas: {type(erro).__name__}.", codigo="banco"
            ) from None

    def listar_selecionadas(self) -> list[LojaDiretaInter]:
        import psycopg

        try:
            with psycopg.connect(self._url) as conexao, conexao.cursor() as cursor:
                cursor.execute(self.LISTA_SELECIONADAS)
                return [LojaDiretaInter(*linha) for linha in cursor.fetchall()]
        except psycopg.Error as erro:
            raise FalhaAoGuardarProdutosInter(
                f"Falha ao ler lojas selecionadas: {type(erro).__name__}.", codigo="banco"
            ) from None

    def iniciar_loja(self, loja: LojaDiretaInter, momento: datetime, versao: str) -> int:
        import psycopg

        try:
            with psycopg.connect(self._url) as conexao, conexao.cursor() as cursor:
                cursor.execute(self.INICIA_LOJA, (loja.id_externo, momento, versao))
                linha = cursor.fetchone()
                if not linha:
                    raise RuntimeError("Loja direta nao esta selecionada")
                return int(linha[0])
        except (psycopg.Error, RuntimeError) as erro:
            raise FalhaAoGuardarProdutosInter(
                f"Falha ao iniciar a loja de produtos: {type(erro).__name__}.", codigo="banco"
            ) from None

    def publicar_loja(
        self,
        execucao_id: int,
        loja: LojaDiretaInter,
        produtos: tuple[ProdutoDiretoInter, ...],
        resumo: ResumoColetaProdutosInter,
    ) -> None:
        import psycopg

        try:
            with psycopg.connect(self._url) as conexao, conexao.cursor() as cursor:
                cursor.execute(
                    "SELECT id FROM loja_direta_inter WHERE id_externo = %s", (loja.id_externo,)
                )
                linha_loja = cursor.fetchone()
                if not linha_loja:
                    raise RuntimeError("Loja direta ausente")
                loja_id = int(linha_loja[0])
                # A preparacao inteira vive em memoria ate aqui. Dentro desta
                # transacao, inativacao, snapshot e medicoes entram ou saem juntas.
                cursor.execute(self.INATIVA_PRODUTOS, (loja_id,))
                for produto in produtos:
                    cursor.execute(self.UPSERT_PRODUTO, _linha_produto(loja_id, produto))
                    linha_produto = cursor.fetchone()
                    if not linha_produto:
                        raise RuntimeError("Produto sem RETURNING")
                    cursor.execute(
                        self.INSERE_MEDICAO,
                        (
                            int(linha_produto[0]),
                            execucao_id,
                            resumo.concluida_em,
                            produto.preco_atual_valor,
                            produto.cashback_valor,
                            produto.preco_liquido_valor,
                        ),
                    )
                cursor.execute(
                    self.CONCLUI_LOJA,
                    (
                        resumo.concluida_em,
                        resumo.total_declarado,
                        resumo.paginas,
                        resumo.itens_lidos,
                        resumo.itens_unicos,
                        resumo.duplicados,
                        execucao_id,
                    ),
                )
                cursor.execute(self.EXPURGA_MEDICOES)
        except (psycopg.Error, RuntimeError) as erro:
            raise FalhaAoGuardarProdutosInter(
                f"Falha ao publicar catalogo de produtos: {type(erro).__name__}.", codigo="banco"
            ) from None

    def falhar_loja(self, execucao_id: int, codigo: str) -> None:
        import psycopg

        try:
            with psycopg.connect(self._url) as conexao, conexao.cursor() as cursor:
                cursor.execute(self.FALHA_LOJA, (codigo, execucao_id))
        except psycopg.Error as erro:
            raise FalhaAoGuardarProdutosInter(
                f"Falha ao registrar erro de produtos: {type(erro).__name__}.", codigo="banco"
            ) from None


def _linha_loja(loja: LojaDiretaInter) -> dict[str, object]:
    return {
        "id_externo": loja.id_externo,
        "slug": loja.slug,
        "nome": loja.nome,
        "nome_busca": normalizar_busca_produtos(loja.nome),
        "slug_busca": normalizar_busca_produtos(loja.slug),
    }


def _linha_produto(loja_id: int, produto: ProdutoDiretoInter) -> dict[str, object]:
    return {
        "loja_id": loja_id,
        "id_externo": produto.id_externo,
        "nome": produto.nome,
        "nome_busca": normalizar_busca_produtos(
            " ".join(parte for parte in (produto.nome, produto.marca, produto.categoria) if parte)
        ),
        "marca": produto.marca,
        "categoria": produto.categoria,
        "caminho": produto.caminho,
        "preco_cheio_texto": produto.preco_cheio_texto,
        "preco_cheio_valor": produto.preco_cheio_valor,
        "preco_atual_texto": produto.preco_atual_texto,
        "preco_atual_valor": produto.preco_atual_valor,
        "desconto_texto": produto.desconto_texto,
        "desconto_valor": produto.desconto_valor,
        "desconto_percentual_texto": produto.desconto_percentual_texto,
        "desconto_percentual_valor": produto.desconto_percentual_valor,
        "cashback_texto": produto.cashback_texto,
        "cashback_valor": produto.cashback_valor,
        "cashback_percentual_texto": produto.cashback_percentual_texto,
        "cashback_percentual_valor": produto.cashback_percentual_valor,
        "preco_liquido_texto": produto.preco_liquido_texto,
        "preco_liquido_valor": produto.preco_liquido_valor,
        "parcelamento": produto.parcelamento,
        "estoque": produto.estoque,
        "etiquetas": list(produto.etiquetas),
    }
