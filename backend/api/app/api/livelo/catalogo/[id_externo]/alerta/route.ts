import { NextResponse } from "next/server";

import { autenticarRequisicao } from "@/lib/autenticacao-api";
import { corpoErro, STATUS } from "@/lib/api";
import { alterarAlertaParceiroLivelo, parceiroLiveloPorIdExterno } from "@/lib/banco";
import { validarAlertaLivelo } from "@/lib/catalogo-livelo";

type Contexto = { params: Promise<{ id_externo: string }> };
const ID_VALIDO = /^[A-Za-z0-9][A-Za-z0-9_-]{0,99}$/;

export async function PATCH(requisicao: Request, contexto: Contexto) {
  const acesso = await autenticarRequisicao(requisicao, {
    operacao: "livelo.catalogo.alerta",
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
  const entrada = validarAlertaLivelo(corpo);
  if (!ID_VALIDO.test(idExterno) || !entrada.ok) {
    return NextResponse.json(corpoErro("validacao", "alerta invalido"), {
      status: STATUS.INVALIDA,
      headers: { "x-request-id": acesso.requisicaoId },
    });
  }

  try {
    if (!(await parceiroLiveloPorIdExterno(idExterno))) {
      return NextResponse.json(corpoErro("nao-achei", "parceiro nao encontrado"), {
        status: STATUS.NAO_ACHEI,
        headers: { "x-request-id": acesso.requisicaoId },
      });
    }
    const confirmado = await alterarAlertaParceiroLivelo(idExterno, entrada.ativo);
    if (!confirmado) {
      return NextResponse.json(corpoErro("conflito", "acompanhe a loja antes de ativar o alerta"), {
        status: STATUS.CONFLITO,
        headers: { "x-request-id": acesso.requisicaoId },
      });
    }
    return NextResponse.json(
      { id_externo: idExterno, alerta_ativo: entrada.ativo },
      { headers: { "x-request-id": acesso.requisicaoId } },
    );
  } catch {
    return NextResponse.json(corpoErro("inesperado", "nao foi possivel alterar o alerta"), {
      status: STATUS.INESPERADO,
      headers: { "x-request-id": acesso.requisicaoId },
    });
  }
}
