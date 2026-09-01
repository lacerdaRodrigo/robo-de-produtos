/**
 * Pede ao GitHub que rode o robo agora (RF13: disparo manual).
 *
 * Por que passar pelo Actions em vez de o site ler a Livelo: a Vercel roda
 * JavaScript e o robo e Python. Reimplementar a leitura aqui duplicaria RN21,
 * RN23 e RN27 em duas linguagens — duas fontes da verdade para a mesma regra
 * e como se cria divergencia silenciosa. O site pede, o robo executa.
 *
 * O token vive so no servidor, como a DATABASE_URL. Nada aqui tem prefixo
 * NEXT_PUBLIC_, entao nada chega ao navegador.
 *
 * Tanto o disparo manual quanto o agendado executam a mesma coleta e gravam
 * o retrato no Postgres. A API le o resultado direto do banco.
 */

const REPOSITORIO = "lacerdaRodrigo/robo-de-produtos";
const RAMO = "main";

export function temTokenDeDisparo(): boolean {
  return Boolean(process.env.GITHUB_TOKEN_DISPARO);
}

export type ResultadoDoDisparo = { ok: true } | { ok: false; motivo: string };

export async function dispararRobo(): Promise<ResultadoDoDisparo> {
  return dispararWorkflow("robo.yml");
}

export function temTokenDeDisparoInter(): boolean {
  return temTokenDeDisparo();
}

export async function dispararRoboInter(): Promise<ResultadoDoDisparo> {
  return dispararWorkflow("inter.yml");
}

async function dispararWorkflow(workflow: string): Promise<ResultadoDoDisparo> {
  const token = process.env.GITHUB_TOKEN_DISPARO;
  if (!token) {
    return { ok: false, motivo: "sem-token" };
  }

  const resposta = await fetch(
    `https://api.github.com/repos/${REPOSITORIO}/actions/workflows/${workflow}/dispatches`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        Accept: "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ ref: RAMO }),
    },
  );

  // 204 e a resposta de sucesso deste endpoint — ele nao devolve corpo.
  if (resposta.status === 204) {
    return { ok: true };
  }
  // A mensagem do GitHub pode conter detalhe do token; so o status sai daqui.
  return { ok: false, motivo: `github-${resposta.status}` };
}
