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

export type EstadoTentativaPichau =
  "iniciada" | "sucesso" | "parcial" | "falha";

export type ResumoPichauPersistido = {
  ultima_tentativa_em: string | null;
  ultima_tentativa_estado: EstadoTentativaPichau | null;
  ultimo_sucesso_em: string | null;
  qualidade: "completa" | "degradada" | null;
  total_catalogo: number;
  acompanhadas: number;
  produtos_ativos: number;
  produtos_esgotados: number;
};

export type OpcoesCatalogoPichau = {
  q: string;
  aba: "todas" | "acompanhadas";
  disponibilidade: "todas" | "disponiveis" | "esgotados" | "fora_catalogo";
  ordenar: "nome" | "preco" | "desconto";
  precoMin: string | null;
  precoMax: string | null;
  pagina: number;
  porPagina: number;
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

export type AcompanhamentoPichauPersistido = {
  id_externo: string;
  acompanhada: boolean;
};

export type PaginaPichauPersistida = {
  itens: ProdutoPichauPersistido[];
  total: number;
  pagina: number;
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

function falhaNoAcompanhamentoPessoal(erro: unknown): boolean {
  if (typeof erro !== "object" || erro === null) return false;
  const registro = erro as { code?: unknown; message?: unknown };
  const codigo = typeof registro.code === "string" ? registro.code : "";
  const mensagem = typeof registro.message === "string" ? registro.message : "";
  return (
    (codigo === "42P01" || codigo === "42501" || codigo === "42703") &&
    /acompanhamento_usuario|acompanhamento\./i.test(mensagem)
  );
}

async function resumoPichauSemAcompanhamento(): Promise<ResumoPichauPersistido> {
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
      count(*) FILTER (WHERE p.presente_no_catalogo)::int AS total_catalogo,
      count(*) FILTER (WHERE p.acompanhada)::int AS acompanhadas,
      count(*) FILTER (WHERE p.presente_no_catalogo)::int AS produtos_ativos,
      count(*) FILTER (WHERE p.presente_no_catalogo AND p.disponibilidade = 'esgotado')::int AS produtos_esgotados
    FROM pichau_produto p
  `) as ResumoPichauPersistido[];
  return (
    linhas[0] ?? {
      ultima_tentativa_em: null,
      ultima_tentativa_estado: null,
      ultimo_sucesso_em: null,
      qualidade: null,
      total_catalogo: 0,
      acompanhadas: 0,
      produtos_ativos: 0,
      produtos_esgotados: 0,
    }
  );
}

export async function resumoPichauPersistido(
  usuarioId?: string,
): Promise<ResumoPichauPersistido> {
  if (usuarioId === undefined) return resumoPichauSemAcompanhamento();

  try {
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
        count(*) FILTER (WHERE p.presente_no_catalogo)::int AS total_catalogo,
        count(*) FILTER (WHERE EXISTS (
          SELECT 1 FROM acompanhamento_usuario acompanhamento
           WHERE acompanhamento.usuario_app_id = ${usuarioId}
             AND acompanhamento.origem = 'pichau'
             AND acompanhamento.entidade_id = p.id
        ))::int AS acompanhadas,
        count(*) FILTER (WHERE p.presente_no_catalogo)::int AS produtos_ativos,
        count(*) FILTER (WHERE p.presente_no_catalogo AND p.disponibilidade = 'esgotado')::int AS produtos_esgotados
      FROM pichau_produto p
    `) as ResumoPichauPersistido[];
    return linhas[0] ?? resumoPichauSemAcompanhamento();
  } catch (erro) {
    if (!falhaNoAcompanhamentoPessoal(erro)) throw erro;
    return resumoPichauSemAcompanhamento();
  }
}

function limiteSeguro(valor: number): number {
  return Math.min(MAXIMO_POR_PAGINA, Math.max(1, Math.floor(valor)));
}

export async function buscarCatalogoPichau(
  opcoes: OpcoesCatalogoPichau,
  usuarioId?: string,
): Promise<PaginaPichauPersistida> {
  if (usuarioId === undefined) return buscarCatalogoPichauPorEscopo(opcoes);

  try {
    return await buscarCatalogoPichauPorEscopo(opcoes, usuarioId);
  } catch (erro) {
    if (!falhaNoAcompanhamentoPessoal(erro)) throw erro;
    return buscarCatalogoPichauPorEscopo(opcoes);
  }
}

async function buscarCatalogoPichauPorEscopo(
  opcoes: OpcoesCatalogoPichau,
  usuarioId?: string,
): Promise<PaginaPichauPersistida> {
  if (usuarioId === undefined) return buscarCatalogoPichauLegado(opcoes);
  return buscarCatalogoPichauPessoal(opcoes, usuarioId);
}

async function buscarCatalogoPichauPessoal(
  opcoes: OpcoesCatalogoPichau,
  usuarioId: string,
): Promise<PaginaPichauPersistida> {
  const sql = conectar();
  const busca = buscaPichau(opcoes.q);
  const limite = limiteSeguro(opcoes.porPagina);
  const paginaSolicitada = Math.max(1, Math.floor(opcoes.pagina));
  const todas = opcoes.aba === "todas";
  const acompanhadas = opcoes.aba === "acompanhadas";
  const acompanhamentoUsuario = usuarioId ?? null;
  const usaAcompanhamentoPessoal = usuarioId !== undefined;
  const todasDisponibilidades = opcoes.disponibilidade === "todas";
  const disponiveis = opcoes.disponibilidade === "disponiveis";
  const esgotados = opcoes.disponibilidade === "esgotados";
  const foraCatalogo = opcoes.disponibilidade === "fora_catalogo";
  const porPreco = opcoes.ordenar === "preco";
  const porDesconto = opcoes.ordenar === "desconto";
  const semPrecoMin = opcoes.precoMin === null;
  const semPrecoMax = opcoes.precoMax === null;
  const totalLinhas = (await sql`
    SELECT count(*)::int AS total
      FROM pichau_produto p
     WHERE (
         (${todas} AND p.presente_no_catalogo = TRUE)
         OR (${acompanhadas} AND (
           (${usaAcompanhamentoPessoal} AND EXISTS (
              SELECT 1 FROM acompanhamento_usuario acompanhamento
               WHERE acompanhamento.usuario_app_id = ${acompanhamentoUsuario}
                 AND acompanhamento.origem = 'pichau'
                 AND acompanhamento.entidade_id = p.id
           ))
           OR (${!usaAcompanhamentoPessoal} AND p.acompanhada = TRUE)
         ))
       )
       AND (
         ${todasDisponibilidades}
         OR (${disponiveis} AND p.presente_no_catalogo = TRUE AND p.disponibilidade <> 'esgotado')
         OR (${esgotados} AND p.presente_no_catalogo = TRUE AND p.disponibilidade = 'esgotado')
         OR (${foraCatalogo} AND p.presente_no_catalogo = FALSE)
       )
       AND (
         ${busca === ""}
         OR p.nome_busca LIKE ${`%${busca}%`}
         OR lower(COALESCE(p.sku, '')) LIKE ${`%${busca}%`}
         OR p.marca_busca LIKE ${`%${busca}%`}
         OR lower(p.id_externo) LIKE ${`%${busca}%`}
       )
       AND (
         ${semPrecoMin}
         OR (SELECT medicao.preco_pix
               FROM pichau_medicao medicao
               JOIN pichau_execucao execucao
                 ON execucao.id = medicao.execucao_id
                AND execucao.estado = 'sucesso'
              WHERE medicao.produto_id = p.id
              ORDER BY medicao.momento DESC, medicao.id DESC
              LIMIT 1) >= ${opcoes.precoMin}::numeric
       )
       AND (
         ${semPrecoMax}
         OR (SELECT medicao.preco_pix
               FROM pichau_medicao medicao
               JOIN pichau_execucao execucao
                 ON execucao.id = medicao.execucao_id
                AND execucao.estado = 'sucesso'
              WHERE medicao.produto_id = p.id
              ORDER BY medicao.momento DESC, medicao.id DESC
              LIMIT 1) <= ${opcoes.precoMax}::numeric
       )
  `) as Array<{ total: number }>;
  const total = totalLinhas[0]?.total ?? 0;
  const totalPaginas = Math.max(1, Math.ceil(total / limite));
  const paginaFinal = Math.min(paginaSolicitada, totalPaginas);
  const deslocamento = (paginaFinal - 1) * limite;
  const itens = (await sql`
    SELECT p.id_externo, p.sku, p.nome, p.marca, p.categoria_externa, p.url_produto,
           p.presente_no_catalogo, p.disponibilidade,
           CASE WHEN ${usaAcompanhamentoPessoal}
                THEN EXISTS (
                       SELECT 1 FROM acompanhamento_usuario acompanhamento
                        WHERE acompanhamento.usuario_app_id = ${acompanhamentoUsuario}
                          AND acompanhamento.origem = 'pichau'
                          AND acompanhamento.entidade_id = p.id
                     )
                ELSE p.acompanhada END AS acompanhada,
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
     WHERE (
         (${todas} AND p.presente_no_catalogo = TRUE)
         OR (${acompanhadas} AND (
           (${usaAcompanhamentoPessoal} AND EXISTS (
              SELECT 1 FROM acompanhamento_usuario acompanhamento
               WHERE acompanhamento.usuario_app_id = ${acompanhamentoUsuario}
                 AND acompanhamento.origem = 'pichau'
                 AND acompanhamento.entidade_id = p.id
           ))
           OR (${!usaAcompanhamentoPessoal} AND p.acompanhada = TRUE)
         ))
       )
       AND (
         ${todasDisponibilidades}
         OR (${disponiveis} AND p.presente_no_catalogo = TRUE AND p.disponibilidade <> 'esgotado')
         OR (${esgotados} AND p.presente_no_catalogo = TRUE AND p.disponibilidade = 'esgotado')
         OR (${foraCatalogo} AND p.presente_no_catalogo = FALSE)
       )
       AND (
         ${busca === ""}
         OR p.nome_busca LIKE ${`%${busca}%`}
         OR lower(COALESCE(p.sku, '')) LIKE ${`%${busca}%`}
           OR p.marca_busca LIKE ${`%${busca}%`}
         OR lower(p.id_externo) LIKE ${`%${busca}%`}
       )
       AND (${semPrecoMin} OR m.preco_pix >= ${opcoes.precoMin}::numeric)
       AND (${semPrecoMax} OR m.preco_pix <= ${opcoes.precoMax}::numeric)
     ORDER BY
       CASE WHEN ${porPreco} THEN m.preco_pix END ASC NULLS LAST,
       CASE WHEN ${porDesconto} THEN m.desconto_pix END DESC NULLS LAST,
       p.nome ASC, p.id_externo ASC
     LIMIT ${limite} OFFSET ${deslocamento}
  `) as ProdutoPichauPersistido[];
  return { itens, total, pagina: paginaFinal };
}

async function buscarCatalogoPichauLegado(
  opcoes: OpcoesCatalogoPichau,
): Promise<PaginaPichauPersistida> {
  const sql = conectar();
  const busca = buscaPichau(opcoes.q);
  const limite = limiteSeguro(opcoes.porPagina);
  const paginaSolicitada = Math.max(1, Math.floor(opcoes.pagina));
  const todas = opcoes.aba === "todas";
  const acompanhadas = opcoes.aba === "acompanhadas";
  const todasDisponibilidades = opcoes.disponibilidade === "todas";
  const disponiveis = opcoes.disponibilidade === "disponiveis";
  const esgotados = opcoes.disponibilidade === "esgotados";
  const foraCatalogo = opcoes.disponibilidade === "fora_catalogo";
  const porPreco = opcoes.ordenar === "preco";
  const porDesconto = opcoes.ordenar === "desconto";
  const semPrecoMin = opcoes.precoMin === null;
  const semPrecoMax = opcoes.precoMax === null;
  const totalLinhas = (await sql`
    SELECT count(*)::int AS total
      FROM pichau_produto p
     WHERE (
         (${todas} AND p.presente_no_catalogo = TRUE)
         OR (${acompanhadas} AND p.acompanhada = TRUE)
       )
       AND (
         ${todasDisponibilidades}
         OR (${disponiveis} AND p.presente_no_catalogo = TRUE AND p.disponibilidade <> 'esgotado')
         OR (${esgotados} AND p.presente_no_catalogo = TRUE AND p.disponibilidade = 'esgotado')
         OR (${foraCatalogo} AND p.presente_no_catalogo = FALSE)
       )
       AND (
         ${busca === ""}
         OR p.nome_busca LIKE ${`%${busca}%`}
         OR lower(COALESCE(p.sku, '')) LIKE ${`%${busca}%`}
         OR p.marca_busca LIKE ${`%${busca}%`}
         OR lower(p.id_externo) LIKE ${`%${busca}%`}
       )
       AND (
         ${semPrecoMin}
         OR (SELECT medicao.preco_pix
               FROM pichau_medicao medicao
               JOIN pichau_execucao execucao
                 ON execucao.id = medicao.execucao_id
                AND execucao.estado = 'sucesso'
              WHERE medicao.produto_id = p.id
              ORDER BY medicao.momento DESC, medicao.id DESC
              LIMIT 1) >= ${opcoes.precoMin}::numeric
       )
       AND (
         ${semPrecoMax}
         OR (SELECT medicao.preco_pix
               FROM pichau_medicao medicao
               JOIN pichau_execucao execucao
                 ON execucao.id = medicao.execucao_id
                AND execucao.estado = 'sucesso'
              WHERE medicao.produto_id = p.id
              ORDER BY medicao.momento DESC, medicao.id DESC
              LIMIT 1) <= ${opcoes.precoMax}::numeric
       )
  `) as Array<{ total: number }>;
  const total = totalLinhas[0]?.total ?? 0;
  const totalPaginas = Math.max(1, Math.ceil(total / limite));
  const paginaFinal = Math.min(paginaSolicitada, totalPaginas);
  const deslocamento = (paginaFinal - 1) * limite;
  const itens = (await sql`
    SELECT p.id_externo, p.sku, p.nome, p.marca, p.categoria_externa, p.url_produto,
           p.presente_no_catalogo, p.disponibilidade, p.acompanhada,
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
     WHERE (
         (${todas} AND p.presente_no_catalogo = TRUE)
         OR (${acompanhadas} AND p.acompanhada = TRUE)
       )
       AND (
         ${todasDisponibilidades}
         OR (${disponiveis} AND p.presente_no_catalogo = TRUE AND p.disponibilidade <> 'esgotado')
         OR (${esgotados} AND p.presente_no_catalogo = TRUE AND p.disponibilidade = 'esgotado')
         OR (${foraCatalogo} AND p.presente_no_catalogo = FALSE)
       )
       AND (
         ${busca === ""}
         OR p.nome_busca LIKE ${`%${busca}%`}
         OR lower(COALESCE(p.sku, '')) LIKE ${`%${busca}%`}
         OR p.marca_busca LIKE ${`%${busca}%`}
         OR lower(p.id_externo) LIKE ${`%${busca}%`}
       )
       AND (${semPrecoMin} OR m.preco_pix >= ${opcoes.precoMin}::numeric)
       AND (${semPrecoMax} OR m.preco_pix <= ${opcoes.precoMax}::numeric)
     ORDER BY
       CASE WHEN ${porPreco} THEN m.preco_pix END ASC NULLS LAST,
       CASE WHEN ${porDesconto} THEN m.desconto_pix END DESC NULLS LAST,
       p.nome ASC, p.id_externo ASC
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
  usuarioId?: string,
): Promise<HistoricoPichauPersistido | null> {
  const sql = conectar();
  const acompanhamentoUsuario = usuarioId ?? null;
  const usaAcompanhamentoPessoal = usuarioId !== undefined;
  const limite = Math.min(
    MAXIMO_HISTORICO_POR_PAGINA,
    Math.max(1, Math.floor(porPagina)),
  );
  const paginaSolicitada = Math.max(1, Math.floor(pagina));
  const produtos = (await sql`
    SELECT p.id_externo, p.sku, p.nome, p.marca, p.categoria_externa, p.url_produto,
           p.presente_no_catalogo, p.disponibilidade,
           CASE WHEN ${usaAcompanhamentoPessoal}
                THEN EXISTS (
                       SELECT 1 FROM acompanhamento_usuario acompanhamento
                        WHERE acompanhamento.usuario_app_id = ${acompanhamentoUsuario}
                          AND acompanhamento.origem = 'pichau'
                          AND acompanhamento.entidade_id = p.id
                     )
                ELSE p.acompanhada END AS acompanhada,
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
  const formatar = (valor: string | null) =>
    valor === null ? null : `R$ ${valor.replace(".", ",")}`;
  return {
    produto,
    minimo_pix_texto: formatar(totais[0]?.minimo ?? null),
    maximo_pix_texto: formatar(totais[0]?.maximo ?? null),
    medicoes,
    total,
    pagina: paginaFinal,
  };
}
