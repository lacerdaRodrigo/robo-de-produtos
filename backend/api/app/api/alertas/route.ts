import { NextResponse } from "next/server";

import { autenticarRequisicao } from "@/lib/autenticacao-api";
import { corpoErro, paginacaoEnvelope, paginaValida, porPaginaValida, STATUS } from "@/lib/api";
import { buscarAlertas, marcarAlertas } from "@/lib/banco-alertas";
import { idsAlerta, tipoAlerta } from "@/lib/alertas-api";

export async function GET(requisicao: Request) {
  const acesso = await autenticarRequisicao(requisicao, { operacao: "alertas.ler" });
  if (!acesso.ok) return acesso.resposta;
  const url = new URL(requisicao.url);
  const tipoBruto = url.searchParams.get("tipo");
  if (tipoBruto !== null && tipoAlerta(tipoBruto) === null) {
    return NextResponse.json(corpoErro("validacao", "tipo de alerta invalido"), { status: STATUS.INVALIDA, headers: { "x-request-id": acesso.requisicaoId } });
  }
  const coleta = url.searchParams.get("coleta");
  if (coleta !== null && !/^[A-Za-z0-9._:-]{1,120}$/.test(coleta)) {
    return NextResponse.json(corpoErro("validacao", "coleta invalida"), { status: STATUS.INVALIDA, headers: { "x-request-id": acesso.requisicaoId } });
  }
  try {
    const resultado = await buscarAlertas(String(acesso.usuario.id), {
      pagina: paginaValida(url.searchParams.get("pagina")),
      porPagina: porPaginaValida(url.searchParams.get("por_pagina")),
      tipo: tipoBruto === null ? null : tipoAlerta(tipoBruto),
      somenteNaoLidos: url.searchParams.get("somente_nao_lidos") === "true",
      coleta,
    });
    return NextResponse.json({ itens: resultado.itens, nao_lidos: resultado.naoLidos, ...paginacaoEnvelope(resultado.total, resultado.pagina, porPaginaValida(url.searchParams.get("por_pagina"))) }, { headers: { "x-request-id": acesso.requisicaoId } });
  } catch {
    return NextResponse.json(corpoErro("inesperado", "nao foi possivel carregar os alertas"), { status: STATUS.INESPERADO, headers: { "x-request-id": acesso.requisicaoId } });
  }
}

export async function PATCH(requisicao: Request) {
  const acesso = await autenticarRequisicao(requisicao, { operacao: "alertas.leitura", sensivel: true });
  if (!acesso.ok) return acesso.resposta;
  let corpo: unknown;
  try { corpo = await requisicao.json(); } catch { corpo = null; }
  if (!corpo || typeof corpo !== "object" || Array.isArray(corpo)) {
    return NextResponse.json(corpoErro("validacao", "corpo invalido"), { status: STATUS.INVALIDA, headers: { "x-request-id": acesso.requisicaoId } });
  }
  const entrada = corpo as Record<string, unknown>;
  const ids = idsAlerta(entrada.ids);
  const lido = entrada.lido;
  if (ids === null || typeof lido !== "boolean") {
    return NextResponse.json(corpoErro("validacao", "ids e lido sao obrigatorios"), { status: STATUS.INVALIDA, headers: { "x-request-id": acesso.requisicaoId } });
  }
  try {
    const alterados = await marcarAlertas(String(acesso.usuario.id), ids, lido);
    return NextResponse.json({ alterados, lido }, { headers: { "x-request-id": acesso.requisicaoId } });
  } catch {
    return NextResponse.json(corpoErro("inesperado", "nao foi possivel atualizar os alertas"), { status: STATUS.INESPERADO, headers: { "x-request-id": acesso.requisicaoId } });
  }
}
