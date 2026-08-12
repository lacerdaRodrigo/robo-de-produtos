"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import {
  adicionarLoja,
  removerLoja,
  salvarLimiarDaLoja,
  salvarPreferencias,
} from "@/lib/banco";
import { fecharSessao, temSessao } from "@/lib/sessao";

/** Toda acao confere a sessao de novo. O `layout` do /admin ja barra a
 *  navegacao, mas Server Action e um endpoint: quem souber o caminho pode
 *  chamar direto, sem passar por pagina nenhuma. */
async function exigirSessao() {
  if (!(await temSessao())) {
    redirect("/entrar");
  }
}

/** Campo vazio significa "usa o padrao global" (RN28) — mesma semantica do
 *  NULL na coluna. Zero e texto vazio nao podem ser confundidos, por isso a
 *  string vazia vira `null` e nao `"0"`. */
function limiarOuPadrao(valor: FormDataEntryValue | null): string | null {
  const texto = String(valor ?? "").trim().replace(",", ".");
  if (!texto) {
    return null;
  }
  if (Number.isNaN(Number(texto))) {
    throw new Error(`Limiar invalido: ${texto}`);
  }
  return texto;
}

export async function acaoSalvarPreferencias(dados: FormData) {
  await exigirSessao();
  const multiplicador = limiarOuPadrao(dados.get("multiplicador"));
  const piso = limiarOuPadrao(dados.get("piso"));
  if (!multiplicador || !piso) {
    redirect("/admin?erro=padrao-obrigatorio");
  }
  await salvarPreferencias({
    multiplicador,
    piso,
    assinanteClube: dados.get("assinante_clube") === "on",
  });
  revalidatePath("/admin");
  revalidatePath("/");
  redirect("/admin?ok=preferencias");
}

export async function acaoSalvarLoja(dados: FormData) {
  await exigirSessao();
  const id = Number(dados.get("id"));
  await salvarLimiarDaLoja(
    id,
    limiarOuPadrao(dados.get("multiplicador")),
    limiarOuPadrao(dados.get("piso")),
  );
  revalidatePath("/admin");
  revalidatePath("/");
  redirect("/admin?ok=loja");
}

export async function acaoAdicionarLoja(dados: FormData) {
  await exigirSessao();
  const nome = String(dados.get("nome") ?? "").trim();
  const categoria = String(dados.get("categoria") ?? "").trim();
  if (!nome || !categoria) {
    redirect("/admin?erro=nome-e-categoria");
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
    redirect("/admin?erro=nome-ou-apelido-repetido");
  }
  revalidatePath("/admin");
  revalidatePath("/");
  redirect("/admin?ok=adicionada");
}

export async function acaoRemoverLoja(dados: FormData) {
  await exigirSessao();
  await removerLoja(Number(dados.get("id")));
  revalidatePath("/admin");
  revalidatePath("/");
  redirect("/admin?ok=removida");
}

export async function acaoSair() {
  await exigirSessao();
  await fecharSessao();
  redirect("/");
}
