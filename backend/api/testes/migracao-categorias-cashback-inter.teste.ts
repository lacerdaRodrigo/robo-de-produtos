import { readFileSync } from "node:fs";
import { resolve } from "node:path";

import { describe, expect, it } from "vitest";

const sql = readFileSync(
  resolve(process.cwd(), "../../migracoes/030_categorias_cashback_inter.sql"),
  "utf8",
);

describe("migração de categorias do cashback Inter", () => {
  it("cria a taxonomia canônica e o mapeamento por loja", () => {
    expect(sql).toContain("CREATE TABLE IF NOT EXISTS categoria_cashback_inter");
    expect(sql).toContain("CREATE TABLE IF NOT EXISTS mapeamento_categoria_cashback_inter");
    expect(sql).toContain("'eletronicos', 'Eletrônicos'");
    expect(sql).toContain("REFERENCES loja_inter (id) ON DELETE CASCADE");
    expect(sql).toContain("'outros', 'Outros'");
  });
});
