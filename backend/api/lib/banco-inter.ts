import { neon } from "@neondatabase/serverless";

import { normalizarBuscaInter } from "./formato-inter";

function conectar() {
  const url = process.env.DATABASE_URL;
  if (!url) {
    throw new Error("DATABASE_URL nao configurada no ambiente do site.");
  }
  return neon(url);
}

export type TentativaInter = {
  id: string;
  iniciada_em: string;
  concluida_em: string | null;
  estado: "iniciada" | "sucesso" | "falha";
  lojas_lidas: number;
  lojas_validas: number;
  favoritas_encontradas: number;
  codigo_falha: string | null;
  versao: string;
};

export type CashbackInter = {
  id: string;
  id_externo: string;
  slug: string;
  nome: string;
  cashback_principal_texto: string | null;
  cashback_principal_valor: string | null;
  cashback_secundario_texto: string | null;
  cashback_secundario_valor: string | null;
  etiqueta: string | null;
  descricao_principal: string | null;
  descricao_secundaria: string | null;
  encontrada: boolean;
  favorita: boolean;
};

export type LojaCatalogoInter = {
  id: string;
  id_externo: string;
  slug: string;
  nome: string;
  cashback_principal_texto: string;
  cashback_principal_valor: string | null;
  ativa: boolean;
  favorita: boolean;
};

export type ResumoCashbackInterPersistido = {
  ultima_tentativa_em: string | null;
  ultima_tentativa_estado: TentativaInter["estado"] | null;
  ultimo_sucesso_em: string | null;
  lojas_acompanhadas: number;
  lojas_encontradas_ultima_coleta: number;
};

/** Última tentativa, último retrato válido e seleção atual em uma leitura. */
export async function resumoCashbackInterPersistido(): Promise<ResumoCashbackInterPersistido> {
  const sql = conectar();
  const linhas = (await sql`
    SELECT tentativa.iniciada_em AS ultima_tentativa_em,
           tentativa.estado AS ultima_tentativa_estado,
           sucesso.concluida_em AS ultimo_sucesso_em,
           (SELECT count(*)::int FROM favorita_inter) AS lojas_acompanhadas,
           COALESCE(sucesso.favoritas_encontradas, 0)::int
             AS lojas_encontradas_ultima_coleta
      FROM (SELECT 1) base
      LEFT JOIN LATERAL (
        SELECT iniciada_em, estado
          FROM execucao_inter
         ORDER BY iniciada_em DESC, id DESC
         LIMIT 1
      ) tentativa ON TRUE
      LEFT JOIN LATERAL (
        SELECT concluida_em, favoritas_encontradas
          FROM execucao_inter
         WHERE estado = 'sucesso'
         ORDER BY concluida_em DESC, id DESC
         LIMIT 1
      ) sucesso ON TRUE
  `) as ResumoCashbackInterPersistido[];
  return linhas[0] ?? {
    ultima_tentativa_em: null,
    ultima_tentativa_estado: null,
    ultimo_sucesso_em: null,
    lojas_acompanhadas: 0,
    lojas_encontradas_ultima_coleta: 0,
  };
}

export async function ultimaTentativaInter(): Promise<TentativaInter | null> {
  const sql = conectar();
  const linhas = (await sql`
    SELECT id, iniciada_em, concluida_em, estado, lojas_lidas, lojas_validas,
           favoritas_encontradas, codigo_falha, versao
      FROM execucao_inter
     ORDER BY iniciada_em DESC
     LIMIT 1
  `) as TentativaInter[];
  return linhas[0] ?? null;
}

export async function ultimaExecucaoInterValida(): Promise<TentativaInter | null> {
  const sql = conectar();
  const linhas = (await sql`
    SELECT id, iniciada_em, concluida_em, estado, lojas_lidas, lojas_validas,
           favoritas_encontradas, codigo_falha, versao
      FROM execucao_inter
     WHERE estado = 'sucesso'
     ORDER BY concluida_em DESC
     LIMIT 1
  `) as TentativaInter[];
  return linhas[0] ?? null;
}

/**
 * Catálogo completo da última coleta. A seleção é devolvida por item para a
 * tela aplicar o filtro "Acompanhadas", mas nunca limita a lista inicial.
 */
export async function cashbacksInter(execucaoId: string): Promise<CashbackInter[]> {
  const sql = conectar();
  return (await sql`
    SELECT l.id, l.id_externo, l.slug, COALESCE(c.nome, l.nome) AS nome,
           COALESCE(c.cashback_principal_texto, l.cashback_principal_texto) AS cashback_principal_texto,
           COALESCE(c.cashback_principal_valor, l.cashback_principal_valor) AS cashback_principal_valor,
           COALESCE(c.cashback_secundario_texto, l.cashback_secundario_texto) AS cashback_secundario_texto,
           COALESCE(c.cashback_secundario_valor, l.cashback_secundario_valor) AS cashback_secundario_valor,
           COALESCE(c.etiqueta, l.etiqueta) AS etiqueta,
           COALESCE(c.descricao_principal, l.descricao_principal) AS descricao_principal,
           COALESCE(c.descricao_secundaria, l.descricao_secundaria) AS descricao_secundaria,
           COALESCE(c.encontrada, TRUE) AS encontrada,
           (f.loja_inter_id IS NOT NULL) AS favorita
      FROM loja_inter l
      LEFT JOIN favorita_inter f ON f.loja_inter_id = l.id
      LEFT JOIN cashback_inter c
        ON c.loja_inter_id = l.id AND c.execucao_inter_id = ${execucaoId}
     WHERE l.ativa = TRUE
  `) as CashbackInter[];
}

export async function buscarLojasInter(
  termo: string,
  pagina = 1,
  porPagina = 10,
): Promise<LojaCatalogoInter[]> {
  const sql = conectar();
  const busca = `%${normalizarBuscaInter(termo)}%`;
  const limite = Math.min(50, Math.max(1, Math.floor(porPagina)));
  const numeroDaPagina = Math.max(1, Math.floor(pagina));
  const deslocamento = (numeroDaPagina - 1) * limite;
  return (await sql`
    SELECT l.id, l.id_externo, l.slug, l.nome,
           l.cashback_principal_texto, l.cashback_principal_valor, l.ativa,
           (f.loja_inter_id IS NOT NULL) AS favorita
      FROM loja_inter l
      LEFT JOIN favorita_inter f ON f.loja_inter_id = l.id
     WHERE l.nome_busca LIKE ${busca} OR l.slug_busca LIKE ${busca}
     ORDER BY l.nome
     LIMIT ${limite}
    OFFSET ${deslocamento}
  `) as LojaCatalogoInter[];
}

export async function totalLojasInter(termo = ""): Promise<number> {
  const sql = conectar();
  const busca = `%${normalizarBuscaInter(termo)}%`;
  const linhas = (await sql`
    SELECT count(*)::int AS total
      FROM loja_inter
     WHERE nome_busca LIKE ${busca} OR slug_busca LIKE ${busca}
  `) as { total: number }[];
  return linhas[0]?.total ?? 0;
}

/** Marca uma loja ativa como favorita sem disparar coleta. */
export async function acompanharLojaInter(id: string): Promise<boolean> {
  const sql = conectar();
  const lojas = (await sql`
    SELECT id FROM loja_inter WHERE id = ${id} AND ativa = TRUE
  `) as Array<{ id: string }>;
  if (lojas.length === 0) return false;
  await sql`
    INSERT INTO favorita_inter (loja_inter_id)
    SELECT id FROM loja_inter WHERE id = ${id} AND ativa = TRUE
    ON CONFLICT (loja_inter_id) DO NOTHING
  `;
  return true;
}

/** Remove uma favorita sem falhar se ela já estiver removida. */
export async function deixarDeAcompanharLojaInter(id: string): Promise<boolean> {
  const sql = conectar();
  const lojas = (await sql`
    SELECT id FROM loja_inter WHERE id = ${id}
  `) as Array<{ id: string }>;
  if (lojas.length === 0) return false;
  await sql`DELETE FROM favorita_inter WHERE loja_inter_id = ${id}`;
  return true;
}

const INTERVALO_MINIMO_INTER_MINUTOS = 5;
export const INTERVALO_INTER_MINUTOS = INTERVALO_MINIMO_INTER_MINUTOS;

export async function esperaAteProximoDisparoInter(): Promise<number> {
  const sql = conectar();
  const linhas = (await sql`
    SELECT GREATEST(
             0,
             CEIL(EXTRACT(EPOCH FROM (
               momento + (${INTERVALO_MINIMO_INTER_MINUTOS} || ' minutes')::interval - now()
             )))
           )::int AS falta
      FROM disparo_manual_inter
     ORDER BY momento DESC
     LIMIT 1
  `) as { falta: number }[];
  return linhas[0]?.falta ?? 0;
}

export async function registrarDisparoInter(): Promise<void> {
  const sql = conectar();
  await sql`INSERT INTO disparo_manual_inter DEFAULT VALUES`;
}
