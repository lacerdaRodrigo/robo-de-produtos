import { readFileSync } from "node:fs";
import { resolve } from "node:path";

import { describe, expect, it } from "vitest";

const sql = readFileSync(
  resolve(process.cwd(), "../../migracoes/032_permissoes_consumidores_neon.sql"),
  "utf8",
);

describe("permissoes dos consumidores Neon", () => {
  it("separa API, dispatchers e executor em logins distintos", () => {
    expect(sql).toContain("GRANT robo_api TO radar_api");
    expect(sql).toContain("GRANT robo_dispatcher TO radar_actions_robo");
    expect(sql).toContain("GRANT pichau_dispatcher TO radar_actions_pichau");
    expect(sql).toContain(
      "GRANT robo_coletor, robo_executor, pichau_publisher TO radar_samsung",
    );
  });

  it("mantem ambas as filas fora do acesso da API", () => {
    expect(sql).toContain("c.relname NOT IN ('coleta_android_fila', 'pichau_android_fila')");
    expect(sql).toContain(
      "REVOKE ALL ON TABLE public.coleta_android_fila, public.pichau_android_fila FROM robo_api",
    );
    expect(sql).toContain(
      "REVOKE ALL ON SEQUENCE\n    public.coleta_android_fila_id_seq,\n    public.pichau_android_fila_id_seq\nFROM robo_api",
    );
    expect(sql).not.toMatch(/GRANT[^;]*usuario_app/s);
  });

  it("restringe funções de alerta e fixa o search_path", () => {
    expect(sql).toContain("ALTER FUNCTION public.gerar_alertas_livelo(BIGINT) SECURITY DEFINER");
    expect(sql).toContain("SET search_path = pg_catalog, public, pg_temp");
    expect(sql).toContain("REVOKE ALL ON FUNCTION public.gerar_alertas_livelo(BIGINT) FROM PUBLIC");
    expect(sql).toContain(
      "GRANT EXECUTE ON FUNCTION public.gerar_alertas_livelo(BIGINT) TO robo_coletor",
    );
  });
});
