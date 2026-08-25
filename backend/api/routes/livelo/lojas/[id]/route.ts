import { NextResponse } from "next/server";

import { validarRegraLojaLivelo } from "@/lib/administracao-api";
import { autenticarRequisicao } from "@/lib/autenticacao-api";
import { corpoErro, STATUS } from "@/lib/api";
import { removerLojaSeExistir, salvarLimiarDaLojaSeExistir } from "@/lib/banco";

type Contexto = { params: Promise<{ id: string }> };

async function idDaRota(contexto: Contexto): Promise<number | null> {
  const bruto = (await contexto.params).id;
  return /^\d{1,10}$/.test(bruto) && Number(bruto) > 0 ? Number(bruto) : null;
}

export async function PATCH(requisicao: Request, contexto: Contexto) {
  const acesso = await autenticarRequisicao(requisicao, {
    operacao: "livelo.lojas.regra",
    papel: "admin",
    sensivel: true,
  });
  if (!acesso.ok) return acesso.resposta;
  const id = await idDaRota(contexto);
  let corpo: unknown;
  try {
    corpo = await requisicao.json();
  } catch {
    corpo = null;
  }
  const entrada = validarRegraLojaLivelo(corpo);
  if (id === null) {
    return NextResponse.json(
      corpoErro("validacao", "loja invalida"),
      { status: STATUS.INVALIDA, headers: { "x-request-id": acesso.requisicaoId } },
    );
  }
  if (!entrada.ok) {
    return NextResponse.json(corpoErro("validacao", entrada.mensagem), {
      status: STATUS.INVALIDA,
      headers: { "x-request-id": acesso.requisicaoId },
    });
  }
  try {
    const alterada = await salvarLimiarDaLojaSeExistir(
      id,
      entrada.valor.multiplicador,
      entrada.valor.piso,
    );
    if (!alterada) {
      return NextResponse.json(corpoErro("nao-achei", "loja nao encontrada"), {
        status: STATUS.NAO_ACHEI,
        headers: { "x-request-id": acesso.requisicaoId },
      });
    }
    return NextResponse.json(
      {
        id: String(id),
        multiplicador: entrada.valor.multiplicador,
        piso_pontos: entrada.valor.piso,
      },
      { headers: { "x-request-id": acesso.requisicaoId } },
    );
  } catch {
    return NextResponse.json(corpoErro("inesperado", "nao foi possivel salvar a regra"), {
      status: STATUS.INESPERADO,
      headers: { "x-request-id": acesso.requisicaoId },
    });
  }
}

export async function DELETE(requisicao: Request, contexto: Contexto) {
  const acesso = await autenticarRequisicao(requisicao, {
    operacao: "livelo.lojas.remover",
    papel: "admin",
    sensivel: true,
  });
  if (!acesso.ok) return acesso.resposta;
  const id = await idDaRota(contexto);
  if (id === null) {
    return NextResponse.json(corpoErro("validacao", "loja invalida"), {
      status: STATUS.INVALIDA,
      headers: { "x-request-id": acesso.requisicaoId },
    });
  }
  try {
    const removida = await removerLojaSeExistir(id);
    if (!removida) {
      return NextResponse.json(corpoErro("nao-achei", "loja nao encontrada"), {
        status: STATUS.NAO_ACHEI,
        headers: { "x-request-id": acesso.requisicaoId },
      });
    }
    return NextResponse.json({ id: String(id), removida: true }, {
      headers: { "x-request-id": acesso.requisicaoId },
    });
  } catch {
    return NextResponse.json(corpoErro("inesperado", "nao foi possivel remover a loja"), {
      status: STATUS.INESPERADO,
      headers: { "x-request-id": acesso.requisicaoId },
    });
  }
}
