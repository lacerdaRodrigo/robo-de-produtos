import { beforeEach, describe, expect, it, vi } from "vitest";

const infraestrutura = vi.hoisted(() => ({ neon: vi.fn(), sql: vi.fn() }));
vi.mock("@neondatabase/serverless", () => ({ neon: infraestrutura.neon }));

import { buscarAcompanhamentosPessoais } from "./banco-alertas";

describe("lista pessoal consolidada", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.stubEnv("DATABASE_URL", "postgres://teste.local/radar");
    infraestrutura.neon.mockReturnValue(infraestrutura.sql);
    infraestrutura.sql.mockImplementation((consulta: unknown) => {
      const texto = typeof consulta === "string"
        ? consulta
        : (consulta as TemplateStringsArray).join(" ");
      if (texto.includes("GROUP BY origem")) {
        return Promise.resolve([{ origem: "inter_cashback", total: 1 }]);
      }
      if (texto.includes("count(*)::int AS total")) {
        return Promise.resolve([{ total: 1 }]);
      }
      return Promise.resolve([{
        id: "7",
        origem: "inter_cashback",
        tipo_entidade: "loja",
        entidade_id: "11",
        entidade_externa: "loja-11",
        nome: "Loja teste",
        estado: "atualizado",
        valor_atual: "6.00",
        valor_texto: "Até 6% de cashback",
        unidade: "percentual",
        url_externa: "loja-11",
        criado_em: "2026-09-19T10:00:00.000Z",
        atualizado_em: "2026-09-19T10:00:00.000Z",
      }]);
    });
  });

  it("mantém valores textuais e monta links oficiais por origem", async () => {
    const resultado = await buscarAcompanhamentosPessoais("42", {
      q: "loja",
      origem: "inter_cashback",
      ordenar: "recentes",
      pagina: 1,
      porPagina: 20,
    });

    expect(resultado.total).toBe(1);
    expect(resultado.itens[0]).toMatchObject({
      valor_atual: "6.00",
      valor_texto: "Até 6% de cashback",
      url_externa: "https://shopping.inter.co/site-parceiro/lojas/loja-11",
    });
    expect(resultado.totaisPorOrigem).toEqual({
      livelo: 0,
      inter_cashback: 1,
      inter_produto: 0,
      pichau: 0,
    });
  });
});
