import { cookies } from "next/headers";

/**
 * Tema claro/escuro/automático (V2.3.3).
 *
 * Sem cookie, o site segue `prefers-color-scheme` do sistema — é o padrão,
 * não uma escolha gravada. O cookie só existe quando a pessoa pediu
 * explicitamente para fugir do automático, e guarda só isso: nenhum dado
 * sensível, então não precisa de assinatura como o cookie de sessão.
 */
const NOME_DO_COOKIE = "tema";
const CICLO = ["auto", "claro", "escuro"] as const;

export type Tema = (typeof CICLO)[number];

export async function temaAtual(): Promise<Tema> {
  const valor = (await cookies()).get(NOME_DO_COOKIE)?.value;
  return valor === "claro" || valor === "escuro" ? valor : "auto";
}

/** Botão único cicla: automático → claro → escuro → automático. */
export function proximoTema(atual: Tema): Tema {
  const indice = CICLO.indexOf(atual);
  return CICLO[(indice + 1) % CICLO.length];
}

export async function definirTema(tema: Tema): Promise<void> {
  const armazem = await cookies();
  if (tema === "auto") {
    armazem.delete(NOME_DO_COOKIE);
    return;
  }
  armazem.set(NOME_DO_COOKIE, tema, {
    sameSite: "lax",
    path: "/",
    maxAge: 60 * 60 * 24 * 365,
  });
}
