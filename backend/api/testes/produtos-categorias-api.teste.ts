import { beforeEach, describe, expect, it, vi } from "vitest";

const dependencias = vi.hoisted(() => ({
  autenticar: vi.fn(),
  buscar: vi.fn(),
  categoriaExiste: vi.fn(),
  status: vi.fn(),
}));

vi.mock("@/lib/autenticacao-api", () => ({
  autenticarRequisicao: dependencias.autenticar,
}));

vi.mock("@/lib/banco-produtos-inter", () => ({
  buscarProdutosDiretosPaginado: dependencias.buscar,
  statusCatalogoProdutos: dependencias.status,
}));

vi.mock("@/lib/banco-categorias-produtos-inter", () => ({
  categoriaRadarAtivaExiste: dependencias.categoriaExiste,
}));

import { GET } from "@/app/api/inter/produtos/route";

describe("catálogo e filtro Radar dos produtos Inter", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    dependencias.autenticar.mockResolvedValue({
      ok: true,
      usuario: { id: "42" },
      requisicaoId: "req-produtos",
    });
    dependencias.buscar.mockResolvedValue({ itens: [], total: 0 });
    dependencias.categoriaExiste.mockResolvedValue(true);
    dependencias.status.mockResolvedValue({
      atualizado_em: null,
      qualidade: null,
      ultima_tentativa_em: null,
      ultima_tentativa_estado: null,
    });
  });

  it("lista o catálogo sem termo e mantém categoria externa separada", async () => {
    const resposta = await GET(
      new Request(
        "http://localhost/api/inter/produtos?categoria=Telefonia&pagina=1",
      ),
    );

    expect(resposta.status).toBe(200);
    expect(dependencias.buscar).toHaveBeenCalledWith("", 1, 20, "42", {
      marca: null,
      categoria: "Telefonia",
      categoria_radar: null,
      loja: null,
      preco_min: null,
      preco_max: null,
    });
    expect(dependencias.categoriaExiste).not.toHaveBeenCalled();
  });

  it("valida e encaminha o filtro temporário categoria_radar", async () => {
    const resposta = await GET(
      new Request(
        "http://localhost/api/inter/produtos?q=tv&categoria_radar=eletronicos",
      ),
    );

    expect(resposta.status).toBe(200);
    expect(dependencias.categoriaExiste).toHaveBeenCalledWith("eletronicos");
    expect(dependencias.buscar).toHaveBeenCalledWith(
      "tv",
      1,
      20,
      "42",
      expect.objectContaining({ categoria_radar: "eletronicos" }),
    );
  });

  it("rejeita termo curto e categoria Radar inexistente", async () => {
    const termoCurto = await GET(
      new Request("http://localhost/api/inter/produtos?q=t"),
    );
    expect(termoCurto.status).toBe(400);
    expect(dependencias.buscar).not.toHaveBeenCalled();

    dependencias.categoriaExiste.mockResolvedValueOnce(false);
    const categoriaInexistente = await GET(
      new Request(
        "http://localhost/api/inter/produtos?categoria_radar=nao-existe",
      ),
    );
    expect(categoriaInexistente.status).toBe(400);
    expect(await categoriaInexistente.json()).toEqual({
      erro: {
        codigo: "validacao",
        mensagem: "categoria_radar inexistente ou inativa",
      },
    });
    expect(dependencias.buscar).not.toHaveBeenCalled();
  });
});
