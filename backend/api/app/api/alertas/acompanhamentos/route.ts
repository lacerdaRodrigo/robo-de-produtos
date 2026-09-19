import { NextResponse } from "next/server";

import { autenticarRequisicao } from "@/lib/autenticacao-api";
import { corpoErro, paginacaoEnvelope, paginaValida, porPaginaValida, STATUS } from "@/lib/api";
import {
  alterarAcompanhamentoPessoal,
  buscarAcompanhamentosPessoais,
  entidadeAcompanhavelExiste,
  ORIGENS_ACOMPANHAMENTO,
} from "@/lib/banco-alertas";
import { idNumerico } from "@/lib/alertas-api";

type Origem = (typeof ORIGENS_ACOMPANHAMENTO)[number];
function origem(valor: unknown): Origem | null {
  return ORIGENS_ACOMPANHAMENTO.includes(valor as Origem) ? valor as Origem : null;
}

export async function GET(requisicao: Request) {
  const acesso = await autenticarRequisicao(requisicao, { operacao: "alertas.acompanhamentos.ler" });
  if (!acesso.ok) return acesso.resposta;
  const url = new URL(requisicao.url);
  const origemBruta = url.searchParams.get("origem");
  const origemEntrada = origemBruta === null || origemBruta === "todas" ? null : origem(origemBruta);
  const ordenarBruta = url.searchParams.get("ordenar") ?? "recentes";
  const busca = url.searchParams.get("q")?.trim() ?? "";
  if ((origemBruta !== null && origemBruta !== "todas" && origemEntrada === null) ||
      !["recentes", "nome"].includes(ordenarBruta) || busca.length > 120) {
    return NextResponse.json(corpoErro("validacao", "filtros de acompanhamento invalidos"), {
      status: STATUS.INVALIDA,
      headers: { "x-request-id": acesso.requisicaoId },
    });
  }
  const pagina = paginaValida(url.searchParams.get("pagina"));
  const porPagina = porPaginaValida(url.searchParams.get("por_pagina"));
  try {
    const resultado = await buscarAcompanhamentosPessoais(String(acesso.usuario.id), {
      q: busca,
      origem: origemEntrada,
      ordenar: ordenarBruta as "recentes" | "nome",
      pagina,
      porPagina,
    });
    return NextResponse.json({
      itens: resultado.itens,
      totais_por_origem: resultado.totaisPorOrigem,
      paginacao: {
        pagina: resultado.pagina,
        por_pagina: porPagina,
        total: resultado.total,
        total_paginas: Math.max(1, Math.ceil(resultado.total / porPagina)),
      },
      ...paginacaoEnvelope(resultado.total, resultado.pagina, porPagina),
    }, { headers: { "cache-control": "no-store, max-age=0", "x-request-id": acesso.requisicaoId } });
  } catch {
    return NextResponse.json(corpoErro("inesperado", "nao foi possivel carregar os acompanhamentos"), {
      status: STATUS.INESPERADO,
      headers: { "x-request-id": acesso.requisicaoId },
    });
  }
}

export async function PATCH(requisicao: Request) {
  const acesso = await autenticarRequisicao(requisicao, { operacao: "alertas.acompanhamento", sensivel: true });
  if (!acesso.ok) return acesso.resposta;
  let corpo: unknown; try { corpo = await requisicao.json(); } catch { corpo = null; }
  const objeto = corpo && typeof corpo === "object" && !Array.isArray(corpo) ? corpo as Record<string, unknown> : null;
  const origemEntrada = origem(objeto?.origem);
  const entidadeId = typeof objeto?.entidade_id === "string" ? objeto.entidade_id : String(objeto?.entidade_id ?? "");
  if (!origemEntrada || idNumerico(entidadeId) === null || typeof objeto?.ativo !== "boolean") {
    return NextResponse.json(corpoErro("validacao", "acompanhamento invalido"), { status: STATUS.INVALIDA, headers: { "x-request-id": acesso.requisicaoId } });
  }
  try {
    if (!(await entidadeAcompanhavelExiste(origemEntrada, entidadeId))) return NextResponse.json(corpoErro("nao-achei", "item nao encontrado"), { status: STATUS.NAO_ACHEI, headers: { "x-request-id": acesso.requisicaoId } });
    await alterarAcompanhamentoPessoal(String(acesso.usuario.id), origemEntrada, entidadeId, objeto.ativo as boolean);
    return NextResponse.json({ origem: origemEntrada, entidade_id: entidadeId, ativo: objeto.ativo }, { headers: { "x-request-id": acesso.requisicaoId } });
  } catch {
    return NextResponse.json(corpoErro("inesperado", "nao foi possivel alterar o acompanhamento"), { status: STATUS.INESPERADO, headers: { "x-request-id": acesso.requisicaoId } });
  }
}
