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
} from "../lib/api";

describe("página e por_página da API v1", () => {
  it("página inválida ou ausente vira 1", () => {
    expect(paginaValida("2")).toBe(2);
    expect(paginaValida(null)).toBe(1);
    expect(paginaValida("")).toBe(1);
    expect(paginaValida("nada")).toBe(1);
    expect(paginaValida("-3")).toBe(1);
    expect(paginaValida("0")).toBe(1);
  });

  it("por_página aplica padrão e teto", () => {
    expect(porPaginaValida(null)).toBe(PADRAO_POR_PAGINA);
    expect(porPaginaValida("10")).toBe(10);
    expect(porPaginaValida("999")).toBe(MAXIMO_POR_PAGINA);
    expect(porPaginaValida("0")).toBe(PADRAO_POR_PAGINA);
    expect(porPaginaValida("abc")).toBe(PADRAO_POR_PAGINA);
  });

  it("histórico usa padrão próprio e teto maior", () => {
    expect(porPaginaValida(null, PADRAO_HISTORICO_POR_PAGINA, MAXIMO_HISTORICO_POR_PAGINA)).toBe(
      PADRAO_HISTORICO_POR_PAGINA,
    );
    expect(
      porPaginaValida("120", PADRAO_HISTORICO_POR_PAGINA, MAXIMO_HISTORICO_POR_PAGINA),
    ).toBe(MAXIMO_HISTORICO_POR_PAGINA);
  });

  it("nunca corta o total em silêncio: página acima do total é limitada", () => {
    const envelope = paginacaoEnvelope(25, 99, 20);
    expect(envelope.pagina).toBe(2); // 25 itens → 2 páginas de 20
    expect(envelope.total_paginas).toBe(2);
  });
});

describe("paginacaoEnvelope", () => {
  it("monta o envelope com tem_proxima", () => {
    const envelope = paginacaoEnvelope(45, 1, 20);
    expect(envelope.por_pagina).toBe(20);
    expect(envelope.total_itens).toBe(45);
    expect(envelope.total_paginas).toBe(3);
    expect(envelope.tem_proxima).toBe(true);
  });

  it("última página não indica próxima", () => {
    const envelope = paginacaoEnvelope(45, 3, 20);
    expect(envelope.pagina).toBe(3);
    expect(envelope.tem_proxima).toBe(false);
  });

  it("lista vazia tem uma página, sem próxima", () => {
    const envelope = paginacaoEnvelope(0, 1, 20);
    expect(envelope.total_paginas).toBe(1);
    expect(envelope.tem_proxima).toBe(false);
    expect(envelope.total_itens).toBe(0);
  });
});

describe("totalPaginas", () => {
  it("arredonda para cima e nunca devolve zero", () => {
    expect(totalPaginas(45, 20)).toBe(3);
    expect(totalPaginas(20, 20)).toBe(1);
    expect(totalPaginas(0, 20)).toBe(1);
  });
});

describe("corpoErro", () => {
  it("devolve o corpo JSON de erro padrão", () => {
    expect(corpoErro("validacao", "termo invalido")).toEqual({
      erro: { codigo: "validacao", mensagem: "termo invalido" },
    });
  });
});