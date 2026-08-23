import { NextResponse } from "next/server";

import { autenticarRequisicao } from "@/lib/autenticacao-api";
import { carregarResumoInicio } from "@/lib/resumo-inicio";

/** GET /api/v1/resumo — retrato agregado local para o Início do Flutter. */
export async function GET(requisicao: Request) {
  const acesso = await autenticarRequisicao(requisicao, { operacao: "resumo.ler" });
  if (!acesso.ok) return acesso.resposta;

  const resumo = await carregarResumoInicio();
  return NextResponse.json(resumo, {
    headers: { "x-request-id": acesso.requisicaoId },
  });
}
