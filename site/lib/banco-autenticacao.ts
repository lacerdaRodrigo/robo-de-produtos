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
    UPDATE usuario_app
       SET firebase_uid = COALESCE(firebase_uid, ${uid}),
           email = CASE WHEN firebase_uid = ${uid} THEN ${email} ELSE email END,
           vinculado_em = COALESCE(vinculado_em, now()),
           ultimo_acesso_em = now(),
           atualizado_em = now()
     WHERE firebase_uid = ${uid}
        OR (firebase_uid IS NULL AND lower(email) = lower(${email}))
     RETURNING id, email, papel, ativo
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
