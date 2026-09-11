import { neon } from "@neondatabase/serverless";

import type { PreferenciasAlertasEntrada, TipoAlerta } from "./alertas-api";
import { mensageriaFirebase } from "./firebase-admin";

function conectar() {
  const url = process.env.DATABASE_URL;
  if (!url) throw new Error("DATABASE_URL nao configurada no ambiente do site.");
  return neon(url);
}

export type AlertaApp = {
  id: string;
  origem: "livelo" | "inter_cashback" | "inter_produto";
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
  origem: "livelo" | "inter_cashback" | "inter_produto",
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
  origem: "livelo" | "inter_cashback" | "inter_produto",
  entidadeId: string,
): Promise<boolean> {
  const sql = conectar();
  const linhas = await sql`
    SELECT CASE
      WHEN ${origem} = 'livelo' THEN EXISTS (SELECT 1 FROM parceiro_livelo WHERE id = ${entidadeId} AND ativo = TRUE)
      WHEN ${origem} = 'inter_cashback' THEN EXISTS (SELECT 1 FROM loja_inter WHERE id = ${entidadeId} AND ativa = TRUE)
      WHEN ${origem} = 'inter_produto' THEN EXISTS (SELECT 1 FROM produto_direto_inter WHERE id = ${entidadeId})
      ELSE FALSE
    END AS existe
  ` as Array<{ existe: boolean }>;
  return linhas[0]?.existe === true;
}

/** Resolve chaves públicas de Livelo/Inter para o ID interno da camada pessoal. */
export async function entidadeAcompanhavelIdPorChave(
  origem: "livelo" | "inter_cashback",
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
    : await sql`
        SELECT id::text
          FROM loja_inter
         WHERE id::text = ${chave} AND ativa = TRUE
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

/** Processa uma pequena janela da outbox. Pode ser chamado por um cron protegido. */
export async function processarOutboxAlertas(limite = 20): Promise<{ processadas: number; enviadas: number }> {
  const sql = conectar();
  await sql`SELECT expurgar_alertas_suporte()`;
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
          const codigo = erro && typeof erro === "object" && "errorInfo" in erro ? String((erro as { errorInfo?: { code?: string } }).errorInfo?.code ?? "") : "";
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
  return { processadas, enviadas };
}
