import { describe, expect, it } from "vitest";

import { correspondeBuscaProdutos, normalizarBuscaProdutosInter } from "../lib/formato-produtos-inter";

describe("busca de produtos V4", () => {
  it("normaliza celular como smartphone e exige todos os termos", () => {
    const busca = normalizarBuscaProdutosInter("celular Motorola Edge 60 Pro");
    expect(busca).toBe("smartphone motorola edge 60 pro");
    expect(correspondeBuscaProdutos("smartphone motorola edge 60 pro 5g", busca)).toBe(true);
    expect(correspondeBuscaProdutos("smartphone motorola moto g06", busca)).toBe(false);
  });
});
