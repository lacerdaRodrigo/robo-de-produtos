import { NextResponse } from "next/server";

import { autenticarRequisicao } from "@/lib/autenticacao-api";
import { corpoErro, STATUS } from "@/lib/api";
import { historicoLivelo } from "@/lib/banco";

type Contexto = { params: Promise<{ id_externo: string }> };
const ID_VALIDO = /^[A-Za-z0-9][A-Za-z0-9_-]{0,99}$/;

export async function GET(requisicao: Request, contexto: Contexto) {
  const acesso = await autenticarRequisicao(requisicao, { operacao: "livelo.catalogo.historico.ler" });
  if (!acesso.ok) return acesso.resposta;
  const idExterno = (await contexto.params).id_externo.trim();
  if (!ID_VALIDO.test(idExterno)) {
    return NextResponse.json(corpoErro("validacao", "identificador invalido"), { status: STATUS.INVALIDA, headers: { "x-request-id": acesso.requisicaoId } });
  }
  try {
    const medicoes = await historicoLivelo(idExterno);
    return NextResponse.json({ id_externo: idExterno, medicoes }, { headers: { "cache-control": "no-store, max-age=0", "x-request-id": acesso.requisicaoId } });
  } catch {
    return NextResponse.json(corpoErro("inesperado", "nao foi possivel carregar o historico"), { status: STATUS.INESPERADO, headers: { "x-request-id": acesso.requisicaoId } });
  }
}
