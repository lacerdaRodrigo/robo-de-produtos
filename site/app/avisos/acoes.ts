"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { salvarLimiarDaLoja, salvarPreferencias } from "@/lib/banco";
import { exigirSessao } from "@/lib/sessao";

/**
 * Campo vazio significa "usa o padrao global" (RN28) — mesma semantica do
 * NULL na coluna. Zero e vazio nao podem se confundir, por isso a string
 * vazia vira `null` e nunca `"0"`.
 *
 * Aceita virgula porque teclado de celular em portugues oferece virgula.
 */
function numeroOuPadrao(valor: FormDataEntryValue | null): string | null {
  const texto = String(valor ?? "").trim().replace(",", ".");
  if (!texto) {
    return null;
  }
  const numero = Number(texto);
  if (Number.isNaN(numero) || numero < 0) {
    throw new Error(`valor invalido: ${texto}`);
  }
  return texto;
}

export async function acaoSalvarPadroes(dados: FormData) {
  await exigirSessao();

  let multiplicador: string | null;
  let piso: string | null;
  try {
    multiplicador = numeroOuPadrao(dados.get("multiplicador"));
    piso = numeroOuPadrao(dados.get("piso"));
  } catch {
    redirect("/avisos?erro=numero");
  }

  if (!multiplicador || !piso || Number(multiplicador) <= 0) {
    redirect("/avisos?erro=padrao-obrigatorio");
  }

  await salvarPreferencias({
    multiplicador,
    piso,
    assinanteClube: dados.get("assinante_clube") === "on",
  });
  revalidatePath("/avisos");
  revalidatePath("/");
  redirect("/avisos?ok=padroes");
}

export async function acaoSalvarExcecao(dados: FormData) {
  await exigirSessao();
  const id = Number(dados.get("id"));

  let multiplicador: string | null;
  let piso: string | null;
  try {
    multiplicador = numeroOuPadrao(dados.get("multiplicador"));
    piso = numeroOuPadrao(dados.get("piso"));
  } catch {
    redirect("/avisos?erro=numero");
  }
  if (multiplicador !== null && Number(multiplicador) <= 0) {
    redirect("/avisos?erro=numero");
  }

  await salvarLimiarDaLoja(id, multiplicador, piso);
  revalidatePath("/avisos");
  revalidatePath("/");
  // Os dois campos vazios significam "volta a seguir o padrao": a excecao
  // deixa de existir, e o recado precisa dizer isso.
  redirect(`/avisos?ok=${multiplicador === null && piso === null ? "removida" : "excecao"}`);
}
