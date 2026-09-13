import { NextResponse } from "next/server";

import { autenticarRequisicao } from "@/lib/autenticacao-api";
import { corpoErro, STATUS } from "@/lib/api";
import {
  alterarAcompanhamentoPessoal,
  entidadeAcompanhavelIdPorChave,
} from "@/lib/banco-alertas";
import { idPichauValido } from "@/lib/catalogo-pichau";

type Contexto = { params: Promise<{ id_externo: string }> };

/** PATCH autenticado para acompanhamento individual de produto Pichau. */
export async function PATCH(requisicao: Request, contexto: Contexto) {
  const acesso = await autenticarRequisicao(requisicao, {
    operacao: "alertas.acompanhamento.pichau",
    sensivel: true,
  });
  if (!acesso.ok) return acesso.resposta;

  const idExterno = (await contexto.params).id_externo.trim();
  let corpo: unknown;
  try { corpo = await requisicao.json(); } catch { corpo = null; }
  const ativo = corpo && typeof corpo === "object" && !Array.isArray(corpo)
    ? (corpo as Record<string, unknown>).ativo
    : null;
  if (!idPichauValido(idExterno) || typeof ativo !== "boolean") {
    return NextResponse.json(corpoErro("validacao", "acompanhamento invalido"), {
      status: STATUS.INVALIDA,
      headers: { "x-request-id": acesso.requisicaoId },
    });
  }

  try {
    const entidadeId = await entidadeAcompanhavelIdPorChave("pichau", idExterno);
    if (!entidadeId) {
      return NextResponse.json(corpoErro("nao-achei", "produto nao encontrado"), {
        status: STATUS.NAO_ACHEI,
        headers: { "x-request-id": acesso.requisicaoId },
      });
    }
    await alterarAcompanhamentoPessoal(
      String(acesso.usuario.id),
      "pichau",
      entidadeId,
      ativo,
    );
    return NextResponse.json(
      { id_externo: idExterno, ativo },
      { headers: { "x-request-id": acesso.requisicaoId } },
    );
  } catch {
    return NextResponse.json(corpoErro("inesperado", "nao foi possivel alterar o acompanhamento"), {
      status: STATUS.INESPERADO,
      headers: { "x-request-id": acesso.requisicaoId },
    });
  }
}
