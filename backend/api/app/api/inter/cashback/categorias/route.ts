import { NextResponse } from "next/server";

import { autenticarRequisicao } from "@/lib/autenticacao-api";
import { listarCategoriasCashbackInter } from "@/lib/banco-inter";
import { corpoErro, STATUS } from "@/lib/api";

/** Categorias editoriais disponíveis para o filtro de Sites parceiros. */
export async function GET(requisicao: Request) {
  const acesso = await autenticarRequisicao(requisicao, { operacao: "inter.cashback.ler" });
  if (!acesso.ok) return acesso.resposta;

  try {
    return NextResponse.json(
      { categorias: await listarCategoriasCashbackInter() },
      { headers: { "x-request-id": acesso.requisicaoId } },
    );
  } catch {
    return NextResponse.json(
      corpoErro("inesperado", "nao foi possivel carregar as categorias"),
      {
        status: STATUS.INESPERADO,
        headers: { "x-request-id": acesso.requisicaoId },
      },
    );
  }
}
