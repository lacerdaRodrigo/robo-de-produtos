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

    def pagina(
        self,
        loja: LojaDiretaInter,
        search_id: str,
        offset: int,
        limite: int,
        *,
        busca: str = "",
    ) -> str:
        corpo = {
            "aggregate": True,
            "slug": loja.slug,
            "searchText": busca,
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
    """Rodadas, staging, snapshots e historico transacionais por loja."""

    SINCRONIZA_LOJA = """
        INSERT INTO loja_direta_inter (
            id_externo, slug, nome, nome_busca, ativa, vista_em
        ) VALUES (%(id_externo)s, %(slug)s, %(nome)s, %(nome_busca)s, TRUE, now())
        ON CONFLICT (id_externo) DO UPDATE SET
            slug = EXCLUDED.slug, nome = EXCLUDED.nome,
            nome_busca = EXCLUDED.nome_busca,
            ativa = TRUE, vista_em = now(), atualizada_em = now()
    """
    MARCA_LOJAS_AUSENTES = "UPDATE loja_direta_inter SET ativa = FALSE"
    LISTA_SELECIONADAS = """
        SELECT id_externo, slug, nome, selecionada, ativa
          FROM loja_direta_inter
         WHERE selecionada = TRUE AND ativa = TRUE
         ORDER BY nome
    """
    OBTEM_SELECIONADA = """
        SELECT id_externo, slug, nome, selecionada, ativa
          FROM loja_direta_inter
         WHERE id_externo = %s AND selecionada = TRUE AND ativa = TRUE
    """
    INICIA_RODADA = """
        INSERT INTO execucao_produtos_inter (
            iniciada_em, estado, lojas_planejadas, versao
        ) VALUES (%s, 'iniciada', %s, %s)
        RETURNING id
    """
    INICIA_LOJA = """
        INSERT INTO execucao_loja_produtos_inter (
            execucao_produtos_inter_id, loja_direta_inter_id, iniciada_em, estado
        ) VALUES (
            %s,
            (SELECT id FROM loja_direta_inter
              WHERE id_externo = %s AND selecionada = TRUE AND ativa = TRUE),
            %s,
            'iniciada'
        ) RETURNING id
    """
    INSERE_ESTAGIO = """
        INSERT INTO estagio_produto_inter (
            execucao_loja_produtos_inter_id, id_externo, nome, nome_busca, caminho,
            marca, categoria, parcelamento, estoque, etiquetas,
            preco_lista_texto, preco_lista, desconto_texto, desconto_valor,
            desconto_percentual_texto, desconto_percentual,
            preco_atual_texto, preco_atual, cashback_texto, cashback_valor,
            cashback_percentual_texto, cashback_percentual,
            preco_liquido_texto, preco_liquido
        ) VALUES (
            %(execucao_id)s, %(id_externo)s, %(nome)s, %(nome_busca)s, %(caminho)s,
            %(marca)s, %(categoria)s, %(parcelamento)s, %(estoque)s, %(etiquetas)s,
            %(preco_lista_texto)s, %(preco_lista)s, %(desconto_texto)s, %(desconto_valor)s,
            %(desconto_percentual_texto)s, %(desconto_percentual)s,
            %(preco_atual_texto)s, %(preco_atual)s, %(cashback_texto)s, %(cashback_valor)s,
            %(cashback_percentual_texto)s, %(cashback_percentual)s,
            %(preco_liquido_texto)s, %(preco_liquido)s
        )
        ON CONFLICT (execucao_loja_produtos_inter_id, id_externo) DO UPDATE SET
            nome = EXCLUDED.nome, nome_busca = EXCLUDED.nome_busca,
            caminho = EXCLUDED.caminho, marca = EXCLUDED.marca,
            categoria = EXCLUDED.categoria, parcelamento = EXCLUDED.parcelamento,
            estoque = EXCLUDED.estoque, etiquetas = EXCLUDED.etiquetas,
            preco_lista_texto = EXCLUDED.preco_lista_texto,
            preco_lista = EXCLUDED.preco_lista,
            desconto_texto = EXCLUDED.desconto_texto,
            desconto_valor = EXCLUDED.desconto_valor,
            desconto_percentual_texto = EXCLUDED.desconto_percentual_texto,
            desconto_percentual = EXCLUDED.desconto_percentual,
            preco_atual_texto = EXCLUDED.preco_atual_texto,
            preco_atual = EXCLUDED.preco_atual,
            cashback_texto = EXCLUDED.cashback_texto,
            cashback_valor = EXCLUDED.cashback_valor,
            cashback_percentual_texto = EXCLUDED.cashback_percentual_texto,
            cashback_percentual = EXCLUDED.cashback_percentual,
            preco_liquido_texto = EXCLUDED.preco_liquido_texto,
            preco_liquido = EXCLUDED.preco_liquido
    """
    PUBLICA_IDENTIDADES = """
        INSERT INTO produto_direto_inter (
            loja_direta_inter_id, id_externo, nome, nome_busca, caminho,
            marca, categoria, ativo, atualizado_em
        )
        SELECT %s, s.id_externo, s.nome, s.nome_busca, s.caminho,
               s.marca, s.categoria, TRUE, now()
          FROM estagio_produto_inter s
         WHERE s.execucao_loja_produtos_inter_id = %s
        ON CONFLICT (loja_direta_inter_id, id_externo) DO UPDATE SET
            nome = EXCLUDED.nome, nome_busca = EXCLUDED.nome_busca,
            caminho = EXCLUDED.caminho, marca = EXCLUDED.marca,
            categoria = EXCLUDED.categoria, ativo = TRUE, atualizado_em = now()
    """
    INATIVA_AUSENTES = """
        UPDATE produto_direto_inter p
           SET ativo = FALSE, atualizado_em = now()
         WHERE p.loja_direta_inter_id = %s
           AND p.ativo = TRUE
           AND NOT EXISTS (
                SELECT 1 FROM estagio_produto_inter s
                 WHERE s.execucao_loja_produtos_inter_id = %s
                   AND s.id_externo = p.id_externo
           )
    """
    INSERE_MEDICOES = """
        INSERT INTO medicao_produto_direto_inter (
            produto_direto_inter_id, execucao_loja_produtos_inter_id, momento,
            preco_lista_texto, preco_lista, desconto_texto, desconto_valor,
            desconto_percentual_texto, desconto_percentual,
            preco_atual_texto, preco_atual, cashback_texto, cashback_valor,
            cashback_percentual_texto, cashback_percentual,
            preco_liquido_texto, preco_liquido, parcelamento, estoque, etiquetas
        )
        SELECT p.id, s.execucao_loja_produtos_inter_id, %s,
               s.preco_lista_texto, s.preco_lista, s.desconto_texto, s.desconto_valor,
               s.desconto_percentual_texto, s.desconto_percentual,
               s.preco_atual_texto, s.preco_atual, s.cashback_texto, s.cashback_valor,
               s.cashback_percentual_texto, s.cashback_percentual,
               s.preco_liquido_texto, s.preco_liquido, s.parcelamento, s.estoque, s.etiquetas
          FROM estagio_produto_inter s
          JOIN produto_direto_inter p
            ON p.loja_direta_inter_id = %s AND p.id_externo = s.id_externo
         WHERE s.execucao_loja_produtos_inter_id = %s
    """
    CONCLUI_LOJA = """
        UPDATE execucao_loja_produtos_inter
           SET concluida_em = %s, estado = 'sucesso', total_declarado = %s,
               paginas = %s, produtos_lidos = %s, produtos_unicos = %s,
               duplicados = %s, qualidade = %s, tentativas = %s,
               total_declarado_minimo = %s, total_declarado_maximo = %s,
               codigo_falha = NULL
         WHERE id = %s AND estado = 'iniciada'
    """
    FALHA_LOJA = """
        UPDATE execucao_loja_produtos_inter
           SET concluida_em = now(), estado = 'falha', codigo_falha = %s
         WHERE id = %s AND estado = 'iniciada'
    """
    RESUMO_RODADA = """
        SELECT r.lojas_planejadas,
               count(l.id) FILTER (WHERE l.estado = 'sucesso')::int AS sucessos
          FROM execucao_produtos_inter r
          LEFT JOIN execucao_loja_produtos_inter l
            ON l.execucao_produtos_inter_id = r.id
         WHERE r.id = %s
         GROUP BY r.id, r.lojas_planejadas
    """
    CONCLUI_RODADA = """
        UPDATE execucao_produtos_inter
           SET concluida_em = %s, estado = %s,
               lojas_sucesso = %s, lojas_falha = %s, codigo_falha = %s
         WHERE id = %s AND estado = 'iniciada'
    """
    EXPURGA_MEDICOES = (
        "DELETE FROM medicao_produto_direto_inter WHERE momento < now() - interval '30 days'"
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

    def obter_loja_selecionada(self, id_externo: str) -> LojaDiretaInter:
        import psycopg

        try:
            with psycopg.connect(self._url) as conexao, conexao.cursor() as cursor:
                cursor.execute(self.OBTEM_SELECIONADA, (id_externo,))
                linha = cursor.fetchone()
                if not linha:
                    raise RuntimeError("Loja direta nao esta selecionada")
                return LojaDiretaInter(*linha)
        except (psycopg.Error, RuntimeError) as erro:
            raise FalhaAoGuardarProdutosInter(
                f"Falha ao obter loja selecionada: {type(erro).__name__}.", codigo="banco"
            ) from None

    def iniciar_rodada(self, momento: datetime, versao: str, lojas_planejadas: int) -> int:
        import psycopg

        try:
            with psycopg.connect(self._url) as conexao, conexao.cursor() as cursor:
                cursor.execute(self.INICIA_RODADA, (momento, lojas_planejadas, versao))
                linha = cursor.fetchone()
                if not linha:
                    raise RuntimeError("Rodada sem RETURNING")
                return int(linha[0])
        except (psycopg.Error, RuntimeError) as erro:
            raise FalhaAoGuardarProdutosInter(
                f"Falha ao iniciar rodada de produtos: {type(erro).__name__}.", codigo="banco"
            ) from None

    def iniciar_loja(
        self,
        loja: LojaDiretaInter,
        momento: datetime,
        versao: str,
        *,
        rodada_id: int | None = None,
    ) -> int:
        import psycopg

        if rodada_id is None:
            raise ConfiguracaoProdutosInterInvalida(
                "A coleta persistente exige uma rodada coordenadora.", codigo="banco"
            )
        try:
            with psycopg.connect(self._url) as conexao, conexao.cursor() as cursor:
                cursor.execute(self.INICIA_LOJA, (rodada_id, loja.id_externo, momento))
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
        *,
        catalogo_completo: bool = True,
    ) -> None:
        import psycopg

        try:
            linhas = [_linha_estagio(execucao_id, produto) for produto in produtos]
            with psycopg.connect(self._url) as conexao, conexao.cursor() as cursor:
                cursor.execute(
                    "SELECT id FROM loja_direta_inter WHERE id_externo = %s", (loja.id_externo,)
                )
                linha_loja = cursor.fetchone()
                if not linha_loja:
                    raise RuntimeError("Loja direta ausente")
                loja_id = int(linha_loja[0])
                if linhas:
                    cursor.executemany(self.INSERE_ESTAGIO, linhas)
                cursor.execute(self.PUBLICA_IDENTIDADES, (loja_id, execucao_id))
                if catalogo_completo:
                    cursor.execute(self.INATIVA_AUSENTES, (loja_id, execucao_id))
                cursor.execute(
                    self.INSERE_MEDICOES,
                    (resumo.concluida_em, loja_id, execucao_id),
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
                        "degradada" if resumo.degradada else "completa",
                        resumo.tentativas,
                        resumo.total_declarado_minimo,
                        resumo.total_declarado_maximo,
                        execucao_id,
                    ),
                )
                if cursor.rowcount != 1:
                    raise RuntimeError("Execucao da loja nao estava iniciada")
                cursor.execute(
                    "DELETE FROM estagio_produto_inter WHERE execucao_loja_produtos_inter_id = %s",
                    (execucao_id,),
                )
                cursor.execute(self.EXPURGA_MEDICOES)
        except (psycopg.Error, RuntimeError, ValueError) as erro:
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

    def concluir_rodada(self, rodada_id: int, momento: datetime) -> str:
        import psycopg

        try:
            with psycopg.connect(self._url) as conexao, conexao.cursor() as cursor:
                cursor.execute(self.RESUMO_RODADA, (rodada_id,))
                linha = cursor.fetchone()
                if not linha:
                    raise RuntimeError("Rodada nao encontrada")
                planejadas, sucessos = (int(linha[0]), int(linha[1]))
                falhas = max(0, planejadas - sucessos)
                if falhas == 0:
                    estado = "sucesso"
                elif sucessos > 0:
                    estado = "parcial"
                else:
                    estado = "falha"
                codigo = None if estado == "sucesso" else "inesperada"
                cursor.execute(
                    self.CONCLUI_RODADA,
                    (momento, estado, sucessos, falhas, codigo, rodada_id),
                )
                if cursor.rowcount != 1:
                    raise RuntimeError("Rodada nao estava iniciada")
                return estado
        except (psycopg.Error, RuntimeError) as erro:
            raise FalhaAoGuardarProdutosInter(
                f"Falha ao concluir rodada de produtos: {type(erro).__name__}.", codigo="banco"
            ) from None


def _linha_loja(loja: LojaDiretaInter) -> dict[str, object]:
    partes = [loja.nome, loja.slug]
    if loja.slug == "ponto":
        partes.extend(["Ponto Frio", "Pontofrio"])
    return {
        "id_externo": loja.id_externo,
        "slug": loja.slug,
        "nome": loja.nome,
        "nome_busca": normalizar_busca_produtos(" ".join(partes)),
    }


def _linha_estagio(execucao_id: int, produto: ProdutoDiretoInter) -> dict[str, object]:
    if produto.preco_atual_texto is None or produto.preco_atual_valor is None:
        raise ValueError("Produto sem preco atual")
    return {
        "execucao_id": execucao_id,
        "id_externo": produto.id_externo,
        "nome": produto.nome,
        "nome_busca": normalizar_busca_produtos(
            " ".join(parte for parte in (produto.nome, produto.marca, produto.categoria) if parte)
        ),
        "caminho": produto.caminho,
        "marca": produto.marca,
        "categoria": produto.categoria,
        "parcelamento": produto.parcelamento,
        "estoque": produto.estoque,
        "etiquetas": list(produto.etiquetas),
        "preco_lista_texto": produto.preco_cheio_texto,
        "preco_lista": produto.preco_cheio_valor,
        "desconto_texto": produto.desconto_texto,
        "desconto_valor": produto.desconto_valor,
        "desconto_percentual_texto": produto.desconto_percentual_texto,
        "desconto_percentual": produto.desconto_percentual_valor,
        "preco_atual_texto": produto.preco_atual_texto,
        "preco_atual": produto.preco_atual_valor,
        "cashback_texto": produto.cashback_texto,
        "cashback_valor": produto.cashback_valor,
        "cashback_percentual_texto": produto.cashback_percentual_texto,
        "cashback_percentual": produto.cashback_percentual_valor,
        "preco_liquido_texto": produto.preco_liquido_texto,
        "preco_liquido": produto.preco_liquido_valor,
    }
