import { NextResponse } from "next/server";

import { autenticarRequisicao } from "@/lib/autenticacao-api";
import { corpoErro, paginacaoEnvelope, paginaValida, porPaginaValida, STATUS } from "@/lib/api";
import { buscarRelatosProblema, registrarRelatoProblema } from "@/lib/banco-alertas";
import { validarRelatoProblema } from "@/lib/alertas-api";

export async function GET(requisicao: Request) {
  const acesso = await autenticarRequisicao(requisicao, {
    operacao: "relatos.problema.ler",
    sensivel: true,
  });
  if (!acesso.ok) return acesso.resposta;
  const url = new URL(requisicao.url);
  const pagina = paginaValida(url.searchParams.get("pagina"));
  const porPagina = porPaginaValida(url.searchParams.get("por_pagina"));
  try {
    const resultado = await buscarRelatosProblema(String(acesso.usuario.id), {
      pagina,
      porPagina,
    });
    return NextResponse.json(
      {
        itens: resultado.itens,
        ...paginacaoEnvelope(resultado.total, resultado.pagina, porPagina),
      },
      {
        headers: {
          "cache-control": "no-store, max-age=0",
          "x-request-id": acesso.requisicaoId,
        },
      },
    );
  } catch {
    return NextResponse.json(
      corpoErro("inesperado", "nao foi possivel carregar os relatos"),
      {
        status: STATUS.INESPERADO,
        headers: { "x-request-id": acesso.requisicaoId },
      },
    );
  }
}

export async function POST(requisicao: Request) {
  const acesso = await autenticarRequisicao(requisicao, { operacao: "relatos.problema.criar", sensivel: true });
  if (!acesso.ok) return acesso.resposta;
  let corpo: unknown; try { corpo = await requisicao.json(); } catch { corpo = null; }
  const entrada = validarRelatoProblema(corpo);
  if (!entrada.ok) return NextResponse.json(corpoErro("validacao", entrada.mensagem), { status: STATUS.INVALIDA, headers: { "x-request-id": acesso.requisicaoId } });
  try { const id = await registrarRelatoProblema(String(acesso.usuario.id), entrada.valor, acesso.requisicaoId); return NextResponse.json({ registrado: true, id }, { status: 201, headers: { "x-request-id": acesso.requisicaoId } }); } catch { return NextResponse.json(corpoErro("inesperado", "nao foi possivel registrar o relato"), { status: STATUS.INESPERADO, headers: { "x-request-id": acesso.requisicaoId } }); }
}
