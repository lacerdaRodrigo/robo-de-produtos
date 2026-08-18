"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import {
  definirAvisoOpcionalNoCadastroEscondido,
  definirTelaDeAlertasEscondida,
} from "@/lib/flags";
import { fraseDaLimpezaConfere } from "@/lib/confirmacao-limpeza";
import { apagarDadosLivelo, resetarDadosInter } from "@/lib/limpeza";
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

async function executarLimpeza(dados: FormData, dominio: "livelo" | "inter"): Promise<never> {
  await exigirSessao();
  const frase = String(dados.get("frase") ?? "");
  if (!fraseDaLimpezaConfere(dominio, frase)) {
    redirect("/configuracoes/limpeza/" + dominio + "?erro=frase");
  }

  try {
    if (dominio === "livelo") {
      await apagarDadosLivelo();
    } else {
      await resetarDadosInter();
    }
  } catch {
    redirect("/configuracoes/limpeza/" + dominio + "?erro=banco");
  }

  if (dominio === "livelo") {
    revalidatePath("/");
    revalidatePath("/lojas");
    revalidatePath("/avisos");
    redirect("/configuracoes?ok=livelo-apagada");
  }

  revalidatePath("/inter");
  revalidatePath("/inter/lojas");
  revalidatePath("/inter/produtos");
  revalidatePath("/inter/produtos/lojas");
  redirect("/configuracoes?ok=inter-resetado");
}

export async function acaoApagarDadosLivelo(dados: FormData) {
  return executarLimpeza(dados, "livelo");
}

export async function acaoResetarDadosInter(dados: FormData) {
  return executarLimpeza(dados, "inter");
}
