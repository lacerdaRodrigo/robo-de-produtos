import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const infraestrutura = vi.hoisted(() => ({ neon: vi.fn(), sql: vi.fn() }));
vi.mock("@neondatabase/serverless", () => ({ neon: infraestrutura.neon }));

import { buscarAlertas } from "./banco-alertas";

describe("consulta paginada de alertas por origem", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.stubEnv("DATABASE_URL", "postgres://teste.local/radar");
  });

  afterEach(() => {
    vi.unstubAllEnvs();
  });

  it("aplica origem e os demais filtros na contagem e nos itens usando parâmetros", async () => {
    const consultas: Array<{ texto: string; valores: unknown[] }> = [];
    infraestrutura.neon.mockReturnValue(infraestrutura.sql);
    infraestrutura.sql.mockImplementation(
      (strings: TemplateStringsArray, ...valores: unknown[]) => {
        const texto = strings.join("?");
        consultas.push({ texto, valores });
        if (texto.includes("count(*)::int AS total")) {
          return Promise.resolve([{ total: 13, nao_lidos: 13 }]);
        }
        return Promise.resolve([
          {
            id: "91",
            origem: "pichau",
            tipo: "preco",
            entidade_id: "14",
            entidade_externa: "gpu-14",
            entidade_nome: "GPU teste",
            coleta_id: "coleta-17",
            valor_anterior: "1200.00",
            valor_atual: "1100.00",
            unidade: "BRL",
            direcao: "reducao",
            lido: false,
            criado_em: "2026-09-28T10:00:00.000Z",
          },
        ]);
      },
    );

    const resultado = await buscarAlertas("42", {
      pagina: 2,
      porPagina: 5,
      tipo: "preco",
      origem: "pichau",
      somenteNaoLidos: true,
      coleta: "coleta-17",
    });

    expect(resultado).toMatchObject({ total: 13, naoLidos: 13, pagina: 2 });
    expect(resultado.itens).toHaveLength(1);
    expect(consultas).toHaveLength(2);
    for (const consulta of consultas) {
      expect(consulta.texto).toContain("origem = ?");
      expect(consulta.texto).toContain("tipo = ?");
      expect(consulta.texto).toContain("lido = FALSE");
      expect(consulta.texto).toContain("coleta_id = ?");
      expect(consulta.texto).not.toContain("pichau");
      expect(consulta.valores).toContain("pichau");
      expect(consulta.valores).toContain("preco");
      expect(consulta.valores).toContain("coleta-17");
    }
  });
});
