import { NextResponse } from "next/server";

import { autenticarRequisicao } from "@/lib/autenticacao-api";
import { corpoErro, STATUS } from "@/lib/api";
import { carregarResumoInicio } from "@/lib/resumo-inicio";

/** GET /api/v1/resumo — retrato agregado local para o Início do Flutter. */
export async function GET(requisicao: Request) {
  const acesso = await autenticarRequisicao(requisicao, { operacao: "resumo.ler" });
  if (!acesso.ok) return acesso.resposta;

  try {
    const resumo = await carregarResumoInicio();
    return NextResponse.json(resumo, {
      headers: {
        "cache-control": "no-store, max-age=0",
        "x-request-id": acesso.requisicaoId,
      },
    });
  } catch {
    return NextResponse.json(corpoErro("inesperado", "nao foi possivel carregar o resumo"), {
      status: STATUS.INESPERADO,
      headers: { "x-request-id": acesso.requisicaoId },
    });
  }
}
