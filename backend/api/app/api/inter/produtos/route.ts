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
import { categoriasDoEscopoNavegacaoProdutosInter } from "@/lib/escopos-navegacao-produtos-inter";

const MIN_Q = 2;
const MAX_Q = 100;
const MAX_CATEGORIA = 500;

// Aceita vírgula como separador decimal (C18/RNF: usuário brasileiro digita
// "1500,50"). Valida no servidor antes de virar parâmetro de banco.
function precoValido(bruto: string): string | null {
  const texto = bruto.trim().replace(",", ".");
  if (!texto || Number.isNaN(Number(texto)) || Number(texto) < 0) {
    return null;
  }
  return texto;
}

function booleanoOpcional(bruto: string | null): boolean | null {
  if (bruto === null) return false;
  if (bruto === "true") return true;
  if (bruto === "false") return false;
  return null;
}

/**
 * GET /api/v1/inter/produtos?q=&pagina=&por_pagina=&marca=&categoria=
 *   &sem_categoria=&loja=&preco_min=&preco_max=
 *
 * Busca de produtos (V4), autenticada e **paginada no servidor** — nada de baixar
 * catálogo no cliente. `q` vazio lista o catálogo persistido; quando presente,
 * deve conter 2–100 caracteres. A categoria usa o valor externo exato recebido
 * do Shopping Inter; `sem_categoria=true` seleciona somente ausência na origem.
 */
export async function GET(requisicao: Request) {
  const acesso = await autenticarRequisicao(requisicao, {
    operacao: "inter.produtos.buscar",
  });
  if (!acesso.ok) return acesso.resposta;

  const url = new URL(requisicao.url);
  const q = (url.searchParams.get("q") ?? "").trim();
  const pagina = paginaValida(url.searchParams.get("pagina"));
  const porPagina = porPaginaValida(url.searchParams.get("por_pagina"));

  if ((q.length > 0 && q.length < MIN_Q) || q.length > MAX_Q) {
    return NextResponse.json(
      corpoErro(
        "validacao",
        `termo de busca entre ${MIN_Q} e ${MAX_Q} caracteres`,
      ),
      { status: STATUS.INVALIDA },
    );
  }

  const precoMin = precoValido(url.searchParams.get("preco_min") ?? "");
  const precoMax = precoValido(url.searchParams.get("preco_max") ?? "");
  const categoriaBruta = url.searchParams.get("categoria");
  const categoria = categoriaBruta?.trim() || null;
  const escopoBruto = url.searchParams.get("escopo");
  const escopo = escopoBruto?.trim() || null;
  const categoriasDoEscopo = categoriasDoEscopoNavegacaoProdutosInter(escopo);
  const semCategoria = booleanoOpcional(url.searchParams.get("sem_categoria"));

  if (
    categoriaBruta !== null &&
    (!categoria || categoria.length > MAX_CATEGORIA || categoria !== categoriaBruta)
  ) {
    return NextResponse.json(
      corpoErro("validacao", "categoria externa invalida"),
      { status: STATUS.INVALIDA },
    );
  }
  if (semCategoria === null) {
    return NextResponse.json(
      corpoErro("validacao", "sem_categoria deve ser true ou false"),
      { status: STATUS.INVALIDA },
    );
  }
  if (escopoBruto !== null && (!escopo || categoriasDoEscopo === null)) {
    return NextResponse.json(
      corpoErro("validacao", "escopo de navegacao invalido"),
      { status: STATUS.INVALIDA },
    );
  }
  if ((categoria && semCategoria) || (categoria && escopo)) {
    return NextResponse.json(
      corpoErro(
        "validacao",
        "categoria, escopo e sem_categoria nao podem ser combinados",
      ),
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
    const { itens, total } = await buscarProdutosDiretosPaginado(
      q,
      pagina,
      porPagina,
      acesso.usuario.id,
      {
        marca: url.searchParams.get("marca")
          ? String(url.searchParams.get("marca"))
          : null,
        categoria,
        ...(categoriasDoEscopo ? { categorias: categoriasDoEscopo } : {}),
        sem_categoria: semCategoria,
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
    return NextResponse.json(
      corpoErro("inesperado", "nao foi possivel buscar os produtos"),
      {
        status: STATUS.INESPERADO,
        headers: { "x-request-id": acesso.requisicaoId },
      },
    );
  }
}
