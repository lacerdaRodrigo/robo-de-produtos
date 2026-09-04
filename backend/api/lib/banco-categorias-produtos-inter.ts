import { neon } from "@neondatabase/serverless";

function conectar() {
  const url = process.env.DATABASE_URL;
  if (!url) throw new Error("DATABASE_URL nao configurada no ambiente do site.");
  return neon(url);
}

export type CategoriaInterUsuario = {
  valor: string | null;
  nome: string;
  selecionada: boolean;
};

export type CatalogoCategoriasInterUsuario = {
  configurada: boolean;
  itens: CategoriaInterUsuario[];
};

export type ResultadoSelecaoCategorias =
  | { ok: true; total: number }
  | { ok: false; invalidas: string[]; sem_categoria_indisponivel: boolean };

/**
 * Lista somente categorias realmente presentes no catálogo ativo das lojas
 * selecionadas. NULL/vazio vira o agrupamento funcional "Sem categoria" sem
 * alterar o valor bruto persistido no produto.
 */
export async function listarCategoriasInterUsuario(
  usuarioId: string,
): Promise<CatalogoCategoriasInterUsuario> {
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
      WITH categorias_catalogo AS (
        SELECT DISTINCT NULLIF(btrim(produto.categoria), '') AS categoria
          FROM produto_direto_inter produto
          JOIN loja_direta_inter loja
            ON loja.id = produto.loja_direta_inter_id
         WHERE produto.ativo = TRUE
           AND loja.selecionada = TRUE
           AND loja.ativa = TRUE
      )
      SELECT catalogo.categoria AS valor,
             COALESCE(catalogo.categoria, 'Sem categoria') AS nome,
             EXISTS (
               SELECT 1
                 FROM categoria_inter_acompanhada acompanhada
                WHERE acompanhada.usuario_app_id = ${usuarioId}::bigint
                  AND acompanhada.categoria IS NOT DISTINCT FROM catalogo.categoria
             ) AS selecionada
        FROM categorias_catalogo catalogo
       ORDER BY catalogo.categoria IS NULL,
                lower(COALESCE(catalogo.categoria, 'Sem categoria')),
                COALESCE(catalogo.categoria, 'Sem categoria')
    `,
  ]);

  return {
    configurada: Boolean(preferencias[0]?.configurada),
    itens: itens as CategoriaInterUsuario[],
  };
}

/**
 * Substitui as categorias externas acompanhadas. A validação usa igualdade
 * exata contra o catálogo atual; nenhuma categoria é criada, traduzida ou
 * normalizada pelo Radar.
 */
export async function substituirCategoriasInterUsuario(
  usuarioId: string,
  categorias: string[],
  semCategoria: boolean,
): Promise<ResultadoSelecaoCategorias> {
  const sql = conectar();
  const linhas = (await sql`
    WITH solicitadas AS (
      SELECT DISTINCT unnest(${categorias}::text[]) AS categoria
    ), disponiveis AS (
      SELECT DISTINCT NULLIF(btrim(produto.categoria), '') AS categoria
        FROM produto_direto_inter produto
        JOIN loja_direta_inter loja
          ON loja.id = produto.loja_direta_inter_id
       WHERE produto.ativo = TRUE
         AND loja.selecionada = TRUE
         AND loja.ativa = TRUE
    ), validacao AS (
      SELECT ARRAY(
               SELECT solicitada.categoria
                 FROM solicitadas solicitada
                WHERE NOT EXISTS (
                  SELECT 1
                    FROM disponiveis disponivel
                   WHERE disponivel.categoria = solicitada.categoria
                )
                ORDER BY solicitada.categoria
             ) AS invalidas,
             ${semCategoria} AND NOT EXISTS (
               SELECT 1 FROM disponiveis WHERE categoria IS NULL
             ) AS sem_categoria_indisponivel
    ), preferencia AS (
      INSERT INTO preferencia_produtos_inter_usuario (
          usuario_app_id, configurada_em, atualizada_em
      )
      SELECT ${usuarioId}::bigint, now(), now()
       WHERE cardinality((SELECT invalidas FROM validacao)) = 0
         AND NOT (SELECT sem_categoria_indisponivel FROM validacao)
      ON CONFLICT (usuario_app_id) DO UPDATE
          SET atualizada_em = now()
      RETURNING usuario_app_id
    ), removidas AS (
      DELETE FROM categoria_inter_acompanhada acompanhada
       WHERE acompanhada.usuario_app_id = ${usuarioId}::bigint
         AND EXISTS (SELECT 1 FROM preferencia)
      RETURNING acompanhada.categoria
    ), inseridas AS (
      INSERT INTO categoria_inter_acompanhada (
          usuario_app_id, categoria, selecionada_em
      )
      SELECT ${usuarioId}::bigint, solicitada.categoria, now()
        FROM solicitadas solicitada
       WHERE EXISTS (SELECT 1 FROM preferencia)
      UNION ALL
      SELECT ${usuarioId}::bigint, NULL, now()
       WHERE ${semCategoria}
         AND EXISTS (SELECT 1 FROM preferencia)
      ON CONFLICT (usuario_app_id, categoria) DO NOTHING
      RETURNING categoria
    )
    SELECT cardinality(validacao.invalidas) = 0
             AND NOT validacao.sem_categoria_indisponivel AS ok,
           validacao.invalidas,
           validacao.sem_categoria_indisponivel,
           (SELECT count(*)::int FROM inseridas) AS total
      FROM validacao
  `) as Array<{
    ok: boolean;
    invalidas: string[];
    sem_categoria_indisponivel: boolean;
    total: number;
  }>;

  const resultado = linhas[0];
  if (!resultado?.ok) {
    return {
      ok: false,
      invalidas: resultado?.invalidas ?? categorias,
      sem_categoria_indisponivel:
        resultado?.sem_categoria_indisponivel ?? semCategoria,
    };
  }
  return { ok: true, total: Number(resultado.total) };
}
