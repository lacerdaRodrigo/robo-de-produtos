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
  // A selecao precisa chegar a consulta sem depender de um disparo manual
  // separado. Respeitamos o intervalo minimo para nao criar uma rodada por
  // clique quando o usuario estiver escolhendo varias lojas.
  const falta = await esperaAteProximoDisparoInter();
  let atualizacao = "pendente";
  if (falta === 0) {
    const resultado = await dispararRoboInter();
    if (resultado.ok) {
      await registrarDisparoInter();
      atualizacao = "solicitada";
    } else {
      atualizacao = resultado.motivo === "sem-token" ? "sem-token" : "falhou";
    }
  }
  revalidatePath("/inter");
  revalidatePath("/inter/lojas");
  const parametros = new URLSearchParams({ ok: "adicionada", nome, atualizacao });
  if (falta > 0) parametros.set("segundos", String(falta));
  redirect(`/inter/lojas?${parametros.toString()}`);
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
