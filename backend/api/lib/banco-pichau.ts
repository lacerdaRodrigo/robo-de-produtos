import { neon } from "@neondatabase/serverless";

import {
  MAXIMO_HISTORICO_POR_PAGINA,
  MAXIMO_POR_PAGINA,
  PADRAO_HISTORICO_POR_PAGINA,
} from "./api";
import { buscaPichau } from "./catalogo-pichau";

function conectar() {
  const url = process.env.DATABASE_URL;
  if (!url) throw new Error("DATABASE_URL nao configurada no ambiente da API.");
  return neon(url);
}

export type EstadoTentativaPichau = "iniciada" | "sucesso" | "parcial" | "falha";

export type ResumoPichauPersistido = {
  ultima_tentativa_em: string | null;
  ultima_tentativa_estado: EstadoTentativaPichau | null;
  ultimo_sucesso_em: string | null;
  qualidade: "completa" | "degradada" | null;
  produtos_ativos: number;
  produtos_esgotados: number;
  acompanhadas: number;
};

export type ProdutoPichauPersistido = {
  id_externo: string;
  sku: string | null;
  nome: string;
  marca: string | null;
  categoria_externa: string;
  url_produto: string;
  presente_no_catalogo: boolean;
  acompanhada: boolean;
  disponibilidade: string;
  preco_original_texto: string | null;
  preco_pix_texto: string | null;
  desconto_pix_texto: string | null;
  preco_cartao_texto: string | null;
  parcelamento: string | null;
  sem_juros: boolean | null;
  etiquetas: string[];
  atualizado_em: string | null;
};

export type PaginaPichauPersistida = {
  itens: ProdutoPichauPersistido[];
  total: number;
  pagina: number;
};

export type OpcoesCatalogoPichau = {
  aba: "todas" | "acompanhadas";
  disponibilidade: "todas" | "disponiveis" | "esgotados";
  ordenar: "nome" | "preco" | "desconto";
};

export type HistoricoPichauPersistido = {
  produto: ProdutoPichauPersistido;
  minimo_pix_texto: string | null;
  maximo_pix_texto: string | null;
  medicoes: Array<{
    momento: string;
    preco_pix_texto: string | null;
    preco_cartao_texto: string | null;
  }>;
  total: number;
  pagina: number;
};

export async function resumoPichauPersistido(): Promise<ResumoPichauPersistido> {
  const sql = conectar();
  const linhas = (await sql`
    WITH tentativa AS (
      SELECT iniciada_em, estado
        FROM pichau_execucao
       ORDER BY iniciada_em DESC, id DESC
       LIMIT 1
    ), sucesso AS (
      SELECT concluida_em, qualidade
        FROM pichau_execucao
       WHERE estado = 'sucesso'
       ORDER BY concluida_em DESC, id DESC
       LIMIT 1
    )
    SELECT
      (SELECT iniciada_em FROM tentativa) AS ultima_tentativa_em,
      (SELECT estado FROM tentativa) AS ultima_tentativa_estado,
      (SELECT concluida_em FROM sucesso) AS ultimo_sucesso_em,
      (SELECT qualidade FROM sucesso) AS qualidade,
      count(*) FILTER (WHERE p.presente_no_catalogo)::int AS produtos_ativos,
      count(*) FILTER (WHERE p.presente_no_catalogo AND p.disponibilidade = 'esgotado')::int AS produtos_esgotados,
      count(*) FILTER (WHERE p.acompanhada)::int AS acompanhadas
    FROM pichau_produto p
  `) as ResumoPichauPersistido[];
  return linhas[0] ?? {
    ultima_tentativa_em: null,
    ultima_tentativa_estado: null,
    ultimo_sucesso_em: null,
    qualidade: null,
    produtos_ativos: 0,
    produtos_esgotados: 0,
    acompanhadas: 0,
  };
}

function limiteSeguro(valor: number): number {
  return Math.min(MAXIMO_POR_PAGINA, Math.max(1, Math.floor(valor)));
}

export async function buscarCatalogoPichau(
  q: string,
  opcoes: OpcoesCatalogoPichau,
  pagina: number,
  porPagina: number,
): Promise<PaginaPichauPersistida> {
  const sql = conectar();
  const busca = buscaPichau(q);
  const limite = limiteSeguro(porPagina);
  const paginaSolicitada = Math.max(1, Math.floor(pagina));
  const totalLinhas = (await sql`
    SELECT count(*)::int AS total
      FROM pichau_produto p
     WHERE ((${opcoes.aba === "acompanhadas"} AND p.acompanhada = TRUE)
        OR (${opcoes.aba !== "acompanhadas"} AND p.presente_no_catalogo = TRUE))
       AND (${opcoes.disponibilidade === "todas"}
         OR (${opcoes.disponibilidade === "disponiveis"} AND p.disponibilidade = 'disponivel')
         OR (${opcoes.disponibilidade === "esgotados"} AND p.disponibilidade = 'esgotado'))
       AND (
         ${busca === ""}
         OR p.nome_busca LIKE ${`%${busca}%`}
         OR lower(COALESCE(p.sku, '')) LIKE ${`%${busca}%`}
         OR p.marca_busca LIKE ${`%${busca}%`}
         OR lower(p.id_externo) LIKE ${`%${busca}%`}
       )
  `) as Array<{ total: number }>;
  const total = totalLinhas[0]?.total ?? 0;
  const totalPaginas = Math.max(1, Math.ceil(total / limite));
  const paginaFinal = Math.min(paginaSolicitada, totalPaginas);
  const deslocamento = (paginaFinal - 1) * limite;
  const itens = (await sql`
    SELECT p.id_externo, p.sku, p.nome, p.marca, p.categoria_externa, p.url_produto,
           p.presente_no_catalogo, p.acompanhada, p.disponibilidade,
           m.preco_original_texto, m.preco_pix_texto, m.desconto_pix_texto,
           m.preco_cartao_texto, m.parcelamento, m.sem_juros, m.etiquetas,
           m.momento AS atualizado_em
      FROM pichau_produto p
      LEFT JOIN LATERAL (
        SELECT medicao.*
          FROM pichau_medicao medicao
          JOIN pichau_execucao execucao ON execucao.id = medicao.execucao_id
         WHERE medicao.produto_id = p.id AND execucao.estado = 'sucesso'
         ORDER BY medicao.momento DESC, medicao.id DESC
         LIMIT 1
      ) m ON TRUE
     WHERE ((${opcoes.aba === "acompanhadas"} AND p.acompanhada = TRUE)
        OR (${opcoes.aba !== "acompanhadas"} AND p.presente_no_catalogo = TRUE))
       AND (${opcoes.disponibilidade === "todas"}
         OR (${opcoes.disponibilidade === "disponiveis"} AND p.disponibilidade = 'disponivel')
         OR (${opcoes.disponibilidade === "esgotados"} AND p.disponibilidade = 'esgotado'))
       AND (
         ${busca === ""}
         OR p.nome_busca LIKE ${`%${busca}%`}
         OR lower(COALESCE(p.sku, '')) LIKE ${`%${busca}%`}
           OR p.marca_busca LIKE ${`%${busca}%`}
         OR lower(p.id_externo) LIKE ${`%${busca}%`}
       )
     ORDER BY
       CASE WHEN ${opcoes.ordenar === "preco"} THEN m.preco_pix END ASC NULLS LAST,
       CASE WHEN ${opcoes.ordenar === "desconto"} THEN m.desconto_pix END DESC NULLS LAST,
       p.nome ASC,
       p.id_externo ASC
     LIMIT ${limite} OFFSET ${deslocamento}
  `) as ProdutoPichauPersistido[];
  return { itens, total, pagina: paginaFinal };
}

export async function alterarAcompanhamentoPichau(
  idExterno: string,
  acompanhada: boolean,
): Promise<boolean> {
  const sql = conectar();
  const linhas = (await sql`
    UPDATE pichau_produto
       SET acompanhada = ${acompanhada}, atualizado_em = now()
     WHERE id_externo = ${idExterno}
     RETURNING id_externo
  `) as Array<{ id_externo: string }>;
  return linhas.length > 0;
}

export async function historicoPichau(
  idExterno: string,
  pagina = 1,
  porPagina = PADRAO_HISTORICO_POR_PAGINA,
): Promise<HistoricoPichauPersistido | null> {
  const sql = conectar();
  const limite = Math.min(MAXIMO_HISTORICO_POR_PAGINA, Math.max(1, Math.floor(porPagina)));
  const paginaSolicitada = Math.max(1, Math.floor(pagina));
  const produtos = (await sql`
    SELECT p.id_externo, p.sku, p.nome, p.marca, p.categoria_externa, p.url_produto,
           p.presente_no_catalogo, p.acompanhada, p.disponibilidade,
           m.preco_original_texto, m.preco_pix_texto, m.desconto_pix_texto,
           m.preco_cartao_texto, m.parcelamento, m.sem_juros, m.etiquetas,
           m.momento AS atualizado_em
      FROM pichau_produto p
      LEFT JOIN LATERAL (
        SELECT medicao.*
          FROM pichau_medicao medicao
          JOIN pichau_execucao execucao ON execucao.id = medicao.execucao_id
         WHERE medicao.produto_id = p.id AND execucao.estado = 'sucesso'
         ORDER BY medicao.momento DESC, medicao.id DESC LIMIT 1
      ) m ON TRUE
     WHERE p.id_externo = ${idExterno}
     LIMIT 1
  `) as ProdutoPichauPersistido[];
  const produto = produtos[0];
  if (!produto) return null;

  const totais = (await sql`
    SELECT count(*)::int AS total,
           min(m.preco_pix) AS minimo,
           max(m.preco_pix) AS maximo
      FROM pichau_medicao m
      JOIN pichau_execucao e ON e.id = m.execucao_id AND e.estado = 'sucesso'
      JOIN pichau_produto p ON p.id = m.produto_id
     WHERE p.id_externo = ${idExterno}
       AND m.momento >= now() - interval '30 days'
  `) as Array<{ total: number; minimo: string | null; maximo: string | null }>;
  const total = totais[0]?.total ?? 0;
  const totalPaginas = Math.max(1, Math.ceil(total / limite));
  const paginaFinal = Math.min(paginaSolicitada, totalPaginas);
  const deslocamento = (paginaFinal - 1) * limite;
  const medicoes = (await sql`
    SELECT m.momento, m.preco_pix_texto, m.preco_cartao_texto
      FROM pichau_medicao m
      JOIN pichau_execucao e ON e.id = m.execucao_id AND e.estado = 'sucesso'
      JOIN pichau_produto p ON p.id = m.produto_id
     WHERE p.id_externo = ${idExterno}
       AND m.momento >= now() - interval '30 days'
     ORDER BY m.momento DESC, m.id DESC
     LIMIT ${limite} OFFSET ${deslocamento}
  `) as HistoricoPichauPersistido["medicoes"];
  const formatar = (valor: string | null) => valor === null ? null : `R$ ${valor.replace(".", ",")}`;
  return {
    produto,
    minimo_pix_texto: formatar(totais[0]?.minimo ?? null),
    maximo_pix_texto: formatar(totais[0]?.maximo ?? null),
    medicoes,
    total,
    pagina: paginaFinal,
  };
}
