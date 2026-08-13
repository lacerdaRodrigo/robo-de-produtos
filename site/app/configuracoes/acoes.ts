"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import {
  definirAvisoOpcionalNoCadastroEscondido,
  definirTelaDeAlertasEscondida,
} from "@/lib/flags";
import { exigirSessao } from "@/lib/sessao";

export async function acaoSalvarConfiguracoes(dados: FormData) {
  await exigirSessao();

  await definirAvisoOpcionalNoCadastroEscondido(dados.get("aviso_opcional_no_cadastro") === "on");
  await definirTelaDeAlertasEscondida(dados.get("esconder_tela_alertas") === "on");

  // /lojas muda de formato e /avisos pode ficar inacessível — precisa
  // recalcular, e o Painel também (some o botão "Ajustar alerta").
  revalidatePath("/lojas");
  revalidatePath("/avisos");
  revalidatePath("/");
  revalidatePath("/configuracoes");
  redirect("/configuracoes?ok=salvo");
}
