import { NextResponse } from "next/server";

import { autenticarRequisicao } from "@/lib/autenticacao-api";
import { corpoErro, paginacaoEnvelope, paginaValida, porPaginaValida, STATUS } from "@/lib/api";
import { historicoPichau } from "@/lib/banco-pichau";
import { idPichauValido } from "@/lib/catalogo-pichau";

type Contexto = { params: Promise<{ id_externo: string }> };

export async function GET(requisicao: Request, contexto: Contexto) {
  const acesso = await autenticarRequisicao(requisicao, { operacao: "pichau.catalogo.historico.ler" });
  if (!acesso.ok) return acesso.resposta;
  const idExterno = (await contexto.params).id_externo.trim();
  if (!idPichauValido(idExterno)) {
    return NextResponse.json(corpoErro("validacao", "identificador invalido"), {
      status: STATUS.INVALIDA,
      headers: { "x-request-id": acesso.requisicaoId },
    });
  }
  try {
    const url = new URL(requisicao.url);
    const pagina = paginaValida(url.searchParams.get("pagina"));
    const porPagina = porPaginaValida(url.searchParams.get("por_pagina"), 30, 100);
    const resultado = await historicoPichau(idExterno, pagina, porPagina);
    if (!resultado) {
      return NextResponse.json(corpoErro("nao_encontrado", "produto Pichau nao encontrado"), {
        status: STATUS.NAO_ACHEI,
        headers: { "x-request-id": acesso.requisicaoId },
      });
    }
    return NextResponse.json({
      produto: { ...resultado.produto, origem: "Pichau" },
      minimo_pix_texto: resultado.minimo_pix_texto,
      maximo_pix_texto: resultado.maximo_pix_texto,
      medicoes: resultado.medicoes,
      ...paginacaoEnvelope(resultado.total, resultado.pagina, porPagina),
    }, {
      headers: { "cache-control": "no-store, max-age=0", "x-request-id": acesso.requisicaoId },
    });
  } catch {
    return NextResponse.json(corpoErro("inesperado", "nao foi possivel carregar o historico Pichau"), {
      status: STATUS.INESPERADO,
      headers: { "x-request-id": acesso.requisicaoId },
    });
  }
}
