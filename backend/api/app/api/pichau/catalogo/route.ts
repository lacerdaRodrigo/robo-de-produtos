import { NextResponse } from "next/server";

import { autenticarRequisicao } from "@/lib/autenticacao-api";
import { corpoErro, paginacaoEnvelope, paginaValida, porPaginaValida, STATUS } from "@/lib/api";
import {
  buscarCatalogoPichau,
  resumoPichauPersistido,
  type OpcoesCatalogoPichau,
} from "@/lib/banco-pichau";

export async function GET(requisicao: Request) {
  const acesso = await autenticarRequisicao(requisicao, { operacao: "pichau.catalogo.ler" });
  if (!acesso.ok) return acesso.resposta;
  try {
    const url = new URL(requisicao.url);
    const q = (url.searchParams.get("q") ?? "").trim().slice(0, 100);
    const aba: OpcoesCatalogoPichau["aba"] =
      url.searchParams.get("aba") === "acompanhadas" ? "acompanhadas" : "todas";
    const disponibilidadeBruta = url.searchParams.get("disponibilidade") ?? "todas";
    const disponibilidade: OpcoesCatalogoPichau["disponibilidade"] =
      disponibilidadeBruta === "disponiveis" || disponibilidadeBruta === "esgotados"
        ? disponibilidadeBruta
        : "todas";
    const ordenarBruto = url.searchParams.get("ordenar") ?? "nome";
    const ordenar: OpcoesCatalogoPichau["ordenar"] =
      ordenarBruto === "preco" || ordenarBruto === "desconto"
        ? ordenarBruto
        : "nome";
    const pagina = paginaValida(url.searchParams.get("pagina"));
    const porPagina = porPaginaValida(url.searchParams.get("por_pagina"));
    const [resultado, resumo] = await Promise.all([
      buscarCatalogoPichau(q, { aba, disponibilidade, ordenar }, pagina, porPagina),
      resumoPichauPersistido(),
    ]);
    return NextResponse.json({
      itens: resultado.itens.map((item) => ({ ...item, origem: "Pichau" })),
      resumo: {
        ultima_tentativa_em: resumo.ultima_tentativa_em,
        ultima_tentativa_estado: resumo.ultima_tentativa_estado,
        ultimo_sucesso_em: resumo.ultimo_sucesso_em,
        qualidade: resumo.qualidade,
        produtos_ativos: resumo.produtos_ativos,
        produtos_esgotados: resumo.produtos_esgotados,
        total_catalogo: resumo.produtos_ativos,
        acompanhadas: resumo.acompanhadas,
      },
      atualizado_em: resumo.ultimo_sucesso_em,
      ...paginacaoEnvelope(resultado.total, resultado.pagina, porPagina),
    }, {
      headers: { "cache-control": "no-store, max-age=0", "x-request-id": acesso.requisicaoId },
    });
  } catch {
    return NextResponse.json(corpoErro("inesperado", "nao foi possivel carregar o catalogo Pichau"), {
      status: STATUS.INESPERADO,
      headers: { "x-request-id": acesso.requisicaoId },
    });
  }
}
