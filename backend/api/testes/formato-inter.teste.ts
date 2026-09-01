import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

import {
  DESCRICAO_INTER_AUSENTE,
  compararDecimaisInter,
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

  it("busca por nome ou slug sem diferenciar símbolos, acento, caixa e espaços", () => {
    expect(normalizarBuscaInter("  SÃO   PAULO ")).toBe("saopaulo");
    expect(normalizarBuscaInter("C&A")).toBe("cea");
    expect(normalizarBuscaInter(" C E A ")).toBe("cea");
    expect(filtrarCashbacksInter(lojas, "cea")).toEqual([lojas[0]]);
    expect(filtrarCashbacksInter(lojas, "c&a")).toEqual([lojas[0]]);
    expect(filtrarCashbacksInter(lojas, "CA")).toEqual([lojas[0]]);
    expect(
      filtrarCashbacksInter([{ nome: "São Paulo", slug: "sao-paulo" }], "sao"),
    ).toHaveLength(1);
    expect(
      filtrarCashbacksInter([{ nome: "Magalu", slug: "magalu" }], "  MAGALU  "),
    ).toHaveLength(1);
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

  it("compara precisão decimal sem Number", () => {
    expect(compararDecimaisInter("9007199254740992.0000002", "9007199254740992.0000001")).toBe(1);
    expect(compararDecimaisInter("12,010", "12.01")).toBe(0);
    expect(compararDecimaisInter(null, "0")).toBe(-1);
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

describe("CT-282 retrato válido, falha e favorita ausente", () => {
  const banco = readFileSync(resolve(process.cwd(), "lib/banco-inter.ts"), "utf8");
  const rota = readFileSync(
    resolve(process.cwd(), "app/api/inter/cashback/route.ts"),
    "utf8",
  );

  it("expõe o catálogo ativo com o estado de favorita e a última tentativa", () => {
    expect(banco).toContain("(f.loja_inter_id IS NOT NULL) AS favorita");
    expect(banco).toContain("WHERE l.ativa = TRUE");
    expect(rota).toContain("ultimaTentativaInter()");
    expect(rota).toContain("ultima_tentativa_estado");
    expect(rota).toContain("atualizado_em: execucao?.concluida_em ?? null");
    expect(rota).toContain("buscarCashbacksInter(execucao.id");
    expect(rota).not.toContain(".filter((loja)");
  });
});
