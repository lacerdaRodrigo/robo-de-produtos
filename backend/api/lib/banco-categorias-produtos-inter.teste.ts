import { beforeEach, describe, expect, it, vi } from "vitest";

const bancoFalso = vi.hoisted(() => ({
  consultas: [] as Array<{ texto: string; valores: unknown[] }>,
  respostas: [] as unknown[][],
}));

vi.mock("@neondatabase/serverless", () => ({
  neon: vi.fn(
    () =>
      async (consulta: string | TemplateStringsArray, ...valores: unknown[]) => {
        const texto =
          typeof consulta === "string"
            ? consulta
            : consulta.reduce(
                (resultado, parte, indice) =>
                  resultado + String(valores[indice - 1] ?? "") + parte,
              );
        bancoFalso.consultas.push({ texto, valores });
        return bancoFalso.respostas.shift() ?? [];
      },
  ),
}));

import {
  listarCategoriasInterUsuario,
  substituirCategoriasInterUsuario,
} from "@/lib/banco-categorias-produtos-inter";

describe("persistência das categorias externas dos produtos Inter", () => {
  beforeEach(() => {
    bancoFalso.consultas.length = 0;
    bancoFalso.respostas.length = 0;
    process.env.DATABASE_URL = "postgresql://teste:teste@localhost/teste";
  });

  it("lista somente categorias reais do catálogo e preserva Sem categoria como null", async () => {
    bancoFalso.respostas.push(
      [{ configurada: true }],
      [
        { valor: "Android", nome: "Android", selecionada: true },
        { valor: null, nome: "Sem categoria", selecionada: false },
      ],
    );

    const resultado = await listarCategoriasInterUsuario("42");

    expect(resultado).toEqual({
      configurada: true,
      itens: [
        { valor: "Android", nome: "Android", selecionada: true },
        { valor: null, nome: "Sem categoria", selecionada: false },
      ],
    });
    const consulta = bancoFalso.consultas[1].texto;
    expect(consulta).toContain("produto_direto_inter");
    expect(consulta).toContain("categoria_inter_acompanhada");
    expect(consulta).toContain("Sem categoria");
    expect(consulta).not.toContain("categoria_radar");
    expect(consulta).not.toContain("WITH RECURSIVE");
  });

  it("substitui a seleção por valores externos exatos", async () => {
    bancoFalso.respostas.push([
      {
        ok: true,
        invalidas: [],
        sem_categoria_indisponivel: false,
        total: 3,
      },
    ]);

    await expect(
      substituirCategoriasInterUsuario(
        "42",
        ["Android", "Notebooks gamer"],
        true,
      ),
    ).resolves.toEqual({ ok: true, total: 3 });

    const consulta = bancoFalso.consultas[0].texto;
    expect(consulta).toContain("DELETE FROM categoria_inter_acompanhada");
    expect(consulta).toContain("acompanhada.categoria IS NOT DISTINCT");
    expect(consulta).toContain("ON CONFLICT (usuario_app_id, categoria)");
    expect(consulta).not.toContain("categoria_radar");
  });

  it("rejeita categoria que não existe no catálogo atual", async () => {
    bancoFalso.respostas.push([
      {
        ok: false,
        invalidas: ["Desconhecida"],
        sem_categoria_indisponivel: true,
        total: 0,
      },
    ]);

    await expect(
      substituirCategoriasInterUsuario("42", ["Desconhecida"], true),
    ).resolves.toEqual({
      ok: false,
      invalidas: ["Desconhecida"],
      sem_categoria_indisponivel: true,
    });
  });
});
