/**
 * Contrato de paginação da API v1.
 *
 * Tudo aqui é puro — recebe strings/numbers de querystring e devolve valores
 * seguros. É o que os route handlers usam e o que o teste unitário cobre,
 * sem tocar o Neon.
 */

/** Padrão e teto aprovados: 20 por página, máximo 50. */
export const PADRAO_POR_PAGINA = 20;
export const MAXIMO_POR_PAGINA = 50;
export const PADRAO_HISTORICO_POR_PAGINA = 30;
export const MAXIMO_HISTORICO_POR_PAGINA = 100;

export function paginaValida(bruta: string | null | undefined): number {
  const numero = Number.parseFloat(String(bruta ?? ""));
  return Number.isFinite(numero) && numero >= 1 ? Math.floor(numero) : 1;
}

export function porPaginaValida(
  bruta: string | null | undefined,
  padrao = PADRAO_POR_PAGINA,
  maximo = MAXIMO_POR_PAGINA,
): number {
  const numero = Number.parseFloat(String(bruta ?? ""));
  if (!Number.isFinite(numero) || numero < 1) {
    return padrao;
  }
  return Math.min(Math.floor(numero), maximo);
}

export function totalPaginas(total: number, porPagina: number): number {
  return Math.max(1, Math.ceil(total / porPagina));
}

/** Envelope de paginação devolvido por toda lista da API v1. */
export function paginacaoEnvelope(
  total: number,
  pagina: number,
  porPagina: number,
): {
  pagina: number;
  por_pagina: number;
  total_itens: number;
  total_paginas: number;
  tem_proxima: boolean;
} {
  const totalPaginasCalculadas = totalPaginas(total, porPagina);
  const paginaFinal = Math.min(pagina, totalPaginasCalculadas);
  return {
    pagina: paginaFinal,
    por_pagina: porPagina,
    total_itens: total,
    total_paginas: totalPaginasCalculadas,
    tem_proxima: paginaFinal < totalPaginasCalculadas,
  };
}

/** Corpo de erro padrão da API v1. */
export type ErroApi = {
  erro: { codigo: string; mensagem: string };
};

export function corpoErro(codigo: string, mensagem: string): ErroApi {
  return { erro: { codigo, mensagem } };
}

export const STATUS: Record<string, number> = {
  INVALIDA: 400,
  NAO_AUTORIZADO: 401,
  PROIBIDO: 403,
  NAO_ACHEI: 404,
  LIMITE: 429,
  INESPERADO: 500,
};
