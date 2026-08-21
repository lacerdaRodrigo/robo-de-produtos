import { NextResponse } from "next/server";

import { autenticarRequisicao } from "@/lib/autenticacao-api";
import {
  paginacaoEnvelope,
  paginaValida,
  porPaginaValida,
} from "@/lib/api";
import { pontuacoes, ultimaExecucao } from "@/lib/banco";
import { filtrarPorNome, ordenarLojas, type Ordenacao } from "@/lib/formato";
import { paginar } from "@/lib/paginacao";

/**
 * GET /api/v1/livelo/painel?q=&ordenar=&pagina=&por_pagina=
 *
 * Painel da Livelo para o Flutter autenticado. A página `/` continua pública
 * e intacta durante a transição.
 * paginado para o Flutter. `ordenar`: `pontos` (padrão) | `alerta` | `nome`.
 */
export async function GET(requisicao: Request) {
  const acesso = await autenticarRequisicao(requisicao, { operacao: "livelo.painel.ler" });
  if (!acesso.ok) return acesso.resposta;

  const url = new URL(requisicao.url);
  const q = url.searchParams.get("q") ?? "";
  const ordenarBruto = url.searchParams.get("ordenar") ?? "pontos";
  const pagina = paginaValida(url.searchParams.get("pagina"));
  const porPagina = porPaginaValida(url.searchParams.get("por_pagina"));

  const ordenar: Ordenacao = ["pontos", "alerta", "nome"].includes(ordenarBruto)
    ? (ordenarBruto as Ordenacao)
    : "pontos";

  const execucao = await ultimaExecucao();
  if (!execucao) {
    return NextResponse.json(
      { itens: [], atualizado_em: null, ...paginacaoEnvelope(0, pagina, porPagina) },
      { status: 200 },
    );
  }

  const todas = await pontuacoes(execucao.id);
  const filtradas = filtrarPorNome(todas, q);
  const ordenadas = ordenarLojas(filtradas, ordenar);
  const paginado = paginar(ordenadas, pagina, porPagina);

  return NextResponse.json({
    itens: paginado.itens,
    atualizado_em: execucao.momento,
    ...paginacaoEnvelope(paginado.totalItens, pagina, porPagina),
  });
}
