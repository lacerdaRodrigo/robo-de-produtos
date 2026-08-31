import { beforeEach, describe, expect, it, vi } from "vitest";

const dependencias = vi.hoisted(() => ({
  autenticar: vi.fn(),
  resumo: vi.fn(),
  execucaoInter: vi.fn(),
  tentativaInter: vi.fn(),
  cashbacks: vi.fn(),
  produtos: vi.fn(),
  statusProdutos: vi.fn(),
}));

vi.mock("@/lib/autenticacao-api", () => ({
  autenticarRequisicao: dependencias.autenticar,
}));

vi.mock("@/lib/resumo-inicio", () => ({
  carregarResumoInicio: dependencias.resumo,
}));

vi.mock("@/lib/banco-inter", () => ({
  cashbacksInter: dependencias.cashbacks,
  ultimaExecucaoInterValida: dependencias.execucaoInter,
  ultimaTentativaInter: dependencias.tentativaInter,
}));

vi.mock("@/lib/banco-produtos-inter", () => ({
  buscarProdutosDiretosPaginado: dependencias.produtos,
  statusCatalogoProdutos: dependencias.statusProdutos,
}));

import { GET as cashback } from "@/app/api/inter/cashback/route";
import { GET as produtos } from "@/app/api/inter/produtos/route";
import { GET as resumo } from "@/app/api/resumo/route";

async function esperarErroSeguro(resposta: Response, mensagem: string) {
  const texto = await resposta.text();
  expect(resposta.status).toBe(500);
  expect(resposta.headers.get("content-type")).toContain("application/json");
  expect(resposta.headers.get("x-request-id")).toBe("req-teste");
  expect(JSON.parse(texto)).toEqual({
    erro: { codigo: "inesperado", mensagem },
  });
  expect(texto).not.toContain("DATABASE_URL");
  expect(texto).not.toContain("SELECT");
  expect(texto).not.toContain("segredo");
}

describe("erros inesperados das leituras consumidas pelo Flutter", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    dependencias.autenticar.mockResolvedValue({
      ok: true,
      usuario: { id: "42" },
      requisicaoId: "req-teste",
    });
    dependencias.tentativaInter.mockResolvedValue(null);
  });

  it("estrutura a falha de banco do resumo", async () => {
    dependencias.resumo.mockRejectedValue(
      new Error("DATABASE_URL=segredo SELECT * FROM resumo"),
    );

    await esperarErroSeguro(
      await resumo(new Request("http://localhost/api/resumo")),
      "nao foi possivel carregar o resumo",
    );
  });

  it("estrutura a falha de banco do cashback", async () => {
    dependencias.execucaoInter.mockRejectedValue(
      new Error("DATABASE_URL=segredo SELECT * FROM cashback"),
    );

    await esperarErroSeguro(
      await cashback(new Request("http://localhost/api/inter/cashback")),
      "nao foi possivel carregar os cashbacks",
    );
  });

  it("estrutura a falha de banco da busca de produtos", async () => {
    dependencias.produtos.mockRejectedValue(
      new Error("DATABASE_URL=segredo SELECT * FROM produto"),
    );

    await esperarErroSeguro(
      await produtos(new Request("http://localhost/api/inter/produtos?q=tv")),
      "nao foi possivel buscar os produtos",
    );
  });
});
