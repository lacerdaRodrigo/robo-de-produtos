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
  autorizarUsuario,
  expurgarRegistrosTecnicos,
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

  it("grava auditoria sem executar expurgo em toda requisicao", async () => {
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
    expect(consulta).not.toContain("DELETE FROM auditoria_app");
    expect(valores).not.toContain(RETENCAO_AUDITORIA_DIAS);
  });

  it("atualiza último acesso no máximo uma vez por 24 horas", async () => {
    bancoFalso.consultar.mockResolvedValue([{ id: "42", email: "piloto@example.com", papel: "usuario", ativo: true }]);

    await autorizarUsuario("firebase-42", "piloto@example.com");

    const [trechos] = bancoFalso.consultar.mock.calls[0];
    const consulta = (trechos as TemplateStringsArray).join("?");
    expect(consulta).toContain("ultimo_acesso_em < now() - interval '24 hours'");
    expect(consulta).toContain("vinculado_em = COALESCE(usuario.vinculado_em, now())");
    expect(consulta).toContain("UNION ALL");
  });

  it("expurga auditoria e baldes inativos em chamada periódica", async () => {
    bancoFalso.consultar.mockResolvedValue([{ auditorias: 3, limites: 5 }]);

    await expect(expurgarRegistrosTecnicos()).resolves.toEqual({ auditorias: 3, limites: 5 });

    const [trechos, ...valores] = bancoFalso.consultar.mock.calls[0];
    const consulta = (trechos as TemplateStringsArray).join("?");
    expect(consulta).toContain("DELETE FROM auditoria_app");
    expect(consulta).toContain("DELETE FROM limite_requisicao_app");
    expect(valores).toContain(RETENCAO_AUDITORIA_DIAS);
  });
});
