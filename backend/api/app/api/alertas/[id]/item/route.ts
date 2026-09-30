import { NextResponse } from "next/server";

import { autenticarRequisicao } from "@/lib/autenticacao-api";
import { corpoErro, STATUS } from "@/lib/api";
import { idNumerico } from "@/lib/alertas-api";
import { buscarItemAlerta } from "@/lib/banco-alertas";

type Contexto = { params: Promise<{ id: string }> };

export async function GET(requisicao: Request, contexto: Contexto) {
  const acesso = await autenticarRequisicao(requisicao, {
    operacao: "alertas.item.ler",
  });
  if (!acesso.ok) return acesso.resposta;

  const { id } = await contexto.params;
  if (idNumerico(id) === null) {
    return NextResponse.json(
      corpoErro("validacao", "id de alerta invalido"),
      {
        status: STATUS.INVALIDA,
        headers: { "x-request-id": acesso.requisicaoId },
      },
    );
  }

  try {
    const resultado = await buscarItemAlerta(String(acesso.usuario.id), id);
    if (!resultado) {
      return NextResponse.json(
        corpoErro("nao-achei", "alerta nao encontrado"),
        {
          status: STATUS.NAO_ACHEI,
          headers: { "x-request-id": acesso.requisicaoId },
        },
      );
    }
    return NextResponse.json(resultado, {
      headers: {
        "cache-control": "no-store, max-age=0",
        "x-request-id": acesso.requisicaoId,
      },
    });
  } catch {
    return NextResponse.json(
      corpoErro("inesperado", "nao foi possivel carregar o item do alerta"),
      {
        status: STATUS.INESPERADO,
        headers: { "x-request-id": acesso.requisicaoId },
      },
    );
  }
}
