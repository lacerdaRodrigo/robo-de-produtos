import { NextResponse } from "next/server";

import { autenticarRequisicao } from "@/lib/autenticacao-api";
import { corpoErro, STATUS } from "@/lib/api";
import { marcarAlerta } from "@/lib/banco-alertas";
import { idNumerico } from "@/lib/alertas-api";

export async function PATCH(requisicao: Request, contexto: { params: Promise<{ id: string }> }) {
  const acesso = await autenticarRequisicao(requisicao, { operacao: "alertas.leitura.individual", sensivel: true });
  if (!acesso.ok) return acesso.resposta;
  const id = (await contexto.params).id;
  if (idNumerico(id) === null) return NextResponse.json(corpoErro("validacao", "id de alerta invalido"), { status: STATUS.INVALIDA, headers: { "x-request-id": acesso.requisicaoId } });
  let corpo: unknown;
  try { corpo = await requisicao.json(); } catch { corpo = null; }
  const lido = corpo && typeof corpo === "object" && !Array.isArray(corpo) ? (corpo as Record<string, unknown>).lido : null;
  if (typeof lido !== "boolean") return NextResponse.json(corpoErro("validacao", "lido deve ser booleano"), { status: STATUS.INVALIDA, headers: { "x-request-id": acesso.requisicaoId } });
  try {
    const ok = await marcarAlerta(String(acesso.usuario.id), id, lido);
    if (!ok) return NextResponse.json(corpoErro("nao-achei", "alerta nao encontrado"), { status: STATUS.NAO_ACHEI, headers: { "x-request-id": acesso.requisicaoId } });
    return NextResponse.json({ id, lido }, { headers: { "x-request-id": acesso.requisicaoId } });
  } catch {
    return NextResponse.json(corpoErro("inesperado", "nao foi possivel atualizar o alerta"), { status: STATUS.INESPERADO, headers: { "x-request-id": acesso.requisicaoId } });
  }
}
