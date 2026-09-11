import { NextResponse } from "next/server";

import { autenticarRequisicao } from "@/lib/autenticacao-api";
import { corpoErro, STATUS } from "@/lib/api";
import { alterarAcompanhamentoPessoal, entidadeAcompanhavelExiste } from "@/lib/banco-alertas";
import { idNumerico } from "@/lib/alertas-api";

type Origem = "livelo" | "inter_cashback" | "inter_produto";
function origem(valor: unknown): Origem | null {
  return valor === "livelo" || valor === "inter_cashback" || valor === "inter_produto" ? valor : null;
}

export async function PATCH(requisicao: Request) {
  const acesso = await autenticarRequisicao(requisicao, { operacao: "alertas.acompanhamento", sensivel: true });
  if (!acesso.ok) return acesso.resposta;
  let corpo: unknown; try { corpo = await requisicao.json(); } catch { corpo = null; }
  const objeto = corpo && typeof corpo === "object" && !Array.isArray(corpo) ? corpo as Record<string, unknown> : null;
  const origemEntrada = origem(objeto?.origem);
  const entidadeId = typeof objeto?.entidade_id === "string" ? objeto.entidade_id : String(objeto?.entidade_id ?? "");
  if (!origemEntrada || idNumerico(entidadeId) === null || typeof objeto?.ativo !== "boolean") {
    return NextResponse.json(corpoErro("validacao", "acompanhamento invalido"), { status: STATUS.INVALIDA, headers: { "x-request-id": acesso.requisicaoId } });
  }
  try {
    if (!(await entidadeAcompanhavelExiste(origemEntrada, entidadeId))) return NextResponse.json(corpoErro("nao-achei", "item nao encontrado"), { status: STATUS.NAO_ACHEI, headers: { "x-request-id": acesso.requisicaoId } });
    await alterarAcompanhamentoPessoal(String(acesso.usuario.id), origemEntrada, entidadeId, objeto.ativo as boolean);
    return NextResponse.json({ origem: origemEntrada, entidade_id: entidadeId, ativo: objeto.ativo }, { headers: { "x-request-id": acesso.requisicaoId } });
  } catch {
    return NextResponse.json(corpoErro("inesperado", "nao foi possivel alterar o acompanhamento"), { status: STATUS.INESPERADO, headers: { "x-request-id": acesso.requisicaoId } });
  }
}
