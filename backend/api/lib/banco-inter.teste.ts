import { beforeEach, describe, expect, it, vi } from "vitest";

const bancoFalso = vi.hoisted(() => ({
  consultas: [] as string[],
  respostas: [] as unknown[][],
}));

vi.mock("@neondatabase/serverless", () => ({
  neon: vi.fn(() => async (partes: TemplateStringsArray, ...valores: unknown[]) => {
    bancoFalso.consultas.push(
      partes.reduce(
        (consulta, parte, indice) => consulta + String(valores[indice - 1] ?? "") + parte,
      ),
    );
    return bancoFalso.respostas.shift() ?? [];
  }),
}));

import { buscarCashbacksInter } from "@/lib/banco-inter";

describe("catálogo paginado de cashback Inter", () => {
  beforeEach(() => {
    bancoFalso.consultas.length = 0;
    bancoFalso.respostas.length = 0;
    process.env.DATABASE_URL = "postgresql://teste:teste@localhost/teste";
  });

  it("devolve primeira página e total global após o filtro", async () => {
    bancoFalso.respostas.push([{ total: 37 }], []);

    const resultado = await buscarCashbacksInter("42", {
      q: "",
      ordenar: "cashback",
      apenasAcompanhadas: false,
      pagina: 1,
      porPagina: 20,
    });

    expect(resultado).toEqual({ itens: [], total: 37, pagina: 1 });
    expect(bancoFalso.consultas[0]).toContain("count(*)::int AS total");
    expect(bancoFalso.consultas[1]).toContain("LIMIT 20");
    expect(bancoFalso.consultas[1]).toContain("OFFSET 0");
  });

  it("busca a página seguinte sem carregar as anteriores", async () => {
    bancoFalso.respostas.push([{ total: 37 }], []);

    const resultado = await buscarCashbacksInter("42", {
      q: "",
      ordenar: "nome",
      apenasAcompanhadas: false,
      pagina: 2,
      porPagina: 20,
    });

    expect(resultado.pagina).toBe(2);
    expect(bancoFalso.consultas[1]).toContain("LIMIT 20");
    expect(bancoFalso.consultas[1]).toContain("OFFSET 20");
  });

  it("aplica busca e acompanhadas globalmente antes da contagem", async () => {
    bancoFalso.respostas.push([{ total: 0 }], []);

    const resultado = await buscarCashbacksInter("42", {
      q: "C&A",
      ordenar: "cashback",
      apenasAcompanhadas: true,
      pagina: 1,
      porPagina: 20,
    });

    expect(resultado).toEqual({ itens: [], total: 0, pagina: 1 });
    for (const consulta of bancoFalso.consultas) {
      expect(consulta).toContain("f.loja_inter_id IS NOT NULL");
      expect(consulta).toContain("strpos(l.nome_busca, c&a) > 0");
      expect(consulta).toContain("strpos(l.slug_busca, c&a) > 0");
    }
  });

  it("ordena o ranking global com NUMERIC no Postgres", async () => {
    bancoFalso.respostas.push([{ total: 3 }], []);

    await buscarCashbacksInter("42", {
      q: "",
      ordenar: "cashback",
      apenasAcompanhadas: true,
      pagina: 1,
      porPagina: 2,
    });

    const consulta = bancoFalso.consultas[1];
    expect(consulta).toContain("cashback_principal_valor) > 0");
    expect(consulta).toContain("cashback_principal_valor) END DESC");
    expect(consulta).toContain("LIMIT 2");
    expect(consulta).not.toMatch(/::(double precision|real)/i);
  });
});
