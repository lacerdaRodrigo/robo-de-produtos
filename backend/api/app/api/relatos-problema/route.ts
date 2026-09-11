import { NextResponse } from "next/server";

import { autenticarRequisicao } from "@/lib/autenticacao-api";
import { corpoErro, STATUS } from "@/lib/api";
import { registrarRelatoProblema } from "@/lib/banco-alertas";
import { validarRelatoProblema } from "@/lib/alertas-api";

export async function POST(requisicao: Request) {
  const acesso = await autenticarRequisicao(requisicao, { operacao: "relatos.problema.criar", sensivel: true });
  if (!acesso.ok) return acesso.resposta;
  let corpo: unknown; try { corpo = await requisicao.json(); } catch { corpo = null; }
  const entrada = validarRelatoProblema(corpo);
  if (!entrada.ok) return NextResponse.json(corpoErro("validacao", entrada.mensagem), { status: STATUS.INVALIDA, headers: { "x-request-id": acesso.requisicaoId } });
  try { const id = await registrarRelatoProblema(String(acesso.usuario.id), entrada.valor, acesso.requisicaoId); return NextResponse.json({ registrado: true, id }, { status: 201, headers: { "x-request-id": acesso.requisicaoId } }); } catch { return NextResponse.json(corpoErro("inesperado", "nao foi possivel registrar o relato"), { status: STATUS.INESPERADO, headers: { "x-request-id": acesso.requisicaoId } }); }
}
