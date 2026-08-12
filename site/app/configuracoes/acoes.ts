"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { definirAvisoOpcionalNoCadastro } from "@/lib/flags";
import { exigirSessao } from "@/lib/sessao";

export async function acaoSalvarConfiguracoes(dados: FormData) {
  await exigirSessao();

  await definirAvisoOpcionalNoCadastro(dados.get("aviso_opcional_no_cadastro") === "on");

  // /lojas muda de formato conforme a flag — precisa recalcular.
  revalidatePath("/lojas");
  revalidatePath("/configuracoes");
  redirect("/configuracoes?ok=salvo");
}
