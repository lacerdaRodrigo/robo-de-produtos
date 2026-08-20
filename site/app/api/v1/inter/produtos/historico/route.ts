import { NextResponse } from "next/server";

import {
  corpoErro,
  MAXIMO_HISTORICO_POR_PAGINA,
  paginacaoEnvelope,
  paginaValida,
  PADRAO_HISTORICO_POR_PAGINA,
  porPaginaValida,
  STATUS,
} from "@/lib/api";
import { historicoProdutoDireto } from "@/lib/banco-produtos-inter";

/**
 * GET /api/v1/inter/produtos/historico?loja=&produto=&pagina=&por_pagina=
 *
 * Histórico de 30 dias de um produto numa loja (V4). Público.
 * `por_pagina` padrão 30, máximo 100 (FASE1-Contrato-API §4.6).
 */
export async function GET(requisicao: Request) {
  const url = new URL(requisicao.url);
  const loja = url.searchParams.get("loja");
  const produto = url.searchParams.get("produto");
  const pagina = paginaValida(url.searchParams.get("pagina"));
  const porPagina = porPaginaValida(
    url.searchParams.get("por_pagina"),
    PADRAO_HISTORICO_POR_PAGINA,
    MAXIMO_HISTORICO_POR_PAGINA,
  );

  if (!loja || !produto) {
    return NextResponse.json(
      corpoErro("validacao", "loja e produto são obrigatórios"),
      { status: STATUS.INVALIDA },
    );
  }

  const historico = await historicoProdutoDireto(loja, produto);
  if (!historico) {
    return NextResponse.json(corpoErro("nao-achei", "produto não encontrado"), {
      status: STATUS.NAO_ACHEI,
    });
  }

  const medicoes = historico.medicoes;
  const inicio = (pagina - 1) * porPagina;
  const paginaDeMedicoes = medicoes.slice(inicio, inicio + porPagina);

  return NextResponse.json({
    produto: { ...historico.produto, ativo: historico.produto.ativo ?? false },
    minimo: historico.minimo,
    maximo: historico.maximo,
    medicoes: paginaDeMedicoes,
    ...paginacaoEnvelope(medicoes.length, pagina, porPagina),
  });
}