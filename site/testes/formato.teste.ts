import { describe, expect, it } from "vitest";

import { idade, pontos, rotuloDoClube, terminaHoje } from "../lib/formato";

// CT-151 a CT-155 — formatacao do site. Mesma convencao do robo: o nome do
// caso cita a regra, e o comentario explica por que ela existe.

describe("CT-151 pontuacao sem residuo de float", () => {
  it("nunca converte para number, entao 2.90 vira 2,9 e nao 2,9000000000000004", () => {
    // O NUMERIC do Postgres chega como string. Um Number() aqui jogaria fora
    // o cuidado que o robo tem com Decimal desde a V1 (PRD §5.4).
    expect(pontos("2.90")).toBe("2,9");
    expect(pontos("10.00")).toBe("10");
    expect(pontos("0.05")).toBe("0,05");
  });

  it("valor ausente vira travessao, nao zero", () => {
    // Zero e uma pontuacao; ausencia e outra coisa. Confundir os dois faria
    // a pagina afirmar algo que ela nao sabe.
    expect(pontos(null)).toBe("—");
  });
});

describe("CT-152 rotulo do Clube (RN23)", () => {
  it("separa exclusividade de vantagem maior", () => {
    // CLUB: a base nao se moveu, o ganho e de outra pessoa.
    expect(rotuloDoClube("CLUB")).toBe("exclusivo assinantes Clube");
    // PROMOTION_CLUB: a base subiu para todo mundo, o Clube subiu mais.
    expect(rotuloDoClube("PROMOTION_CLUB")).toBe("assinantes Clube ganham mais");
  });

  it("campanha comum ou desconhecida nao ganha rotulo", () => {
    expect(rotuloDoClube("BAU")).toBeNull();
    expect(rotuloDoClube("CAMPANHA_NOVA")).toBeNull();
    expect(rotuloDoClube(null)).toBeNull();
  });
});

describe("CT-153 termina hoje (RN22)", () => {
  it("compara no fuso de Brasilia, nao no do servidor", () => {
    // A Vercel roda em UTC. Sem fixar o fuso, uma promocao que acaba as 23h59
    // de Brasilia apareceria como "amanha" para o servidor.
    const hoje = new Date();
    expect(terminaHoje(hoje.toISOString())).toBe(true);
    expect(terminaHoje(new Date(hoje.getTime() + 5 * 86400000).toISOString())).toBe(false);
    expect(terminaHoje(null)).toBe(false);
  });
});

describe("CT-154 idade do carimbo (RN26)", () => {
  it("marca como velho o que passou de meio dia", () => {
    // O carimbo so cumpre o papel se der para perceber que envelheceu — e o
    // que sustenta MS6. Pagina velha sem aviso e pagina mentirosa.
    const agora = Date.now();
    expect(idade(new Date(agora - 30 * 60000).toISOString())).toEqual({
      texto: "há 30 min",
      velho: false,
    });
    expect(idade(new Date(agora - 3 * 3600000).toISOString()).velho).toBe(false);
    expect(idade(new Date(agora - 20 * 3600000).toISOString()).velho).toBe(true);
    expect(idade(new Date(agora - 3 * 86400000).toISOString())).toEqual({
      texto: "há 3 dias",
      velho: true,
    });
  });
});

describe("CT-155 pontuacao inteira nao ganha virgula", () => {
  it("6 e 6, nao 6,00", () => {
    expect(pontos("6")).toBe("6");
    expect(pontos("6.000")).toBe("6");
  });
});
