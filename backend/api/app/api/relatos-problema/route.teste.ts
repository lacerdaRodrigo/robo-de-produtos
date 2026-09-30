import { beforeEach, describe, expect, it, vi } from "vitest";

const dependencias = vi.hoisted(() => ({ autenticar: vi.fn(), buscar: vi.fn(), registrar: vi.fn() }));

vi.mock("@/lib/autenticacao-api", () => ({
  autenticarRequisicao: dependencias.autenticar,
}));
vi.mock("@/lib/banco-alertas", () => ({
  buscarRelatosProblema: dependencias.buscar,
  registrarRelatoProblema: dependencias.registrar,
}));

import { GET, POST } from "./route";

describe("GET /api/relatos-problema", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    dependencias.autenticar.mockResolvedValue({
      ok: true,
      usuario: { id: "42" },
      requisicaoId: "req-relatos-teste",
    });
    dependencias.buscar.mockResolvedValue({ itens: [], total: 0, pagina: 1 });
    dependencias.registrar.mockResolvedValue("519");
  });

  it("consulta somente a conta autenticada e preserva paginação", async () => {
    dependencias.buscar.mockResolvedValue({
      itens: [
        {
          id: "519",
          categoria: "dados",
          mensagem: "O catálogo não atualizou.",
          criado_em: "2026-09-28T16:30:00.000Z",
        },
      ],
      total: 21,
      pagina: 2,
    });

    const resposta = await GET(
      new Request("http://localhost/api/relatos-problema?pagina=2&por_pagina=10"),
    );

    expect(dependencias.autenticar).toHaveBeenCalledWith(expect.any(Request), {
      operacao: "relatos.problema.ler",
      sensivel: true,
    });
    expect(dependencias.buscar).toHaveBeenCalledWith("42", {
      pagina: 2,
      porPagina: 10,
    });
    expect(resposta.headers.get("cache-control")).toBe("no-store, max-age=0");
    expect(resposta.headers.get("x-request-id")).toBe("req-relatos-teste");
    await expect(resposta.json()).resolves.toMatchObject({
      itens: [{ id: "519", mensagem: "O catálogo não atualizou." }],
      pagina: 2,
      por_pagina: 10,
      total_itens: 21,
      total_paginas: 3,
      tem_proxima: true,
    });
  });

  it("responde erro sem fingir lista vazia quando a consulta falha", async () => {
    dependencias.buscar.mockRejectedValue(new Error("banco indisponível"));

    const resposta = await GET(
      new Request("http://localhost/api/relatos-problema"),
    );

    expect(resposta.status).toBe(500);
    await expect(resposta.json()).resolves.toEqual({
      erro: {
        codigo: "inesperado",
        mensagem: "nao foi possivel carregar os relatos",
      },
    });
  });
});

describe("POST /api/relatos-problema", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    dependencias.autenticar.mockResolvedValue({
      ok: true,
      usuario: { id: "42" },
      requisicaoId: "req-relatos-teste",
    });
    dependencias.registrar.mockResolvedValue("519");
  });

  it("salva uma categoria V15 e retorna o protocolo", async () => {
    const resposta = await POST(
      new Request("http://localhost/api/relatos-problema", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({
          categoria: "privacy",
          mensagem: "Quero corrigir meus dados de conta.",
          tela: "relato-problema",
          versao_app: "1.2.3",
        }),
      }),
    );

    expect(dependencias.registrar).toHaveBeenCalledWith(
      "42",
      {
        categoria: "privacy",
        mensagem: "Quero corrigir meus dados de conta.",
        tela: "relato-problema",
        versao_app: "1.2.3",
        sistema: null,
      },
      "req-relatos-teste",
    );
    expect(resposta.status).toBe(201);
    await expect(resposta.json()).resolves.toEqual({
      registrado: true,
      id: "519",
    });
  });
});
