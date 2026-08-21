import { NextResponse } from "next/server";

import { autenticarRequisicao } from "@/lib/autenticacao-api";

/** Perfil minimo usado pelo Flutter para fechar o gate de entrada. */
export async function GET(requisicao: Request) {
  const acesso = await autenticarRequisicao(requisicao, { operacao: "perfil.ler" });
  if (!acesso.ok) return acesso.resposta;

  return NextResponse.json(
    {
      id: acesso.usuario.id,
      email: acesso.usuario.email,
      papel: acesso.usuario.papel,
    },
    { headers: { "x-request-id": acesso.requisicaoId } },
  );
}
