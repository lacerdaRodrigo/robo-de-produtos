import { readFileSync } from "node:fs";
import { resolve } from "node:path";

import { describe, expect, it } from "vitest";

const sql = readFileSync(
  resolve(process.cwd(), "../../migracoes/018_categorias_produtos_inter.sql"),
  "utf8",
);

describe("migração de categorias dos produtos Inter", () => {
  it("cria taxonomia hierárquica sem permitir exclusão histórica", () => {
    expect(sql).toContain("CREATE TABLE IF NOT EXISTS categoria_radar");
    expect(sql).toContain("categoria_pai_id");
    expect(sql).toContain("ON DELETE RESTRICT");
    expect(sql).toContain("impedir_ciclo_categoria_radar");
    expect(sql).toContain("trg_categoria_radar_sem_ciclo");
    expect(sql).toContain("ativo               BOOLEAN NOT NULL DEFAULT TRUE");
  });

  it("distingue preferência ainda não configurada de seleção vazia", () => {
    expect(sql).toContain("preferencia_produtos_inter_usuario");
    expect(sql).toContain("categoria_radar_acompanhada");
    expect(sql).toContain("PRIMARY KEY (usuario_app_id, categoria_radar_id)");
    expect(sql).toContain("Seleção vazia significa");
  });

  it("preserva categoria externa e exige mapeamento versionado", () => {
    expect(sql).toContain("categoria_externa_loja_inter");
    expect(sql).toContain("mapeamento_categoria_loja_inter");
    expect(sql).toContain("versao_mapeamento");
    expect(sql).toContain("idx_mapeamento_categoria_inter_ativo");
    expect(sql).toContain("categoria_externa_nao_mapeada");
    expect(sql).toContain("sem_categoria_na_origem");
    expect(sql).toContain("classificacao_ambigua");
    expect(sql).toContain("erro_de_classificacao");
  });

  it("faz backfill observável sem classificar por semelhança", () => {
    expect(sql).toContain("categoria_externa_sem_mapeamento_aprovado");
    expect(sql).toContain("categoria_ausente_no_contrato_inter");
    expect(sql).not.toMatch(/UPDATE produto_direto_inter[\s\S]*SET categoria_radar_id\s*=/);
  });

  it("semeia um recorte expansível que distingue celulares de cabos", () => {
    expect(sql).toContain("('celulares', 'Celulares', 'eletronicos'");
    expect(sql).toContain(
      "('acessorios-para-celulares', 'Acessórios para celulares', 'eletronicos'",
    );
    expect(sql).toContain("('cabos', 'Cabos', 'acessorios-para-celulares'");
    expect(sql).toContain("('geladeiras', 'Geladeiras', 'eletrodomesticos'");
    expect(sql).not.toContain("Pichau");
  });
});
