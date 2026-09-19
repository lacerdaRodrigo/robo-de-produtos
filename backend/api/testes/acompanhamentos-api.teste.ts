import { beforeEach, describe, expect, it, vi } from "vitest";

const dependencias = vi.hoisted(() => ({
  autenticar: vi.fn(),
  buscar: vi.fn(),
  alterar: vi.fn(),
  existe: vi.fn(),
}));

vi.mock("@/lib/autenticacao-api", () => ({ autenticarRequisicao: dependencias.autenticar }));
vi.mock("@/lib/banco-alertas", () => ({
  ORIGENS_ACOMPANHAMENTO: ["livelo", "inter_cashback", "inter_produto", "pichau"],
  buscarAcompanhamentosPessoais: dependencias.buscar,
  alterarAcompanhamentoPessoal: dependencias.alterar,
  entidadeAcompanhavelExiste: dependencias.existe,
}));

import { GET, PATCH } from "@/app/api/alertas/acompanhamentos/route";

describe("acompanhamentos consolidados do Mobile V15", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    dependencias.autenticar.mockResolvedValue({
      ok: true,
      usuario: { id: "42", papel: "usuario" },
      requisicaoId: "req-teste",
    });
    dependencias.buscar.mockResolvedValue({
      itens: [
        {
          id: "7",
          origem: "inter_cashback",
          tipo_entidade: "loja",
          entidade_id: "11",
          entidade_externa: "loja-11",
          nome: "Loja teste",
          estado: "atualizado",
          valor_atual: "6.00",
          valor_texto: "Até 6% de cashback",
          unidade: "percentual",
          url_externa: "https://shopping.inter.co/site-parceiro/lojas/loja-11",
          criado_em: "2026-09-19T10:00:00.000Z",
          atualizado_em: "2026-09-19T10:00:00.000Z",
        },
      ],
      total: 1,
      pagina: 1,
      totaisPorOrigem: { livelo: 0, inter_cashback: 1, inter_produto: 0, pichau: 0 },
    });
    dependencias.existe.mockResolvedValue(true);
    dependencias.alterar.mockResolvedValue(true);
  });

  it("repassa filtros, paginação e usuário autenticado", async () => {
    const resposta = await GET(new Request(
      "http://localhost/api/alertas/acompanhamentos?q=loja&origem=inter_cashback&ordenar=nome&pagina=2&por_pagina=10",
    ));
    const corpo = await resposta.json();

    expect(resposta.status).toBe(200);
    expect(dependencias.buscar).toHaveBeenCalledWith("42", {
      q: "loja",
      origem: "inter_cashback",
      ordenar: "nome",
      pagina: 2,
      porPagina: 10,
    });
    expect(corpo.itens[0].nome).toBe("Loja teste");
    expect(corpo.paginacao).toMatchObject({ total: 1, pagina: 1, por_pagina: 10 });
    expect(corpo.totais_por_origem.inter_cashback).toBe(1);
  });

  it("rejeita filtros inválidos antes de consultar o banco", async () => {
    const resposta = await GET(new Request(
      "http://localhost/api/alertas/acompanhamentos?origem=fonte-inexistente",
    ));

    expect(resposta.status).toBe(400);
    expect(dependencias.buscar).not.toHaveBeenCalled();
  });

  it("preserva o PATCH de alteração pessoal", async () => {
    const resposta = await PATCH(new Request(
      "http://localhost/api/alertas/acompanhamentos",
      { method: "PATCH", body: JSON.stringify({ origem: "pichau", entidade_id: "17", ativo: false }) },
    ));

    expect(resposta.status).toBe(200);
    expect(dependencias.existe).toHaveBeenCalledWith("pichau", "17");
    expect(dependencias.alterar).toHaveBeenCalledWith("42", "pichau", "17", false);
  });
});
