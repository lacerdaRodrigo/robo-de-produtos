import { NextResponse } from "next/server";

import { paginacaoEnvelope, paginaValida, porPaginaValida } from "@/lib/api";
import { cashbacksInter, ultimaExecucaoInterValida } from "@/lib/banco-inter";
import {
  filtrarCashbacksInter,
  ordenarCashbacksInter,
  ordenarCashbacksPorNome,
} from "@/lib/formato-inter";
import { paginar } from "@/lib/paginacao";

/**
 * GET /api/v1/inter/cashback?q=&ordenar=&pagina=&por_pagina=
 *
 * Cashback dos Sites parceiros (V3), público. `ordenar`:
 * `cashback` (padrão, RN37) | `nome`.
 */
export async function GET(requisicao: Request) {
  const url = new URL(requisicao.url);
  const q = url.searchParams.get("q") ?? "";
  const ordenarBruto = url.searchParams.get("ordenar") ?? "cashback";
  const pagina = paginaValida(url.searchParams.get("pagina"));
  const porPagina = porPaginaValida(url.searchParams.get("por_pagina"));

  const ordenar = ordenarBruto === "nome" ? ("nome" as const) : ("cashback" as const);

  const execucao = await ultimaExecucaoInterValida();
  if (!execucao) {
    return NextResponse.json(
      { itens: [], atualizado_em: null, ...paginacaoEnvelope(0, pagina, porPagina) },
      { status: 200 },
    );
  }

  const filtradas = filtrarCashbacksInter(await cashbacksInter(execucao.id), q);
  const ordenadas =
    ordenar === "nome" ? ordenarCashbacksPorNome(filtradas) : ordenarCashbacksInter(filtradas);
  const paginado = paginar(ordenadas, pagina, porPagina);

  return NextResponse.json({
    itens: paginado.itens,
    atualizado_em: execucao.concluida_em,
    ...paginacaoEnvelope(paginado.totalItens, pagina, porPagina),
  });
}