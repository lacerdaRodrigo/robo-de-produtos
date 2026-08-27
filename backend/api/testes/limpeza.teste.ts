import { describe, expect, it } from "vitest";

import {
  FRASE_LIMPEZA,
  fraseDaLimpezaConfere,
} from "../lib/confirmacao-limpeza";

describe("confirmação das limpezas administrativas", () => {
  it("aceita a frase exata de cada domínio", () => {
    expect(fraseDaLimpezaConfere("livelo", FRASE_LIMPEZA.livelo)).toBe(true);
    expect(fraseDaLimpezaConfere("inter", FRASE_LIMPEZA.inter)).toBe(true);
  });

  it("remove espaços externos, mas não troca a frase entre domínios", () => {
    expect(fraseDaLimpezaConfere("livelo", "  APAGAR LIVELO  ")).toBe(true);
    expect(fraseDaLimpezaConfere("livelo", FRASE_LIMPEZA.inter)).toBe(false);
    expect(fraseDaLimpezaConfere("inter", FRASE_LIMPEZA.livelo)).toBe(false);
  });

  it("recusa ausência, caixa diferente e texto parcial", () => {
    expect(fraseDaLimpezaConfere("livelo", "")).toBe(false);
    expect(fraseDaLimpezaConfere("inter", "resetar inter")).toBe(false);
    expect(fraseDaLimpezaConfere("inter", "RESETAR INTER agora")).toBe(false);
  });
});
