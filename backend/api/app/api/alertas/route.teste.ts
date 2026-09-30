import { beforeEach, describe, expect, it, vi } from "vitest";

const dependencias = vi.hoisted(() => ({
  autenticar: vi.fn(),
  buscar: vi.fn(),
  marcar: vi.fn(),
}));

vi.mock("@/lib/autenticacao-api", () => ({
  autenticarRequisicao: dependencias.autenticar,
}));

vi.mock("@/lib/banco-alertas", () => ({
  buscarAlertas: dependencias.buscar,
  marcarAlertas: dependencias.marcar,
}));

import { GET } from "./route";

describe("GET /api/alertas", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    dependencias.autenticar.mockResolvedValue({
      ok: true,
      usuario: { id: "42" },
      requisicaoId: "req-alertas-teste",
    });
    dependencias.buscar.mockResolvedValue({
      itens: [],
      total: 0,
      naoLidos: 0,
      pagina: 1,
    });
  });

  it("rejeita origem inválida com 400 sem consultar a lista", async () => {
    const resposta = await GET(
      new Request("http://localhost/api/alertas?origem=outra"),
    );

    expect(resposta.status).toBe(400);
    expect(resposta.headers.get("x-request-id")).toBe("req-alertas-teste");
    await expect(resposta.json()).resolves.toEqual({
      erro: {
        codigo: "validacao",
        mensagem: "origem de alerta invalida",
      },
    });
    expect(dependencias.buscar).not.toHaveBeenCalled();
  });

  it("encaminha origem junto aos filtros combináveis da consulta", async () => {
    const resposta = await GET(
      new Request(
        "http://localhost/api/alertas?origem=livelo&tipo=pontuacao&somente_nao_lidos=true&coleta=coleta-17&pagina=2&por_pagina=8",
      ),
    );

    expect(resposta.status).toBe(200);
    expect(dependencias.buscar).toHaveBeenCalledWith("42", {
      pagina: 2,
      porPagina: 8,
      tipo: "pontuacao",
      origem: "livelo",
      somenteNaoLidos: true,
      coleta: "coleta-17",
    });
  });
});
