"use server";

import { redirect } from "next/navigation";

import { destinoSeguro, fecharSessao } from "@/lib/sessao";
import { definirTema, proximoTema, temaAtual } from "@/lib/tema";

/** Sair vale de qualquer tela, entao a acao mora na raiz e nao numa pasta. */
export async function acaoSair() {
  await fecharSessao();
  redirect("/");
}

/** Tambem vale de qualquer tela — o botao fica no cabecalho, ao lado de
 *  Entrar/Sair, e devolve para a mesma pagina de onde foi chamado. */
export async function acaoAlternarTema(dados: FormData) {
  await definirTema(proximoTema(await temaAtual()));
  redirect(destinoSeguro(String(dados.get("voltar") ?? "")));
}
