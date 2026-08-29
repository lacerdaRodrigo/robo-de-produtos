import { NextResponse } from "next/server";

import { autenticarRequisicao } from "@/lib/autenticacao-api";
import { corpoErro, paginacaoEnvelope, paginaValida, porPaginaValida, STATUS } from "@/lib/api";
import { catalogoLiveloPersistido } from "@/lib/banco";
import {
  apresentarParceiroLivelo,
  filtrarEOrdenarCatalogoLivelo,
  melhorOfertaLivelo,
  type AbaCatalogoLivelo,
  type OrdenacaoCatalogoLivelo,
} from "@/lib/catalogo-livelo";
import { paginar } from "@/lib/paginacao";

/** Catálogo completo da última coleta válida, paginado para o Flutter. */
export async function GET(requisicao: Request) {
  const acesso = await autenticarRequisicao(requisicao, { operacao: "livelo.catalogo.ler" });
  if (!acesso.ok) return acesso.resposta;

  try {
    const url = new URL(requisicao.url);
    const paginaSolicitada = paginaValida(url.searchParams.get("pagina"));
    const porPagina = porPaginaValida(url.searchParams.get("por_pagina"));
    const abaBruta = url.searchParams.get("aba") ?? "todas";
    const aba: AbaCatalogoLivelo = ["todas", "acompanhadas", "alertas"].includes(abaBruta)
      ? (abaBruta as AbaCatalogoLivelo)
      : "todas";
    const ordenarBruto = url.searchParams.get("ordenar") ?? "pontos";
    const ordenar: OrdenacaoCatalogoLivelo = ordenarBruto === "nome" ? "nome" : "pontos";

    const persistidos = await catalogoLiveloPersistido();
    const todos = persistidos.map(apresentarParceiroLivelo);
    const filtrados = filtrarEOrdenarCatalogoLivelo(todos, {
      q: url.searchParams.get("q") ?? "",
      aba,
      categoria: url.searchParams.get("categoria") ?? "",
      ordenar,
    });
    const resultado = paginar(filtrados, paginaSolicitada, porPagina);
    const primeiro = persistidos[0];
    const categorias = [...new Set(todos.flatMap((parceiro) => parceiro.categorias))]
      .sort((a, b) => a.localeCompare(b, "pt-BR"));

    return NextResponse.json({
      itens: resultado.itens,
      resumo: {
        ultima_coleta: primeiro?.atualizado_em ?? null,
        parceiros_lidos: primeiro?.parceiros_lidos ?? 0,
        total_catalogo: todos.length,
        acompanhadas: todos.filter((parceiro) => parceiro.acompanhada).length,
        alertas: todos.filter((parceiro) => parceiro.acompanhada && parceiro.alerta).length,
        melhor_oferta: melhorOfertaLivelo(todos),
      },
      categorias,
      atualizado_em: primeiro?.atualizado_em ?? null,
      ...paginacaoEnvelope(resultado.totalItens, resultado.pagina, porPagina),
    });
  } catch {
    return NextResponse.json(corpoErro("inesperado", "nao foi possivel carregar o catalogo Livelo"), {
      status: STATUS.INESPERADO,
      headers: { "x-request-id": acesso.requisicaoId },
    });
  }
}
