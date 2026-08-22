import { NextResponse } from "next/server";

import { validarPreferenciasLivelo } from "@/lib/administracao-api";
import { autenticarRequisicao } from "@/lib/autenticacao-api";
import { corpoErro, STATUS } from "@/lib/api";
import { preferencias, salvarPreferencias } from "@/lib/banco";

export async function GET(requisicao: Request) {
  const acesso = await autenticarRequisicao(requisicao, {
    operacao: "livelo.preferencias.ler",
    papel: "admin",
  });
  if (!acesso.ok) return acesso.resposta;
  try {
    return NextResponse.json(await preferencias(), {
      headers: { "x-request-id": acesso.requisicaoId },
    });
  } catch {
    return NextResponse.json(corpoErro("inesperado", "nao foi possivel carregar as preferencias"), {
      status: STATUS.INESPERADO,
      headers: { "x-request-id": acesso.requisicaoId },
    });
  }
}

export async function PATCH(requisicao: Request) {
  const acesso = await autenticarRequisicao(requisicao, {
    operacao: "livelo.preferencias.salvar",
    papel: "admin",
    sensivel: true,
  });
  if (!acesso.ok) return acesso.resposta;
  let corpo: unknown;
  try {
    corpo = await requisicao.json();
  } catch {
    corpo = null;
  }
  const entrada = validarPreferenciasLivelo(corpo);
  if (!entrada.ok) {
    return NextResponse.json(corpoErro("validacao", entrada.mensagem), {
      status: STATUS.INVALIDA,
      headers: { "x-request-id": acesso.requisicaoId },
    });
  }
  try {
    await salvarPreferencias(entrada.valor);
    return NextResponse.json({
      multiplicador_padrao: entrada.valor.multiplicador,
      piso_pontos_padrao: entrada.valor.piso,
      assinante_clube: entrada.valor.assinanteClube,
    }, { headers: { "x-request-id": acesso.requisicaoId } });
  } catch {
    return NextResponse.json(corpoErro("inesperado", "nao foi possivel salvar as preferencias"), {
      status: STATUS.INESPERADO,
      headers: { "x-request-id": acesso.requisicaoId },
    });
  }
}
