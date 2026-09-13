import { readFileSync } from "node:fs";
import { resolve } from "node:path";

import { describe, expect, it } from "vitest";

const sql = readFileSync(
  resolve(process.cwd(), "../../migracoes/023_alertas_suporte_privacidade.sql"),
  "utf8",
);
const correcao = readFileSync(
  resolve(process.cwd(), "../../migracoes/026_alertas_pichau_pessoal.sql"),
  "utf8",
);
const permissoesPichau = readFileSync(
  resolve(process.cwd(), "../../migracoes/028_permissoes_alertas_pichau.sql"),
  "utf8",
);

describe("geração de alertas dos produtos Inter", () => {
  it("usa qualidade da execução da loja, que é a coluna persistida", () => {
    expect(sql).toContain("rodada_loja.qualidade = 'completa'");
    expect(sql).not.toMatch(/\brodada\.qualidade\b/);
  });

  it("redefine a geração com push opcional e inclui Pichau", () => {
    expect(correcao).toContain("evento_alerta_origem_check");
    expect(correcao).toContain("'pichau'");
    expect(correcao).toContain("notificar_push BOOLEAN NOT NULL DEFAULT TRUE");
    expect(correcao).toContain("gerar_alertas_pichau_com_push");
    expect(correcao).toContain("gerar_alertas_produtos_inter_com_push");
  });

  it("faz o backfill apenas para a janela posterior ao último evento Inter", () => {
    const backfill = readFileSync(
      resolve(process.cwd(), "../../migracoes/027_backfill_alertas_sem_push.sql"),
      "utf8",
    );
    expect(backfill).toContain("gerar_alertas_produtos_inter_com_push(v_execucao_id, FALSE)");
    expect(backfill).toContain("max(rodada.id)");
    expect(backfill).toContain("loja.acompanhada = TRUE");
    expect(backfill).toContain("produto.acompanhada = TRUE");
  });

  it("isola o publicador Pichau atrás de funções seguras", () => {
    expect(permissoesPichau).toContain("gerar_alertas_pichau(BIGINT)");
    expect(permissoesPichau).toContain("SECURITY DEFINER");
    expect(permissoesPichau).toContain(
      "SET search_path = pg_catalog, public, pg_temp",
    );
    expect(permissoesPichau).toContain(
      "GRANT EXECUTE ON FUNCTION gerar_alertas_pichau(BIGINT) TO pichau_publisher",
    );
  });
});
