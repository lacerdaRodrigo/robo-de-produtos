import { NextResponse } from "next/server";

import { validarFavoritaInter } from "@/lib/administracao-api";
import { autenticarRequisicao } from "@/lib/autenticacao-api";
import { corpoErro, paginacaoEnvelope, paginaValida, porPaginaValida, STATUS } from "@/lib/api";
import {
  acompanharLojaInter,
  buscarLojasInter,
  deixarDeAcompanharLojaInter,
  totalLojasInter,
} from "@/lib/banco-inter";

/** Catálogo administrativo dos Sites parceiros do Inter. */
export async function GET(requisicao: Request) {
  const acesso = await autenticarRequisicao(requisicao, {
    operacao: "inter.lojas.ler",
    papel: "admin",
  });
  if (!acesso.ok) return acesso.resposta;

  const url = new URL(requisicao.url);
  const q = url.searchParams.get("q") ?? "";
  const pagina = paginaValida(url.searchParams.get("pagina"));
  const porPagina = porPaginaValida(url.searchParams.get("por_pagina"));
  const [itens, total] = await Promise.all([
    buscarLojasInter(q, pagina, porPagina),
    totalLojasInter(q),
  ]);
  return NextResponse.json({ itens, ...paginacaoEnvelope(total, pagina, porPagina) });
}

/**
 * PATCH /api/v1/inter/lojas
 *
 * Corpo: `{ "id": "…", "favorita": true|false }`. A seleção é idempotente
 * e não inicia coleta: o disparo controlado pertence à etapa 5.2.
 */
export async function PATCH(requisicao: Request) {
  const acesso = await autenticarRequisicao(requisicao, {
    operacao: "inter.lojas.favorita",
    papel: "admin",
    sensivel: true,
  });
  if (!acesso.ok) return acesso.resposta;

  let corpo: unknown;
  try {
    corpo = await requisicao.json();
  } catch {
    return NextResponse.json(corpoErro("validacao", "corpo da requisicao invalido"), {
      status: STATUS.INVALIDA,
      headers: { "x-request-id": acesso.requisicaoId },
    });
  }
  const entrada = validarFavoritaInter(corpo);
  if (!entrada.ok) {
    return NextResponse.json(corpoErro("validacao", entrada.mensagem), {
      status: STATUS.INVALIDA,
      headers: { "x-request-id": acesso.requisicaoId },
    });
  }

  try {
    const alterada = entrada.valor.favorita
      ? await acompanharLojaInter(entrada.valor.id)
      : await deixarDeAcompanharLojaInter(entrada.valor.id);
    if (!alterada) {
      return NextResponse.json(corpoErro("nao-achei", "loja nao encontrada ou indisponivel"), {
        status: STATUS.NAO_ACHEI,
        headers: { "x-request-id": acesso.requisicaoId },
      });
    }
    return NextResponse.json(entrada.valor, {
      headers: { "x-request-id": acesso.requisicaoId },
    });
  } catch {
    return NextResponse.json(corpoErro("inesperado", "nao foi possivel alterar a favorita"), {
      status: STATUS.INESPERADO,
      headers: { "x-request-id": acesso.requisicaoId },
    });
  }
}
