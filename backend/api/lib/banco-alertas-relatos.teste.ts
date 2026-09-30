import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const infraestrutura = vi.hoisted(() => ({ neon: vi.fn(), sql: vi.fn() }));
vi.mock("@neondatabase/serverless", () => ({ neon: infraestrutura.neon }));
vi.mock("./firebase-admin", () => ({ mensageriaFirebase: vi.fn() }));

import { buscarRelatosProblema } from "./banco-alertas";

describe("consulta paginada de relatos da conta", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.stubEnv("DATABASE_URL", "postgres://teste.local/radar");
  });

  afterEach(() => {
    vi.unstubAllEnvs();
  });

  it("filtra pela conta, aplica retenção e limita a página no SQL", async () => {
    const consultas: Array<{ texto: string; valores: unknown[] }> = [];
    infraestrutura.neon.mockReturnValue(infraestrutura.sql);
    infraestrutura.sql.mockImplementation(
      (strings: TemplateStringsArray, ...valores: unknown[]) => {
        const texto = strings.join("?");
        consultas.push({ texto, valores });
        if (texto.includes("count(*)::int AS total")) {
          return Promise.resolve([{ total: 21 }]);
        }
        return Promise.resolve([
          {
            id: "519",
            categoria: "dados",
            mensagem: "O catálogo não atualizou.",
            criado_em: "2026-09-28T16:30:00.000Z",
          },
        ]);
      },
    );

    const resultado = await buscarRelatosProblema("42", {
      pagina: 99,
      porPagina: 10,
    });

    expect(resultado).toMatchObject({ total: 21, pagina: 3 });
    expect(resultado.itens).toEqual([
      {
        id: "519",
        categoria: "dados",
        mensagem: "O catálogo não atualizou.",
        criado_em: "2026-09-28T16:30:00.000Z",
      },
    ]);
    expect(consultas).toHaveLength(2);
    for (const consulta of consultas) {
      expect(consulta.texto).toContain("usuario_app_id = ?");
      expect(consulta.texto).toContain("criado_em >= now() - interval '180 days'");
      expect(consulta.valores).toContain("42");
      expect(consulta.texto).not.toContain("versao_app");
    }
    expect(consultas[1].texto).toContain("LIMIT ? OFFSET ?");
    expect(consultas[1].valores).toContain(10);
    expect(consultas[1].valores).toContain(20);
  });
});
