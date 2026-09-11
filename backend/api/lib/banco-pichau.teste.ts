import { beforeEach, describe, expect, it, vi } from "vitest";

const bancoFalso = vi.hoisted(() => ({
  consultas: [] as string[],
  respostas: [] as unknown[][],
}));

vi.mock("@neondatabase/serverless", () => ({
  neon: vi.fn(() => async (partes: TemplateStringsArray, ...valores: unknown[]) => {
    bancoFalso.consultas.push(
      partes.reduce(
        (consulta, parte, indice) =>
          consulta + String(valores[indice - 1] ?? "") + parte,
      ),
    );
    return bancoFalso.respostas.shift() ?? [];
  }),
}));

import {
  alterarAcompanhamentoPichau,
  buscarCatalogoPichau,
} from "./banco-pichau";

describe("catálogo Pichau", () => {
  beforeEach(() => {
    bancoFalso.consultas.length = 0;
    bancoFalso.respostas.length = 0;
    process.env.DATABASE_URL = "postgresql://teste:teste@localhost/teste";
  });

  it("filtra acompanhadas e disponibilidade antes de paginar", async () => {
    bancoFalso.respostas.push([{ total: 1 }], []);

    await buscarCatalogoPichau(
      "ryzen",
      { aba: "acompanhadas", disponibilidade: "esgotados", ordenar: "preco" },
      1,
      20,
    );

    expect(bancoFalso.consultas[0]).toContain("p.acompanhada = TRUE");
    expect(bancoFalso.consultas[0]).toContain("p.disponibilidade = 'esgotado'");
    expect(bancoFalso.consultas[0]).toContain("p.nome_busca LIKE");
    expect(bancoFalso.consultas[1]).toContain("ORDER BY");
    expect(bancoFalso.consultas[1]).toContain("m.preco_pix");
    expect(bancoFalso.consultas[1]).toContain("LIMIT 20");
  });

  it("persiste o sino global com operação idempotente", async () => {
    bancoFalso.respostas.push([{ id_externo: "PG-7800" }]);

    await expect(alterarAcompanhamentoPichau("PG-7800", true)).resolves.toBe(
      true,
    );
    expect(bancoFalso.consultas[0]).toContain("UPDATE pichau_produto");
    expect(bancoFalso.consultas[0]).toContain("SET acompanhada = true");
    expect(bancoFalso.consultas[0]).toContain("WHERE id_externo = PG-7800");
  });
});
