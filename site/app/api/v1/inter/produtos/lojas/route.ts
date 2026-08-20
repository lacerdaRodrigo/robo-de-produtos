import { NextResponse } from "next/server";

import { paginacaoEnvelope, paginaValida, porPaginaValida } from "@/lib/api";
import { buscarLojasDiretas, totalLojasDiretas } from "@/lib/banco-produtos-inter";

/**
 * GET /api/v1/inter/produtos/lojas?q=&pagina=&por_pagina=
 *
 * Catálogo de vendedores diretos (V4). Público para leitura; a seleção é
 * mutação administrativa e entra quando a autenticação (Firebase) estiver
 * ligada na Fase 3/5.
 */
export async function GET(requisicao: Request) {
  const url = new URL(requisicao.url);
  const q = url.searchParams.get("q") ?? "";
  const pagina = paginaValida(url.searchParams.get("pagina"));
  const porPagina = porPaginaValida(url.searchParams.get("por_pagina"));

  const [itens, total] = await Promise.all([
    buscarLojasDiretas(q, pagina, porPagina),
    totalLojasDiretas(q),
  ]);

  return NextResponse.json({
    itens,
    ...paginacaoEnvelope(total, pagina, porPagina),
  });
}