import { neon } from "@neondatabase/serverless";

// PRD-V2 9.0: a credencial do banco vive so no servidor. Nenhuma variavel
// deste arquivo tem prefixo NEXT_PUBLIC_, entao nada disso chega ao navegador.
function conectar() {
  const url = process.env.DATABASE_URL;
  if (!url) {
    throw new Error("DATABASE_URL nao configurada no ambiente do site.");
  }
  return neon(url);
}

/** NUMERIC do Postgres chega como string — e assim que fica (PRD 5.4).
 *  Converter para `number` reintroduziria o 2.9000000000000004 que o robo
 *  evita usando Decimal do lado dele. */
export type Numerico = string | null;

export type Execucao = {
  id: number;
  momento: string;
  parceiros_lidos: number;
  alertas: number;
  versao: string;
  qualidade: "completa" | "degradada";
};

export type PontuacaoDeLoja = {
  nome: string;
  categoria: string | null;
  pontos_atuais: Numerico;
  pontos_base: Numerico;
  pontos_clube: Numerico;
  valor_de_disparo: Numerico;
  moeda: string;
  prefixo_ate: boolean;
  em_promocao: boolean;
  alertou: boolean;
  campanha: string | null;
  descricao_campanha: string | null;
  fim_promocao: string | null;
  link: string | null;
  multiplicador: Numerico;
  piso_pontos: Numerico;
};

export type Loja = {
  id: number;
  nome: string;
  categoria: string;
  multiplicador: Numerico;
  piso_pontos: Numerico;
  apelidos: string[];
};

export type Preferencias = {
  multiplicador_padrao: string;
  piso_pontos_padrao: string;
  assinante_clube: boolean;
};

export type ResumoLiveloPersistido = {
  ultima_tentativa_em: string | null;
  qualidade: "completa" | "degradada" | null;
  ultimo_sucesso_em: string | null;
  lojas_acompanhadas: number;
  alertas_ultima_coleta: number;
};

export type ParceiroLiveloPersistido = {
  id_externo: string;
  nome: string;
  categorias: string[];
  pontos_atuais: string;
  pontos_anteriores: Numerico;
  pontos_base: Numerico;
  pontos_clube: Numerico;
  moeda: string;
  prefixo_ate: boolean;
  em_promocao: boolean;
  campanha: string | null;
  descricao_campanha: string | null;
  inicio_promocao: string | null;
  fim_promocao: string | null;
  link: string | null;
  acompanhada: boolean;
  alerta_ativo?: boolean;
  alerta: boolean;
  atualizado_em: string;
  parceiros_lidos: number;
};

export type FiltrosCatalogoLiveloPersistido = {
  busca: string;
  codigosBusca: string[];
  buscaIncluiOutros: boolean;
  aba: "todas" | "acompanhadas" | "alertas";
  categoriaAtiva: boolean;
  codigosCategoria: string[];
  categoriaIncluiOutros: boolean;
  codigosConhecidos: string[];
  ordenar: "pontos" | "nome";
};

export type PaginaCatalogoLiveloPersistido = {
  itens: ParceiroLiveloPersistido[];
  total: number;
  pagina: number;
};

export type ResumoCatalogoLiveloPersistido = {
  ultima_coleta: string | null;
  ultima_tentativa_em: string | null;
  qualidade: "completa" | "degradada" | null;
  parceiros_lidos: number;
  total_catalogo: number;
  acompanhadas: number;
  alertas_ativos: number;
  alertas: number;
  categorias: string[];
  melhor_oferta_id_externo: string | null;
  melhor_oferta_nome: string | null;
  melhor_oferta_pontos_atuais: string | null;
  melhor_oferta_moeda: string | null;
  melhor_oferta_prefixo_ate: boolean | null;
};

export type MedicaoHistoricoLivelo = {
  momento: string;
  pontos_atuais: Numerico;
  pontos_base: Numerico;
  pontos_clube: Numerico;
  moeda: string;
};

/** Busca, filtra, ordena e pagina o catálogo ativo inteiramente no Postgres. */
export async function buscarCatalogoLiveloPersistido(
  filtros: FiltrosCatalogoLiveloPersistido,
  pagina: number,
  porPagina: number,
): Promise<PaginaCatalogoLiveloPersistido> {
  const sql = conectar();
  const busca = filtros.busca;
  const paginaSolicitada = Math.max(1, Math.floor(pagina));
  const limite = Math.min(50, Math.max(1, Math.floor(porPagina)));
  const totais = (await sql`
    SELECT count(*)::int AS total
      FROM parceiro_livelo parceiro
      LEFT JOIN loja
        ON loja.parceiro_livelo_id = parceiro.id
       AND loja.acompanhada = TRUE
      LEFT JOIN pontuacao
        ON pontuacao.execucao_id = parceiro.atualizado_execucao_id
       AND pontuacao.loja_id = loja.id
     WHERE parceiro.ativo = TRUE
       AND (${filtros.aba === "todas"} OR loja.id IS NOT NULL)
       AND (${filtros.aba !== "alertas"} OR COALESCE(pontuacao.alertou, FALSE))
       AND (
         ${filtros.busca === ""}
         OR strpos(
              regexp_replace(
                translate(
                  lower(parceiro.nome),
                  'áàâãäéèêëíìîïóòôõöúùûüç',
                  'aaaaaeeeeiiiiooooouuuuc'
                ),
                '[[:space:]]+', ' ', 'g'
              ),
              ${busca}
            ) > 0
         OR parceiro.categorias && ${filtros.codigosBusca}::text[]
         OR (
           ${filtros.buscaIncluiOutros}
           AND (
             NOT EXISTS (
               SELECT 1 FROM unnest(parceiro.categorias) categoria
                WHERE categoria <> 'todos'
             )
             OR EXISTS (
               SELECT 1 FROM unnest(parceiro.categorias) categoria
                WHERE categoria <> 'todos'
                  AND NOT (categoria = ANY(${filtros.codigosConhecidos}::text[]))
             )
           )
         )
       )
       AND (
         ${!filtros.categoriaAtiva}
         OR parceiro.categorias && ${filtros.codigosCategoria}::text[]
         OR (
           ${filtros.categoriaIncluiOutros}
           AND (
             NOT EXISTS (
               SELECT 1 FROM unnest(parceiro.categorias) categoria
                WHERE categoria <> 'todos'
             )
             OR EXISTS (
               SELECT 1 FROM unnest(parceiro.categorias) categoria
                WHERE categoria <> 'todos'
                  AND NOT (categoria = ANY(${filtros.codigosConhecidos}::text[]))
             )
           )
         )
       )
  `) as Array<{ total: number }>;
  const total = totais[0]?.total ?? 0;
  const totalPaginas = Math.max(1, Math.ceil(total / limite));
  const paginaFinal = Math.min(paginaSolicitada, totalPaginas);
  const deslocamento = (paginaFinal - 1) * limite;

  const itens = (await sql`
    SELECT parceiro.id_externo, parceiro.nome, parceiro.categorias,
           parceiro.pontos_atuais, parceiro.pontos_anteriores,
           parceiro.pontos_base, parceiro.pontos_clube, parceiro.moeda,
           parceiro.prefixo_ate, parceiro.em_promocao, parceiro.campanha,
           parceiro.descricao_campanha, parceiro.inicio_promocao,
           parceiro.fim_promocao, parceiro.link,
           (loja.id IS NOT NULL) AS acompanhada,
           COALESCE(loja.alerta_ativo, FALSE) AS alerta_ativo,
           COALESCE(pontuacao.alertou, FALSE) AS alerta,
           execucao.momento AS atualizado_em,
           execucao.parceiros_lidos
      FROM parceiro_livelo parceiro
      JOIN execucao ON execucao.id = parceiro.atualizado_execucao_id
      LEFT JOIN loja
        ON loja.parceiro_livelo_id = parceiro.id
       AND loja.acompanhada = TRUE
      LEFT JOIN pontuacao
       ON pontuacao.execucao_id = parceiro.atualizado_execucao_id
       AND pontuacao.loja_id = loja.id
     WHERE parceiro.ativo = TRUE
       AND (${filtros.aba === "todas"} OR loja.id IS NOT NULL)
       AND (${filtros.aba !== "alertas"} OR COALESCE(pontuacao.alertou, FALSE))
       AND (
         ${filtros.busca === ""}
         OR strpos(
              regexp_replace(
                translate(
                  lower(parceiro.nome),
                  'áàâãäéèêëíìîïóòôõöúùûüç',
                  'aaaaaeeeeiiiiooooouuuuc'
                ),
                '[[:space:]]+', ' ', 'g'
              ),
              ${busca}
            ) > 0
         OR parceiro.categorias && ${filtros.codigosBusca}::text[]
         OR (
           ${filtros.buscaIncluiOutros}
           AND (
             NOT EXISTS (
               SELECT 1 FROM unnest(parceiro.categorias) categoria
                WHERE categoria <> 'todos'
             )
             OR EXISTS (
               SELECT 1 FROM unnest(parceiro.categorias) categoria
                WHERE categoria <> 'todos'
                  AND NOT (categoria = ANY(${filtros.codigosConhecidos}::text[]))
             )
           )
         )
       )
       AND (
         ${!filtros.categoriaAtiva}
         OR parceiro.categorias && ${filtros.codigosCategoria}::text[]
         OR (
           ${filtros.categoriaIncluiOutros}
           AND (
             NOT EXISTS (
               SELECT 1 FROM unnest(parceiro.categorias) categoria
                WHERE categoria <> 'todos'
             )
             OR EXISTS (
               SELECT 1 FROM unnest(parceiro.categorias) categoria
                WHERE categoria <> 'todos'
                  AND NOT (categoria = ANY(${filtros.codigosConhecidos}::text[]))
             )
           )
         )
       )
     ORDER BY
       CASE WHEN ${filtros.ordenar === "pontos"} THEN parceiro.pontos_atuais END DESC,
       parceiro.nome,
       parceiro.id_externo
     LIMIT ${limite}
    OFFSET ${deslocamento}
  `) as ParceiroLiveloPersistido[];
  return { itens, total, pagina: paginaFinal };
}

/** Agregados globais do catálogo, sem materializar seus parceiros no Node. */
export async function resumoCatalogoLiveloPersistido(): Promise<ResumoCatalogoLiveloPersistido> {
  const sql = conectar();
  const linhas = (await sql`
    WITH catalogo AS (
      SELECT parceiro.id_externo, parceiro.nome, parceiro.categorias,
             parceiro.pontos_atuais, parceiro.moeda, parceiro.prefixo_ate,
             (loja.id IS NOT NULL) AS acompanhada,
             COALESCE(loja.alerta_ativo, FALSE) AS alerta_ativo,
             COALESCE(pontuacao.alertou, FALSE) AS alerta,
             execucao.momento AS atualizado_em,
             execucao.parceiros_lidos
        FROM parceiro_livelo parceiro
        JOIN execucao ON execucao.id = parceiro.atualizado_execucao_id
        LEFT JOIN loja
          ON loja.parceiro_livelo_id = parceiro.id
         AND loja.acompanhada = TRUE
        LEFT JOIN pontuacao
          ON pontuacao.execucao_id = parceiro.atualizado_execucao_id
         AND pontuacao.loja_id = loja.id
       WHERE parceiro.ativo = TRUE
    ), contagens AS (
      SELECT count(*)::int AS total_catalogo,
             count(*) FILTER (WHERE acompanhada)::int AS acompanhadas,
             count(*) FILTER (WHERE acompanhada AND alerta_ativo)::int AS alertas_ativos,
             count(*) FILTER (WHERE acompanhada AND alerta)::int AS alertas
        FROM catalogo
    )
    SELECT ultima.atualizado_em AS ultima_coleta,
           tentativa.momento AS ultima_tentativa_em,
           tentativa.qualidade,
           COALESCE(ultima.parceiros_lidos, 0)::int AS parceiros_lidos,
           contagens.total_catalogo, contagens.acompanhadas,
           contagens.alertas_ativos, contagens.alertas,
           ARRAY(
             SELECT DISTINCT categoria
               FROM catalogo
               CROSS JOIN LATERAL unnest(categorias) categoria
              ORDER BY categoria
           ) AS categorias,
           melhor.id_externo AS melhor_oferta_id_externo,
           melhor.nome AS melhor_oferta_nome,
           melhor.pontos_atuais AS melhor_oferta_pontos_atuais,
           melhor.moeda AS melhor_oferta_moeda,
           melhor.prefixo_ate AS melhor_oferta_prefixo_ate
      FROM contagens
      LEFT JOIN LATERAL (
        SELECT atualizado_em, parceiros_lidos
          FROM catalogo
         ORDER BY atualizado_em DESC, id_externo
         LIMIT 1
      ) ultima ON TRUE
      LEFT JOIN LATERAL (
        SELECT momento, qualidade
          FROM execucao
         ORDER BY momento DESC, id DESC
         LIMIT 1
      ) tentativa ON TRUE
      LEFT JOIN LATERAL (
        SELECT id_externo, nome, pontos_atuais, moeda, prefixo_ate
          FROM catalogo
         WHERE acompanhada
         ORDER BY pontos_atuais DESC, nome, id_externo
         LIMIT 1
      ) melhor ON TRUE
  `) as ResumoCatalogoLiveloPersistido[];
  return linhas[0] ?? {
    ultima_coleta: null,
    ultima_tentativa_em: null,
    qualidade: null,
    parceiros_lidos: 0,
    total_catalogo: 0,
    acompanhadas: 0,
    alertas_ativos: 0,
    alertas: 0,
    categorias: [],
    melhor_oferta_id_externo: null,
    melhor_oferta_nome: null,
    melhor_oferta_pontos_atuais: null,
    melhor_oferta_moeda: null,
    melhor_oferta_prefixo_ate: null,
  };
}

export async function historicoLivelo(idExterno: string): Promise<MedicaoHistoricoLivelo[]> {
  const sql = conectar();
  return (await sql`
    SELECT e.momento, p.pontos_atuais, p.pontos_base, p.pontos_clube, p.moeda
      FROM pontuacao p
      JOIN execucao e ON e.id = p.execucao_id
      JOIN parceiro_livelo pl ON pl.id_externo = ${idExterno}
     WHERE p.parceiro_livelo_id = pl.id
        -- Fallback apenas para retratos antigos, gravados antes da migração
        -- 015 e portanto sem a identidade estável do parceiro.
        OR EXISTS (
          SELECT 1 FROM loja l
           WHERE l.parceiro_livelo_id = pl.id AND l.id = p.loja_id
        )
     ORDER BY e.momento DESC
     LIMIT 30
  `) as MedicaoHistoricoLivelo[];
}

export async function parceiroLiveloPorIdExterno(
  idExterno: string,
): Promise<Pick<ParceiroLiveloPersistido, "id_externo" | "nome" | "categorias"> | null> {
  const sql = conectar();
  const linhas = (await sql`
    SELECT id_externo, nome, categorias
      FROM parceiro_livelo
     WHERE id_externo = ${idExterno} AND ativo = TRUE
     LIMIT 1
  `) as Array<Pick<ParceiroLiveloPersistido, "id_externo" | "nome" | "categorias">>;
  return linhas[0] ?? null;
}

/** Acompanhamento idempotente. Nome e categoria vêm do catálogo do servidor. */
export async function alterarAcompanhamentoParceiroLivelo(entrada: {
  idExterno: string;
  nome: string;
  categoria: string;
  acompanhada: boolean;
}): Promise<boolean> {
  const sql = conectar();
  if (!entrada.acompanhada) {
    const linhas = (await sql`
      WITH parceiro AS (
        SELECT id FROM parceiro_livelo WHERE id_externo = ${entrada.idExterno}
      ), atualizada AS (
        UPDATE loja
           SET acompanhada = FALSE,
               alerta_ativo = FALSE
         WHERE parceiro_livelo_id = (SELECT id FROM parceiro)
         RETURNING id
      )
      -- Sem vínculo prévio, o estado desejado já existe e a operação também
      -- é idempotente. A linha permanece como identidade para o histórico.
      SELECT TRUE AS confirmado FROM parceiro
    `) as Array<{ confirmado: boolean }>;
    return linhas[0]?.confirmado === true;
  }

  const linhas = (await sql`
    WITH parceiro AS (
      SELECT id FROM parceiro_livelo
       WHERE id_externo = ${entrada.idExterno} AND ativo = TRUE
    ), atualizada AS (
      UPDATE loja
         SET parceiro_livelo_id = parceiro.id,
             nome = ${entrada.nome},
             categoria = ${entrada.categoria},
             acompanhada = TRUE
        FROM parceiro
       WHERE loja.parceiro_livelo_id = parceiro.id
          OR (loja.parceiro_livelo_id IS NULL AND loja.nome = ${entrada.nome})
       RETURNING loja.id
    ), inserida AS (
      INSERT INTO loja (nome, categoria, parceiro_livelo_id, acompanhada)
      SELECT ${entrada.nome}, ${entrada.categoria}, parceiro.id, TRUE
        FROM parceiro
       WHERE NOT EXISTS (SELECT 1 FROM atualizada)
      ON CONFLICT DO NOTHING
      RETURNING id
    )
    -- CTEs que alteram dados não ficam visíveis ao SELECT final pela tabela
    -- base nesta mesma instrução. Confirmamos pelo RETURNING das próprias
    -- CTEs; reler loja aqui fazia um acompanhamento novo parecer falho.
    SELECT EXISTS (
      SELECT 1 FROM atualizada
      UNION ALL
      SELECT 1 FROM inserida
    ) AS estado
  `) as Array<{ estado: boolean }>;
  return linhas[0]?.estado === true;
}

/** Liga/desliga a preferência do sino sem alterar o acompanhamento. */
export async function alterarAlertaParceiroLivelo(
  idExterno: string,
  ativo: boolean,
): Promise<boolean> {
  const sql = conectar();
  const linhas = (await sql`
    UPDATE loja
       SET alerta_ativo = ${ativo}
     WHERE parceiro_livelo_id = (
       SELECT id FROM parceiro_livelo WHERE id_externo = ${idExterno} AND ativo = TRUE
     )
       AND acompanhada = TRUE
     RETURNING id
  `) as Array<{ id: number }>;
  return linhas.length > 0;
}

/** Recorte agregado da Livelo para o Início do aplicativo.
 *
 * Tentativas degradadas ficam em `execucao`, mas o sucesso e seus alertas
 * continuam vindo exclusivamente do último snapshot completo.
 */
export async function resumoLiveloPersistido(): Promise<ResumoLiveloPersistido> {
  const sql = conectar();
  const linhas = (await sql`
    SELECT tentativa.momento AS ultima_tentativa_em,
           tentativa.qualidade,
           sucesso.momento AS ultimo_sucesso_em,
           (SELECT count(*)::int FROM loja WHERE acompanhada = TRUE) AS lojas_acompanhadas,
           COALESCE(sucesso.alertas, 0)::int AS alertas_ultima_coleta
      FROM (SELECT 1) base
      LEFT JOIN LATERAL (
        SELECT momento, alertas
          FROM execucao
         WHERE qualidade = 'completa'
         ORDER BY momento DESC, id DESC
         LIMIT 1
      ) sucesso ON TRUE
      LEFT JOIN LATERAL (
        SELECT momento, qualidade
          FROM execucao
         ORDER BY momento DESC, id DESC
         LIMIT 1
      ) tentativa ON TRUE
  `) as ResumoLiveloPersistido[];
  return linhas[0] ?? {
    ultima_tentativa_em: null,
    qualidade: null,
    ultimo_sucesso_em: null,
    lojas_acompanhadas: 0,
    alertas_ultima_coleta: 0,
  };
}

/** RN26: o carimbo da pagina. Sem execucao registrada, a pagina diz isso em
 *  vez de fingir que esta atualizada. */
export async function ultimaExecucao(): Promise<Execucao | null> {
  const sql = conectar();
  const linhas = (await sql`
    SELECT id, momento, parceiros_lidos, alertas, versao, qualidade
      FROM execucao
     WHERE qualidade = 'completa'
     ORDER BY momento DESC
     LIMIT 1
  `) as Execucao[];
  return linhas[0] ?? null;
}

/** RN24: todas as favoritas, em promocao ou nao. E o que permite consultar a
 *  pontuacao base sem abrir a Livelo (O5). */
export async function pontuacoes(execucaoId: number): Promise<PontuacaoDeLoja[]> {
  const sql = conectar();
  return (await sql`
    SELECT l.nome, l.categoria, p.pontos_atuais, p.pontos_base, p.pontos_clube,
           p.valor_de_disparo, p.moeda, p.prefixo_ate, p.em_promocao, p.alertou,
           p.campanha, p.descricao_campanha, p.fim_promocao, p.link,
           l.multiplicador, l.piso_pontos
      FROM loja l
      LEFT JOIN pontuacao p
        ON p.loja_id = l.id AND p.execucao_id = ${execucaoId}
     WHERE l.acompanhada = TRUE
     ORDER BY l.categoria NULLS LAST, p.alertou DESC, p.pontos_atuais DESC NULLS LAST, p.nome
  `) as PontuacaoDeLoja[];
}

export async function loja(id: number): Promise<Loja | null> {
  const sql = conectar();
  const linhas = (await sql`
    SELECT l.id, l.nome, l.categoria, l.multiplicador, l.piso_pontos,
           COALESCE(ARRAY_AGG(a.texto) FILTER (WHERE a.texto IS NOT NULL), ARRAY[]::TEXT[])
               AS apelidos
      FROM loja l
      LEFT JOIN apelido a ON a.loja_id = l.id
     WHERE l.id = ${id}
     GROUP BY l.id
  `) as Loja[];
  return linhas[0] ?? null;
}

export async function catalogo(): Promise<Loja[]> {
  const sql = conectar();
  return (await sql`
    SELECT l.id, l.nome, l.categoria, l.multiplicador, l.piso_pontos,
           COALESCE(ARRAY_AGG(a.texto) FILTER (WHERE a.texto IS NOT NULL), ARRAY[]::TEXT[])
               AS apelidos
      FROM loja l
      LEFT JOIN apelido a ON a.loja_id = l.id
     WHERE l.acompanhada = TRUE
     GROUP BY l.id
     ORDER BY l.categoria, l.nome
  `) as Loja[];
}

export async function preferencias(): Promise<Preferencias> {
  const sql = conectar();
  const linhas = (await sql`SELECT chave, valor FROM preferencia`) as {
    chave: string;
    valor: string;
  }[];
  const mapa = new Map(linhas.map((l) => [l.chave, l.valor]));
  return {
    multiplicador_padrao: mapa.get("multiplicador_padrao") ?? "2.0",
    piso_pontos_padrao: mapa.get("piso_pontos_padrao") ?? "4",
    assinante_clube: (mapa.get("assinante_clube") ?? "false").toLowerCase() === "true",
  };
}

// --- Edicao (RF17). Tudo abaixo exige sessao — ver lib/sessao.ts. ---

export async function salvarPreferencias(entrada: {
  multiplicador: string;
  piso: string;
  assinanteClube: boolean;
}): Promise<void> {
  const sql = conectar();
  await sql`
    INSERT INTO preferencia (chave, valor) VALUES
      ('multiplicador_padrao', ${entrada.multiplicador}),
      ('piso_pontos_padrao', ${entrada.piso}),
      ('assinante_clube', ${entrada.assinanteClube ? "true" : "false"})
    ON CONFLICT (chave) DO UPDATE SET valor = EXCLUDED.valor
  `;
}

/** Cadastro atômico usado pela API v1: loja, regra e apelidos entram juntos. */
export async function adicionarLojaAdministrativa(entrada: {
  nome: string;
  categoria: string;
  apelidos: string[];
  multiplicador: string | null;
  piso: string | null;
}): Promise<number> {
  const sql = conectar();
  const linhas = (await sql`
    WITH nova AS (
      INSERT INTO loja (nome, categoria, multiplicador, piso_pontos)
      VALUES (${entrada.nome}, ${entrada.categoria}, ${entrada.multiplicador}, ${entrada.piso})
      RETURNING id
    ), novos_apelidos AS (
      INSERT INTO apelido (loja_id, texto)
      SELECT nova.id, valor
        FROM nova, unnest(${entrada.apelidos}::text[]) AS valor
    )
    SELECT id FROM nova
  `) as Array<{ id: number }>;
  if (!linhas[0]) throw new Error("loja nao criada");
  return linhas[0].id;
}

export async function salvarLimiarDaLojaSeExistir(
  id: number,
  multiplicador: string | null,
  piso: string | null,
): Promise<boolean> {
  const sql = conectar();
  const linhas = (await sql`
    UPDATE loja SET multiplicador = ${multiplicador}, piso_pontos = ${piso}
     WHERE id = ${id}
     RETURNING id
  `) as Array<{ id: number }>;
  return linhas.length > 0;
}

export async function removerLojaSeExistir(id: number): Promise<boolean> {
  const sql = conectar();
  const linhas = (await sql`
    UPDATE loja
       SET acompanhada = FALSE, alerta_ativo = FALSE
     WHERE id = ${id}
     RETURNING id
  `) as Array<{ id: number }>;
  return linhas.length > 0;
}

export async function categorias(): Promise<string[]> {
  const sql = conectar();
  const linhas = (await sql`
    SELECT DISTINCT categoria
      FROM loja
     WHERE acompanhada = TRUE
     ORDER BY categoria
  `) as { categoria: string }[];
  return linhas.map((l) => l.categoria);
}

// --- Limite de tentativas de login (PRD-V2 9.0, migracao 003) ---

const JANELA_MINUTOS = 15;
const TENTATIVAS_MAXIMAS = 5;

export async function tentativasRecentes(origem: string): Promise<number> {
  const sql = conectar();
  const linhas = (await sql`
    SELECT count(*)::int AS total
      FROM tentativa_login
     WHERE origem = ${origem}
       AND sucesso = FALSE
       AND momento > now() - (${JANELA_MINUTOS} || ' minutes')::interval
  `) as { total: number }[];
  return linhas[0]?.total ?? 0;
}

export async function registrarTentativa(origem: string, sucesso: boolean): Promise<void> {
  const sql = conectar();
  await sql`INSERT INTO tentativa_login (origem, sucesso) VALUES (${origem}, ${sucesso})`;
}

export const LIMITE_DE_TENTATIVAS = TENTATIVAS_MAXIMAS;
export const JANELA_DE_BLOQUEIO_MINUTOS = JANELA_MINUTOS;
