"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { selecionarLojaDireta } from "@/lib/banco-produtos-inter";
import { exigirSessao } from "@/lib/sessao";

function destinoDepoisDaAcao(dados: FormData, ok: "adicionada" | "removida", nome: string) {
  const parametros = new URLSearchParams({ ok, nome });
  const busca = String(dados.get("q") ?? "").trim();
  const pagina = Number.parseInt(String(dados.get("pagina") ?? ""), 10);

  if (busca) {
    parametros.set("q", busca);
  }
  if (Number.isFinite(pagina) && pagina > 1) {
    parametros.set("pagina", String(pagina));
  }

  return `/inter/produtos/lojas?${parametros.toString()}`;
}

export async function acaoSelecionarLojaDireta(dados: FormData) {
  await exigirSessao();
  const id = String(dados.get("id") ?? "");
  const nome = String(dados.get("nome") ?? "");
  if (!id) redirect("/inter/produtos/lojas?erro=nao-achei");
  await selecionarLojaDireta(id, true);
  revalidatePath("/inter/produtos");
  revalidatePath("/inter/produtos/lojas");
  redirect(destinoDepoisDaAcao(dados, "adicionada", nome));
}

export async function acaoRemoverLojaDireta(dados: FormData) {
  await exigirSessao();
  const id = String(dados.get("id") ?? "");
  const nome = String(dados.get("nome") ?? "");
  if (!id) redirect("/inter/produtos/lojas?erro=nao-achei");
  await selecionarLojaDireta(id, false);
  revalidatePath("/inter/produtos");
  revalidatePath("/inter/produtos/lojas");
  redirect(destinoDepoisDaAcao(dados, "removida", nome));
}
