import { beforeEach, describe, expect, it, vi } from "vitest";

const dependencias = vi.hoisted(() => ({
  autenticar: vi.fn(),
  listar: vi.fn(),
  substituir: vi.fn(),
}));

vi.mock("@/lib/autenticacao-api", () => ({
  autenticarRequisicao: dependencias.autenticar,
}));

vi.mock("@/lib/banco-categorias-produtos-inter", () => ({
  listarCategoriasRadarUsuario: dependencias.listar,
  substituirCategoriasRadarUsuario: dependencias.substituir,
}));

import { GET, PATCH } from "@/app/api/inter/produtos/categorias/route";
import { validarSelecaoCategoriasProdutosInter } from "@/lib/categorias-produtos-inter";

const catalogo = {
  configurada: true,
  itens: [
    {
      id: "1",
      slug: "eletronicos",
      nome: "Eletrônicos",
      categoria_pai_slug: null,
      ordem: 10,
      selecionada: true,
      acompanhada: true,
    },
  ],
};

describe("categorias dos produtos Inter", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    dependencias.autenticar.mockResolvedValue({
      ok: true,
      usuario: { id: "42" },
      requisicaoId: "req-categorias",
    });
    dependencias.listar.mockResolvedValue(catalogo);
    dependencias.substituir.mockResolvedValue({ ok: true, total: 1 });
  });

  it("valida e deduplica slugs sem impedir seleção vazia", () => {
    expect(validarSelecaoCategoriasProdutosInter({ categorias: [] })).toEqual({
      ok: true,
      valor: { categorias: [] },
    });
    expect(
      validarSelecaoCategoriasProdutosInter({
        categorias: ["celulares", "celulares", "cabos"],
      }),
    ).toEqual({
      ok: true,
      valor: { categorias: ["celulares", "cabos"] },
    });
    expect(
      validarSelecaoCategoriasProdutosInter({ categorias: ["Celulares"] }),
    ).toEqual({
      ok: false,
      mensagem: "categorias contem identificador invalido",
    });
  });

  it("lista a árvore para a pessoa autenticada", async () => {
    const resposta = await GET(
      new Request("http://localhost/api/inter/produtos/categorias"),
    );

    expect(resposta.status).toBe(200);
    expect(await resposta.json()).toEqual(catalogo);
    expect(dependencias.listar).toHaveBeenCalledWith("42");
    expect(resposta.headers.get("x-request-id")).toBe("req-categorias");
  });

  it("substitui a seleção e devolve o estado persistido", async () => {
    const resposta = await PATCH(
      new Request("http://localhost/api/inter/produtos/categorias", {
        method: "PATCH",
        body: JSON.stringify({ categorias: ["eletronicos"] }),
      }),
    );

    expect(resposta.status).toBe(200);
    expect(dependencias.substituir).toHaveBeenCalledWith("42", [
      "eletronicos",
    ]);
    expect(await resposta.json()).toEqual(catalogo);
  });

  it("não persiste corpo inválido nem categoria desconhecida", async () => {
    const corpoInvalido = await PATCH(
      new Request("http://localhost/api/inter/produtos/categorias", {
        method: "PATCH",
        body: JSON.stringify({ categorias: ["TVs"] }),
      }),
    );
    expect(corpoInvalido.status).toBe(400);
    expect(dependencias.substituir).not.toHaveBeenCalled();

    dependencias.substituir.mockResolvedValueOnce({
      ok: false,
      invalidas: ["nao-existe"],
    });
    const desconhecida = await PATCH(
      new Request("http://localhost/api/inter/produtos/categorias", {
        method: "PATCH",
        body: JSON.stringify({ categorias: ["nao-existe"] }),
      }),
    );
    expect(desconhecida.status).toBe(400);
    expect(await desconhecida.json()).toEqual({
      erro: {
        codigo: "validacao",
        mensagem: "categorias inexistentes ou inativas: nao-existe",
      },
    });
  });
});
