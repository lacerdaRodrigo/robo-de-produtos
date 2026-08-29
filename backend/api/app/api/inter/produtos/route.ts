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
  buscarProdutosDiretosPaginado,
  statusCatalogoProdutos,
} from "@/lib/banco-produtos-inter";

const MIN_Q = 2;
const MAX_Q = 100;

// Aceita vírgula como separador decimal (C18/RNF: usuário brasileiro digita
// "1500,50"). Valida no servidor antes de virar parâmetro de banco.
function precoValido(bruto: string): string | null {
  const texto = bruto.trim().replace(",", ".");
  if (!texto || Number.isNaN(Number(texto)) || Number(texto) < 0) {
    return null;
  }
  return texto;
}

/**
 * GET /api/v1/inter/produtos?q=&pagina=&por_pagina=&marca=&categoria=&loja=&preco_min=&preco_max=
 *
 * Busca de produtos (V4), autenticada e **paginada no servidor** — nada de baixar
 * catálogo no cliente. `q` é obrigatório (2–100 carac.). Ordenação estável
 * por menor preço atual, depois nome, depois ID (RN71).
 */
export async function GET(requisicao: Request) {
  const acesso = await autenticarRequisicao(requisicao, { operacao: "inter.produtos.buscar" });
  if (!acesso.ok) return acesso.resposta;

  const url = new URL(requisicao.url);
  const q = (url.searchParams.get("q") ?? "").trim();
  const pagina = paginaValida(url.searchParams.get("pagina"));
  const porPagina = porPaginaValida(url.searchParams.get("por_pagina"));

  if (q.length < MIN_Q || q.length > MAX_Q) {
    return NextResponse.json(
      corpoErro("validacao", `termo de busca entre ${MIN_Q} e ${MAX_Q} caracteres`),
      { status: STATUS.INVALIDA },
    );
  }

  const precoMin = precoValido(url.searchParams.get("preco_min") ?? "");
  const precoMax = precoValido(url.searchParams.get("preco_max") ?? "");
  if (
    (url.searchParams.get("preco_min") && precoMin === null) ||
    (url.searchParams.get("preco_max") && precoMax === null)
  ) {
    return NextResponse.json(
      corpoErro("validacao", "preco_min/preco_max devem ser números >= 0"),
      { status: STATUS.INVALIDA },
    );
  }

  const { itens, total } = await buscarProdutosDiretosPaginado(q, pagina, porPagina, {
    marca: url.searchParams.get("marca") ? String(url.searchParams.get("marca")) : null,
    categoria: url.searchParams.get("categoria")
      ? String(url.searchParams.get("categoria"))
      : null,
    loja: url.searchParams.get("loja") ? String(url.searchParams.get("loja")) : null,
    preco_min: precoMin,
    preco_max: precoMax,
  });

  const status = await statusCatalogoProdutos();

  return NextResponse.json({
    itens,
    ...paginacaoEnvelope(total, pagina, porPagina),
    atualizado_em: status.atualizado_em,
    qualidade: status.qualidade,
  });
}
