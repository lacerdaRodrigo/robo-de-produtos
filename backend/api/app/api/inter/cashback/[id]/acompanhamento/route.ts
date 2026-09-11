import { NextResponse } from "next/server";

import { autenticarRequisicao } from "@/lib/autenticacao-api";
import { corpoErro, STATUS } from "@/lib/api";
import {
  alterarAcompanhamentoPessoal,
  entidadeAcompanhavelIdPorChave,
} from "@/lib/banco-alertas";

type Contexto = { params: Promise<{ id: string }> };

/** PATCH autenticado para acompanhamento individual de uma loja Inter. */
export async function PATCH(requisicao: Request, contexto: Contexto) {
  const acesso = await autenticarRequisicao(requisicao, {
    operacao: "alertas.acompanhamento.inter_cashback",
    sensivel: true,
  });
  if (!acesso.ok) return acesso.resposta;

  const id = (await contexto.params).id.trim();
  let corpo: unknown;
  try { corpo = await requisicao.json(); } catch { corpo = null; }
  const ativo = corpo && typeof corpo === "object" && !Array.isArray(corpo)
    ? (corpo as Record<string, unknown>).ativo
    : null;
  if (!/^\d+$/.test(id) || typeof ativo !== "boolean") {
    return NextResponse.json(corpoErro("validacao", "acompanhamento invalido"), {
      status: STATUS.INVALIDA,
      headers: { "x-request-id": acesso.requisicaoId },
    });
  }

  try {
    const entidadeId = await entidadeAcompanhavelIdPorChave("inter_cashback", id);
    if (!entidadeId) {
      return NextResponse.json(corpoErro("nao-achei", "loja nao encontrada"), {
        status: STATUS.NAO_ACHEI,
        headers: { "x-request-id": acesso.requisicaoId },
      });
    }
    await alterarAcompanhamentoPessoal(
      String(acesso.usuario.id),
      "inter_cashback",
      entidadeId,
      ativo,
    );
    return NextResponse.json(
      { id, ativo },
      { headers: { "x-request-id": acesso.requisicaoId } },
    );
  } catch {
    return NextResponse.json(corpoErro("inesperado", "nao foi possivel alterar o acompanhamento"), {
      status: STATUS.INESPERADO,
      headers: { "x-request-id": acesso.requisicaoId },
    });
  }
}
