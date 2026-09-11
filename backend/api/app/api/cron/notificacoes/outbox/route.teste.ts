import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const dependencias = vi.hoisted(() => ({
  processar: vi.fn(),
}));

vi.mock("@/lib/banco-alertas", () => ({
  processarOutboxAlertas: dependencias.processar,
}));

import { POST } from "./route";

const segredo = "segredo-cron-de-teste-com-tamanho-suficiente";

describe("rota interna da outbox", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.stubEnv("OUTBOX_CRON_SECRET", segredo);
    dependencias.processar.mockResolvedValue({ processadas: 2, enviadas: 1, recuperadas: 1 });
  });

  afterEach(() => {
    vi.unstubAllEnvs();
  });

  it("recusa credencial ausente ou incorreta sem processar a fila", async () => {
    const semCredencial = await POST(
      new Request("https://radar.example/api/cron/notificacoes/outbox", { method: "POST" }),
    );
    const incorreta = await POST(
      new Request("https://radar.example/api/cron/notificacoes/outbox", {
        method: "POST",
        headers: { authorization: "Bearer outro-segredo" },
      }),
    );

    expect(semCredencial.status).toBe(401);
    expect(incorreta.status).toBe(401);
    await expect(semCredencial.json()).resolves.toEqual({
      erro: { codigo: "autenticacao", mensagem: "autenticacao interna obrigatoria" },
    });
    expect(dependencias.processar).not.toHaveBeenCalled();
  });

  it("recusa tudo quando o segredo não foi configurado", async () => {
    vi.stubEnv("OUTBOX_CRON_SECRET", "");

    const resposta = await POST(
      new Request("https://radar.example/api/cron/notificacoes/outbox", {
        method: "POST",
        headers: { authorization: `Bearer ${segredo}` },
      }),
    );

    expect(resposta.status).toBe(503);
    await expect(resposta.json()).resolves.toEqual({
      erro: { codigo: "cron-nao-configurado", mensagem: "processamento interno indisponivel" },
    });
    expect(dependencias.processar).not.toHaveBeenCalled();
  });

  it("processa com a credencial correta e devolve somente contagens", async () => {
    const resposta = await POST(
      new Request("https://radar.example/api/cron/notificacoes/outbox", {
        method: "POST",
        headers: {
          authorization: `Bearer ${segredo}`,
          "x-request-id": "actions-run-123",
        },
      }),
    );

    expect(resposta.status).toBe(200);
    expect(resposta.headers.get("x-request-id")).toBe("actions-run-123");
    expect(resposta.headers.get("cache-control")).toBe("no-store");
    await expect(resposta.json()).resolves.toEqual({ processadas: 2, enviadas: 1, recuperadas: 1 });
    expect(dependencias.processar).toHaveBeenCalledTimes(1);
  });

  it("converte falha do processamento em resposta segura", async () => {
    dependencias.processar.mockRejectedValue(new Error("DATABASE_URL=secreta token=fcm"));

    const resposta = await POST(
      new Request("https://radar.example/api/cron/notificacoes/outbox", {
        method: "POST",
        headers: { authorization: `Bearer ${segredo}` },
      }),
    );
    const texto = await resposta.text();

    expect(resposta.status).toBe(500);
    expect(texto).not.toContain("DATABASE_URL");
    expect(texto).not.toContain("secreta");
    expect(texto).not.toContain("token=fcm");
  });
});
