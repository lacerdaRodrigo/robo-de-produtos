import { describe, expect, it } from "vitest";

import {
  corpoErro,
  MAXIMO_HISTORICO_POR_PAGINA,
  MAXIMO_POR_PAGINA,
  PADRAO_HISTORICO_POR_PAGINA,
  PADRAO_POR_PAGINA,
  paginacaoEnvelope,
  paginaValida,
  porPaginaValida,
  totalPaginas,
} from "@/lib/api";

describe("paginacaoEnvelope", () => {
  it("mantem total e calcula paginas", () => {
    const e = paginacaoEnvelope(50, 1, 20);
    expect(e).toMatchObject({
      pagina: 1,
      por_pagina: 20,
      total_itens: 50,
      total_paginas: 3,
      tem_proxima: true,
    });
  });

  it("recua pagina para o fim quando excede o total", () => {
    const e = paginacaoEnvelope(20, 5, 20);
    expect(e.pagina).toBe(1);
    expect(e.tem_proxima).toBe(false);
  });

  it("nao deixa total zerado virar matriz maior que 1", () => {
    expect(totalPaginas(0, 20)).toBe(1);
  });
});

describe("paginaValida", () => {
  it("aceita inteiro >= 1", () => {
    expect(paginaValida("3")).toBe(3);
  });
  it("cai para 1 em valor invalido ou nulo", () => {
    expect(paginaValida(null)).toBe(1);
    expect(paginaValida("abc")).toBe(1);
    expect(paginaValida("0")).toBe(1);
  });
});

describe("porPaginaValida", () => {
  it("aplica teto de 50", () => {
    expect(porPaginaValida("999", PADRAO_POR_PAGINA, MAXIMO_POR_PAGINA)).toBe(50);
  });
  it("usa o padrao quando ausente ou invalido", () => {
    expect(porPaginaValida(null)).toBe(PADRAO_POR_PAGINA);
    expect(porPaginaValida("-1")).toBe(PADRAO_POR_PAGINA);
  });

  it("aplica o padrao e o teto proprios do historico", () => {
    expect(
      porPaginaValida(null, PADRAO_HISTORICO_POR_PAGINA, MAXIMO_HISTORICO_POR_PAGINA),
    ).toBe(PADRAO_HISTORICO_POR_PAGINA);
    expect(
      porPaginaValida("120", PADRAO_HISTORICO_POR_PAGINA, MAXIMO_HISTORICO_POR_PAGINA),
    ).toBe(MAXIMO_HISTORICO_POR_PAGINA);
  });
});

describe("corpoErro", () => {
  it("devolve o contrato JSON de erro da API", () => {
    expect(corpoErro("validacao", "termo invalido")).toEqual({
      erro: { codigo: "validacao", mensagem: "termo invalido" },
    });
  });
});
