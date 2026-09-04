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
  listarCategoriasInterUsuario: dependencias.listar,
  substituirCategoriasInterUsuario: dependencias.substituir,
}));

import { GET, PATCH } from "@/app/api/inter/produtos/categorias/route";
import { validarSelecaoCategoriasProdutosInter } from "@/lib/categorias-produtos-inter";

const catalogo = {
  configurada: true,
  itens: [
    { valor: "Android", nome: "Android", selecionada: true },
    { valor: null, nome: "Sem categoria", selecionada: false },
  ],
};

describe("categorias externas dos produtos Inter", () => {
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

  it("valida e deduplica valores externos sem impedir seleção vazia", () => {
    expect(validarSelecaoCategoriasProdutosInter({ categorias: [] })).toEqual({
      ok: true,
      valor: { categorias: [], sem_categoria: false },
    });
    expect(
      validarSelecaoCategoriasProdutosInter({
        categorias: ["Android", "Android", "Notebooks gamer"],
        sem_categoria: true,
      }),
    ).toEqual({
      ok: true,
      valor: {
        categorias: ["Android", "Notebooks gamer"],
        sem_categoria: true,
      },
    });
    expect(
      validarSelecaoCategoriasProdutosInter({ categorias: [" Android "] }),
    ).toEqual({
      ok: false,
      mensagem: "categorias contem valor externo invalido",
    });
  });

  it("lista as categorias reais para a pessoa autenticada", async () => {
    const resposta = await GET(
      new Request("http://localhost/api/inter/produtos/categorias"),
    );

    expect(resposta.status).toBe(200);
    expect(await resposta.json()).toEqual(catalogo);
    expect(dependencias.listar).toHaveBeenCalledWith("42");
    expect(resposta.headers.get("x-request-id")).toBe("req-categorias");
  });

  it("substitui a seleção externa e devolve o estado persistido", async () => {
    const resposta = await PATCH(
      new Request("http://localhost/api/inter/produtos/categorias", {
        method: "PATCH",
        body: JSON.stringify({
          categorias: ["Android"],
          sem_categoria: true,
        }),
      }),
    );

    expect(resposta.status).toBe(200);
    expect(dependencias.substituir).toHaveBeenCalledWith(
      "42",
      ["Android"],
      true,
    );
    expect(await resposta.json()).toEqual(catalogo);
  });

  it("não persiste corpo inválido nem categoria inexistente no catálogo", async () => {
    const corpoInvalido = await PATCH(
      new Request("http://localhost/api/inter/produtos/categorias", {
        method: "PATCH",
        body: JSON.stringify({ categorias: [" Android "] }),
      }),
    );
    expect(corpoInvalido.status).toBe(400);
    expect(dependencias.substituir).not.toHaveBeenCalled();

    dependencias.substituir.mockResolvedValueOnce({
      ok: false,
      invalidas: ["Não existe"],
      sem_categoria_indisponivel: true,
    });
    const desconhecida = await PATCH(
      new Request("http://localhost/api/inter/produtos/categorias", {
        method: "PATCH",
        body: JSON.stringify({
          categorias: ["Não existe"],
          sem_categoria: true,
        }),
      }),
    );
    expect(desconhecida.status).toBe(400);
    expect(await desconhecida.json()).toEqual({
      erro: {
        codigo: "validacao",
        mensagem:
          "categorias inexistentes no catálogo atual: Não existe, Sem categoria",
      },
    });
  });
});
