import { beforeEach, describe, expect, it, vi } from "vitest";

const dependencias = vi.hoisted(() => ({
  autenticar: vi.fn(),
  buscar: vi.fn(),
}));

vi.mock("@/lib/autenticacao-api", () => ({
  autenticarRequisicao: dependencias.autenticar,
}));

vi.mock("@/lib/banco-alertas", () => ({
  buscarItemAlerta: dependencias.buscar,
}));

import { GET } from "./route";

describe("GET /api/alertas/{id}/item", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    dependencias.autenticar.mockResolvedValue({
      ok: true,
      usuario: { id: "42" },
      requisicaoId: "req-alerta-item-teste",
    });
    dependencias.buscar.mockResolvedValue({
      origem: "livelo",
      item: { id_externo: "loja-8", nome: "Loja teste" },
    });
  });

  it("autentica e retorna origem e DTO do catálogo resolvido", async () => {
    const resposta = await GET(
      new Request("http://localhost/api/alertas/71/item"),
      { params: Promise.resolve({ id: "71" }) },
    );

    expect(resposta.status).toBe(200);
    expect(resposta.headers.get("cache-control")).toBe("no-store, max-age=0");
    expect(resposta.headers.get("x-request-id")).toBe("req-alerta-item-teste");
    await expect(resposta.json()).resolves.toEqual({
      origem: "livelo",
      item: { id_externo: "loja-8", nome: "Loja teste" },
    });
    expect(dependencias.autenticar).toHaveBeenCalledWith(
      expect.any(Request),
      { operacao: "alertas.item.ler" },
    );
    expect(dependencias.buscar).toHaveBeenCalledWith("42", "71");
  });

  it("rejeita identificador inválido antes da consulta", async () => {
    const resposta = await GET(
      new Request("http://localhost/api/alertas/nao-numerico/item"),
      { params: Promise.resolve({ id: "nao-numerico" }) },
    );

    expect(resposta.status).toBe(400);
    expect(dependencias.buscar).not.toHaveBeenCalled();
  });

  it("retorna o mesmo 404 quando o alerta ou entidade não existe para a conta", async () => {
    dependencias.buscar.mockResolvedValue(null);

    const resposta = await GET(
      new Request("http://localhost/api/alertas/71/item"),
      { params: Promise.resolve({ id: "71" }) },
    );

    expect(resposta.status).toBe(404);
    expect(resposta.headers.get("x-request-id")).toBe("req-alerta-item-teste");
    await expect(resposta.json()).resolves.toEqual({
      erro: { codigo: "nao-achei", mensagem: "alerta nao encontrado" },
    });
  });
});
