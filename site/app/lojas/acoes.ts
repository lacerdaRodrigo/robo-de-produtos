"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { adicionarLoja, removerLoja } from "@/lib/banco";
import { exigirSessao } from "@/lib/sessao";

export async function acaoAdicionarLoja(dados: FormData) {
  await exigirSessao();

  const nome = String(dados.get("nome") ?? "").trim();
  const categoria = String(dados.get("categoria") ?? "").trim();
  if (!nome || !categoria) {
    redirect("/lojas?erro=nome-e-categoria");
  }

  // RN04: apelido e grafia exata, uma por linha. O banco recusa repetida
  // entre lojas — ambiguidade vira erro, nao empate silencioso.
  const apelidos = String(dados.get("apelidos") ?? "")
    .split("\n")
    .map((linha) => linha.trim())
    .filter(Boolean);

  try {
    await adicionarLoja(nome, categoria, apelidos);
  } catch {
    redirect("/lojas?erro=repetido");
  }

  revalidatePath("/lojas");
  revalidatePath("/avisos");
  revalidatePath("/");
  redirect(`/lojas?ok=adicionada&nome=${encodeURIComponent(nome)}`);
}

export async function acaoRemoverLoja(dados: FormData) {
  await exigirSessao();
  const id = Number(dados.get("id"));
  const nome = String(dados.get("nome") ?? "");

  await removerLoja(id);

  revalidatePath("/lojas");
  revalidatePath("/avisos");
  revalidatePath("/");
  redirect(`/lojas?ok=removida&nome=${encodeURIComponent(nome)}`);
}
