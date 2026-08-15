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
 * `enviar_email: "false"` cala o notificador so nesta execucao — o
 * agendado continua mandando e-mail sempre. Cadastrar dez lojas numa tarde
 * geraria dez e-mails identicos, e o robo ja grava o retrato de qualquer
 * forma; o site le o resultado direto do banco.
 */

const REPOSITORIO = "lacerdaRodrigo/robo-livelo";
const RAMO = "main";

export function temTokenDeDisparo(): boolean {
  return Boolean(process.env.GITHUB_TOKEN_DISPARO);
}

export type ResultadoDoDisparo = { ok: true } | { ok: false; motivo: string };

export async function dispararRobo(): Promise<ResultadoDoDisparo> {
  return dispararWorkflow("robo.yml", { enviar_email: "false" });
}

export function temTokenDeDisparoInter(): boolean {
  return temTokenDeDisparo();
}

export async function dispararRoboInter(): Promise<ResultadoDoDisparo> {
  return dispararWorkflow("inter.yml", {});
}

async function dispararWorkflow(
  workflow: string,
  inputs: Record<string, string>,
): Promise<ResultadoDoDisparo> {
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
      // "false" como string: a API de dispatch so aceita valores de input
      // como texto, mesmo quando o workflow declara `type: boolean`.
      body: JSON.stringify({ ref: RAMO, inputs }),
    },
  );

  // 204 e a resposta de sucesso deste endpoint — ele nao devolve corpo.
  if (resposta.status === 204) {
    return { ok: true };
  }
  // A mensagem do GitHub pode conter detalhe do token; so o status sai daqui.
  return { ok: false, motivo: `github-${resposta.status}` };
}
