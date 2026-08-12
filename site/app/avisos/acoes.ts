"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { salvarLimiarDaLoja, salvarPreferencias } from "@/lib/banco";
import { numeroOuPadrao } from "@/lib/formato";
import { exigirSessao } from "@/lib/sessao";

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
