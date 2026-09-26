import { describe, expect, it } from "vitest";

import {
  CATEGORIAS_CASHBACK_INTER,
  categoriaCashbackInterValida,
} from "./categorias-cashback-inter";

describe("taxonomia editorial do cashback Inter", () => {
  it("mantém os rótulos na ordem do protótipo", () => {
    expect(CATEGORIAS_CASHBACK_INTER.map((categoria) => categoria.nome)).toEqual([
      "Beleza",
      "Casa",
      "Eletrônicos",
      "Esporte",
      "Moda",
      "Outros",
      "Pets",
    ]);
  });

  it("aceita somente códigos canônicos", () => {
    expect(categoriaCashbackInterValida("eletronicos")).toBe(true);
    expect(categoriaCashbackInterValida("Todas as categorias")).toBe(false);
    expect(categoriaCashbackInterValida(null)).toBe(false);
  });
});
