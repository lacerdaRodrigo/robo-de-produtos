import { NextResponse } from "next/server";

import { autenticarRequisicao } from "@/lib/autenticacao-api";
import { corpoErro, STATUS } from "@/lib/api";
import { registrarDispositivo, removerDispositivo } from "@/lib/banco-alertas";
import { validarTokenFcm } from "@/lib/alertas-api";

export async function POST(requisicao: Request) {
  const acesso = await autenticarRequisicao(requisicao, { operacao: "notificacoes.dispositivo.registrar", sensivel: true });
  if (!acesso.ok) return acesso.resposta;
  let corpo: unknown; try { corpo = await requisicao.json(); } catch { corpo = null; }
  const entrada = validarTokenFcm(corpo);
  if (!entrada.ok) return NextResponse.json(corpoErro("validacao", entrada.mensagem), { status: STATUS.INVALIDA, headers: { "x-request-id": acesso.requisicaoId } });
  try { await registrarDispositivo(String(acesso.usuario.id), entrada.valor); return NextResponse.json({ registrado: true }, { status: 201, headers: { "x-request-id": acesso.requisicaoId } }); } catch { return NextResponse.json(corpoErro("inesperado", "nao foi possivel registrar o dispositivo"), { status: STATUS.INESPERADO, headers: { "x-request-id": acesso.requisicaoId } }); }
}

export async function DELETE(requisicao: Request) {
  const acesso = await autenticarRequisicao(requisicao, { operacao: "notificacoes.dispositivo.remover", sensivel: true });
  if (!acesso.ok) return acesso.resposta;
  let corpo: unknown; try { corpo = await requisicao.json(); } catch { corpo = null; }
  const token = corpo && typeof corpo === "object" && !Array.isArray(corpo) ? (corpo as Record<string, unknown>).token : null;
  if (typeof token !== "string" || token.trim().length < 20 || token.length > 4096) return NextResponse.json(corpoErro("validacao", "token invalido"), { status: STATUS.INVALIDA, headers: { "x-request-id": acesso.requisicaoId } });
  try { await removerDispositivo(String(acesso.usuario.id), token.trim()); return NextResponse.json({ removido: true }, { headers: { "x-request-id": acesso.requisicaoId } }); } catch { return NextResponse.json(corpoErro("inesperado", "nao foi possivel remover o dispositivo"), { status: STATUS.INESPERADO, headers: { "x-request-id": acesso.requisicaoId } }); }
}
