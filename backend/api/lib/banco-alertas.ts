import { neon } from "@neondatabase/serverless";

import type { PreferenciasAlertasEntrada, TipoAlerta } from "./alertas-api";
import { mensageriaFirebase } from "./firebase-admin";
import { linkShoppingInterDaLoja } from "./formato-inter";

function conectar() {
  const url = process.env.DATABASE_URL;
  if (!url) throw new Error("DATABASE_URL nao configurada no ambiente do site.");
  return neon(url);
}

export type AlertaApp = {
  id: string;
  origem: "livelo" | "inter_cashback" | "inter_produto" | "pichau";
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
  opcoes: { pagina: number; porPagina: number; tipo: TipoAlerta | null; somenteNaoLidos: boolean; coleta: string | null },
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

type OutboxPendente = { id: string; usuario_app_id: string; origem: string; coleta_id: string };
type ResultadoOutbox = { processadas: number; enviadas: number; recuperadas: number };

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
  for (let indice = 0; indice < Math.min(50, Math.max(1, limite)); indice += 1) {
    const linhas = (await sql`
      UPDATE notificacao_outbox_alerta
         SET estado = 'enviando', tentativas = tentativas + 1, atualizado_em = now()
       WHERE id = (
         SELECT id FROM notificacao_outbox_alerta
          WHERE estado IN ('pendente', 'falha') AND proxima_tentativa_em <= now()
          ORDER BY id FOR UPDATE SKIP LOCKED LIMIT 1
       )
      RETURNING id, usuario_app_id, origem, coleta_id
    `) as OutboxPendente[];
    const outbox = linhas[0];
    if (!outbox) break;
    processadas += 1;
    try {
      const [tokens, contagens, preferencias] = await Promise.all([
        sql`SELECT id, token FROM token_fcm_app WHERE usuario_app_id = ${outbox.usuario_app_id} AND ativo = TRUE`,
        sql`SELECT tipo, count(*)::int AS total FROM evento_alerta WHERE usuario_app_id = ${outbox.usuario_app_id} AND origem = ${outbox.origem} AND coleta_id = ${outbox.coleta_id} GROUP BY tipo`,
        sql`SELECT push_global, preco, cashback, pontuacao FROM preferencia_alerta WHERE usuario_app_id = ${outbox.usuario_app_id}`,
      ]);
      const preferencia = (preferencias as Array<{ push_global: boolean; preco: boolean; cashback: boolean; pontuacao: boolean }>)[0];
      if (preferencia?.push_global === false) {
        await sql`UPDATE notificacao_outbox_alerta SET estado = 'enviada', atualizado_em = now() WHERE id = ${outbox.id}`;
        enviadas += 1;
        continue;
      }
      const habilitado = (tipo: string) => preferencia?.[tipo as "preco" | "cashback" | "pontuacao"] ?? true;
      const contagensHabilitadas = (contagens as Array<{ tipo: string; total: number }>).filter((item) => habilitado(item.tipo));
      if (contagensHabilitadas.length === 0) {
        await sql`UPDATE notificacao_outbox_alerta SET estado = 'enviada', atualizado_em = now() WHERE id = ${outbox.id}`;
        enviadas += 1;
        continue;
      }
      if (tokens.length === 0) {
        await sql`UPDATE notificacao_outbox_alerta SET estado = 'enviada', atualizado_em = now() WHERE id = ${outbox.id}`;
        enviadas += 1;
        continue;
      }
      const resumo = contagensHabilitadas.map((item) => `${item.tipo}:${item.total}`).join(", ");
      const mensagem = {
        notification: { title: "Novas alterações no Radar", body: `${resumo || "Há uma nova alteração"}. Toque para abrir a Central.` },
        data: { rota: "alertas", coleta: outbox.coleta_id, origem: outbox.origem },
      };
      const invalidos: string[] = [];
      let falhaEnvio = false;
      for (const token of tokens as Array<{ id: string; token: string }>) {
        try { await mensageriaFirebase().send({ ...mensagem, token: token.token }); }
        catch (erro) {
          const codigo = codigoErroMensageria(erro);
          if (codigo === "messaging/registration-token-not-registered" || codigo === "messaging/invalid-registration-token") invalidos.push(token.token);
          else falhaEnvio = true;
        }
      }
      if (invalidos.length > 0) await sql`UPDATE token_fcm_app SET ativo = FALSE, atualizado_em = now() WHERE usuario_app_id = ${outbox.usuario_app_id} AND token = ANY(${invalidos}::text[])`;
      if (falhaEnvio) {
        await sql`UPDATE notificacao_outbox_alerta SET estado = 'falha', proxima_tentativa_em = now() + make_interval(secs => LEAST(3600, 30 * tentativas)), ultimo_erro = 'falha de envio', atualizado_em = now() WHERE id = ${outbox.id}`;
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
