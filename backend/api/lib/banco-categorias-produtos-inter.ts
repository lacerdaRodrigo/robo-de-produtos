import { neon } from "@neondatabase/serverless";

function conectar() {
  const url = process.env.DATABASE_URL;
  if (!url) throw new Error("DATABASE_URL nao configurada no ambiente do site.");
  return neon(url);
}

export type CategoriaRadarUsuario = {
  id: string;
  slug: string;
  nome: string;
  categoria_pai_slug: string | null;
  ordem: number;
  selecionada: boolean;
  acompanhada: boolean;
};

export type CatalogoCategoriasRadarUsuario = {
  configurada: boolean;
  itens: CategoriaRadarUsuario[];
};

export type ResultadoSelecaoCategorias =
  | { ok: true; total: number }
  | { ok: false; invalidas: string[] };

export async function categoriaRadarAtivaExiste(slug: string): Promise<boolean> {
  const sql = conectar();
  const linhas = (await sql`
    SELECT EXISTS (
      SELECT 1
        FROM categoria_radar
       WHERE slug = ${slug} AND ativo = TRUE
    ) AS existe
  `) as Array<{ existe: boolean }>;
  return Boolean(linhas[0]?.existe);
}

/**
 * Retorna a taxonomia ativa e distingue seleção direta de seleção herdada.
 * Filhas de um pai selecionado são resolvidas a cada leitura; uma filha criada
 * no futuro passa a ser acompanhada sem regravar a preferência da pessoa.
 */
export async function listarCategoriasRadarUsuario(
  usuarioId: string,
): Promise<CatalogoCategoriasRadarUsuario> {
  const sql = conectar();
  const [preferencias, itens] = await Promise.all([
    sql`
      SELECT EXISTS (
        SELECT 1
          FROM preferencia_produtos_inter_usuario
         WHERE usuario_app_id = ${usuarioId}::bigint
      ) AS configurada
    `,
    sql`
      WITH RECURSIVE diretas AS (
        SELECT acompanhada.categoria_radar_id AS id
          FROM categoria_radar_acompanhada acompanhada
         WHERE acompanhada.usuario_app_id = ${usuarioId}::bigint
      ), efetivas AS (
        SELECT direta.id FROM diretas direta
        UNION
        SELECT filha.id
          FROM categoria_radar filha
          JOIN efetivas pai ON filha.categoria_pai_id = pai.id
         WHERE filha.ativo = TRUE
      )
      SELECT categoria.id::text AS id,
             categoria.slug,
             categoria.nome,
             pai.slug AS categoria_pai_slug,
             categoria.ordem,
             EXISTS (SELECT 1 FROM diretas WHERE diretas.id = categoria.id)
               AS selecionada,
             EXISTS (SELECT 1 FROM efetivas WHERE efetivas.id = categoria.id)
               AS acompanhada
        FROM categoria_radar categoria
        LEFT JOIN categoria_radar pai ON pai.id = categoria.categoria_pai_id
       WHERE categoria.ativo = TRUE
       ORDER BY COALESCE(pai.ordem, categoria.ordem),
                categoria.categoria_pai_id NULLS FIRST,
                categoria.ordem,
                categoria.nome
    `,
  ]);
  return {
    configurada: Boolean(preferencias[0]?.configurada),
    itens: itens as CategoriaRadarUsuario[],
  };
}

/** Substitui os nós escolhidos diretamente em uma única instrução SQL. */
export async function substituirCategoriasRadarUsuario(
  usuarioId: string,
  slugs: string[],
): Promise<ResultadoSelecaoCategorias> {
  const sql = conectar();
  const linhas = (await sql`
    WITH solicitadas AS (
      SELECT DISTINCT unnest(${slugs}::text[]) AS slug
    ), validas AS (
      SELECT categoria.id, categoria.slug
        FROM categoria_radar categoria
        JOIN solicitadas ON solicitadas.slug = categoria.slug
       WHERE categoria.ativo = TRUE
    ), validacao AS (
      SELECT NOT EXISTS (
               SELECT 1
                 FROM solicitadas
                WHERE solicitadas.slug NOT IN (SELECT slug FROM validas)
             ) AS ok,
             ARRAY(
               SELECT solicitadas.slug
                 FROM solicitadas
                WHERE solicitadas.slug NOT IN (SELECT slug FROM validas)
                ORDER BY solicitadas.slug
             ) AS invalidas
    ), preferencia AS (
      INSERT INTO preferencia_produtos_inter_usuario (
          usuario_app_id, configurada_em, atualizada_em
      )
      SELECT ${usuarioId}::bigint, now(), now()
       WHERE (SELECT ok FROM validacao)
      ON CONFLICT (usuario_app_id) DO UPDATE
          SET atualizada_em = now()
      RETURNING usuario_app_id
    ), removidas AS (
      DELETE FROM categoria_radar_acompanhada acompanhada
       WHERE acompanhada.usuario_app_id = ${usuarioId}::bigint
         AND EXISTS (SELECT 1 FROM preferencia)
         AND acompanhada.categoria_radar_id NOT IN (SELECT id FROM validas)
      RETURNING acompanhada.categoria_radar_id
    ), inseridas AS (
      INSERT INTO categoria_radar_acompanhada (
          usuario_app_id, categoria_radar_id, selecionada_em
      )
      SELECT ${usuarioId}::bigint, valida.id, now()
        FROM validas valida
       WHERE EXISTS (SELECT 1 FROM preferencia)
      ON CONFLICT (usuario_app_id, categoria_radar_id) DO NOTHING
      RETURNING categoria_radar_id
    )
    SELECT validacao.ok,
           validacao.invalidas,
           (SELECT count(*)::int FROM validas) AS total
      FROM validacao
  `) as Array<{ ok: boolean; invalidas: string[]; total: number }>;
  const resultado = linhas[0];
  if (!resultado?.ok) {
    return { ok: false, invalidas: resultado?.invalidas ?? slugs };
  }
  return { ok: true, total: Number(resultado.total) };
}
