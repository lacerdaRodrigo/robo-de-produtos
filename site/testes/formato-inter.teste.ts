import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

import {
  DESCRICAO_INTER_AUSENTE,
  descricaoInter,
  estadoInter,
  filtrarCashbacksInter,
  idadeInter,
  LINK_SHOPPING_INTER,
  normalizarBuscaInter,
  ordenarCashbacksInter,
} from "../lib/formato-inter";

describe("CT-190 busca normalizada do Inter", () => {
  const lojas = [
    { nome: "C&A", slug: "ca" },
    { nome: "Riachuelo", slug: "riachuelo" },
  ];

  it("busca por nome ou slug sem diferenciar acento, caixa e espaços", () => {
    expect(normalizarBuscaInter("  SÃO   PAULO ")).toBe("sao paulo");
    expect(filtrarCashbacksInter(lojas, "c&a")).toEqual([lojas[0]]);
    expect(filtrarCashbacksInter(lojas, "CA")).toEqual([lojas[0]]);
  });
});

describe("CT-191 ranking do cashback", () => {
  const item = (nome: string, valor: string | null, encontrada = true) => ({
    nome,
    slug: nome.toLowerCase(),
    cashback_principal_valor: valor,
    encontrada,
  });

  it("ordena positivos, zero, nulo e não encontrada", () => {
    const nomes = ordenarCashbacksInter([
      item("Amazon", "0"),
      item("Riachuelo", "15"),
      item("Sem número", null),
      item("Magalu", "20"),
      item("Ausente", null, false),
    ]).map((loja) => loja.nome);
    expect(nomes).toEqual(["Magalu", "Riachuelo", "Amazon", "Sem número", "Ausente"]);
  });
});

describe("CT-192/193 descrição da promoção", () => {
  it("preserva todas as faixas da Magalu", () => {
    const texto = "20% no aparelho\n11% vendidos pela Magalu\n2% nas demais condições";
    expect(descricaoInter(texto)).toContain("20%");
    expect(descricaoInter(texto)).toContain("11%");
    expect(descricaoInter(texto)).toContain("2%");
  });

  it("ausência usa a frase neutra exata", () => {
    expect(descricaoInter(null)).toBe(DESCRICAO_INTER_AUSENTE);
    expect(descricaoInter("  ")).toBe(DESCRICAO_INTER_AUSENTE);
  });
});

describe("CT-194 link genérico", () => {
  it("usa somente a página de lojas aprovada", () => {
    expect(LINK_SHOPPING_INTER).toBe("https://shopping.inter.co/site-parceiro/lojas");
  });
});

describe("CT-195/197/198 fronteiras da página", () => {
  const pagina = readFileSync(resolve(process.cwd(), "app/inter/page.tsx"), "utf8");
  const acoes = readFileSync(resolve(process.cwd(), "app/inter/lojas/acoes.ts"), "utf8");

  it("não injeta HTML nem usa imagem externa", () => {
    expect(pagina).not.toContain("dangerouslySetInnerHTML");
    expect(pagina).not.toContain("imageUrl");
  });

  it("todas as mutações exigem sessão antes do banco", () => {
    const funcoes = acoes.split("export async function ").slice(1);
    expect(funcoes).toHaveLength(3);
    for (const funcao of funcoes) {
      const sessao = funcao.indexOf("await exigirSessao()");
      const indicesDeBanco = [
        "acompanharLojaInter(",
        "deixarDeAcompanharLojaInter(",
        "esperaAteProximoDisparoInter(",
      ]
        .map((termo) => funcao.indexOf(termo))
        .filter((indice) => indice >= 0);
      expect(sessao).toBeGreaterThanOrEqual(0);
      expect(sessao).toBeLessThan(Math.min(...indicesDeBanco));
    }
  });
});

describe("CT-196 estados da atualização", () => {
  const agora = Date.parse("2026-08-15T12:00:00Z");

  it("separa sem execução, andamento, falha, atual e atrasado", () => {
    expect(estadoInter({})).toBe("sem-execucao");
    expect(estadoInter({ estadoTentativa: "iniciada" })).toBe("atualizando");
    expect(estadoInter({ estadoTentativa: "falha" })).toBe("falha");
    expect(
      estadoInter({
        estadoTentativa: "sucesso",
        concluidaEm: "2026-08-15T11:00:00Z",
        agora,
      }),
    ).toBe("atual");
    expect(
      estadoInter({
        estadoTentativa: "sucesso",
        concluidaEm: "2026-08-14T11:00:00Z",
        agora,
      }),
    ).toBe("atrasado");
    expect(idadeInter("2026-08-14T11:00:00Z", agora).atrasado).toBe(true);
  });
});
