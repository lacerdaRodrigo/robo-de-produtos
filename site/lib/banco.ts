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

/** RN26: o carimbo da pagina. Sem execucao registrada, a pagina diz isso em
 *  vez de fingir que esta atualizada. */
export async function ultimaExecucao(): Promise<Execucao | null> {
  const sql = conectar();
  const linhas = (await sql`
    SELECT id, momento, parceiros_lidos, alertas, versao
      FROM execucao
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
    SELECT p.nome, l.categoria, p.pontos_atuais, p.pontos_base, p.pontos_clube,
           p.valor_de_disparo, p.moeda, p.prefixo_ate, p.em_promocao, p.alertou,
           p.campanha, p.descricao_campanha, p.fim_promocao, p.link,
           l.multiplicador, l.piso_pontos
      FROM pontuacao p
      LEFT JOIN loja l ON l.id = p.loja_id
     WHERE p.execucao_id = ${execucaoId}
     ORDER BY l.categoria NULLS LAST, p.alertou DESC, p.pontos_atuais DESC NULLS LAST, p.nome
  `) as PontuacaoDeLoja[];
}

/** Só as lojas com regra própria (RN28). A tela de avisos mostra estas, e
 *  não as 132 — pedir 132 decisões é o erro que o PRD-V2 §6.1 alerta. */
export async function lojasComExcecao(): Promise<Loja[]> {
  const sql = conectar();
  return (await sql`
    SELECT l.id, l.nome, l.categoria, l.multiplicador, l.piso_pontos,
           ARRAY[]::TEXT[] AS apelidos
     FROM loja l
     WHERE l.favorita = TRUE
       AND (l.multiplicador IS NOT NULL OR l.piso_pontos IS NOT NULL)
     ORDER BY l.nome
  `) as Loja[];
}

export async function loja(id: number): Promise<Loja | null> {
  const sql = conectar();
  const linhas = (await sql`
    SELECT l.id, l.nome, l.categoria, l.multiplicador, l.piso_pontos,
           COALESCE(ARRAY_AGG(a.texto) FILTER (WHERE a.texto IS NOT NULL), ARRAY[]::TEXT[])
               AS apelidos
     FROM loja l
     LEFT JOIN apelido a ON a.loja_id = l.id
     WHERE l.id = ${id} AND l.favorita = TRUE
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
     WHERE l.favorita = TRUE
     GROUP BY l.id
     ORDER BY l.categoria, l.nome
  `) as Loja[];
}

export async function lojasDescobertas(): Promise<Loja[]> {
  const sql = conectar();
  return (await sql`
    SELECT id, nome, categoria, multiplicador, piso_pontos, ARRAY[]::TEXT[] AS apelidos
      FROM loja
     WHERE favorita = FALSE
     ORDER BY nome
  `) as Loja[];
}

export async function adicionarLojaDescoberta(id: number): Promise<void> {
  const sql = conectar();
  await sql`UPDATE loja SET favorita = TRUE WHERE id = ${id}`;
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

/** `null` nos limiares significa "usa o padrao global" (RN28) — a mesma
 *  semantica do NULL na coluna e do `None` no robo. */
export async function salvarLimiarDaLoja(
  id: number,
  multiplicador: string | null,
  piso: string | null,
): Promise<void> {
  const sql = conectar();
  await sql`
    UPDATE loja SET multiplicador = ${multiplicador}, piso_pontos = ${piso}
     WHERE id = ${id}
  `;
}

export async function adicionarLoja(
  nome: string,
  categoria: string,
  apelidos: string[],
): Promise<number> {
  const sql = conectar();
  const linhas = (await sql`
    INSERT INTO loja (nome, categoria) VALUES (${nome}, ${categoria})
    RETURNING id
  `) as { id: number }[];

  // RN04: apelido e unico entre TODAS as lojas. A restricao mora no banco,
  // entao grafia repetida vira erro aqui e nao ambiguidade silenciosa.
  for (const apelido of apelidos) {
    await sql`INSERT INTO apelido (loja_id, texto) VALUES (${linhas[0].id}, ${apelido})`;
  }

  return linhas[0].id;
}

export async function removerLoja(id: number): Promise<void> {
  const sql = conectar();
  await sql`DELETE FROM loja WHERE id = ${id}`;
}

export async function categorias(): Promise<string[]> {
  const sql = conectar();
  const linhas = (await sql`
      SELECT DISTINCT categoria FROM loja WHERE favorita = TRUE ORDER BY categoria
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

// --- Disparo manual do robô (RNF02, migração 004) ---

/** RNF02: intervalo mínimo entre pedidos manuais. O projeto se propõe a bater
 *  na página da Livelo poucas vezes por dia, e um botão sem trava
 *  transformaria isso em dezenas de requisições numa tarde de cadastro. */
export const INTERVALO_MINIMO_MINUTOS = 5;

/** Segundos que ainda faltam para o próximo disparo poder acontecer.
 *  Zero significa liberado. */
export async function esperaAteProximoDisparo(): Promise<number> {
  const sql = conectar();
  const linhas = (await sql`
    SELECT GREATEST(
             0,
             CEIL(EXTRACT(EPOCH FROM (
               momento + (${INTERVALO_MINIMO_MINUTOS} || ' minutes')::interval - now()
             )))
           )::int AS falta
      FROM disparo_manual
     ORDER BY momento DESC
     LIMIT 1
  `) as { falta: number }[];
  return linhas[0]?.falta ?? 0;
}

export async function registrarDisparo(): Promise<void> {
  const sql = conectar();
  await sql`INSERT INTO disparo_manual DEFAULT VALUES`;
}
