import { readFileSync } from "node:fs";
import { resolve } from "node:path";

import { describe, expect, it } from "vitest";

const migracao = readFileSync(
  resolve(process.cwd(), "../../migracoes/033_limpeza_admin_segura.sql"),
  "utf8",
);

describe("limpeza administrativa de escopo fixo", () => {
  it("encapsula os dois TRUNCATE em funções SECURITY DEFINER com search_path fechado", () => {
    expect(migracao.match(/SECURITY DEFINER/g)).toHaveLength(2);
    expect(migracao.match(/SET search_path = pg_catalog, public, pg_temp/g)).toHaveLength(2);
    expect(migracao).toContain("public.apagar_dados_livelo()");
    expect(migracao).toContain("public.resetar_dados_inter()");
  });

  it("revoga acesso público e concede apenas EXECUTE à role da API", () => {
    expect(migracao.match(/REVOKE ALL ON FUNCTION/g)).toHaveLength(2);
    expect(migracao.match(/GRANT EXECUTE ON FUNCTION .* TO robo_api/g)).toHaveLength(2);
    expect(migracao).not.toMatch(/GRANT\s+TRUNCATE/i);
  });

  it("limpa o mapeamento Inter antes das lojas sem cascata e preserva o dicionário", () => {
    const truncateInter =
      migracao.match(
        /CREATE OR REPLACE FUNCTION public\.resetar_dados_inter\(\)[\s\S]*?TRUNCATE TABLE([\s\S]*?)RESTART IDENTITY;/,
      )?.[1] ?? "";
    expect(truncateInter).toContain("public.mapeamento_categoria_cashback_inter");
    expect(truncateInter.indexOf("public.mapeamento_categoria_cashback_inter")).toBeLessThan(
      truncateInter.indexOf("public.loja_inter"),
    );
    expect(migracao).not.toMatch(/TRUNCATE[\s\S]*CASCADE/i);
    expect(truncateInter).not.toMatch(/\bpublic\.categoria_cashback_inter\b/);
  });
});
