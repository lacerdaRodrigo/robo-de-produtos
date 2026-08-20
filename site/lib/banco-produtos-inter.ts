import { neon } from "@neondatabase/serverless";

import { normalizarBuscaProdutosInter } from "./formato-produtos-inter";

function conectar() {
  const url = process.env.DATABASE_URL;
  if (!url) throw new Error("DATABASE_URL nao configurada no ambiente do site.");
  return neon(url);
}

export type ProdutoDireto = {
  id_externo: string;
  nome: string;
  marca: string | null;
  categoria: string | null;
  caminho: string;
  preco_cheio_texto: string | null;
  preco_cheio_valor: string | null;
  preco_atual_texto: string;
  preco_atual_valor: string;
  desconto_texto: string | null;
  desconto_percentual_texto: string | null;
  cashback_texto: string | null;
  cashback_percentual_texto: string | null;
  preco_liquido_texto: string | null;
  parcelamento: string | null;
  estoque: number | null;
  etiquetas: string[];
  loja_slug: string;
  loja_nome: string;
  atualizada_em: string;
};

export type LojaDireta = {
  id: string;
  id_externo: string;
  slug: string;
  nome: string;
  selecionada: boolean;
  ativa: boolean;
  ultima_execucao: string | null;
  ultimo_estado: string | null;
  paginas: number | null;
};

export type HistoricoProduto = {
  produto: ProdutoDireto & { ativo: boolean };
  minimo: string | null;
  maximo: string | null;
  medicoes: Array<{
    momento: string;
    preco_atual_valor: string;
    cashback_valor: string | null;
    preco_liquido_valor: string | null;
  }>;
};

export type FiltrosProdutosDiretos = {
  marca?: string | null;
  categoria?: string | null;
  loja?: string | null; // slug da loja direta
  preco_min?: string | null; // string decimal (NUMERIC) >= 0
  preco_max?: string | null;
};

export type PaginaProdutosDiretos = {
  itens: ProdutoDireto[];
  total: number;
};

/** Colunas de produto + a medição mais recente, igual a `buscarProdutosDiretos`
 *  mas com `?` para parâmetros posicionais e um apelido de tabela reutilizável. */
const COLUNAS_PRODUTO = `
  p.id_externo, p.nome, p.marca, p.categoria, p.caminho,
  m.preco_lista_texto AS preco_cheio_texto,
  m.preco_lista AS preco_cheio_valor,
  m.preco_atual_texto, m.preco_atual AS preco_atual_valor,
  m.desconto_texto, m.desconto_percentual_texto,
  m.cashback_texto, m.cashback_percentual_texto,
  m.preco_liquido_texto, m.parcelamento, m.estoque, m.etiquetas,
  m.momento AS atualizada_em, l.slug AS loja_slug, l.nome AS loja_nome`;

/**
 * Busca paginada de produtos (FASE1-Contrato-API §4.3): entrega `total` e uma
 * página de `itens` por consulta. É a correção da lacuna do site atual, que
 * devolvia tudo numa chamada (LIMIT 500) e não paginava.
 *
 * Filtros: marca, categoria, loja (por slug) e faixa de `preco_atual`.
 * Tudo é aplicado no servidor; o cliente nunca baixa o catálogo (PLANO §4.3).
 */
export async function buscarProdutosDiretosPaginado(
  termo: string,
  pagina: number,
  porPagina: number,
  filtros: FiltrosProdutosDiretos = {},
): Promise<PaginaProdutosDiretos> {
  const sql = conectar();
  const busca = normalizarBuscaProdutosInter(termo);

  const params: unknown[] = [];
  const condicoes: string[] = [
    `p.ativo = TRUE AND l.selecionada = TRUE AND l.ativa = TRUE`,
  ];

  // Busca por texto: todos os tokens devem constar em nome/marca/categoria.
  if (busca) {
    params.push(busca);
    condicoes.push(`
      NOT EXISTS (
        SELECT 1 FROM unnest(string_to_array($${params.length}, ' ')) AS t(token)
        WHERE p.nome_busca NOT LIKE '%' || t.token || '%'
      )
    `);
  }

  if (filtros.marca) {
    params.push(`%${filtros.marca}%`);
    condicoes.push(`p.marca ILIKE $${params.length}`);
  }
  if (filtros.categoria) {
    params.push(`%${filtros.categoria}%`);
    condicoes.push(`p.categoria ILIKE $${params.length}`);
  }
  if (filtros.loja) {
    params.push(filtros.loja);
    condicoes.push(`l.slug = $${params.length}`);
  }
  if (filtros.preco_min) {
    params.push(filtros.preco_min);
    condicoes.push(`m.preco_atual >= $${params.length}::numeric`);
  }
  if (filtros.preco_max) {
    params.push(filtros.preco_max);
    condicoes.push(`m.preco_atual <= $${params.length}::numeric`);
  }

  const onde = condicoes.join(" AND ");
  params.push(porPagina);
  params.push((pagina - 1) * porPagina);

  const [totais, itens] = await Promise.all([
    sql(
      `
      SELECT count(*)::int AS total
        FROM produto_direto_inter p
        JOIN loja_direta_inter l ON l.id = p.loja_direta_inter_id
        JOIN LATERAL (
          SELECT med.*
            FROM medicao_produto_direto_inter med
            JOIN execucao_loja_produtos_inter e
              ON e.id = med.execucao_loja_produtos_inter_id AND e.estado = 'sucesso'
           WHERE med.produto_direto_inter_id = p.id
           ORDER BY med.momento DESC
           LIMIT 1
        ) m ON TRUE
       WHERE ${onde}
      `,
      params.slice(0, -2),
    ),
    sql(
      `
      SELECT ${COLUNAS_PRODUTO}
        FROM produto_direto_inter p
        JOIN loja_direta_inter l ON l.id = p.loja_direta_inter_id
        JOIN LATERAL (
          SELECT med.*
            FROM medicao_produto_direto_inter med
            JOIN execucao_loja_produtos_inter e
              ON e.id = med.execucao_loja_produtos_inter_id AND e.estado = 'sucesso'
           WHERE med.produto_direto_inter_id = p.id
           ORDER BY med.momento DESC
           LIMIT 1
        ) m ON TRUE
       WHERE ${onde}
       ORDER BY m.preco_atual ASC, p.nome, p.id_externo
       LIMIT $${params.length - 1} OFFSET $${params.length}
      `,
      params,
    ),
  ]);

  const total = Number(totais[0]?.total ?? 0);
  return {
    itens: itens as ProdutoDireto[],
    total,
  };
}

export async function buscarProdutosDiretos(termo: string): Promise<ProdutoDireto[]> {
  const busca = normalizarBuscaProdutosInter(termo);
  if (!busca) return [];
  const sql = conectar();
  return (await sql`
    SELECT p.id_externo, p.nome, p.marca, p.categoria, p.caminho,
           m.preco_lista_texto AS preco_cheio_texto,
           m.preco_lista AS preco_cheio_valor,
           m.preco_atual_texto, m.preco_atual AS preco_atual_valor,
           m.desconto_texto, m.desconto_percentual_texto,
           m.cashback_texto, m.cashback_percentual_texto,
           m.preco_liquido_texto, m.parcelamento, m.estoque, m.etiquetas,
           m.momento AS atualizada_em, l.slug AS loja_slug, l.nome AS loja_nome
      FROM produto_direto_inter p
      JOIN loja_direta_inter l ON l.id = p.loja_direta_inter_id
      JOIN LATERAL (
        SELECT med.*
          FROM medicao_produto_direto_inter med
          JOIN execucao_loja_produtos_inter e
            ON e.id = med.execucao_loja_produtos_inter_id AND e.estado = 'sucesso'
         WHERE med.produto_direto_inter_id = p.id
         ORDER BY med.momento DESC
         LIMIT 1
      ) m ON TRUE
     WHERE p.ativo = TRUE AND l.selecionada = TRUE AND l.ativa = TRUE
       AND NOT EXISTS (
            SELECT 1
              FROM unnest(string_to_array(${busca}, ' ')) AS termo(token)
             WHERE p.nome_busca NOT LIKE '%' || termo.token || '%'
       )
     ORDER BY m.preco_atual ASC, p.nome, p.id_externo
     LIMIT 500
  `) as ProdutoDireto[];
}

export async function totalProdutosDiretos(): Promise<number> {
  const sql = conectar();
  const linhas = (await sql`
    SELECT count(*)::int AS total
      FROM produto_direto_inter p
      JOIN loja_direta_inter l ON l.id = p.loja_direta_inter_id
     WHERE p.ativo = TRUE
       AND l.selecionada = TRUE
       AND l.ativa = TRUE
  `) as Array<{ total: number }>;
  return Number(linhas[0]?.total ?? 0);
}

export async function buscarLojasDiretas(
  termo: string,
  pagina = 1,
  porPagina = 10,
): Promise<LojaDireta[]> {
  const sql = conectar();
  const busca = normalizarBuscaProdutosInter(termo);
  const paginaSegura = Number.isFinite(pagina) && pagina > 0 ? Math.floor(pagina) : 1;
  const tamanhoSeguro =
    Number.isFinite(porPagina) && porPagina > 0 ? Math.floor(porPagina) : 10;
  const deslocamento = (paginaSegura - 1) * tamanhoSeguro;
  const linhas = (await sql`
    SELECT l.id, l.id_externo, l.slug, l.nome, l.selecionada, l.ativa,
           e.concluida_em AS ultima_execucao, e.estado AS ultimo_estado, e.paginas
      FROM loja_direta_inter l
      LEFT JOIN LATERAL (
        SELECT concluida_em, estado, paginas
          FROM execucao_loja_produtos_inter
         WHERE loja_direta_inter_id = l.id
         ORDER BY iniciada_em DESC LIMIT 1
      ) e ON TRUE
     WHERE (${busca} = '' OR l.nome_busca LIKE ${`%${busca}%`})
     ORDER BY l.nome, l.id_externo
     LIMIT ${tamanhoSeguro}
    OFFSET ${deslocamento}
  `) as LojaDireta[];
  return linhas;
}

export async function totalLojasDiretas(termo = ""): Promise<number> {
  const sql = conectar();
  const busca = normalizarBuscaProdutosInter(termo);
  const linhas = (await sql`
    SELECT count(*)::int AS total
      FROM loja_direta_inter l
     WHERE (${busca} = '' OR l.nome_busca LIKE ${`%${busca}%`})
  `) as Array<{ total: number }>;
  return Number(linhas[0]?.total ?? 0);
}

export async function selecionarLojaDireta(id: string, selecionar: boolean): Promise<void> {
  const sql = conectar();
  await sql`
    UPDATE loja_direta_inter
       SET selecionada = ${selecionar}, atualizada_em = now()
     WHERE id = ${id} AND (${selecionar} = FALSE OR ativa = TRUE)
  `;
}

export async function resumoLojasDiretas(): Promise<{ selecionadas: number; total: number }> {
  const sql = conectar();
  const linhas = (await sql`
    SELECT count(*) FILTER (WHERE selecionada = TRUE AND ativa = TRUE)::int AS selecionadas,
           count(*)::int AS total
      FROM loja_direta_inter
  `) as Array<{ selecionadas: number; total: number }>;
  return linhas[0] ?? { selecionadas: 0, total: 0 };
}

export async function historicoProdutoDireto(
  lojaSlug: string,
  produtoId: string,
): Promise<HistoricoProduto | null> {
  const sql = conectar();
  const produtos = (await sql`
    SELECT p.id, p.id_externo, p.nome, p.marca, p.categoria, p.caminho, p.ativo,
           m.preco_lista_texto AS preco_cheio_texto,
           m.preco_lista AS preco_cheio_valor,
           m.preco_atual_texto, m.preco_atual AS preco_atual_valor,
           m.desconto_texto, m.desconto_percentual_texto,
           m.cashback_texto, m.cashback_percentual_texto,
           m.preco_liquido_texto, m.parcelamento, m.estoque, m.etiquetas,
           m.momento AS atualizada_em, l.slug AS loja_slug, l.nome AS loja_nome
      FROM produto_direto_inter p
      JOIN loja_direta_inter l ON l.id = p.loja_direta_inter_id
      JOIN LATERAL (
        SELECT med.*
          FROM medicao_produto_direto_inter med
          JOIN execucao_loja_produtos_inter e
            ON e.id = med.execucao_loja_produtos_inter_id AND e.estado = 'sucesso'
         WHERE med.produto_direto_inter_id = p.id
         ORDER BY med.momento DESC
         LIMIT 1
      ) m ON TRUE
     WHERE l.slug = ${lojaSlug} AND l.selecionada = TRUE AND p.id_externo = ${produtoId}
     LIMIT 1
  `) as Array<ProdutoDireto & { id: string; ativo: boolean }>;
  const produto = produtos[0];
  if (!produto) return null;
  const [resumo] = (await sql`
    SELECT min(preco_atual) AS minimo, max(preco_atual) AS maximo
      FROM medicao_produto_direto_inter
     WHERE produto_direto_inter_id = ${produto.id}
       AND momento >= now() - interval '30 days'
  `) as Array<{ minimo: string | null; maximo: string | null }>;
  const medicoes = (await sql`
    SELECT momento, preco_atual AS preco_atual_valor,
           cashback_valor, preco_liquido AS preco_liquido_valor
      FROM medicao_produto_direto_inter
     WHERE produto_direto_inter_id = ${produto.id}
       AND momento >= now() - interval '30 days'
     ORDER BY momento DESC
  `) as HistoricoProduto["medicoes"];
  return { produto, minimo: resumo?.minimo ?? null, maximo: resumo?.maximo ?? null, medicoes };
}

export type StatusCatalogoProdutos = {
  atualizado_em: string | null;
  qualidade: string | null;
};

/** Resumo da última execução de produtos, para o envelope da busca pública
 *  (FASE1-Contrato-API §4.3: `atualizado_em` e `qualidade`). null quando a
 *  V4 ainda não coletou nada. */
export async function statusCatalogoProdutos(): Promise<StatusCatalogoProdutos> {
  const sql = conectar();
  const linhas = (await sql`
    SELECT concluida_em AS atualizado_em, qualidade
      FROM execucao_loja_produtos_inter
     ORDER BY iniciada_em DESC
     LIMIT 1
  `) as StatusCatalogoProdutos[];
  return linhas[0] ?? { atualizado_em: null, qualidade: null };
}
