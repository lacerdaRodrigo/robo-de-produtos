import { beforeEach, describe, expect, it, vi } from "vitest";

const dependencias = vi.hoisted(() => ({
  autenticar: vi.fn(),
  buscar: vi.fn(),
  resumo: vi.fn(),
}));

vi.mock("@/lib/autenticacao-api", () => ({
  autenticarRequisicao: dependencias.autenticar,
}));
vi.mock("@/lib/banco", () => ({
  buscarCatalogoLiveloPersistido: dependencias.buscar,
  resumoCatalogoLiveloPersistido: dependencias.resumo,
}));

import { GET } from "./route";

describe("GET /api/livelo/catalogo", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    dependencias.autenticar.mockResolvedValue({
      ok: true,
      usuario: { id: "42", papel: "usuario" },
      requisicaoId: "req-livelo-teste",
    });
    dependencias.buscar.mockResolvedValue({ itens: [], total: 0, pagina: 1 });
    dependencias.resumo.mockResolvedValue({
      ultima_coleta: null,
      ultima_tentativa_em: null,
      qualidade: null,
      parceiros_lidos: 0,
      total_catalogo: 0,
      acompanhadas: 0,
      alertas_ativos: 0,
      alertas: 0,
      melhor_oferta_id_externo: null,
      melhor_oferta_nome: null,
      melhor_oferta_pontos_atuais: null,
      melhor_oferta_moeda: null,
      melhor_oferta_prefixo_ate: null,
      categorias: [],
    });
  });

  it("encaminha filtro de pontuação, validade e paginação ao Postgres", async () => {
    const resposta = await GET(
      new Request(
        "http://localhost/api/livelo/catalogo?somente_pontuacao_comum_ampliada=true&ordenar=validade&pagina=2&por_pagina=10",
      ),
    );

    expect(resposta.status).toBe(200);
    expect(dependencias.buscar).toHaveBeenCalledWith(
      expect.objectContaining({
        somentePontuacaoComumAmpliada: true,
        aba: "todas",
        ordenar: "validade",
      }),
      2,
      10,
      "42",
    );
    expect(resposta.headers.get("cache-control")).toBe("no-store, max-age=0");
  });

  it("rejeita filtro booleano inválido antes de consultar o banco", async () => {
    const resposta = await GET(
      new Request(
        "http://localhost/api/livelo/catalogo?somente_pontuacao_comum_ampliada=sim",
      ),
    );

    expect(resposta.status).toBe(400);
    expect(dependencias.buscar).not.toHaveBeenCalled();
    await expect(resposta.json()).resolves.toMatchObject({
      erro: { codigo: "validacao" },
    });
  });
});
