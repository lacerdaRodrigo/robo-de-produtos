"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { selecionarLojaDireta } from "@/lib/banco-produtos-inter";
import { exigirSessao } from "@/lib/sessao";

export async function acaoSelecionarLojaDireta(dados: FormData) {
  await exigirSessao();
  const id = String(dados.get("id") ?? "");
  const nome = String(dados.get("nome") ?? "");
  if (!id) redirect("/inter/produtos/lojas?erro=nao-achei");
  await selecionarLojaDireta(id, true);
  revalidatePath("/inter/produtos");
  revalidatePath("/inter/produtos/lojas");
  redirect(`/inter/produtos/lojas?ok=adicionada&nome=${encodeURIComponent(nome)}`);
}

export async function acaoRemoverLojaDireta(dados: FormData) {
  await exigirSessao();
  const id = String(dados.get("id") ?? "");
  const nome = String(dados.get("nome") ?? "");
  if (!id) redirect("/inter/produtos/lojas?erro=nao-achei");
  await selecionarLojaDireta(id, false);
  revalidatePath("/inter/produtos");
  revalidatePath("/inter/produtos/lojas");
  redirect(`/inter/produtos/lojas?ok=removida&nome=${encodeURIComponent(nome)}`);
}
