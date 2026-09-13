import { beforeEach, describe, expect, it, vi } from "vitest";

const dependencias = vi.hoisted(() => ({
  autenticar: vi.fn(),
  alterar: vi.fn(),
}));

vi.mock("@/lib/autenticacao-api", () => ({
  autenticarRequisicao: dependencias.autenticar,
}));

vi.mock("@/lib/banco-pichau", () => ({
  alterarAcompanhamentoPichau: dependencias.alterar,
}));

import { PATCH } from "@/app/api/pichau/catalogo/[id_externo]/acompanhamento/route";

describe("acompanhamento administrativo Pichau", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    dependencias.autenticar.mockResolvedValue({
      ok: true,
      usuario: { id: "42", papel: "admin" },
      requisicaoId: "req-teste",
    });
    dependencias.alterar.mockResolvedValue({ id_externo: "PG-1", acompanhada: true });
  });

  it("grava o estado final para um administrador", async () => {
    const resposta = await PATCH(
      new Request("http://localhost/api/pichau/catalogo/PG-1/acompanhamento", {
        method: "PATCH",
        body: JSON.stringify({ acompanhada: true }),
      }),
      { params: Promise.resolve({ id_externo: "PG-1" }) },
    );

    expect(resposta.status).toBe(200);
    expect(await resposta.json()).toEqual({ id_externo: "PG-1", acompanhada: true });
    expect(dependencias.alterar).toHaveBeenCalledWith("PG-1", true);
  });

  it("rejeita corpo extra antes de tocar no banco", async () => {
    const resposta = await PATCH(
      new Request("http://localhost/api/pichau/catalogo/PG-1/acompanhamento", {
        method: "PATCH",
        body: JSON.stringify({ acompanhada: true, nome: "hostil" }),
      }),
      { params: Promise.resolve({ id_externo: "PG-1" }) },
    );

    expect(resposta.status).toBe(400);
    expect(dependencias.alterar).not.toHaveBeenCalled();
  });

  it("mantém a autorização administrativa", async () => {
    dependencias.autenticar.mockResolvedValue({
      ok: false,
      resposta: new Response(null, { status: 403 }),
    });

    const resposta = await PATCH(
      new Request("http://localhost/api/pichau/catalogo/PG-1/acompanhamento", {
        method: "PATCH",
        body: JSON.stringify({ acompanhada: true }),
      }),
      { params: Promise.resolve({ id_externo: "PG-1" }) },
    );

    expect(resposta.status).toBe(403);
    expect(dependencias.alterar).not.toHaveBeenCalled();
  });

  it("retorna 404 quando o produto não existe", async () => {
    dependencias.alterar.mockResolvedValue(null);

    const resposta = await PATCH(
      new Request("http://localhost/api/pichau/catalogo/PG-404/acompanhamento", {
        method: "PATCH",
        body: JSON.stringify({ acompanhada: false }),
      }),
      { params: Promise.resolve({ id_externo: "PG-404" }) },
    );

    expect(resposta.status).toBe(404);
  });
});
