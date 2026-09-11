import { NextResponse } from "next/server";

import { corpoErro, STATUS } from "@/lib/api";
import {
  autorizacaoOutboxValida,
  idRequisicaoCron,
  segredoOutboxConfigurado,
} from "@/lib/cron-api";
import { processarOutboxAlertas } from "@/lib/banco-alertas";

export const runtime = "nodejs";

function cabecalhos(requisicaoId: string): Record<string, string> {
  return {
    "cache-control": "no-store",
    "x-request-id": requisicaoId,
  };
}

/** Endpoint interno do GitHub Actions; não usa a autenticação do usuário. */
export async function POST(requisicao: Request) {
  const requisicaoId = idRequisicaoCron(requisicao);
  const segredo = segredoOutboxConfigurado();
  if (!segredo) {
    return NextResponse.json(
      corpoErro("cron-nao-configurado", "processamento interno indisponivel"),
      { status: 503, headers: cabecalhos(requisicaoId) },
    );
  }
  if (!autorizacaoOutboxValida(requisicao.headers.get("authorization"), segredo)) {
    return NextResponse.json(
      corpoErro("autenticacao", "autenticacao interna obrigatoria"),
      { status: STATUS.NAO_AUTORIZADO, headers: cabecalhos(requisicaoId) },
    );
  }

  try {
    const resultado = await processarOutboxAlertas();
    return NextResponse.json(resultado, { headers: cabecalhos(requisicaoId) });
  } catch {
    return NextResponse.json(
      corpoErro("inesperado", "nao foi possivel processar notificacoes"),
      { status: STATUS.INESPERADO, headers: cabecalhos(requisicaoId) },
    );
  }
}
