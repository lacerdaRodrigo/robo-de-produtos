import { describe, expect, it } from "vitest";

import { paginasVisiveis, paginar } from "../lib/paginacao";

describe("paginar", () => {
  const lojas = Array.from({ length: 23 }, (_, indice) => `Loja ${indice + 1}`);

  it("mostra dez itens por pagina", () => {
    const resultado = paginar(lojas, "1");
    expect(resultado.itens).toEqual(lojas.slice(0, 10));
    expect(resultado.totalPaginas).toBe(3);
    expect(resultado.primeiroItem).toBe(1);
    expect(resultado.ultimoItem).toBe(10);
  });

  it("mostra a pagina seguinte e o intervalo correto", () => {
    const resultado = paginar(lojas, "2");
    expect(resultado.itens).toEqual(lojas.slice(10, 20));
    expect(resultado.primeiroItem).toBe(11);
    expect(resultado.ultimoItem).toBe(20);
  });

  it("limita paginas invalidas ou acima do total", () => {
    expect(paginar(lojas, "invalida").pagina).toBe(1);
    expect(paginar(lojas, "99").pagina).toBe(3);
  });

  it("trata uma lista vazia sem criar intervalos falsos", () => {
    const resultado = paginar([], "1");
    expect(resultado.itens).toEqual([]);
    expect(resultado.primeiroItem).toBe(0);
    expect(resultado.ultimoItem).toBe(0);
  });
});

describe("paginasVisiveis", () => {
  it("mantem no maximo cinco paginas ao redor da atual", () => {
    expect(paginasVisiveis(1, 8)).toEqual([1, 2, 3, 4, 5]);
    expect(paginasVisiveis(4, 8)).toEqual([2, 3, 4, 5, 6]);
    expect(paginasVisiveis(8, 8)).toEqual([4, 5, 6, 7, 8]);
  });
});
