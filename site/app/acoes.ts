"use server";

import { redirect } from "next/navigation";

import { fecharSessao } from "@/lib/sessao";

/** Sair vale de qualquer tela, entao a acao mora na raiz e nao numa pasta. */
export async function acaoSair() {
  await fecharSessao();
  redirect("/");
}
