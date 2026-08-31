import { NextResponse } from "next/server";

import { autenticarRequisicao } from "@/lib/autenticacao-api";
import {
  corpoErro,
  paginacaoEnvelope,
  paginaValida,
  porPaginaValida,
  STATUS,
} from "@/lib/api";
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
 * GET /api/v1/inter/cashback?q=&ordenar=&acompanhadas=&pagina=&por_pagina=
 *
 * Cashback dos Sites parceiros (V3), autenticado para o Flutter. `ordenar`:
 * `cashback` (padrão, RN37) | `nome`. Quando `acompanhadas=true`, o filtro
 * é aplicado ao catálogo completo antes da paginação.
 */
export async function GET(requisicao: Request) {
  const acesso = await autenticarRequisicao(requisicao, { operacao: "inter.cashback.ler" });
  if (!acesso.ok) return acesso.resposta;

  const url = new URL(requisicao.url);
  const q = url.searchParams.get("q") ?? "";
  const ordenarBruto = url.searchParams.get("ordenar") ?? "cashback";
  const apenasAcompanhadas = url.searchParams.get("acompanhadas") === "true";
  const pagina = paginaValida(url.searchParams.get("pagina"));
  const porPagina = porPaginaValida(url.searchParams.get("por_pagina"));

  const ordenar = ordenarBruto === "nome" ? ("nome" as const) : ("cashback" as const);

  try {
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

    const catalogo = await cashbacksInter(execucao.id);
    const filtradas = filtrarCashbacksInter(
      apenasAcompanhadas ? catalogo.filter((loja) => loja.favorita) : catalogo,
      q,
    );
    const ordenadas =
      ordenar === "nome" ? ordenarCashbacksPorNome(filtradas) : ordenarCashbacksInter(filtradas);
    const paginado = paginar(ordenadas, pagina, porPagina);

    return NextResponse.json({
      itens: paginado.itens,
      ...atualizacao,
      ...paginacaoEnvelope(paginado.totalItens, pagina, porPagina),
    });
  } catch {
    return NextResponse.json(
      corpoErro("inesperado", "nao foi possivel carregar os cashbacks"),
      {
        status: STATUS.INESPERADO,
        headers: { "x-request-id": acesso.requisicaoId },
      },
    );
  }
}
