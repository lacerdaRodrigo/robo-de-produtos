import { beforeEach, describe, expect, it, vi } from "vitest";

const dependencias = vi.hoisted(() => ({
  autenticar: vi.fn(),
  buscar: vi.fn(),
  resumo: vi.fn(),
}));

vi.mock("@/lib/autenticacao-api", () => ({
  autenticarRequisicao: dependencias.autenticar,
}));

vi.mock("@/lib/banco-pichau", () => ({
  buscarCatalogoPichau: dependencias.buscar,
  resumoPichauPersistido: dependencias.resumo,
}));

import { GET } from "@/app/api/pichau/catalogo/route";

describe("catálogo Pichau", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    dependencias.autenticar.mockResolvedValue({
      ok: true,
      usuario: { id: "42", papel: "admin" },
      requisicaoId: "req-teste",
    });
    dependencias.buscar.mockResolvedValue({
      itens: [
        {
          id_externo: "PG-1",
          acompanhada: true,
          presente_no_catalogo: true,
        },
      ],
      total: 17,
      pagina: 1,
    });
    dependencias.resumo.mockResolvedValue({
      ultima_tentativa_em: null,
      ultima_tentativa_estado: null,
      ultimo_sucesso_em: null,
      qualidade: "completa",
      total_catalogo: 1169,
      acompanhadas: 17,
      produtos_ativos: 1169,
      produtos_esgotados: 12,
    });
  });

  it("repassa busca, aba, disponibilidade e ordenação ao retrato", async () => {
    const resposta = await GET(
      new Request(
        "http://localhost/api/pichau/catalogo?q=ryzen&aba=acompanhadas&disponibilidade=esgotados&ordenar=desconto&pagina=2&por_pagina=50",
      ),
    );
    const corpo = await resposta.json();

    expect(resposta.status).toBe(200);
    expect(dependencias.buscar).toHaveBeenCalledWith(
      {
        q: "ryzen",
        aba: "acompanhadas",
        disponibilidade: "esgotados",
        ordenar: "desconto",
        precoMin: null,
        precoMax: null,
        pagina: 2,
        porPagina: 50,
      },
      "42",
    );
    expect(dependencias.resumo).toHaveBeenCalledWith("42");
    expect(corpo.itens[0]).toMatchObject({
      id_externo: "PG-1",
      acompanhada: true,
    });
    expect(corpo.resumo).toMatchObject({
      total_catalogo: 1169,
      acompanhadas: 17,
    });
  });

  it("preserva a ordenação por nome oferecida no catálogo mobile", async () => {
    await GET(new Request("http://localhost/api/pichau/catalogo?ordenar=nome"));

    expect(dependencias.buscar).toHaveBeenCalledWith(
      expect.objectContaining({ ordenar: "nome" }),
      "42",
    );
  });

  it("normaliza filtros desconhecidos para o recorte seguro padrão", async () => {
    await GET(
      new Request(
        "http://localhost/api/pichau/catalogo?aba=hostil&disponibilidade=hostil&ordenar=hostil",
      ),
    );

    expect(dependencias.buscar).toHaveBeenCalledWith(
      expect.objectContaining({
        aba: "todas",
        disponibilidade: "todas",
        ordenar: "preco",
        precoMin: null,
        precoMax: null,
      }),
      "42",
    );
  });

  it("encaminha a faixa de preço Pix e rejeita valores inválidos", async () => {
    await GET(
      new Request(
        "http://localhost/api/pichau/catalogo?preco_min=3000,00&preco_max=8000,00",
      ),
    );

    expect(dependencias.buscar).toHaveBeenCalledWith(
      expect.objectContaining({ precoMin: "3000.00", precoMax: "8000.00" }),
      "42",
    );

    vi.clearAllMocks();
    dependencias.autenticar.mockResolvedValue({
      ok: true,
      usuario: { id: "42", papel: "admin" },
      requisicaoId: "req-teste",
    });
    const invalida = await GET(
      new Request("http://localhost/api/pichau/catalogo?preco_min=aberto"),
    );
    expect(invalida.status).toBe(400);
    expect(dependencias.buscar).not.toHaveBeenCalled();
  });
});
