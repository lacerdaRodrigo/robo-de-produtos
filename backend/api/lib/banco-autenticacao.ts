import { createHmac } from "node:crypto";

import { neon } from "@neondatabase/serverless";

export type PapelUsuarioApp = "admin" | "usuario";

export type UsuarioApp = {
  id: string;
  email: string;
  papel: PapelUsuarioApp;
  ativo: boolean;
};

export type ResultadoLimite = {
  permitido: boolean;
  tentarNovamenteEm: number;
};

export type EventoAuditoria = {
  usuarioId: string | null;
  identidadeHash: string | null;
  origemHash: string;
  requisicaoId: string;
  acao: string;
  resultado: "sucesso" | "negado" | "falha";
  codigo: string;
};

/** Prazo de retenção da auditoria técnica, expurgada pelo cron horário. */
export const RETENCAO_AUDITORIA_DIAS = 30;

function conectar() {
  const url = process.env.DATABASE_URL;
  if (!url) throw new Error("DATABASE_URL nao configurada no ambiente do site.");
  return neon(url);
}

function segredoDoHash(): string {
  const segredo = process.env.SEGREDO_LIMITE_API;
  if (!segredo) throw new Error("SEGREDO_LIMITE_API nao configurado no servidor.");
  return segredo;
}

/** Pseudonimiza IP, UID e chaves de balde antes de qualquer persistencia. */
export function hashTecnico(tipo: string, valor: string): string {
  return createHmac("sha256", segredoDoHash()).update(`${tipo}:${valor}`).digest("hex");
}

/**
 * Liga o primeiro token verificado ao convite por e-mail. Depois do vinculo,
 * o UID manda; uma troca de e-mail verificada no mesmo usuario Firebase nao
 * cria outra identidade no Radar.
 */
export async function autorizarUsuario(
  uid: string,
  email: string,
): Promise<UsuarioApp | null> {
  const sql = conectar();
  const linhas = (await sql`
    WITH encontrado AS (
      SELECT id
        FROM usuario_app
       WHERE firebase_uid = ${uid}
          OR (firebase_uid IS NULL AND lower(email) = lower(${email}))
       ORDER BY id
       LIMIT 1
       FOR UPDATE
    ), atualizado AS (
      UPDATE usuario_app usuario
         SET firebase_uid = COALESCE(usuario.firebase_uid, ${uid}),
             email = CASE WHEN usuario.firebase_uid = ${uid}
               THEN ${email} ELSE usuario.email END,
             vinculado_em = COALESCE(usuario.vinculado_em, now()),
             ultimo_acesso_em = now(),
             atualizado_em = now()
        FROM encontrado
       WHERE usuario.id = encontrado.id
         AND (
           usuario.firebase_uid IS NULL
           OR (usuario.firebase_uid = ${uid} AND usuario.email IS DISTINCT FROM ${email})
           OR usuario.ultimo_acesso_em IS NULL
           OR usuario.ultimo_acesso_em < now() - interval '24 hours'
         )
      RETURNING usuario.id, usuario.email, usuario.papel, usuario.ativo
    )
    SELECT id, email, papel, ativo FROM atualizado
    UNION ALL
    SELECT usuario.id, usuario.email, usuario.papel, usuario.ativo
      FROM usuario_app usuario
      JOIN encontrado ON encontrado.id = usuario.id
     WHERE NOT EXISTS (SELECT 1 FROM atualizado)
    LIMIT 1
  `) as UsuarioApp[];
  return linhas[0] ?? null;
}

/** Incremento atomico por balde, proprio para funcoes serverless. */
export async function consumirLimite(
  chaveHash: string,
  maximo: number,
  janelaSegundos: number,
): Promise<ResultadoLimite> {
  const sql = conectar();
  const linhas = (await sql`
    INSERT INTO limite_requisicao_app (chave_hash, janela_inicio, quantidade)
    VALUES (${chaveHash}, now(), 1)
    ON CONFLICT (chave_hash) DO UPDATE
       SET quantidade = CASE
             WHEN limite_requisicao_app.janela_inicio
                    + make_interval(secs => ${janelaSegundos}) <= now()
               THEN 1
             ELSE limite_requisicao_app.quantidade + 1
           END,
           janela_inicio = CASE
             WHEN limite_requisicao_app.janela_inicio
                    + make_interval(secs => ${janelaSegundos}) <= now()
               THEN now()
             ELSE limite_requisicao_app.janela_inicio
           END,
           atualizado_em = now()
    RETURNING quantidade,
              GREATEST(1, CEIL(EXTRACT(EPOCH FROM (
                janela_inicio + make_interval(secs => ${janelaSegundos}) - now()
              ))))::int AS tentar_novamente_em
  `) as { quantidade: number; tentar_novamente_em: number }[];
  const estado = linhas[0];
  return {
    permitido: Boolean(estado && estado.quantidade <= maximo),
    tentarNovamenteEm: estado?.tentar_novamente_em ?? janelaSegundos,
  };
}

export async function registrarAuditoria(evento: EventoAuditoria): Promise<void> {
  const sql = conectar();
  await sql`
    INSERT INTO auditoria_app (
      usuario_app_id, identidade_hash, origem_hash, requisicao_id,
      acao, resultado, codigo
    ) VALUES (
      ${evento.usuarioId}, ${evento.identidadeHash}, ${evento.origemHash},
      ${evento.requisicaoId}, ${evento.acao}, ${evento.resultado}, ${evento.codigo}
    )
  `;
}

/** Expurgo amortizado: chamado uma vez por hora pelo cron interno protegido. */
export async function expurgarRegistrosTecnicos(): Promise<{
  auditorias: number;
  limites: number;
}> {
  const sql = conectar();
  const linhas = (await sql`
    WITH auditorias_expurgadas AS (
      DELETE FROM auditoria_app
       WHERE momento < now() - make_interval(days => ${RETENCAO_AUDITORIA_DIAS})
       RETURNING 1
    ), limites_expurgados AS (
      DELETE FROM limite_requisicao_app
       WHERE atualizado_em < now() - interval '24 hours'
       RETURNING 1
    )
    SELECT
      (SELECT count(*)::int FROM auditorias_expurgadas) AS auditorias,
      (SELECT count(*)::int FROM limites_expurgados) AS limites
  `) as Array<{ auditorias: number; limites: number }>;
  return linhas[0] ?? { auditorias: 0, limites: 0 };
}
