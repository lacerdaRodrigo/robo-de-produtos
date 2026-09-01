import { describe, expect, it, vi } from "vitest";

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

import { GET } from "@/app/api/livelo/catalogo/route";

describe("qualidade RN29 no catálogo Livelo", () => {
  it("transmite degradação mantendo o instante do snapshot válido", async () => {
    dependencias.autenticar.mockResolvedValue({
      ok: true,
      usuario: { id: "42" },
      requisicaoId: "req-teste",
    });
    dependencias.buscar.mockResolvedValue({ itens: [], total: 0, pagina: 1 });
    dependencias.resumo.mockResolvedValue({
      ultima_coleta: "2026-08-23T08:00:00.000Z",
      ultima_tentativa_em: "2026-08-23T10:30:00.000Z",
      qualidade: "degradada",
      parceiros_lidos: 250,
      total_catalogo: 250,
      acompanhadas: 3,
      alertas_ativos: 2,
      alertas: 1,
      categorias: [],
      melhor_oferta_id_externo: null,
    });

    const resposta = await GET(
      new Request("http://localhost/api/livelo/catalogo"),
    );
    const corpo = await resposta.json();

    expect(resposta.status).toBe(200);
    expect(corpo.resumo).toMatchObject({
      ultima_coleta: "2026-08-23T08:00:00.000Z",
      ultima_tentativa_em: "2026-08-23T10:30:00.000Z",
      qualidade: "degradada",
    });
  });
});
