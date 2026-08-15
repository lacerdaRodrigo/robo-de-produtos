"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import {
  acompanharLojaInter,
  deixarDeAcompanharLojaInter,
  esperaAteProximoDisparoInter,
  registrarDisparoInter,
} from "@/lib/banco-inter";
import { dispararRoboInter } from "@/lib/github";
import { exigirSessao } from "@/lib/sessao";

export async function acaoAcompanharInter(dados: FormData) {
  await exigirSessao();
  const id = String(dados.get("id") ?? "");
  const nome = String(dados.get("nome") ?? "");
  if (!id) {
    redirect("/inter/lojas?erro=nao-achei");
  }
  await acompanharLojaInter(id);
  revalidatePath("/inter");
  revalidatePath("/inter/lojas");
  redirect(`/inter/lojas?ok=adicionada&nome=${encodeURIComponent(nome)}`);
}

export async function acaoRemoverInter(dados: FormData) {
  await exigirSessao();
  const id = String(dados.get("id") ?? "");
  const nome = String(dados.get("nome") ?? "");
  if (!id) {
    redirect("/inter/lojas?erro=nao-achei");
  }
  await deixarDeAcompanharLojaInter(id);
  revalidatePath("/inter");
  revalidatePath("/inter/lojas");
  redirect(`/inter/lojas?ok=removida&nome=${encodeURIComponent(nome)}`);
}

export async function acaoAtualizarInter() {
  await exigirSessao();
  const falta = await esperaAteProximoDisparoInter();
  if (falta > 0) {
    redirect(`/inter/lojas?erro=espere&segundos=${falta}`);
  }
  const resultado = await dispararRoboInter();
  if (!resultado.ok) {
    redirect(
      `/inter/lojas?erro=${resultado.motivo === "sem-token" ? "sem-token" : "disparo"}`,
    );
  }
  await registrarDisparoInter();
  redirect("/inter/lojas?ok=disparado");
}
