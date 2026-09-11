import { readFileSync } from "node:fs";
import { resolve } from "node:path";

import { describe, expect, it } from "vitest";

const sql = readFileSync(
  resolve(process.cwd(), "../../migracoes/023_alertas_suporte_privacidade.sql"),
  "utf8",
);

describe("geração de alertas dos produtos Inter", () => {
  it("usa qualidade da execução da loja, que é a coluna persistida", () => {
    expect(sql).toContain("rodada_loja.qualidade = 'completa'");
    expect(sql).not.toMatch(/\brodada\.qualidade\b/);
  });
});
