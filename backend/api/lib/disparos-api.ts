import { neon } from "@neondatabase/serverless";

import {
  dispararRobo,
  dispararRoboInter,
  type ResultadoDoDisparo,
} from "./github";

export const DOMINIOS_DE_DISPARO = ["livelo", "inter", "produtos_inter"] as const;
export type DominioDeDisparo = (typeof DOMINIOS_DE_DISPARO)[number];

export const COOLDOWN_DISPARO_SEGUNDOS = 5 * 60;

type EstadoDaSolicitacao = "reservada" | "aceita" | "falha";

type ReservaNoBanco =
  | { tipo: "reservada"; id: string; esperaSegundos: 0 }
  | { tipo: "existente"; id: string; estado: EstadoDaSolicitacao; esperaSegundos: number }
  | { tipo: "cooldown"; esperaSegundos: number };

export type ResultadoDeDisparoApi =
  | { estado: "aceito"; cooldownSegundos: number }
  | { estado: "em-andamento"; cooldownSegundos: number }
  | { estado: "cooldown"; cooldownSegundos: number }
  | { estado: "falha" };

export type EstadoDeDisparoApi = {
  dominio: DominioDeDisparo;
  cooldownSegundos: number;
  ultimaSolicitacaoEm: string | null;
  ultimoEstado: EstadoDaSolicitacao | null;
};

export type DependenciasDeDisparo = {
  reservar: (
    dominio: DominioDeDisparo,
    chave: string,
    usuarioId: string,
  ) => Promise<ReservaNoBanco>;
  finalizar: (
    id: string,
    estado: "aceita" | "falha",
    codigoFalha?: "sem-token" | "github" | "interno",
  ) => Promise<void>;
  disparar: (dominio: DominioDeDisparo) => Promise<ResultadoDoDisparo>;
};

function conectar() {
  const url = process.env.DATABASE_URL;
  if (!url) throw new Error("DATABASE_URL nao configurada no ambiente do site.");
  return neon(url);
}

export function dominioDeDisparoValido(valor: unknown): valor is DominioDeDisparo {
  return typeof valor === "string" && DOMINIOS_DE_DISPARO.includes(valor as DominioDeDisparo);
}

/** Cabeçalho obrigatório para repetir somente a mesma intenção do cliente. */
export function chaveDeIdempotenciaValida(valor: string | null): valor is string {
  return Boolean(valor && /^[A-Za-z0-9_-]{16,100}$/.test(valor));
}

async function reservarNoBanco(
  dominio: DominioDeDisparo,
  chave: string,
  usuarioId: string,
): Promise<ReservaNoBanco> {
  const sql = conectar();
  const existentes = (await sql`
    SELECT id, estado,
           GREATEST(0, CEIL(EXTRACT(EPOCH FROM (
             criada_em + make_interval(secs => ${COOLDOWN_DISPARO_SEGUNDOS}) - now()
           ))))::int AS espera_segundos
      FROM solicitacao_disparo_app
     WHERE dominio = ${dominio} AND chave_idempotencia = ${chave}
     LIMIT 1
  `) as Array<{ id: string; estado: EstadoDaSolicitacao; espera_segundos: number }>;
  const existente = existentes[0];
  if (existente) {
    return {
      tipo: "existente",
      id: existente.id,
      estado: existente.estado,
      esperaSegundos: existente.espera_segundos,
    };
  }

  // Libera somente reservas cujo cooldown acabou. A linha ativa restante é
  // protegida por índice único parcial, que é seguro entre instâncias Vercel.
  await sql`
    UPDATE solicitacao_disparo_app
       SET ativa = FALSE
     WHERE dominio = ${dominio}
       AND ativa = TRUE
       AND criada_em + make_interval(secs => ${COOLDOWN_DISPARO_SEGUNDOS}) <= now()
  `;
  const inseridas = (await sql`
    INSERT INTO solicitacao_disparo_app (
      dominio, chave_idempotencia, usuario_app_id, estado
    ) VALUES (${dominio}, ${chave}, ${usuarioId}, 'reservada')
    ON CONFLICT (dominio) WHERE ativa = TRUE DO NOTHING
    RETURNING id
  `) as Array<{ id: string }>;
  if (inseridas[0]) {
    return { tipo: "reservada", id: inseridas[0].id, esperaSegundos: 0 };
  }

  const ativas = (await sql`
    SELECT GREATEST(1, CEIL(EXTRACT(EPOCH FROM (
             criada_em + make_interval(secs => ${COOLDOWN_DISPARO_SEGUNDOS}) - now()
           ))))::int AS espera_segundos
      FROM solicitacao_disparo_app
     WHERE dominio = ${dominio} AND ativa = TRUE
     ORDER BY criada_em DESC
     LIMIT 1
  `) as Array<{ espera_segundos: number }>;
  return { tipo: "cooldown", esperaSegundos: ativas[0]?.espera_segundos ?? 1 };
}

async function finalizarNoBanco(
  id: string,
  estado: "aceita" | "falha",
  codigoFalha?: "sem-token" | "github" | "interno",
): Promise<void> {
  const sql = conectar();
  await sql`
    UPDATE solicitacao_disparo_app
       SET estado = ${estado}, ativa = ${estado === "aceita"},
           codigo_falha = ${codigoFalha ?? null}, concluida_em = now()
     WHERE id = ${id} AND estado = 'reservada'
  `;
}

async function dispararDominio(dominio: DominioDeDisparo): Promise<ResultadoDoDisparo> {
  switch (dominio) {
    case "livelo":
      return dispararRobo();
    case "inter":
    case "produtos_inter":
      return dispararRoboInter();
  }
}

const dependenciasPadrao: DependenciasDeDisparo = {
  reservar: reservarNoBanco,
  finalizar: finalizarNoBanco,
  disparar: dispararDominio,
};

/**
 * Reserva antes de chamar o GitHub. Em queda entre o dispatch e a confirmação
 * final, a reserva segura o domínio por cinco minutos — prefere atrasar um
 * novo pedido a disparar duas coletas para a mesma intenção.
 */
export async function solicitarDisparo(
  dominio: DominioDeDisparo,
  chave: string,
  usuarioId: string,
  deps: DependenciasDeDisparo = dependenciasPadrao,
): Promise<ResultadoDeDisparoApi> {
  const reserva = await deps.reservar(dominio, chave, usuarioId);
  if (reserva.tipo === "cooldown") {
    return { estado: "cooldown", cooldownSegundos: reserva.esperaSegundos };
  }
  if (reserva.tipo === "existente") {
    if (reserva.estado === "aceita") {
      return { estado: "aceito", cooldownSegundos: reserva.esperaSegundos };
    }
    if (reserva.estado === "reservada") {
      return { estado: "em-andamento", cooldownSegundos: reserva.esperaSegundos };
    }
    return { estado: "falha" };
  }

  try {
    const resposta = await deps.disparar(dominio);
    if (resposta.ok) {
      await deps.finalizar(reserva.id, "aceita");
      return { estado: "aceito", cooldownSegundos: COOLDOWN_DISPARO_SEGUNDOS };
    }
    const codigo = resposta.motivo === "sem-token" ? "sem-token" : "github";
    await deps.finalizar(reserva.id, "falha", codigo);
    return { estado: "falha" };
  } catch {
    await deps.finalizar(reserva.id, "falha", "interno").catch(() => undefined);
    return { estado: "falha" };
  }
}

export async function estadoDoDisparo(
  dominio: DominioDeDisparo,
): Promise<EstadoDeDisparoApi> {
  const sql = conectar();
  const linhas = (await sql`
    SELECT estado, criada_em,
           GREATEST(0, CEIL(EXTRACT(EPOCH FROM (
             criada_em + make_interval(secs => ${COOLDOWN_DISPARO_SEGUNDOS}) - now()
           ))))::int AS cooldown_segundos
      FROM solicitacao_disparo_app
     WHERE dominio = ${dominio}
     ORDER BY criada_em DESC
     LIMIT 1
  `) as Array<{
    estado: EstadoDaSolicitacao;
    criada_em: string;
    cooldown_segundos: number;
  }>;
  const ultima = linhas[0];
  return {
    dominio,
    cooldownSegundos: ultima?.cooldown_segundos ?? 0,
    ultimaSolicitacaoEm: ultima?.criada_em ?? null,
    ultimoEstado: ultima?.estado ?? null,
  };
}
