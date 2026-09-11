import { NextResponse } from "next/server";

import { autenticarRequisicao } from "@/lib/autenticacao-api";
import { corpoErro, STATUS } from "@/lib/api";
import { alterarAcompanhamentoPichau } from "@/lib/banco-pichau";
import { idPichauValido, validarAcompanhamentoPichau } from "@/lib/catalogo-pichau";

type Contexto = { params: Promise<{ id_externo: string }> };

export async function PATCH(requisicao: Request, contexto: Contexto) {
  const acesso = await autenticarRequisicao(requisicao, {
    operacao: "pichau.catalogo.acompanhamento",
    papel: "admin",
    sensivel: true,
  });
  if (!acesso.ok) return acesso.resposta;

  const idExterno = (await contexto.params).id_externo.trim();
  let corpo: unknown;
  try {
    corpo = await requisicao.json();
  } catch {
    corpo = null;
  }
  const entrada = validarAcompanhamentoPichau(corpo);
  if (!idPichauValido(idExterno) || !entrada.ok) {
    return NextResponse.json(corpoErro("validacao", "acompanhamento invalido"), {
      status: STATUS.INVALIDA,
      headers: { "x-request-id": acesso.requisicaoId },
    });
  }

  try {
    const alterada = await alterarAcompanhamentoPichau(
      idExterno,
      entrada.acompanhada,
    );
    if (!alterada) {
      return NextResponse.json(corpoErro("nao-achei", "produto nao encontrado"), {
        status: STATUS.NAO_ACHEI,
        headers: { "x-request-id": acesso.requisicaoId },
      });
    }
    return NextResponse.json(
      { id_externo: idExterno, acompanhada: entrada.acompanhada },
      { headers: { "x-request-id": acesso.requisicaoId } },
    );
  } catch {
    return NextResponse.json(
      corpoErro("inesperado", "nao foi possivel alterar o acompanhamento"),
      {
        status: STATUS.INESPERADO,
        headers: { "x-request-id": acesso.requisicaoId },
      },
    );
  }
}
