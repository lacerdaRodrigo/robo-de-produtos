import { createHmac, timingSafeEqual } from "node:crypto";
import { cookies } from "next/headers";

/**
 * Sessao do site (PRD-V2 9.0).
 *
 * Senha unica, sem tabela de usuario. O trade-off foi apresentado e aceito
 * la; o que este arquivo garante sao as medidas obrigatorias que vieram
 * junto: cookie httpOnly e secure, e comparacao em tempo constante.
 *
 * O cookie carrega apenas a validade e uma assinatura HMAC dela. Nao ha nada
 * a roubar dentro dele: sem o segredo do servidor, nao da para forjar.
 */

const NOME_DO_COOKIE = "sessao";
const DURACAO_HORAS = 12;

function segredo(): string {
  const valor = process.env.SEGREDO_SESSAO;
  if (!valor) {
    throw new Error("SEGREDO_SESSAO nao configurada no ambiente do site.");
  }
  return valor;
}

function assinar(carga: string): string {
  return createHmac("sha256", segredo()).update(carga).digest("hex");
}

function iguais(a: string, b: string): boolean {
  const bufferA = Buffer.from(a);
  const bufferB = Buffer.from(b);
  // timingSafeEqual exige mesmo tamanho — comprimento diferente ja e recusa.
  return bufferA.length === bufferB.length && timingSafeEqual(bufferA, bufferB);
}

/** Compara a senha enviada com a configurada, sem vazar o tamanho pelo tempo. */
export function senhaConfere(enviada: string): boolean {
  const esperada = process.env.SENHA_SITE;
  if (!esperada) {
    throw new Error("SENHA_SITE nao configurada no ambiente do site.");
  }
  const digestEnviada = assinar(enviada);
  const digestEsperada = assinar(esperada);
  return iguais(digestEnviada, digestEsperada);
}

export async function abrirSessao(): Promise<void> {
  const expira = Date.now() + DURACAO_HORAS * 60 * 60 * 1000;
  const carga = String(expira);
  const armazem = await cookies();
  armazem.set(NOME_DO_COOKIE, `${carga}.${assinar(carga)}`, {
    httpOnly: true, // fora do alcance de qualquer script
    secure: process.env.NODE_ENV === "production", // so sobre HTTPS
    sameSite: "lax",
    path: "/",
    maxAge: DURACAO_HORAS * 60 * 60,
  });
}

export async function fecharSessao(): Promise<void> {
  const armazem = await cookies();
  armazem.delete(NOME_DO_COOKIE);
}

export async function temSessao(): Promise<boolean> {
  const bruto = (await cookies()).get(NOME_DO_COOKIE)?.value;
  if (!bruto) {
    return false;
  }
  const [carga, assinatura] = bruto.split(".");
  if (!carga || !assinatura || !iguais(assinatura, assinar(carga))) {
    return false;
  }
  return Number(carga) > Date.now();
}

/** A origem usada para contar tentativas de login. Atras da Vercel, o IP
 *  real vem em `x-forwarded-for`; sem ele, tudo vira um balde so — o que
 *  ainda limita a forca bruta, so que de forma mais grosseira. */
export function origemDaRequisicao(cabecalhos: Headers): string {
  const encaminhado = cabecalhos.get("x-forwarded-for");
  return encaminhado?.split(",")[0]?.trim() || "desconhecida";
}

/**
 * Barreira das telas de edicao.
 *
 * Toda tela e toda Server Action privada chama isto. A pagina ja barraria a
 * navegacao, mas Server Action e um endpoint: quem souber o caminho pode
 * chamar direto, sem passar por pagina nenhuma.
 */
export async function exigirSessao(): Promise<void> {
  const { redirect } = await import("next/navigation");
  if (!(await temSessao())) {
    redirect("/entrar");
  }
}
