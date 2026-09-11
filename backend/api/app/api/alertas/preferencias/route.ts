import { NextResponse } from "next/server";

import { autenticarRequisicao } from "@/lib/autenticacao-api";
import { corpoErro, STATUS } from "@/lib/api";
import { lerPreferenciasAlertas, salvarPreferenciasAlertas } from "@/lib/banco-alertas";
import { validarPreferenciasAlertas } from "@/lib/alertas-api";

export async function GET(requisicao: Request) {
  const acesso = await autenticarRequisicao(requisicao, { operacao: "alertas.preferencias.ler" });
  if (!acesso.ok) return acesso.resposta;
  try { return NextResponse.json(await lerPreferenciasAlertas(String(acesso.usuario.id)), { headers: { "x-request-id": acesso.requisicaoId } }); } catch { return NextResponse.json(corpoErro("inesperado", "nao foi possivel carregar as preferencias"), { status: STATUS.INESPERADO, headers: { "x-request-id": acesso.requisicaoId } }); }
}

export async function PATCH(requisicao: Request) {
  const acesso = await autenticarRequisicao(requisicao, { operacao: "alertas.preferencias.salvar", sensivel: true });
  if (!acesso.ok) return acesso.resposta;
  let corpo: unknown; try { corpo = await requisicao.json(); } catch { corpo = null; }
  const entrada = validarPreferenciasAlertas(corpo);
  if (!entrada.ok) return NextResponse.json(corpoErro("validacao", entrada.mensagem), { status: STATUS.INVALIDA, headers: { "x-request-id": acesso.requisicaoId } });
  try { return NextResponse.json(await salvarPreferenciasAlertas(String(acesso.usuario.id), entrada.valor), { headers: { "x-request-id": acesso.requisicaoId } }); } catch { return NextResponse.json(corpoErro("inesperado", "nao foi possivel salvar as preferencias"), { status: STATUS.INESPERADO, headers: { "x-request-id": acesso.requisicaoId } }); }
}
