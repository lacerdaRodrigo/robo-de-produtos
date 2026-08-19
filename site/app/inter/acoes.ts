"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { deixarDeAcompanharLojaInter } from "@/lib/banco-inter";
import { exigirSessao } from "@/lib/sessao";

export async function acaoRemoverInter(dados: FormData) {
  await exigirSessao();
  const id = String(dados.get("id") ?? "");
  const q = String(dados.get("q") ?? "");
  const ordenar = String(dados.get("ordenar") ?? "cashback");

  if (!id) {
    redirect("/inter");
  }

  await deixarDeAcompanharLojaInter(id);
  revalidatePath("/inter");
  revalidatePath("/inter/lojas");

  const parametros = new URLSearchParams();
  if (q) parametros.set("q", q);
  if (ordenar && ordenar !== "cashback") parametros.set("ordenar", ordenar);
  const query = parametros.toString();
  redirect(`/inter${query ? `?${query}` : ""}#lista-cashback`);
}
