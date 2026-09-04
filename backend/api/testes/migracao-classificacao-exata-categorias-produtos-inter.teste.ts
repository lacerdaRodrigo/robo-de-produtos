import { readFileSync } from "node:fs";
import { resolve } from "node:path";

import { describe, expect, it } from "vitest";

const sql = readFileSync(
  resolve(process.cwd(), "../../migracoes/019_classificacao_exata_categorias_produtos_inter.sql"),
  "utf8",
);

describe("migração de classificação exata das categorias Inter", () => {
  it("mapeia somente a identidade externa idêntica ao slug Radar", () => {
    expect(sql).toContain("radar.slug = externa.identificador_categoria_externa");
    expect(sql).toContain("identificador externo coincide exatamente com slug Radar");
    expect(sql).toContain("mapeamento_categoria_loja_inter");
    expect(sql).toContain("versao_mapeamento");
  });

  it("reclassifica o catálogo existente sem usar nome ou marca do produto", () => {
    expect(sql).toContain("UPDATE produto_direto_inter produto");
    expect(sql).toContain("categoria_radar_id = mapa.categoria_radar_id");
    expect(sql).toContain("estado_classificacao = 'classificado'");
    expect(sql).not.toMatch(/produto\.nome/);
    expect(sql).not.toMatch(/produto\.marca/);
  });
});
