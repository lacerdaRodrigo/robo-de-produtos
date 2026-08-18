"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import {
  adicionarLoja,
  adicionarLojaDescoberta,
  esperaAteProximoDisparo,
  registrarDisparo,
  removerLoja,
  salvarLimiarDaLoja,
} from "@/lib/banco";
import { dispararRobo } from "@/lib/github";
import { numeroOuPadrao } from "@/lib/formato";
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

  // Aviso proprio e opcional (RN28): campo vazio segue o padrao global, sem
  // forcar quem so quer testar o cadastro a decidir um limiar agora.
  let multiplicador: string | null;
  let piso: string | null;
  try {
    multiplicador = numeroOuPadrao(dados.get("multiplicador"));
    piso = numeroOuPadrao(dados.get("piso"));
  } catch {
    redirect("/lojas?erro=numero");
  }
  if (multiplicador !== null && Number(multiplicador) <= 0) {
    redirect("/lojas?erro=numero");
  }

  let id: number;
  try {
    id = await adicionarLoja(nome, categoria, apelidos);
  } catch {
    redirect("/lojas?erro=repetido");
  }

  if (multiplicador !== null || piso !== null) {
    await salvarLimiarDaLoja(id, multiplicador, piso);
  }

  revalidatePath("/lojas");
  revalidatePath("/avisos");
  revalidatePath("/");
  redirect(`/lojas?ok=adicionada&nome=${encodeURIComponent(nome)}`);
}

export async function acaoAdicionarLojaDescoberta(dados: FormData) {
  await exigirSessao();
  const id = Number(dados.get("id"));
  if (!Number.isInteger(id) || id <= 0) redirect("/lojas?erro=nao-achei");
  await adicionarLojaDescoberta(id);
  revalidatePath("/lojas");
  revalidatePath("/");
  redirect("/lojas?ok=adicionada");
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

export async function acaoAtualizarAgora() {
  await exigirSessao();

  // RNF02 antes de qualquer coisa: a trava vale mesmo que o GitHub aceitasse.
  const falta = await esperaAteProximoDisparo();
  if (falta > 0) {
    redirect(`/lojas?erro=espere&segundos=${falta}`);
  }

  const resultado = await dispararRobo();
  if (!resultado.ok) {
    redirect(`/lojas?erro=${resultado.motivo === "sem-token" ? "sem-token" : "disparo"}`);
  }

  // Registrado depois do sucesso: pedido recusado pelo GitHub não deve
  // consumir a sua janela de cinco minutos.
  await registrarDisparo();
  redirect("/lojas?ok=disparado");
}
