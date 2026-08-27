import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const bancoFalso = vi.hoisted(() => ({
  conectar: vi.fn(),
  consultar: vi.fn<
    (trechos: TemplateStringsArray, ...valores: unknown[]) => Promise<unknown[]>
  >(),
}));

vi.mock("@neondatabase/serverless", () => ({
  neon: bancoFalso.conectar,
}));

import {
  registrarAuditoria,
  RETENCAO_AUDITORIA_DIAS,
} from "../lib/banco-autenticacao";

describe("retenção da auditoria da API", () => {
  beforeEach(() => {
    process.env.DATABASE_URL = "postgresql://banco-falso";
    bancoFalso.consultar.mockReset();
    bancoFalso.consultar.mockResolvedValue([]);
    bancoFalso.conectar.mockReset();
    bancoFalso.conectar.mockReturnValue(bancoFalso.consultar);
  });

  afterEach(() => {
    delete process.env.DATABASE_URL;
  });

  it("grava o evento e remove registros anteriores a 30 dias na mesma consulta", async () => {
    await registrarAuditoria({
      usuarioId: "42",
      identidadeHash: "a".repeat(64),
      origemHash: "b".repeat(64),
      requisicaoId: "req-retencao",
      acao: "perfil.ler",
      resultado: "sucesso",
      codigo: "permitido",
    });

    expect(RETENCAO_AUDITORIA_DIAS).toBe(30);
    expect(bancoFalso.consultar).toHaveBeenCalledTimes(1);

    const [trechos, ...valores] = bancoFalso.consultar.mock.calls[0];
    const consulta = (trechos as TemplateStringsArray).join("?");
    expect(consulta).toContain("INSERT INTO auditoria_app");
    expect(consulta).toContain("DELETE FROM auditoria_app");
    expect(consulta).toContain("make_interval(days => ?)");
    expect(valores).toContain(RETENCAO_AUDITORIA_DIAS);
  });
});
