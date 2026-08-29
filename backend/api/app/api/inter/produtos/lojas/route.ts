import { NextResponse } from "next/server";

import { autenticarRequisicao } from "@/lib/autenticacao-api";
import { validarSelecaoDeLojaDireta } from "@/lib/administracao-api";
import { corpoErro, paginacaoEnvelope, paginaValida, porPaginaValida, STATUS } from "@/lib/api";
import {
  buscarLojasDiretas,
  selecionarLojaDireta,
  totalLojasDiretas,
} from "@/lib/banco-produtos-inter";

/**
 * GET /api/v1/inter/produtos/lojas?q=&pagina=&por_pagina=
 *
 * Catálogo de vendedores diretos (V4), autenticado para leitura; a seleção é
 * mutação administrativa e entra quando a autenticação (Firebase) estiver
 * ligada na Fase 3/5.
 */
export async function GET(requisicao: Request) {
  const acesso = await autenticarRequisicao(requisicao, {
    operacao: "inter.produtos.lojas.ler",
    papel: "admin",
  });
  if (!acesso.ok) return acesso.resposta;

  const url = new URL(requisicao.url);
  const q = url.searchParams.get("q") ?? "";
  const pagina = paginaValida(url.searchParams.get("pagina"));
  const porPagina = porPaginaValida(url.searchParams.get("por_pagina"));

  const [itens, total] = await Promise.all([
    buscarLojasDiretas(q, pagina, porPagina),
    totalLojasDiretas(q),
  ]);

  return NextResponse.json({
    itens,
    ...paginacaoEnvelope(total, pagina, porPagina),
  });
}

/**
 * PATCH /api/v1/inter/produtos/lojas
 *
 * Corpo: `{ "id": "…", "selecionada": true|false }`.
 * Esta ação só altera a seleção; não inicia coleta nem aceita workflow, URL
 * ou qualquer valor de fonte externa vindo do aplicativo.
 */
export async function PATCH(requisicao: Request) {
  const acesso = await autenticarRequisicao(requisicao, {
    operacao: "inter.produtos.lojas.selecao",
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
  const entrada = validarSelecaoDeLojaDireta(corpo);
  if (!entrada.ok) {
    return NextResponse.json(corpoErro("validacao", entrada.mensagem), {
      status: STATUS.INVALIDA,
      headers: { "x-request-id": acesso.requisicaoId },
    });
  }

  try {
    const alterada = await selecionarLojaDireta(entrada.valor.id, entrada.valor.selecionada);
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
    return NextResponse.json(corpoErro("inesperado", "nao foi possivel alterar a selecao"), {
      status: STATUS.INESPERADO,
      headers: { "x-request-id": acesso.requisicaoId },
    });
  }
}
