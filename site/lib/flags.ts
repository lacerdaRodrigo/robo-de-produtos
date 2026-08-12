import { cookies } from "next/headers";

/**
 * Flags de funcionalidade (V2.3.4), guardadas em cookie — mesma ideia do
 * tema (lib/tema.ts) e não da tabela `preferencia`: liga/desliga pedaço da
 * interface, não é regra de negócio, então não precisa de banco nem
 * migração pra existir.
 *
 * Hoje só tem uma. Se aparecer uma segunda, aí sim vale generalizar.
 */
const NOME_DO_COOKIE = "aviso_opcional_no_cadastro";

export async function avisoOpcionalNoCadastroLigado(): Promise<boolean> {
  return (await cookies()).get(NOME_DO_COOKIE)?.value === "1";
}

export async function definirAvisoOpcionalNoCadastro(ligado: boolean): Promise<void> {
  const armazem = await cookies();
  if (ligado) {
    armazem.set(NOME_DO_COOKIE, "1", {
      sameSite: "lax",
      path: "/",
      maxAge: 60 * 60 * 24 * 365,
    });
  } else {
    armazem.delete(NOME_DO_COOKIE);
  }
}
