import { describe, expect, it } from "vitest";

import { normalizarBuscaProdutosInter } from "../lib/formato-produtos-inter";

describe("busca de produtos V4", () => {
  it("normaliza celular como smartphone para a consulta persistida", () => {
    const busca = normalizarBuscaProdutosInter("celular Motorola Edge 60 Pro");
    expect(busca).toBe("smartphone motorola edge 60 pro");
  });
});
