import { NextResponse } from "next/server";

import { autenticarRequisicao } from "@/lib/autenticacao-api";
import { corpoErro, STATUS } from "@/lib/api";
import { alterarAcompanhamentoPessoal } from "@/lib/banco-alertas";

export async function PATCH(requisicao: Request, contexto: { params: Promise<{ loja: string; id_externo: string }> }) {
  const acesso = await autenticarRequisicao(requisicao, { operacao: "inter.produtos.acompanhamento", sensivel: true });
  if (!acesso.ok) return acesso.resposta;
  const parametros = await contexto.params;
  if (!/^[A-Za-z0-9][A-Za-z0-9_-]{0,199}$/.test(parametros.loja) || !/^[A-Za-z0-9][A-Za-z0-9_-]{0,199}$/.test(parametros.id_externo)) return NextResponse.json(corpoErro("validacao", "produto invalido"), { status: STATUS.INVALIDA, headers: { "x-request-id": acesso.requisicaoId } });
  let corpo: unknown; try { corpo = await requisicao.json(); } catch { corpo = null; }
  const ativo = corpo && typeof corpo === "object" && !Array.isArray(corpo) ? (corpo as Record<string, unknown>).ativo : null;
  if (typeof ativo !== "boolean") return NextResponse.json(corpoErro("validacao", "ativo deve ser booleano"), { status: STATUS.INVALIDA, headers: { "x-request-id": acesso.requisicaoId } });
  try {
    const sqlExiste = await entidadeAcompanhavelExistePorChave(parametros.loja, parametros.id_externo);
    if (!sqlExiste) return NextResponse.json(corpoErro("nao-achei", "produto nao encontrado"), { status: STATUS.NAO_ACHEI, headers: { "x-request-id": acesso.requisicaoId } });
    await alterarAcompanhamentoPessoal(String(acesso.usuario.id), "inter_produto", sqlExiste, ativo);
    return NextResponse.json({ loja: parametros.loja, id_externo: parametros.id_externo, ativo }, { headers: { "x-request-id": acesso.requisicaoId } });
  } catch { return NextResponse.json(corpoErro("inesperado", "nao foi possivel alterar o acompanhamento"), { status: STATUS.INESPERADO, headers: { "x-request-id": acesso.requisicaoId } }); }
}

async function entidadeAcompanhavelExistePorChave(loja: string, idExterno: string): Promise<string | null> {
  // Mantém a validação da rota no servidor e devolve apenas o ID interno usado
  // pela camada pessoal; o cliente nunca precisa conhecer esse ID.
  const { neon } = await import("@neondatabase/serverless");
  const url = process.env.DATABASE_URL;
  if (!url) throw new Error("DATABASE_URL nao configurada no ambiente do site.");
  const sql = neon(url);
  const linhas = await sql`
    SELECT p.id::text
      FROM produto_direto_inter p
      JOIN loja_direta_inter l ON l.id = p.loja_direta_inter_id
     WHERE l.slug = ${loja} AND p.id_externo = ${idExterno} AND p.ativo = TRUE
     LIMIT 1
  ` as Array<{ id: string }>;
  return linhas[0]?.id ?? null;
}
