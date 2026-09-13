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

import {
  alterarAcompanhamentoPichau,
  buscarCatalogoPichau,
  resumoPichauPersistido,
} from "./banco-pichau";

const produto = {
  id_externo: "PG-1",
  sku: "SKU-1",
  nome: "PC Gamer PG-1",
  marca: "Pichau",
  categoria_externa: "PC Gamer",
  url_produto: "https://www.pichau.com.br/pg-1",
  presente_no_catalogo: true,
  disponibilidade: "disponivel",
  preco_original_texto: null,
  preco_pix_texto: "R$ 4.000,00",
  desconto_pix_texto: null,
  preco_cartao_texto: null,
  parcelamento: null,
  sem_juros: null,
  etiquetas: [],
  atualizado_em: "2026-09-13T00:00:00Z",
  acompanhada: true,
};

describe("persistência do acompanhamento Pichau", () => {
  beforeEach(() => {
    bancoFalso.consultas.length = 0;
    bancoFalso.respostas.length = 0;
    process.env.DATABASE_URL = "postgresql://teste:teste@localhost/teste";
  });

  it("expõe contagem global de catálogo e acompanhadas", async () => {
    bancoFalso.respostas.push([{
      ultima_tentativa_em: null,
      ultima_tentativa_estado: null,
      ultimo_sucesso_em: null,
      qualidade: "completa",
      total_catalogo: 1169,
      acompanhadas: 17,
      produtos_ativos: 1169,
      produtos_esgotados: 12,
    }]);

    await expect(resumoPichauPersistido()).resolves.toMatchObject({
      total_catalogo: 1169,
      acompanhadas: 17,
      produtos_ativos: 1169,
    });
    expect(bancoFalso.consultas[0]).toContain("ELSE p.acompanhada END");
  });

  it("consulta acompanhadas sem teto de 16 e preserva paginação", async () => {
    bancoFalso.respostas.push(
      [{ total: 17 }],
      Array.from({ length: 17 }, (_, indice) => ({ ...produto, id_externo: `PG-${indice + 1}` })),
    );

    const resultado = await buscarCatalogoPichau({
      q: "",
      aba: "acompanhadas",
      disponibilidade: "todas",
      ordenar: "nome",
      pagina: 1,
      porPagina: 50,
    });

    expect(resultado.total).toBe(17);
    expect(resultado.itens).toHaveLength(17);
    expect(bancoFalso.consultas[0]).toContain("p.acompanhada = TRUE");
    expect(bancoFalso.consultas[1]).toContain("LIMIT 50");
    expect(bancoFalso.consultas[1]).toContain("p.acompanhada");
  });

  it("usa o acompanhamento pessoal quando recebe o usuário autenticado", async () => {
    bancoFalso.respostas.push(
      [{ total: 1 }],
      [{ ...produto, acompanhada: true }],
    );

    await buscarCatalogoPichau({
      q: "",
      aba: "acompanhadas",
      disponibilidade: "todas",
      ordenar: "nome",
      pagina: 1,
      porPagina: 20,
    }, "42");

    expect(bancoFalso.consultas[0]).toContain("acompanhamento_usuario");
    expect(bancoFalso.consultas[0]).toContain("acompanhamento.origem = 'pichau'");
    expect(bancoFalso.consultas[1]).toContain("CASE WHEN true");
  });

  it("altera o estado por ID externo de forma idempotente", async () => {
    bancoFalso.respostas.push([{ id_externo: "PG-1", acompanhada: true }]);

    await expect(alterarAcompanhamentoPichau("PG-1", true)).resolves.toEqual({
      id_externo: "PG-1",
      acompanhada: true,
    });
    expect(bancoFalso.consultas[0]).toContain("UPDATE pichau_produto");
    expect(bancoFalso.consultas[0]).toContain("SET acompanhada = true");
  });
});
