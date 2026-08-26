import { NextResponse } from "next/server";

import { autenticarRequisicao } from "@/lib/autenticacao-api";
import { paginacaoEnvelope, paginaValida, porPaginaValida } from "@/lib/api";
import {
  cashbacksInter,
  ultimaExecucaoInterValida,
  ultimaTentativaInter,
} from "@/lib/banco-inter";
import {
  filtrarCashbacksInter,
  ordenarCashbacksInter,
  ordenarCashbacksPorNome,
} from "@/lib/formato-inter";
import { paginar } from "@/lib/paginacao";

/**
 * GET /api/v1/inter/cashback?q=&ordenar=&pagina=&por_pagina=
 *
 * Cashback dos Sites parceiros (V3), autenticado para o Flutter. `ordenar`:
 * `cashback` (padrão, RN37) | `nome`.
 */
export async function GET(requisicao: Request) {
  const acesso = await autenticarRequisicao(requisicao, { operacao: "inter.cashback.ler" });
  if (!acesso.ok) return acesso.resposta;

  const url = new URL(requisicao.url);
  const q = url.searchParams.get("q") ?? "";
  const ordenarBruto = url.searchParams.get("ordenar") ?? "cashback";
  const pagina = paginaValida(url.searchParams.get("pagina"));
  const porPagina = porPaginaValida(url.searchParams.get("por_pagina"));

  const ordenar = ordenarBruto === "nome" ? ("nome" as const) : ("cashback" as const);

  const [execucao, tentativa] = await Promise.all([
    ultimaExecucaoInterValida(),
    ultimaTentativaInter(),
  ]);
  // RN33: a última tentativa e o último retrato válido são informações
  // independentes. O cliente mantém o retrato anterior, mas pode avisar uma
  // falha recente sem inventar cashback zero.
  const atualizacao = {
    atualizado_em: execucao?.concluida_em ?? null,
    ultima_tentativa_em: tentativa?.iniciada_em ?? null,
    ultima_tentativa_estado: tentativa?.estado ?? null,
  };
  if (!execucao) {
    return NextResponse.json(
      { itens: [], ...atualizacao, ...paginacaoEnvelope(0, pagina, porPagina) },
      { status: 200 },
    );
  }

  const filtradas = filtrarCashbacksInter(await cashbacksInter(execucao.id), q);
  const ordenadas =
    ordenar === "nome" ? ordenarCashbacksPorNome(filtradas) : ordenarCashbacksInter(filtradas);
  const paginado = paginar(ordenadas, pagina, porPagina);

  return NextResponse.json({
    itens: paginado.itens,
    ...atualizacao,
    ...paginacaoEnvelope(paginado.totalItens, pagina, porPagina),
  });
}
