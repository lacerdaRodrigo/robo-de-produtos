import { NextResponse } from "next/server";

import { autenticarRequisicao } from "@/lib/autenticacao-api";
import { corpoErro, paginacaoEnvelope, paginaValida, porPaginaValida, STATUS } from "@/lib/api";
import {
  buscarCatalogoLiveloPersistido,
  resumoCatalogoLiveloPersistido,
} from "@/lib/banco";
import {
  apresentarParceiroLivelo,
  categoriasEmPortugues,
  filtrosSqlCatalogoLivelo,
  type AbaCatalogoLivelo,
  type OrdenacaoCatalogoLivelo,
} from "@/lib/catalogo-livelo";

/** Catálogo da última coleta válida, filtrado e paginado no Postgres. */
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
    const q = url.searchParams.get("q") ?? "";
    const categoria = url.searchParams.get("categoria") ?? "";
    const filtrosCategorias = filtrosSqlCatalogoLivelo(q, categoria);
    const [resultado, resumo] = await Promise.all([
      buscarCatalogoLiveloPersistido({
        ...filtrosCategorias,
        aba,
        ordenar,
      }, paginaSolicitada, porPagina),
      resumoCatalogoLiveloPersistido(),
    ]);
    const itens = resultado.itens.map(apresentarParceiroLivelo);
    const melhorOferta = resumo.melhor_oferta_id_externo === null
      ? null
      : {
          id_externo: resumo.melhor_oferta_id_externo,
          nome: resumo.melhor_oferta_nome!,
          pontos_atuais: resumo.melhor_oferta_pontos_atuais!,
          moeda: resumo.melhor_oferta_moeda!,
          prefixo_ate: resumo.melhor_oferta_prefixo_ate!,
        };

    return NextResponse.json({
      itens,
      resumo: {
        ultima_coleta: resumo.ultima_coleta,
        ultima_tentativa_em: resumo.ultima_tentativa_em,
        qualidade: resumo.qualidade,
        parceiros_lidos: resumo.parceiros_lidos,
        total_catalogo: resumo.total_catalogo,
        acompanhadas: resumo.acompanhadas,
        alertas_ativos: resumo.alertas_ativos,
        alertas: resumo.alertas,
        melhor_oferta: melhorOferta,
      },
      categorias: categoriasEmPortugues(resumo.categorias),
      atualizado_em: resumo.ultima_coleta,
      ...paginacaoEnvelope(resultado.total, resultado.pagina, porPagina),
    }, {
      headers: {
        "cache-control": "no-store, max-age=0",
        "x-request-id": acesso.requisicaoId,
      },
    });
  } catch {
    return NextResponse.json(corpoErro("inesperado", "nao foi possivel carregar o catalogo Livelo"), {
      status: STATUS.INESPERADO,
      headers: { "x-request-id": acesso.requisicaoId },
    });
  }
}
