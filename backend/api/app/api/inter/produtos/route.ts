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
import { categoriaRadarAtivaExiste } from "@/lib/banco-categorias-produtos-inter";

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
 * GET /api/v1/inter/produtos?q=&pagina=&por_pagina=&marca=&categoria=
 *   &categoria_radar=&loja=&preco_min=&preco_max=
 *
 * Busca de produtos (V4), autenticada e **paginada no servidor** — nada de baixar
 * catálogo no cliente. `q` vazio lista o catálogo persistido; quando presente,
 * deve conter 2–100 caracteres. Ordenação estável por menor preço atual,
 * depois nome, depois ID (RN71).
 */
export async function GET(requisicao: Request) {
  const acesso = await autenticarRequisicao(requisicao, { operacao: "inter.produtos.buscar" });
  if (!acesso.ok) return acesso.resposta;

  const url = new URL(requisicao.url);
  const q = (url.searchParams.get("q") ?? "").trim();
  const pagina = paginaValida(url.searchParams.get("pagina"));
  const porPagina = porPaginaValida(url.searchParams.get("por_pagina"));

  if ((q.length > 0 && q.length < MIN_Q) || q.length > MAX_Q) {
    return NextResponse.json(
      corpoErro("validacao", `termo de busca entre ${MIN_Q} e ${MAX_Q} caracteres`),
      { status: STATUS.INVALIDA },
    );
  }

  const precoMin = precoValido(url.searchParams.get("preco_min") ?? "");
  const precoMax = precoValido(url.searchParams.get("preco_max") ?? "");
  const categoriaRadar = url.searchParams.get("categoria_radar")?.trim() || null;
  if (
    categoriaRadar &&
    (categoriaRadar.length > 120 ||
      !/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(categoriaRadar))
  ) {
    return NextResponse.json(
      corpoErro("validacao", "categoria_radar invalida"),
      { status: STATUS.INVALIDA },
    );
  }
  if (
    (url.searchParams.get("preco_min") && precoMin === null) ||
    (url.searchParams.get("preco_max") && precoMax === null)
  ) {
    return NextResponse.json(
      corpoErro("validacao", "preco_min/preco_max devem ser números >= 0"),
      { status: STATUS.INVALIDA },
    );
  }

  try {
    if (categoriaRadar && !(await categoriaRadarAtivaExiste(categoriaRadar))) {
      return NextResponse.json(
        corpoErro("validacao", "categoria_radar inexistente ou inativa"),
        { status: STATUS.INVALIDA },
      );
    }
    const { itens, total } = await buscarProdutosDiretosPaginado(
      q,
      pagina,
      porPagina,
      acesso.usuario.id,
      {
        marca: url.searchParams.get("marca")
          ? String(url.searchParams.get("marca"))
          : null,
        categoria: url.searchParams.get("categoria")
          ? String(url.searchParams.get("categoria"))
          : null,
        categoria_radar: categoriaRadar,
        loja: url.searchParams.get("loja")
          ? String(url.searchParams.get("loja"))
          : null,
        preco_min: precoMin,
        preco_max: precoMax,
      },
    );

    const status = await statusCatalogoProdutos(itens);

    return NextResponse.json({
      itens,
      ...paginacaoEnvelope(total, pagina, porPagina),
      atualizado_em: status.atualizado_em,
      qualidade: status.qualidade,
      ultima_tentativa_em: status.ultima_tentativa_em,
      ultima_tentativa_estado: status.ultima_tentativa_estado,
    });
  } catch {
    return NextResponse.json(corpoErro("inesperado", "nao foi possivel buscar os produtos"), {
      status: STATUS.INESPERADO,
      headers: { "x-request-id": acesso.requisicaoId },
    });
  }
}
