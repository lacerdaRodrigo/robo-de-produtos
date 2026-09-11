import { NextResponse } from "next/server";

import { autenticarRequisicao } from "@/lib/autenticacao-api";
import { corpoErro, STATUS } from "@/lib/api";
import { processarOutboxAlertas } from "@/lib/banco-alertas";

/** Endpoint interno para cron; nunca expõe token ou payload pessoal. */
export async function POST(requisicao: Request) {
  const acesso = await autenticarRequisicao(requisicao, { operacao: "notificacoes.outbox.processar", papel: "admin", sensivel: true });
  if (!acesso.ok) return acesso.resposta;
  try {
    const resultado = await processarOutboxAlertas();
    return NextResponse.json(resultado, { headers: { "x-request-id": acesso.requisicaoId } });
  } catch {
    return NextResponse.json(corpoErro("inesperado", "nao foi possivel processar notificacoes"), { status: STATUS.INESPERADO, headers: { "x-request-id": acesso.requisicaoId } });
  }
}
