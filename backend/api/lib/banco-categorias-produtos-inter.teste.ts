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
  categoriaRadarAtivaExiste,
  listarCategoriasRadarUsuario,
  substituirCategoriasRadarUsuario,
} from "@/lib/banco-categorias-produtos-inter";

describe("persistência das categorias dos produtos Inter", () => {
  beforeEach(() => {
    bancoFalso.consultas.length = 0;
    bancoFalso.respostas.length = 0;
    process.env.DATABASE_URL = "postgresql://teste:teste@localhost/teste";
  });

  it("resolve descendentes dinamicamente e preserva seleção direta", async () => {
    bancoFalso.respostas.push([{ configurada: true }], [
      {
        id: "1",
        slug: "eletronicos",
        nome: "Eletrônicos",
        categoria_pai_slug: null,
        ordem: 10,
        selecionada: true,
        acompanhada: true,
      },
    ]);

    const resultado = await listarCategoriasRadarUsuario("42");

    expect(resultado.configurada).toBe(true);
    expect(resultado.itens[0].selecionada).toBe(true);
    expect(bancoFalso.consultas[1].texto).toContain("WITH RECURSIVE");
    expect(bancoFalso.consultas[1].texto).toContain(
      "JOIN efetivas pai ON filha.categoria_pai_id = pai.id",
    );
  });

  it("substitui por diferença e rejeita slugs inativos ou inexistentes", async () => {
    bancoFalso.respostas.push([
      { ok: true, invalidas: [], total: 2 },
      { ok: false, invalidas: ["desconhecida"], total: 0 },
    ]);

    await expect(
      substituirCategoriasRadarUsuario("42", ["celulares", "cabos"]),
    ).resolves.toEqual({ ok: true, total: 2 });
    await expect(
      substituirCategoriasRadarUsuario("42", ["desconhecida"]),
    ).resolves.toEqual({ ok: false, invalidas: ["desconhecida"] });

    const consulta = bancoFalso.consultas[0].texto;
    expect(consulta).toContain("DELETE FROM categoria_radar_acompanhada");
    expect(consulta).toContain("NOT IN (SELECT id FROM validas)");
    expect(consulta).toContain("ON CONFLICT (usuario_app_id, categoria_radar_id)");
    expect(consulta).toContain("WHERE (SELECT ok FROM validacao)");
  });

  it("valida categoria Radar ativa sem inferir classificação", async () => {
    bancoFalso.respostas.push([{ existe: true }], [{ existe: false }]);

    await expect(categoriaRadarAtivaExiste("celulares")).resolves.toBe(true);
    await expect(categoriaRadarAtivaExiste("inativa")).resolves.toBe(false);

    expect(bancoFalso.consultas[0].texto).toContain("slug = celulares");
    expect(bancoFalso.consultas[0].texto).toContain("ativo = TRUE");
  });
});
