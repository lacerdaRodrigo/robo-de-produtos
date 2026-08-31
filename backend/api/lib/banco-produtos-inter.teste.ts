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
  EXPIRACAO_EXECUCAO_PRODUTOS_SEGUNDOS,
  buscarProdutosDiretosPaginado,
  resumoProdutosPersistido,
  statusCatalogoProdutos,
} from "@/lib/banco-produtos-inter";

const item = (loja: string, atualizadaEm: string) => ({
  loja_slug: loja,
  atualizada_em: atualizadaEm,
});
const agora = new Date("2026-08-30T14:00:00Z");

describe("qualidade e frescor dos resultados de produtos", () => {
  beforeEach(() => {
    bancoFalso.consultas.length = 0;
    bancoFalso.respostas.length = 0;
    process.env.DATABASE_URL = "postgresql://teste:teste@localhost/teste";
  });

  it("usa a execução da única loja presente no resultado", async () => {
    bancoFalso.respostas.push([
      {
        loja_slug: "loja-a",
        qualidade: "completa",
        ultima_tentativa_em: "2026-08-30T11:00:00Z",
        ultima_tentativa_estado: "sucesso",
      },
    ]);

    await expect(
      statusCatalogoProdutos([item("loja-a", "2026-08-30T10:00:00Z")], agora),
    ).resolves.toEqual({
      atualizado_em: "2026-08-30T10:00:00Z",
      qualidade: "completa",
      ultima_tentativa_em: "2026-08-30T11:00:00Z",
      ultima_tentativa_estado: "sucesso",
    });
  });

  it("consolida várias lojas pela medição mais antiga e pela pior qualidade", async () => {
    bancoFalso.respostas.push([
      {
        loja_slug: "loja-a",
        qualidade: "completa",
        ultima_tentativa_em: "2026-08-30T11:00:00Z",
        ultima_tentativa_estado: "sucesso",
      },
      {
        loja_slug: "loja-b",
        qualidade: "degradada",
        ultima_tentativa_em: "2026-08-30T12:00:00Z",
        ultima_tentativa_estado: "falha",
      },
    ]);

    await expect(
      statusCatalogoProdutos(
        [
          item("loja-a", "2026-08-30T10:00:00Z"),
          item("loja-b", "2026-08-29T08:00:00Z"),
        ],
        agora,
      ),
    ).resolves.toEqual({
      atualizado_em: "2026-08-29T08:00:00Z",
      qualidade: "degradada",
      ultima_tentativa_em: "2026-08-30T12:00:00Z",
      ultima_tentativa_estado: "parcial",
    });
  });

  it("ignora uma execução global mais recente de loja fora da página", async () => {
    bancoFalso.respostas.push([
      {
        loja_slug: "loja-a",
        qualidade: "completa",
        ultima_tentativa_em: "2026-08-29T10:00:00Z",
        ultima_tentativa_estado: "sucesso",
      },
      {
        loja_slug: "loja-d-fora",
        qualidade: "degradada",
        ultima_tentativa_em: "2026-08-30T13:00:00Z",
        ultima_tentativa_estado: "iniciada",
      },
    ]);

    const status = await statusCatalogoProdutos(
      [item("loja-a", "2026-08-29T09:00:00Z")],
      agora,
    );

    expect(status.qualidade).toBe("completa");
    expect(status.ultima_tentativa_estado).toBe("sucesso");
    expect(bancoFalso.consultas[0].texto).toContain("loja.slug = ANY(loja-a::text[])");
  });

  it("mantém o último catálogo enquanto uma loja relevante está atualizando", async () => {
    bancoFalso.respostas.push([
      {
        loja_slug: "loja-a",
        qualidade: "completa",
        ultima_tentativa_em: "2026-08-30T13:00:00Z",
        ultima_tentativa_estado: "iniciada",
      },
    ]);

    const status = await statusCatalogoProdutos(
      [item("loja-a", "2026-08-29T09:00:00Z")],
      agora,
    );

    expect(status.atualizado_em).toBe("2026-08-29T09:00:00Z");
    expect(status.ultima_tentativa_estado).toBe("iniciada");
  });

  it("expõe execução abandonada como falha sem apagar o snapshot", async () => {
    bancoFalso.respostas.push([
      {
        loja_slug: "loja-a",
        qualidade: "degradada",
        ultima_tentativa_em: "2026-08-29T01:00:00Z",
        ultima_tentativa_estado: "iniciada",
      },
    ]);

    const status = await statusCatalogoProdutos(
      [item("loja-a", "2026-08-28T09:00:00Z")],
      agora,
    );

    expect(status).toEqual({
      atualizado_em: "2026-08-28T09:00:00Z",
      qualidade: "degradada",
      ultima_tentativa_em: "2026-08-29T01:00:00Z",
      ultima_tentativa_estado: "falha",
    });
    expect(bancoFalso.consultas[0].texto).not.toContain("UPDATE produto_direto_inter");
    expect(bancoFalso.consultas[0].texto).not.toContain("DELETE FROM");
  });

  it("retorna estado indisponível sem resultado ou execução válida", async () => {
    await expect(statusCatalogoProdutos([], agora)).resolves.toEqual({
      atualizado_em: null,
      qualidade: null,
      ultima_tentativa_em: null,
      ultima_tentativa_estado: null,
    });
    expect(bancoFalso.consultas).toHaveLength(0);
  });

  it("preserva LIMIT, OFFSET e decimais textuais na busca paginada", async () => {
    bancoFalso.respostas.push([{ total: 25 }], []);

    const pagina = await buscarProdutosDiretosPaginado("celular", 2, 20, {
      preco_min: "1000.50",
    });

    expect(pagina).toEqual({ itens: [], total: 25 });
    expect(bancoFalso.consultas).toHaveLength(2);
    expect(bancoFalso.consultas[1].texto).toContain("LIMIT $3 OFFSET $4");
    expect(bancoFalso.consultas[1].valores[0]).toEqual([
      "smartphone",
      "1000.50",
      20,
      20,
    ]);
  });

  it("reconcilia somente rodadas iniciadas antigas antes de montar o resumo", async () => {
    bancoFalso.respostas.push([], [
      {
        ultima_tentativa_em: "2026-08-29T01:00:00Z",
        ultima_tentativa_estado: "falha",
        dados_mais_antigos_em: "2026-08-28T09:00:00Z",
        dados_mais_recentes_em: "2026-08-28T10:00:00Z",
        qualidade: "degradada",
        lojas_selecionadas: 2,
        lojas_sem_coleta: 0,
        produtos_ativos: 50,
      },
    ]);

    const resumo = await resumoProdutosPersistido();

    expect(resumo.ultima_tentativa_estado).toBe("falha");
    expect(resumo.qualidade).toBe("degradada");
    expect(resumo.produtos_ativos).toBe(50);
    const reconciliacao = bancoFalso.consultas[0].texto;
    expect(reconciliacao).toContain("WHERE estado = 'iniciada'");
    expect(reconciliacao).toContain(`secs => ${EXPIRACAO_EXECUCAO_PRODUTOS_SEGUNDOS}`);
    expect(reconciliacao).toContain("loja.estado = 'iniciada'");
    expect(reconciliacao).toContain("rodada.estado = 'iniciada'");
    expect(reconciliacao).not.toContain("UPDATE produto_direto_inter");
    expect(reconciliacao).not.toContain("DELETE FROM");
  });
});
