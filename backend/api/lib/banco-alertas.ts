import { neon } from "@neondatabase/serverless";

import type { OrigemAlerta, PreferenciasAlertasEntrada, TipoAlerta } from "./alertas-api";
import type { ParceiroLiveloPersistido } from "./banco";
import { apresentarParceiroLivelo } from "./catalogo-livelo";
import { mensageriaFirebase } from "./firebase-admin";
import { linkShoppingInterDaLoja } from "./formato-inter";
import { formatarCorpoPush, type EventoPush } from "./notificacoes-formatacao";

function conectar() {
  const url = process.env.DATABASE_URL;
  if (!url) throw new Error("DATABASE_URL nao configurada no ambiente do site.");
  return neon(url);
}

export type AlertaApp = {
  id: string;
  origem: OrigemAlerta;
  tipo: TipoAlerta;
  entidade_id: string;
  entidade_externa: string | null;
  entidade_nome: string;
  coleta_id: string;
  valor_anterior: string | null;
  valor_atual: string;
  unidade: string;
  direcao: "aumento" | "reducao";
  lido: boolean;
  criado_em: string;
};

export type ItemAlertaApp = {
  origem: OrigemAlerta;
  item: Record<string, unknown>;
};

export type RelatoProblemaApp = {
  id: string;
  categoria: string;
  mensagem: string;
  criado_em: string;
};

export type PreferenciasAlertas = PreferenciasAlertasEntrada;

export const ORIGENS_ACOMPANHAMENTO = [
  "livelo",
  "inter_cashback",
  "inter_produto",
  "pichau",
] as const;
export type OrigemAcompanhamento = (typeof ORIGENS_ACOMPANHAMENTO)[number];
export type EstadoAcompanhamento =
  | "atualizado"
  | "parcial"
  | "atrasado"
  | "sem_dados"
  | "indisponivel";

export type AcompanhamentoPessoal = {
  id: string;
  origem: OrigemAcompanhamento;
  tipo_entidade: "parceiro" | "loja" | "produto";
  entidade_id: string;
  entidade_externa: string | null;
  nome: string;
  estado: EstadoAcompanhamento;
  valor_atual: string | null;
  valor_texto: string | null;
  unidade: string | null;
  url_externa: string | null;
  criado_em: string;
  atualizado_em: string;
};

export type ResultadoAcompanhamentosPessoais = {
  itens: AcompanhamentoPessoal[];
  total: number;
  pagina: number;
  totaisPorOrigem: Record<OrigemAcompanhamento, number>;
};

export type DestaqueRadarPessoal = {
  alerta_id: string;
  origem: OrigemAcompanhamento;
  tipo: TipoAlerta;
  entidade_id: string;
  entidade_externa: string | null;
  nome: string;
  valor_anterior: string | null;
  valor_atual: string;
  unidade: string;
  direcao: "aumento" | "reducao";
  criado_em: string;
  url_externa: string | null;
};

export type ResumoRadarPessoal = {
  estado: "atualizado" | "parcial" | "indisponivel";
  total_acompanhamentos: number | null;
  por_origem: Record<OrigemAcompanhamento, number | null>;
  alertas_nao_lidos: number | null;
  destaque: DestaqueRadarPessoal | null;
};

const ACOMPANHAMENTOS_SELECT = `
  SELECT acompanhamento.id::text AS id,
         'livelo'::text AS origem,
         'parceiro'::text AS tipo_entidade,
         parceiro.id::text AS entidade_id,
         parceiro.id_externo AS entidade_externa,
         parceiro.nome,
         CASE
           WHEN parceiro.ativo = FALSE THEN 'indisponivel'
           WHEN execucao.qualidade = 'degradada' THEN 'parcial'
           WHEN execucao.momento IS NULL THEN 'sem_dados'
           WHEN execucao.momento < now() - interval '36 hours' THEN 'atrasado'
           ELSE 'atualizado'
         END AS estado,
         parceiro.pontos_atuais::text AS valor_atual,
         parceiro.pontos_atuais::text || ' pontos por real' AS valor_texto,
         'pontos_por_real'::text AS unidade,
         parceiro.link AS url_externa,
         acompanhamento.criado_em,
         acompanhamento.atualizado_em
    FROM acompanhamento_usuario acompanhamento
    JOIN parceiro_livelo parceiro
      ON parceiro.id = acompanhamento.entidade_id
     AND acompanhamento.origem = 'livelo'
    LEFT JOIN execucao
      ON execucao.id = parceiro.atualizado_execucao_id
   WHERE acompanhamento.usuario_app_id = $1::bigint

  UNION ALL

  SELECT acompanhamento.id::text,
         'inter_cashback'::text,
         'loja'::text,
         loja.id::text,
         loja.id_externo,
         loja.nome,
         CASE
           WHEN loja.ativa = FALSE THEN 'indisponivel'
           WHEN cashback.concluida_em IS NULL THEN 'sem_dados'
           WHEN cashback.concluida_em < now() - interval '36 hours' THEN 'atrasado'
           ELSE 'atualizado'
         END,
         cashback.cashback_principal_valor::text,
         cashback.cashback_principal_texto,
         'percentual'::text,
         loja.slug,
         acompanhamento.criado_em,
         acompanhamento.atualizado_em
    FROM acompanhamento_usuario acompanhamento
    JOIN loja_inter loja
      ON loja.id = acompanhamento.entidade_id
     AND acompanhamento.origem = 'inter_cashback'
    LEFT JOIN LATERAL (
      SELECT coleta.concluida_em,
             resultado.cashback_principal_valor,
             resultado.cashback_principal_texto
        FROM cashback_inter resultado
        JOIN execucao_inter coleta ON coleta.id = resultado.execucao_inter_id
       WHERE resultado.loja_inter_id = loja.id
         AND coleta.estado = 'sucesso'
       ORDER BY coleta.concluida_em DESC NULLS LAST, resultado.id DESC
       LIMIT 1
    ) cashback ON TRUE
   WHERE acompanhamento.usuario_app_id = $1::bigint

  UNION ALL

  SELECT acompanhamento.id::text,
         'inter_produto'::text,
         'produto'::text,
         produto.id::text,
         produto.id_externo,
         produto.nome,
         CASE
           WHEN produto.ativo = FALSE OR loja.ativa = FALSE THEN 'indisponivel'
           WHEN medicao.momento IS NULL THEN 'sem_dados'
           WHEN medicao.momento < now() - interval '36 hours' THEN 'atrasado'
           ELSE 'atualizado'
         END,
         medicao.preco_atual::text,
         medicao.preco_atual_texto,
         'BRL'::text,
         produto.caminho,
         acompanhamento.criado_em,
         acompanhamento.atualizado_em
    FROM acompanhamento_usuario acompanhamento
    JOIN produto_direto_inter produto
      ON produto.id = acompanhamento.entidade_id
     AND acompanhamento.origem = 'inter_produto'
    JOIN loja_direta_inter loja ON loja.id = produto.loja_direta_inter_id
    LEFT JOIN LATERAL (
      SELECT medicao.momento, medicao.preco_atual, medicao.preco_atual_texto
        FROM medicao_produto_direto_inter medicao
        JOIN execucao_loja_produtos_inter coleta
          ON coleta.id = medicao.execucao_loja_produtos_inter_id
         AND coleta.estado = 'sucesso'
       WHERE medicao.produto_direto_inter_id = produto.id
       ORDER BY medicao.momento DESC, medicao.id DESC
       LIMIT 1
    ) medicao ON TRUE
   WHERE acompanhamento.usuario_app_id = $1::bigint

  UNION ALL

  SELECT acompanhamento.id::text,
         'pichau'::text,
         'produto'::text,
         produto.id::text,
         produto.id_externo,
         produto.nome,
         CASE
           WHEN produto.presente_no_catalogo = FALSE THEN 'indisponivel'
           WHEN medicao.momento IS NULL THEN 'sem_dados'
           WHEN medicao.momento < now() - interval '36 hours' THEN 'atrasado'
           ELSE 'atualizado'
         END,
         medicao.preco_pix::text,
         medicao.preco_pix_texto,
         'BRL'::text,
         produto.url_produto,
         acompanhamento.criado_em,
         acompanhamento.atualizado_em
    FROM acompanhamento_usuario acompanhamento
    JOIN pichau_produto produto
      ON produto.id = acompanhamento.entidade_id
     AND acompanhamento.origem = 'pichau'
    LEFT JOIN LATERAL (
      SELECT medicao.momento, medicao.preco_pix, medicao.preco_pix_texto
        FROM pichau_medicao medicao
        JOIN pichau_execucao coleta
          ON coleta.id = medicao.execucao_id
         AND coleta.estado = 'sucesso'
       WHERE medicao.produto_id = produto.id
       ORDER BY medicao.momento DESC, medicao.id DESC
       LIMIT 1
    ) medicao ON TRUE
   WHERE acompanhamento.usuario_app_id = $1::bigint
`;

function origemValida(valor: string): valor is OrigemAcompanhamento {
  return (ORIGENS_ACOMPANHAMENTO as readonly string[]).includes(valor);
}

function urlExterna(origem: OrigemAcompanhamento, valor: string | null): string | null {
  if (!valor) return null;
  const candidata = origem === "inter_cashback"
    ? linkShoppingInterDaLoja(valor)
    : origem === "inter_produto" && valor.startsWith("/")
      ? `https://shopping.inter.co${valor}`
      : valor;
  try {
    const url = new URL(candidata);
    return url.protocol === "http:" || url.protocol === "https:" ? url.toString() : null;
  } catch {
    return null;
  }
}

function apresentarAcompanhamento(item: AcompanhamentoPessoal): AcompanhamentoPessoal {
  return { ...item, url_externa: urlExterna(item.origem, item.url_externa) };
}

const origensVazias = (): Record<OrigemAcompanhamento, number> => ({
  livelo: 0,
  inter_cashback: 0,
  inter_produto: 0,
  pichau: 0,
});

export async function buscarAcompanhamentosPessoais(
  usuarioId: string,
  opcoes: {
    q: string;
    origem: OrigemAcompanhamento | null;
    ordenar: "recentes" | "nome";
    pagina: number;
    porPagina: number;
  },
): Promise<ResultadoAcompanhamentosPessoais> {
  const sql = conectar();
  const limite = Math.min(50, Math.max(1, Math.floor(opcoes.porPagina)));
  const paginaSolicitada = Math.max(1, Math.floor(opcoes.pagina));
  const busca = opcoes.q.trim().toLocaleLowerCase("pt-BR");
  const filtros = `
    WHERE ($2 = '' OR lower(coalesce(nome, '')) LIKE '%' || lower($2) || '%'
      OR lower(coalesce(entidade_externa, '')) LIKE '%' || lower($2) || '%')
      AND ($3::text IS NULL OR origem = $3::text)
  `;
  const [totais, contagens] = await Promise.all([
    sql(
      `SELECT count(*)::int AS total FROM (${ACOMPANHAMENTOS_SELECT}) itens ${filtros}`,
      [usuarioId, busca, opcoes.origem],
    ) as unknown as Promise<Array<{ total: number }>>,
    sql(
      `SELECT origem, count(*)::int AS total FROM (${ACOMPANHAMENTOS_SELECT}) itens GROUP BY origem`,
      [usuarioId],
    ) as unknown as Promise<Array<{ origem: string; total: number }>>,
  ]);
  const total = totais[0]?.total ?? 0;
  const totalPaginas = Math.max(1, Math.ceil(total / limite));
  const pagina = Math.min(paginaSolicitada, totalPaginas);
  const itens = (await sql(
    `SELECT * FROM (${ACOMPANHAMENTOS_SELECT}) itens
      ${filtros}
      ORDER BY
        CASE WHEN $4 = 'nome' THEN lower(nome) END ASC NULLS LAST,
        CASE WHEN $4 = 'recentes' THEN atualizado_em END DESC NULLS LAST,
        id DESC
      LIMIT $5 OFFSET $6`,
    [usuarioId, busca, opcoes.origem, opcoes.ordenar, limite, (pagina - 1) * limite],
  )) as AcompanhamentoPessoal[];
  const totaisPorOrigem = origensVazias();
  for (const contagem of contagens) {
    if (origemValida(contagem.origem)) totaisPorOrigem[contagem.origem] = contagem.total;
  }
  return {
    itens: itens.map(apresentarAcompanhamento),
    total,
    pagina,
    totaisPorOrigem,
  };
}

export async function resumoRadarPessoal(usuarioId: string): Promise<ResumoRadarPessoal> {
  const sql = conectar();
  const [contagens, alertas] = await Promise.all([
    sql`
      SELECT origem, count(*)::int AS total
        FROM acompanhamento_usuario
       WHERE usuario_app_id = ${usuarioId}
       GROUP BY origem
    ` as unknown as Promise<Array<{ origem: string; total: number }>>,
    sql`
      SELECT count(*)::int AS total
        FROM evento_alerta
       WHERE usuario_app_id = ${usuarioId} AND lido = FALSE
    ` as unknown as Promise<Array<{ total: number }>>,
  ]);
  const porOrigem: Record<OrigemAcompanhamento, number | null> = origensVazias();
  for (const contagem of contagens) {
    if (origemValida(contagem.origem)) porOrigem[contagem.origem] = contagem.total;
  }
  const destaque = (await sql`
    SELECT alerta.id::text AS alerta_id, alerta.origem, alerta.tipo,
           alerta.entidade_id::text, alerta.entidade_externa,
           alerta.entidade_nome AS nome, alerta.valor_anterior::text,
           alerta.valor_atual::text, alerta.unidade, alerta.direcao,
           alerta.criado_em,
           CASE
             WHEN alerta.origem = 'livelo' THEN parceiro.link
             WHEN alerta.origem = 'inter_cashback' THEN loja.slug
             WHEN alerta.origem = 'inter_produto' THEN produto.caminho
             WHEN alerta.origem = 'pichau' THEN pichau.url_produto
           END AS url_externa
      FROM evento_alerta alerta
      LEFT JOIN parceiro_livelo parceiro
        ON alerta.origem = 'livelo' AND parceiro.id = alerta.entidade_id
      LEFT JOIN loja_inter loja
        ON alerta.origem = 'inter_cashback' AND loja.id = alerta.entidade_id
      LEFT JOIN produto_direto_inter produto
        ON alerta.origem = 'inter_produto' AND produto.id = alerta.entidade_id
      LEFT JOIN pichau_produto pichau
        ON alerta.origem = 'pichau' AND pichau.id = alerta.entidade_id
     WHERE alerta.usuario_app_id = ${usuarioId} AND alerta.lido = FALSE
     ORDER BY alerta.criado_em DESC, alerta.id DESC
     LIMIT 1
  `) as Array<Omit<DestaqueRadarPessoal, "url_externa"> & { url_externa: string | null }>;
  const item = destaque[0];
  return {
    estado: "atualizado",
    total_acompanhamentos: Object.values(porOrigem).reduce<number>((soma, valor) => soma + (valor ?? 0), 0),
    por_origem: porOrigem,
    alertas_nao_lidos: alertas[0]?.total ?? 0,
    destaque: item
      ? { ...item, origem: item.origem as OrigemAcompanhamento, tipo: item.tipo as TipoAlerta, url_externa: urlExterna(item.origem as OrigemAcompanhamento, item.url_externa) }
      : null,
  };
}

export async function buscarAlertas(
  usuarioId: string,
  opcoes: { pagina: number; porPagina: number; tipo: TipoAlerta | null; origem: OrigemAlerta | null; somenteNaoLidos: boolean; coleta: string | null },
): Promise<{ itens: AlertaApp[]; total: number; naoLidos: number; pagina: number }> {
  const sql = conectar();
  const limite = Math.min(50, Math.max(1, Math.floor(opcoes.porPagina)));
  const solicitada = Math.max(1, Math.floor(opcoes.pagina));
  const totalLinhas = (await sql`
    SELECT count(*)::int AS total,
           count(*) FILTER (WHERE lido = FALSE)::int AS nao_lidos
      FROM evento_alerta
     WHERE usuario_app_id = ${usuarioId}
       AND criado_em >= now() - interval '90 days'
       AND (${opcoes.tipo === null} OR tipo = ${opcoes.tipo})
       AND (${opcoes.origem === null} OR origem = ${opcoes.origem})
       AND (${!opcoes.somenteNaoLidos} OR lido = FALSE)
       AND (${opcoes.coleta === null} OR coleta_id = ${opcoes.coleta})
  `) as Array<{ total: number; nao_lidos: number }>;
  const total = totalLinhas[0]?.total ?? 0;
  const naoLidos = totalLinhas[0]?.nao_lidos ?? 0;
  const totalPaginas = Math.max(1, Math.ceil(total / limite));
  const pagina = Math.min(solicitada, totalPaginas);
  const deslocamento = (pagina - 1) * limite;
  const itens = (await sql`
    SELECT id, origem, tipo, entidade_id, entidade_externa, entidade_nome,
           coleta_id, valor_anterior::text, valor_atual::text, unidade,
           direcao, lido, criado_em
      FROM evento_alerta
     WHERE usuario_app_id = ${usuarioId}
       AND criado_em >= now() - interval '90 days'
       AND (${opcoes.tipo === null} OR tipo = ${opcoes.tipo})
       AND (${opcoes.origem === null} OR origem = ${opcoes.origem})
       AND (${!opcoes.somenteNaoLidos} OR lido = FALSE)
       AND (${opcoes.coleta === null} OR coleta_id = ${opcoes.coleta})
     ORDER BY criado_em DESC, id DESC
     LIMIT ${limite} OFFSET ${deslocamento}
  `) as AlertaApp[];
  return { itens, total, naoLidos, pagina };
}

export async function marcarAlerta(usuarioId: string, alertaId: string, lido: boolean): Promise<boolean> {
  const sql = conectar();
  const linhas = await sql`
    UPDATE evento_alerta SET lido = ${lido}
     WHERE id = ${alertaId} AND usuario_app_id = ${usuarioId}
     RETURNING id
  `;
  return linhas.length === 1;
}

export async function marcarAlertas(usuarioId: string, ids: string[], lido: boolean): Promise<number> {
  if (ids.length === 0) return 0;
  const sql = conectar();
  const linhas = await sql`
    UPDATE evento_alerta SET lido = ${lido}
     WHERE usuario_app_id = ${usuarioId} AND id = ANY(${ids}::bigint[])
     RETURNING id
  `;
  return linhas.length;
}

/** Resolve somente a entidade vinculada a um alerta pertencente à conta. */
export async function buscarItemAlerta(
  usuarioId: string,
  alertaId: string,
): Promise<ItemAlertaApp | null> {
  const sql = conectar();
  const alertas = (await sql`
    SELECT origem, entidade_id::text AS entidade_id
      FROM evento_alerta
     WHERE id = ${alertaId}::bigint
       AND usuario_app_id = ${usuarioId}::bigint
     LIMIT 1
  `) as Array<{ origem: OrigemAlerta; entidade_id: string }>;
  const alerta = alertas[0];
  if (!alerta) return null;

  if (alerta.origem === "livelo") {
    const itens = (await sql`
      SELECT parceiro.id_externo, parceiro.nome, parceiro.categorias,
             parceiro.pontos_atuais, parceiro.pontos_anteriores,
             parceiro.pontos_base, parceiro.pontos_clube, parceiro.moeda,
             parceiro.prefixo_ate, parceiro.em_promocao, parceiro.campanha,
             parceiro.descricao_campanha, parceiro.inicio_promocao,
             parceiro.fim_promocao, parceiro.link,
             EXISTS (
               SELECT 1 FROM acompanhamento_usuario acompanhamento
                WHERE acompanhamento.usuario_app_id = ${usuarioId}::bigint
                  AND acompanhamento.origem = 'livelo'
                  AND acompanhamento.entidade_id = parceiro.id
             ) AS acompanhada,
             COALESCE(loja.alerta_ativo, FALSE) AS alerta_ativo,
             COALESCE(pontuacao.alertou, FALSE) AS alerta,
             execucao.momento AS atualizado_em,
             execucao.parceiros_lidos
        FROM parceiro_livelo parceiro
        JOIN execucao ON execucao.id = parceiro.atualizado_execucao_id
        LEFT JOIN loja ON loja.parceiro_livelo_id = parceiro.id
        LEFT JOIN pontuacao
          ON pontuacao.execucao_id = parceiro.atualizado_execucao_id
         AND pontuacao.loja_id = loja.id
       WHERE parceiro.id = ${alerta.entidade_id}::bigint
         AND parceiro.ativo = TRUE
       LIMIT 1
    `) as ParceiroLiveloPersistido[];
    const parceiro = itens[0];
    return parceiro
      ? {
          origem: alerta.origem,
          item: { ...apresentarParceiroLivelo(parceiro) },
        }
      : null;
  }

  if (alerta.origem === "inter_cashback") {
    const itens = (await sql`
      WITH execucao_atual AS (
        SELECT id
          FROM execucao_inter
         WHERE estado = 'sucesso'
         ORDER BY concluida_em DESC
         LIMIT 1
      )
      SELECT loja.id, loja.id_externo, loja.slug,
             COALESCE(cashback.nome, loja.nome) AS nome,
             COALESCE(cashback.cashback_principal_texto, loja.cashback_principal_texto)
               AS cashback_principal_texto,
             COALESCE(cashback.cashback_principal_valor, loja.cashback_principal_valor)
               AS cashback_principal_valor,
             COALESCE(cashback.cashback_secundario_texto, loja.cashback_secundario_texto)
               AS cashback_secundario_texto,
             COALESCE(cashback.cashback_secundario_valor, loja.cashback_secundario_valor)
               AS cashback_secundario_valor,
             COALESCE(cashback.etiqueta, loja.etiqueta) AS etiqueta,
             COALESCE(cashback.descricao_principal, loja.descricao_principal)
               AS descricao_principal,
             COALESCE(cashback.descricao_secundaria, loja.descricao_secundaria)
               AS descricao_secundaria,
             COALESCE(categoria.categoria, 'outros') AS categoria,
             COALESCE(cashback.encontrada, TRUE) AS encontrada,
             EXISTS (
               SELECT 1 FROM acompanhamento_usuario acompanhamento
                WHERE acompanhamento.usuario_app_id = ${usuarioId}::bigint
                  AND acompanhamento.origem = 'inter_cashback'
                  AND acompanhamento.entidade_id = loja.id
             ) AS favorita
        FROM loja_inter loja
        CROSS JOIN execucao_atual
        LEFT JOIN mapeamento_categoria_cashback_inter categoria
          ON categoria.loja_inter_id = loja.id
        LEFT JOIN cashback_inter cashback
          ON cashback.loja_inter_id = loja.id
         AND cashback.execucao_inter_id = execucao_atual.id
       WHERE loja.id = ${alerta.entidade_id}::bigint
         AND loja.ativa = TRUE
       LIMIT 1
    `) as Array<Record<string, unknown> & { slug: string }>;
    const loja = itens[0];
    if (!loja) return null;
    return {
      origem: alerta.origem,
      item: { ...loja, link: linkShoppingInterDaLoja(loja.slug) },
    };
  }

  if (alerta.origem === "inter_produto") {
    const itens = (await sql`
      SELECT produto.id_externo, produto.nome, produto.marca,
             COALESCE(NULLIF(btrim(produto.categoria), ''), 'Sem categoria') AS categoria,
             produto.caminho,
             medicao.preco_lista_texto AS preco_cheio_texto,
             medicao.preco_lista AS preco_cheio_valor,
             medicao.preco_atual_texto,
             medicao.preco_atual AS preco_atual_valor,
             medicao.desconto_texto, medicao.desconto_percentual_texto,
             medicao.cashback_texto, medicao.cashback_percentual_texto,
             medicao.preco_liquido_texto, medicao.parcelamento,
             medicao.estoque, medicao.etiquetas,
             medicao.momento AS atualizada_em,
             loja.slug AS loja_slug, loja.nome AS loja_nome,
             EXISTS (
               SELECT 1 FROM acompanhamento_usuario acompanhamento
                WHERE acompanhamento.usuario_app_id = ${usuarioId}::bigint
                  AND acompanhamento.origem = 'inter_produto'
                  AND acompanhamento.entidade_id = produto.id
             ) AS acompanhado
        FROM produto_direto_inter produto
        JOIN loja_direta_inter loja
          ON loja.id = produto.loja_direta_inter_id
        JOIN LATERAL (
          SELECT medicao.*
            FROM medicao_produto_direto_inter medicao
            JOIN execucao_loja_produtos_inter execucao
              ON execucao.id = medicao.execucao_loja_produtos_inter_id
             AND execucao.estado = 'sucesso'
           WHERE medicao.produto_direto_inter_id = produto.id
           ORDER BY medicao.momento DESC
           LIMIT 1
        ) medicao ON TRUE
       WHERE produto.id = ${alerta.entidade_id}::bigint
       LIMIT 1
    `) as Array<Record<string, unknown>>;
    const item = itens[0];
    return item ? { origem: alerta.origem, item } : null;
  }

  if (alerta.origem !== "pichau") return null;

  const itens = (await sql`
    SELECT produto.id_externo, produto.sku, produto.nome, produto.marca,
           produto.categoria_externa, produto.url_produto,
           produto.presente_no_catalogo, produto.disponibilidade,
           EXISTS (
             SELECT 1 FROM acompanhamento_usuario acompanhamento
              WHERE acompanhamento.usuario_app_id = ${usuarioId}::bigint
                AND acompanhamento.origem = 'pichau'
                AND acompanhamento.entidade_id = produto.id
           ) AS acompanhada,
           medicao.preco_original_texto, medicao.preco_pix_texto,
           medicao.desconto_pix_texto, medicao.preco_cartao_texto,
           medicao.parcelamento, medicao.sem_juros, medicao.etiquetas,
           medicao.momento AS atualizado_em
      FROM pichau_produto produto
      LEFT JOIN LATERAL (
        SELECT medicao.*
          FROM pichau_medicao medicao
          JOIN pichau_execucao execucao
            ON execucao.id = medicao.execucao_id
           AND execucao.estado = 'sucesso'
         WHERE medicao.produto_id = produto.id
         ORDER BY medicao.momento DESC, medicao.id DESC
         LIMIT 1
      ) medicao ON TRUE
     WHERE produto.id = ${alerta.entidade_id}::bigint
     LIMIT 1
  `) as Array<Record<string, unknown>>;
  const produto = itens[0];
  return produto
    ? { origem: alerta.origem, item: { ...produto, origem: "Pichau" } }
    : null;
}

export async function lerPreferenciasAlertas(usuarioId: string): Promise<PreferenciasAlertas> {
  const sql = conectar();
  const linhas = (await sql`
    INSERT INTO preferencia_alerta (usuario_app_id)
    VALUES (${usuarioId})
    ON CONFLICT (usuario_app_id) DO UPDATE SET usuario_app_id = EXCLUDED.usuario_app_id
    RETURNING push_global, preco, cashback, pontuacao
  `) as PreferenciasAlertas[];
  return linhas[0] ?? { push_global: true, preco: true, cashback: true, pontuacao: true };
}

export async function salvarPreferenciasAlertas(usuarioId: string, preferencias: PreferenciasAlertas): Promise<PreferenciasAlertas> {
  const sql = conectar();
  const linhas = (await sql`
    INSERT INTO preferencia_alerta (usuario_app_id, push_global, preco, cashback, pontuacao, atualizado_em)
    VALUES (${usuarioId}, ${preferencias.push_global}, ${preferencias.preco}, ${preferencias.cashback}, ${preferencias.pontuacao}, now())
    ON CONFLICT (usuario_app_id) DO UPDATE SET
      push_global = EXCLUDED.push_global, preco = EXCLUDED.preco,
      cashback = EXCLUDED.cashback, pontuacao = EXCLUDED.pontuacao,
      atualizado_em = now()
    RETURNING push_global, preco, cashback, pontuacao
  `) as PreferenciasAlertas[];
  return linhas[0];
}

export async function registrarDispositivo(usuarioId: string, valor: { token: string; plataforma: string; versao_app: string }): Promise<void> {
  const sql = conectar();
  await sql`
    INSERT INTO token_fcm_app (usuario_app_id, token, plataforma, versao_app, ativo, atualizado_em)
    VALUES (${usuarioId}, ${valor.token}, ${valor.plataforma}, ${valor.versao_app}, TRUE, now())
    ON CONFLICT (usuario_app_id, token) DO UPDATE SET
      plataforma = EXCLUDED.plataforma, versao_app = EXCLUDED.versao_app,
      ativo = TRUE, atualizado_em = now()
  `;
}

export async function removerDispositivo(usuarioId: string, token: string): Promise<void> {
  const sql = conectar();
  await sql`UPDATE token_fcm_app SET ativo = FALSE, atualizado_em = now() WHERE usuario_app_id = ${usuarioId} AND token = ${token}`;
}

export async function alterarAcompanhamentoPessoal(
  usuarioId: string,
  origem: "livelo" | "inter_cashback" | "inter_produto" | "pichau",
  entidadeId: string,
  ativo: boolean,
): Promise<boolean> {
  const sql = conectar();
  if (ativo) {
    const linhas = await sql`
      INSERT INTO acompanhamento_usuario (usuario_app_id, origem, entidade_id)
      VALUES (${usuarioId}, ${origem}, ${entidadeId})
      ON CONFLICT (usuario_app_id, origem, entidade_id) DO UPDATE SET atualizado_em = now()
      RETURNING id
    `;
    return linhas.length === 1;
  }
  const linhas = await sql`
    DELETE FROM acompanhamento_usuario
     WHERE usuario_app_id = ${usuarioId} AND origem = ${origem} AND entidade_id = ${entidadeId}
     RETURNING id
  `;
  return linhas.length === 1;
}

export async function entidadeAcompanhavelExiste(
  origem: "livelo" | "inter_cashback" | "inter_produto" | "pichau",
  entidadeId: string,
): Promise<boolean> {
  const sql = conectar();
  const linhas = await sql`
    SELECT CASE
      WHEN ${origem} = 'livelo' THEN EXISTS (SELECT 1 FROM parceiro_livelo WHERE id = ${entidadeId} AND ativo = TRUE)
      WHEN ${origem} = 'inter_cashback' THEN EXISTS (SELECT 1 FROM loja_inter WHERE id = ${entidadeId} AND ativa = TRUE)
      WHEN ${origem} = 'inter_produto' THEN EXISTS (SELECT 1 FROM produto_direto_inter WHERE id = ${entidadeId})
      WHEN ${origem} = 'pichau' THEN EXISTS (SELECT 1 FROM pichau_produto WHERE id = ${entidadeId})
      ELSE FALSE
    END AS existe
  ` as Array<{ existe: boolean }>;
  return linhas[0]?.existe === true;
}

/** Resolve chaves públicas de Livelo/Inter/Pichau para o ID interno da camada pessoal. */
export async function entidadeAcompanhavelIdPorChave(
  origem: "livelo" | "inter_cashback" | "pichau",
  chave: string,
): Promise<string | null> {
  const sql = conectar();
  const linhas = origem === "livelo"
    ? await sql`
        SELECT id::text
          FROM parceiro_livelo
         WHERE id_externo = ${chave} AND ativo = TRUE
         LIMIT 1
      `
    : origem === "inter_cashback"
    ? await sql`
        SELECT id::text
          FROM loja_inter
         WHERE id::text = ${chave} AND ativa = TRUE
         LIMIT 1
      `
    : await sql`
        SELECT id::text
          FROM pichau_produto
         WHERE id_externo = ${chave}
         LIMIT 1
      `;
  return (linhas as Array<{ id: string }>)[0]?.id ?? null;
}

export async function registrarRelatoProblema(usuarioId: string, valor: { categoria: string; mensagem: string; tela: string; versao_app: string; sistema: string | null }, requisicaoId: string): Promise<string> {
  const sql = conectar();
  const linhas = (await sql`
    INSERT INTO relato_problema_app (usuario_app_id, categoria, mensagem, tela, versao_app, sistema, requisicao_id)
    VALUES (${usuarioId}, ${valor.categoria}, ${valor.mensagem}, ${valor.tela}, ${valor.versao_app}, ${valor.sistema}, ${requisicaoId})
    RETURNING id
  `) as Array<{ id: string }>;
  return String(linhas[0].id);
}

export async function buscarRelatosProblema(
  usuarioId: string,
  opcoes: { pagina: number; porPagina: number },
): Promise<{ itens: RelatoProblemaApp[]; total: number; pagina: number }> {
  const sql = conectar();
  const limite = Math.min(50, Math.max(1, Math.floor(opcoes.porPagina)));
  const solicitada = Math.max(1, Math.floor(opcoes.pagina));
  const totais = (await sql`
    SELECT count(*)::int AS total
      FROM relato_problema_app
     WHERE usuario_app_id = ${usuarioId}
       AND criado_em >= now() - interval '180 days'
  `) as Array<{ total: number }>;
  const total = totais[0]?.total ?? 0;
  const totalPaginas = Math.max(1, Math.ceil(total / limite));
  const pagina = Math.min(solicitada, totalPaginas);
  const deslocamento = (pagina - 1) * limite;
  const itens = (await sql`
    SELECT id::text, categoria, mensagem, criado_em
      FROM relato_problema_app
     WHERE usuario_app_id = ${usuarioId}
       AND criado_em >= now() - interval '180 days'
     ORDER BY criado_em DESC, id DESC
     LIMIT ${limite} OFFSET ${deslocamento}
  `) as RelatoProblemaApp[];
  return { itens, total, pagina };
}

type OutboxPendente = { id: string; usuario_app_id: string; origem: string; coleta_id: string };
type EventoOutbox = EventoPush & { id: string };
type TokenPush = { id: string; token: string };
type ResultadoOutbox = { processadas: number; enviadas: number; recuperadas: number };
const MAXIMO_ENTREGAS_POR_EXECUCAO = 25;

function codigoErroMensageria(erro: unknown): string {
  if (!erro || typeof erro !== "object") return "";
  const valor = erro as { code?: unknown; errorInfo?: { code?: unknown } };
  if (typeof valor.code === "string") return valor.code;
  return typeof valor.errorInfo?.code === "string" ? valor.errorInfo.code : "";
}

/** Processa uma pequena janela da outbox. Pode ser chamado por um cron protegido. */
export async function processarOutboxAlertas(limite = 20): Promise<ResultadoOutbox> {
  const sql = conectar();
  await sql`SELECT expurgar_alertas_suporte()`;
  await sql`
    UPDATE notificacao_entrega_alerta
       SET estado = 'falha', proxima_tentativa_em = now(),
           ultimo_erro = 'processamento interrompido', atualizado_em = now()
     WHERE estado = 'enviando'
       AND atualizado_em < now() - interval '15 minutes'
  `;
  const presas = (await sql`
    UPDATE notificacao_outbox_alerta
       SET estado = 'falha', proxima_tentativa_em = now(),
           ultimo_erro = 'processamento interrompido', atualizado_em = now()
     WHERE estado = 'enviando'
       AND atualizado_em < now() - interval '15 minutes'
     RETURNING id
  `) as Array<{ id: string }>;
  let processadas = 0;
  let enviadas = 0;
  let entregasTentadas = 0;
  for (let indice = 0; indice < Math.min(50, Math.max(1, limite)); indice += 1) {
    if (entregasTentadas >= MAXIMO_ENTREGAS_POR_EXECUCAO) break;
    const linhas = (await sql`
      UPDATE notificacao_outbox_alerta
         SET estado = 'enviando', tentativas = tentativas + 1, atualizado_em = now()
       WHERE id = (
          SELECT id FROM notificacao_outbox_alerta
          WHERE estado IN ('pendente', 'falha') AND proxima_tentativa_em <= now()
          ORDER BY atualizado_em, id FOR UPDATE SKIP LOCKED LIMIT 1
       )
      RETURNING id, usuario_app_id, origem, coleta_id
    `) as OutboxPendente[];
    const outbox = linhas[0];
    if (!outbox) break;
    processadas += 1;
    try {
      const [tokens, preferencias, eventos] = await Promise.all([
        sql`SELECT id::text, token FROM token_fcm_app WHERE usuario_app_id = ${outbox.usuario_app_id} AND ativo = TRUE`,
        sql`SELECT push_global, preco, cashback, pontuacao FROM preferencia_alerta WHERE usuario_app_id = ${outbox.usuario_app_id}`,
        sql`
          SELECT alerta.id::text, alerta.origem, alerta.tipo,
                 alerta.entidade_nome, alerta.valor_atual::text, alerta.unidade,
                 CASE WHEN alerta.origem = 'inter_produto' THEN loja.nome END AS loja_nome
            FROM evento_alerta alerta
            LEFT JOIN produto_direto_inter produto
              ON alerta.origem = 'inter_produto' AND produto.id = alerta.entidade_id
            LEFT JOIN loja_direta_inter loja
              ON loja.id = produto.loja_direta_inter_id
           WHERE alerta.usuario_app_id = ${outbox.usuario_app_id}
             AND alerta.origem = ${outbox.origem}
             AND alerta.coleta_id = ${outbox.coleta_id}
             AND alerta.notificar_push = TRUE
           ORDER BY alerta.id
        `,
      ]) as [TokenPush[], PreferenciasAlertas[], EventoOutbox[]];
      const preferencia = (preferencias as Array<{ push_global: boolean; preco: boolean; cashback: boolean; pontuacao: boolean }>)[0];
      if (preferencia?.push_global === false) {
        await sql`
          UPDATE notificacao_entrega_alerta entrega
             SET estado = 'cancelada', atualizado_em = now()
            FROM evento_alerta alerta
           WHERE entrega.evento_alerta_id = alerta.id
             AND alerta.usuario_app_id = ${outbox.usuario_app_id}
             AND alerta.origem = ${outbox.origem}
             AND alerta.coleta_id = ${outbox.coleta_id}
             AND entrega.estado IN ('pendente', 'falha')
        `;
        await sql`UPDATE notificacao_outbox_alerta SET estado = 'enviada', atualizado_em = now() WHERE id = ${outbox.id}`;
        enviadas += 1;
        continue;
      }
      const habilitado = (tipo: string) => preferencia?.[tipo as "preco" | "cashback" | "pontuacao"] ?? true;
      const eventosHabilitados = (eventos as EventoOutbox[]).filter((evento) => habilitado(evento.tipo));
      const tiposHabilitados = Array.from(new Set(eventosHabilitados.map((evento) => evento.tipo)));
      if (tiposHabilitados.length === 0) {
        await sql`
          UPDATE notificacao_entrega_alerta entrega
             SET estado = 'cancelada', atualizado_em = now()
            FROM evento_alerta alerta
           WHERE entrega.evento_alerta_id = alerta.id
             AND alerta.usuario_app_id = ${outbox.usuario_app_id}
             AND alerta.origem = ${outbox.origem}
             AND alerta.coleta_id = ${outbox.coleta_id}
             AND entrega.estado IN ('pendente', 'falha')
        `;
        await sql`UPDATE notificacao_outbox_alerta SET estado = 'enviada', atualizado_em = now() WHERE id = ${outbox.id}`;
        enviadas += 1;
        continue;
      }
      if ((tokens as TokenPush[]).length === 0) {
        await sql`
          UPDATE notificacao_entrega_alerta entrega
             SET estado = 'cancelada', atualizado_em = now()
            FROM evento_alerta alerta
           WHERE entrega.evento_alerta_id = alerta.id
             AND alerta.usuario_app_id = ${outbox.usuario_app_id}
             AND alerta.origem = ${outbox.origem}
             AND alerta.coleta_id = ${outbox.coleta_id}
             AND entrega.estado IN ('pendente', 'falha')
        `;
        await sql`UPDATE notificacao_outbox_alerta SET estado = 'enviada', atualizado_em = now() WHERE id = ${outbox.id}`;
        enviadas += 1;
        continue;
      }

      await sql`
        UPDATE notificacao_entrega_alerta entrega
           SET estado = 'cancelada', atualizado_em = now()
          FROM evento_alerta alerta
           WHERE entrega.evento_alerta_id = alerta.id
             AND alerta.usuario_app_id = ${outbox.usuario_app_id}
             AND alerta.origem = ${outbox.origem}
             AND alerta.coleta_id = ${outbox.coleta_id}
             AND alerta.tipo <> ALL(${tiposHabilitados}::text[])
             AND entrega.estado IN ('pendente', 'falha')
      `;

      await sql`
        UPDATE notificacao_entrega_alerta entrega
           SET estado = 'cancelada', atualizado_em = now()
          FROM token_fcm_app token, evento_alerta alerta
         WHERE entrega.evento_alerta_id = alerta.id
           AND entrega.token_fcm_app_id = token.id
           AND alerta.usuario_app_id = ${outbox.usuario_app_id}
           AND alerta.origem = ${outbox.origem}
           AND alerta.coleta_id = ${outbox.coleta_id}
           AND token.ativo = FALSE
           AND entrega.estado IN ('pendente', 'falha')
      `;

      await sql`
        INSERT INTO notificacao_entrega_alerta (evento_alerta_id, token_fcm_app_id)
        SELECT alerta.id, token.id
          FROM evento_alerta alerta
          JOIN token_fcm_app token ON token.usuario_app_id = alerta.usuario_app_id
         WHERE alerta.usuario_app_id = ${outbox.usuario_app_id}
           AND alerta.origem = ${outbox.origem}
           AND alerta.coleta_id = ${outbox.coleta_id}
           AND alerta.notificar_push = TRUE
           AND alerta.tipo = ANY(${tiposHabilitados}::text[])
           AND token.ativo = TRUE
        ON CONFLICT (evento_alerta_id, token_fcm_app_id) DO NOTHING
      `;

      const eventosPorId = new Map((eventos as EventoOutbox[]).map((evento) => [evento.id, evento]));
      const tokensPorId = new Map((tokens as TokenPush[]).map((token) => [token.id, token]));
      for (let indiceEntrega = 0; indiceEntrega < MAXIMO_ENTREGAS_POR_EXECUCAO; indiceEntrega += 1) {
        if (entregasTentadas >= MAXIMO_ENTREGAS_POR_EXECUCAO) break;
        const reclamadas = (await sql`
          WITH candidata AS (
            SELECT entrega.evento_alerta_id, entrega.token_fcm_app_id
              FROM notificacao_entrega_alerta entrega
              JOIN evento_alerta alerta ON alerta.id = entrega.evento_alerta_id
              JOIN token_fcm_app token ON token.id = entrega.token_fcm_app_id
             WHERE alerta.usuario_app_id = ${outbox.usuario_app_id}
               AND alerta.origem = ${outbox.origem}
               AND alerta.coleta_id = ${outbox.coleta_id}
               AND alerta.notificar_push = TRUE
               AND alerta.tipo = ANY(${tiposHabilitados}::text[])
               AND token.ativo = TRUE
               AND entrega.estado IN ('pendente', 'falha')
               AND entrega.proxima_tentativa_em <= now()
             ORDER BY entrega.tentativas, entrega.proxima_tentativa_em,
                      entrega.evento_alerta_id, entrega.token_fcm_app_id
             FOR UPDATE OF entrega SKIP LOCKED
             LIMIT 1
          )
          UPDATE notificacao_entrega_alerta entrega
             SET estado = 'enviando', tentativas = tentativas + 1,
                 atualizado_em = now()
            FROM candidata
           WHERE entrega.evento_alerta_id = candidata.evento_alerta_id
             AND entrega.token_fcm_app_id = candidata.token_fcm_app_id
          RETURNING entrega.evento_alerta_id::text, entrega.token_fcm_app_id::text
        `) as Array<{ evento_alerta_id: string; token_fcm_app_id: string }>;
        const entrega = reclamadas[0];
        if (!entrega) break;
        entregasTentadas += 1;

        const evento = eventosPorId.get(entrega.evento_alerta_id);
        const token = tokensPorId.get(entrega.token_fcm_app_id);
        if (!evento || !token) {
          await sql`
            UPDATE notificacao_entrega_alerta
               SET estado = 'cancelada', atualizado_em = now()
             WHERE evento_alerta_id = ${entrega.evento_alerta_id}
               AND token_fcm_app_id = ${entrega.token_fcm_app_id}
          `;
          continue;
        }

        try {
          await mensageriaFirebase().send({
            notification: {
              title: "Novas alterações no Radar",
              body: formatarCorpoPush(evento),
            },
            data: { rota: "alertas", coleta: outbox.coleta_id, origem: outbox.origem },
            token: token.token,
          });
          await sql`
            UPDATE notificacao_entrega_alerta
               SET estado = 'enviada', ultimo_erro = NULL, atualizado_em = now()
             WHERE evento_alerta_id = ${evento.id}
               AND token_fcm_app_id = ${token.id}
          `;
        } catch (erro) {
          const codigo = codigoErroMensageria(erro);
          if (codigo === "messaging/registration-token-not-registered" || codigo === "messaging/invalid-registration-token") {
            await sql`UPDATE token_fcm_app SET ativo = FALSE, atualizado_em = now() WHERE id = ${token.id}`;
            await sql`
              UPDATE notificacao_entrega_alerta
                 SET estado = 'invalida', ultimo_erro = 'token FCM inválido', atualizado_em = now()
               WHERE token_fcm_app_id = ${token.id}
                 AND estado IN ('pendente', 'enviando', 'falha')
                 AND evento_alerta_id IN (
                   SELECT id FROM evento_alerta
                    WHERE usuario_app_id = ${outbox.usuario_app_id}
                      AND origem = ${outbox.origem}
                      AND coleta_id = ${outbox.coleta_id}
                 )
            `;
          } else {
            await sql`
              UPDATE notificacao_entrega_alerta
                 SET estado = 'falha',
                     proxima_tentativa_em = now() + make_interval(secs => LEAST(3600, 30 * tentativas)),
                     ultimo_erro = 'falha de envio', atualizado_em = now()
               WHERE evento_alerta_id = ${evento.id}
                 AND token_fcm_app_id = ${token.id}
            `;
          }
        }
      }

      const pendencias = (await sql`
        SELECT count(*)::int AS total, min(entrega.proxima_tentativa_em) AS proxima_tentativa_em
          FROM notificacao_entrega_alerta entrega
          JOIN evento_alerta alerta ON alerta.id = entrega.evento_alerta_id
         WHERE alerta.usuario_app_id = ${outbox.usuario_app_id}
           AND alerta.origem = ${outbox.origem}
           AND alerta.coleta_id = ${outbox.coleta_id}
           AND entrega.estado IN ('pendente', 'enviando', 'falha')
      `) as Array<{ total: number; proxima_tentativa_em: string | null }>;
      if ((pendencias[0]?.total ?? 0) > 0) {
        await sql`
          UPDATE notificacao_outbox_alerta
             SET estado = 'falha',
                 proxima_tentativa_em = GREATEST(COALESCE(${pendencias[0].proxima_tentativa_em}, now()), now() + interval '30 seconds'),
                 ultimo_erro = 'falha de envio', atualizado_em = now()
           WHERE id = ${outbox.id}
        `;
        continue;
      }
      await sql`UPDATE notificacao_outbox_alerta SET estado = 'enviada', ultimo_erro = NULL, atualizado_em = now() WHERE id = ${outbox.id}`;
      enviadas += 1;
    } catch {
      await sql`UPDATE notificacao_outbox_alerta SET estado = 'falha', proxima_tentativa_em = now() + make_interval(secs => LEAST(3600, 30 * tentativas)), ultimo_erro = 'falha de envio', atualizado_em = now() WHERE id = ${outbox.id}`;
    }
  }
  return { processadas, enviadas, recuperadas: presas.length };
}
