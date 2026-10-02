import { describe, expect, it } from "vitest";

import { formatarCorpoPush, type EventoPush } from "./notificacoes-formatacao";

function evento(overrides: Partial<EventoPush>): EventoPush {
  return {
    origem: "inter_produto",
    tipo: "preco",
    entidade_nome: "Notebook A",
    valor_atual: "1299.900000",
    loja_nome: "Loja Exemplo",
    ...overrides,
  };
}

describe("mensagens personalizadas de push", () => {
  it("identifica produto, loja e novo preço com formatação brasileira exata", () => {
    expect(formatarCorpoPush(evento({}))).toBe(
      "Olá! Loja Exemplo: Notebook A agora custa R$ 1.299,90.",
    );
  });

  it("identifica cashback do produto e preserva casas decimais", () => {
    expect(
      formatarCorpoPush(evento({ tipo: "cashback", valor_atual: "8.500000" })),
    ).toBe(
      "Olá! Loja Exemplo: cashback de Notebook A agora é 8,5%.",
    );
  });

  it("identifica cashback de loja parceira", () => {
    expect(
      formatarCorpoPush(
        evento({
          origem: "inter_cashback",
          tipo: "cashback",
          entidade_nome: "Loja Inter",
          loja_nome: null,
          valor_atual: "6.00",
        }),
      ),
    ).toBe(
      "Olá! Loja Inter: cashback agora é 6%.",
    );
  });

  it("explicita que a pontuação Livelo é por real", () => {
    expect(
      formatarCorpoPush(
        evento({
          origem: "livelo",
          tipo: "pontuacao",
          entidade_nome: "Parceira Exemplo",
          loja_nome: null,
          valor_atual: "3.000000",
        }),
      ),
    ).toBe(
      "Olá! Parceira Exemplo: pontuação agora é 3 pontos por real.",
    );
  });

  it("identifica o preço Pix de produto Pichau", () => {
    expect(
      formatarCorpoPush(
        evento({
          origem: "pichau",
          tipo: "preco",
          entidade_nome: "Placa de vídeo",
          loja_nome: null,
          valor_atual: "4999.90",
        }),
      ),
    ).toBe(
      "Olá! Pichau: Placa de vídeo agora custa R$ 4.999,90 no Pix.",
    );
  });

  it("limpa controles e limita nomes longos", () => {
    const corpo = formatarCorpoPush(
      evento({ entidade_nome: `\n${"X".repeat(60)}` }),
    );
    expect(corpo).not.toContain("\n");
    expect(corpo).toContain(`${"X".repeat(47)}…`);
  });
});
