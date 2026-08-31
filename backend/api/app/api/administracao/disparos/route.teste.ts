import { beforeEach, describe, expect, it, vi } from "vitest";

const dependencias = vi.hoisted(() => ({
  autenticar: vi.fn(),
  estado: vi.fn(),
  solicitar: vi.fn(),
  resumoLojas: vi.fn(),
}));

vi.mock("@/lib/autenticacao-api", () => ({
  autenticarRequisicao: dependencias.autenticar,
}));

vi.mock("@/lib/disparos-api", () => ({
  chaveDeIdempotenciaValida: (valor: unknown) =>
    typeof valor === "string" && valor.length >= 16,
  dominioDeDisparoValido: (valor: unknown) =>
    valor === "livelo" || valor === "inter" || valor === "produtos_inter",
  estadoDoDisparo: dependencias.estado,
  solicitarDisparo: dependencias.solicitar,
}));

vi.mock("@/lib/banco-produtos-inter", () => ({
  resumoLojasDiretas: dependencias.resumoLojas,
}));

import { GET, POST } from "./route";

describe("rota administrativa de disparos", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    dependencias.autenticar.mockResolvedValue({
      ok: true,
      usuario: { id: "42" },
      requisicaoId: "req-teste",
    });
    dependencias.resumoLojas.mockResolvedValue({ selecionadas: 1 });
  });

  it("devolve erro interno JSON seguro quando a infraestrutura falha", async () => {
    dependencias.estado.mockRejectedValue(
      new Error("DATABASE_URL=segredo SELECT * FROM solicitacao_disparo_app"),
    );

    const resposta = await GET(
      new Request("http://localhost/api/administracao/disparos?dominio=inter"),
    );
    const texto = await resposta.text();

    expect(resposta.status).toBe(500);
    expect(resposta.headers.get("content-type")).toContain("application/json");
    expect(JSON.parse(texto)).toEqual({
      erro: {
        codigo: "inesperado",
        mensagem: "nao foi possivel consultar o disparo",
      },
    });
    expect(texto).not.toContain("DATABASE_URL");
    expect(texto).not.toContain("SELECT");
    expect(texto).not.toContain("segredo");
  });

  it("devolve cooldown no corpo e no cabecalho sem disparar novamente", async () => {
    dependencias.solicitar.mockResolvedValue({
      estado: "cooldown",
      cooldownSegundos: 91,
    });

    const resposta = await POST(
      new Request("http://localhost/api/administracao/disparos", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "idempotency-key": "chave-valida-123456",
        },
        body: JSON.stringify({ dominio: "inter" }),
      }),
    );

    expect(resposta.status).toBe(429);
    expect(resposta.headers.get("retry-after")).toBe("91");
    await expect(resposta.json()).resolves.toEqual({
      erro: {
        codigo: "cooldown",
        mensagem: "aguarde antes de solicitar outra coleta",
        retry_after_seconds: 91,
      },
    });
    expect(dependencias.solicitar).toHaveBeenCalledTimes(1);
  });
});
