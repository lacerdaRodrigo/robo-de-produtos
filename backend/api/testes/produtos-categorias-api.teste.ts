import { beforeEach, describe, expect, it, vi } from "vitest";

const dependencias = vi.hoisted(() => ({
  autenticar: vi.fn(),
  buscar: vi.fn(),
  status: vi.fn(),
}));

vi.mock("@/lib/autenticacao-api", () => ({
  autenticarRequisicao: dependencias.autenticar,
}));

vi.mock("@/lib/banco-produtos-inter", () => ({
  buscarProdutosDiretosPaginado: dependencias.buscar,
  statusCatalogoProdutos: dependencias.status,
}));

import { GET } from "@/app/api/inter/produtos/route";

describe("catálogo e categorias externas dos produtos Inter", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    dependencias.autenticar.mockResolvedValue({
      ok: true,
      usuario: { id: "42" },
      requisicaoId: "req-produtos",
    });
    dependencias.buscar.mockResolvedValue({ itens: [], total: 0 });
    dependencias.status.mockResolvedValue({
      atualizado_em: null,
      qualidade: null,
      ultima_tentativa_em: null,
      ultima_tentativa_estado: null,
    });
  });

  it("lista o catálogo sem termo e encaminha a categoria externa exata", async () => {
    const resposta = await GET(
      new Request(
        "http://localhost/api/inter/produtos?categoria=Notebooks%20gamer&pagina=1",
      ),
    );

    expect(resposta.status).toBe(200);
    expect(dependencias.buscar).toHaveBeenCalledWith("", 1, 20, "42", {
      marca: null,
      categoria: "Notebooks gamer",
      sem_categoria: false,
      loja: null,
      preco_min: null,
      preco_max: null,
    });
  });

  it("encaminha Sem categoria sem inventar valor textual no filtro", async () => {
    const resposta = await GET(
      new Request(
        "http://localhost/api/inter/produtos?q=tv&sem_categoria=true",
      ),
    );

    expect(resposta.status).toBe(200);
    expect(dependencias.buscar).toHaveBeenCalledWith(
      "tv",
      1,
      20,
      "42",
      expect.objectContaining({ categoria: null, sem_categoria: true }),
    );
  });

  it("resolve escopo de navegação em categorias externas exatas", async () => {
    const resposta = await GET(
      new Request("http://localhost/api/inter/produtos?q=galaxy&escopo=celulares"),
    );

    expect(resposta.status).toBe(200);
    expect(dependencias.buscar).toHaveBeenCalledWith(
      "galaxy",
      1,
      20,
      "42",
      expect.objectContaining({ categorias: ["Android", "Smartphones"] }),
    );
  });

  it("encaminha Outros como exclusão dinâmica das categorias já mapeadas", async () => {
    const resposta = await GET(
      new Request(
        "http://localhost/api/inter/produtos?q=pipoca&escopo=outros-novas-categorias",
      ),
    );

    expect(resposta.status).toBe(200);
    expect(dependencias.buscar).toHaveBeenCalledWith(
      "pipoca",
      1,
      20,
      "42",
      expect.objectContaining({
        categorias_excluidas: expect.arrayContaining(["Android", "Smartphones"]),
      }),
    );
  });

  it("rejeita termo curto, categoria malformada e combinação ambígua", async () => {
    const termoCurto = await GET(
      new Request("http://localhost/api/inter/produtos?q=t"),
    );
    expect(termoCurto.status).toBe(400);
    expect(dependencias.buscar).not.toHaveBeenCalled();

    const categoriaComEspacos = await GET(
      new Request(
        "http://localhost/api/inter/produtos?categoria=%20Android%20",
      ),
    );
    expect(categoriaComEspacos.status).toBe(400);

    const combinados = await GET(
      new Request(
        "http://localhost/api/inter/produtos?categoria=Android&sem_categoria=true",
      ),
    );
    expect(combinados.status).toBe(400);
  });
});
