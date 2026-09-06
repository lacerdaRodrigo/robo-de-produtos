import { describe, expect, it } from "vitest";

import { buscaPichau, idPichauValido } from "./catalogo-pichau";

describe("contrato puro do catalogo Pichau", () => {
  it("normaliza acentos e limita a busca", () => {
    expect(buscaPichau("  Ryzen 7 5800X3D  ")).toBe("ryzen 7 5800x3d");
    expect(buscaPichau("á".repeat(120))).toHaveLength(100);
  });

  it("aceita somente identidades seguras na rota de historico", () => {
    expect(idPichauValido("PCM-Pichau-Gamer-67332")).toBe(true);
    expect(idPichauValido("../segredo")).toBe(false);
    expect(idPichauValido("a".repeat(201))).toBe(false);
  });
});
