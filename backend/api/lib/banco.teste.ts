import { beforeEach, describe, expect, it, vi } from "vitest";

const bancoFalso = vi.hoisted(() => ({
  consultas: [] as string[],
}));

vi.mock("@neondatabase/serverless", () => ({
  neon: vi.fn(() => async (partes: TemplateStringsArray, ...valores: unknown[]) => {
    bancoFalso.consultas.push(
      partes.reduce(
        (consulta, parte, indice) => consulta + String(valores[indice - 1] ?? "") + parte,
      ),
    );
    return [];
  }),
}));

import { pontuacoes } from "@/lib/banco";

describe("pontuacoes", () => {
  beforeEach(() => {
    bancoFalso.consultas.length = 0;
    process.env.DATABASE_URL = "postgresql://teste:teste@localhost/teste";
  });

  it("considera todas as lojas do catalogo, que ja representam as favoritas", async () => {
    await pontuacoes(42);

    expect(bancoFalso.consultas).toHaveLength(1);
    expect(bancoFalso.consultas[0]).toContain("FROM loja l");
    expect(bancoFalso.consultas[0]).not.toContain("l.favorita");
  });
});
