import { describe, expect, it } from "vitest";

import {
  ancora,
  barraDeProgresso,
  filtrarPorNome,
  idade,
  numeroOuPadrao,
  pontos,
  rotuloDoClube,
  terminaHoje,
} from "../lib/formato";

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

// CT-156 a CT-158 — busca e ancoras da lista de 132 lojas.

describe("CT-156 busca ignora acento e caixa (RN03)", () => {
  const lojas = [
    { nome: "O Boticário", categoria: "Beleza" },
    { nome: "Renner", categoria: "Moda" },
    { nome: "Petlove", categoria: "Pet" },
  ];

  it("acha a loja escrita de qualquer jeito", () => {
    // Mesma normalizacao do robo: quem digita no celular nao poe acento.
    expect(filtrarPorNome(lojas, "boticario").map((l) => l.nome)).toEqual(["O Boticário"]);
    expect(filtrarPorNome(lojas, "BOTICÁRIO").map((l) => l.nome)).toEqual(["O Boticário"]);
    expect(filtrarPorNome(lojas, "  renner ").map((l) => l.nome)).toEqual(["Renner"]);
  });

  it("acha tambem pela categoria", () => {
    expect(filtrarPorNome(lojas, "moda").map((l) => l.nome)).toEqual(["Renner"]);
  });

  it("termo vazio devolve tudo, nao nada", () => {
    // Busca sem termo recarrega a lista; esconder tudo seria armadilha.
    expect(filtrarPorNome(lojas, "")).toHaveLength(3);
    expect(filtrarPorNome(lojas, "   ")).toHaveLength(3);
  });
});

describe("CT-157 busca por pedaco do nome", () => {
  it("aqui o pedaco vale, ao contrario de RN04", () => {
    // RN04 proibe substring no *reconhecimento* da loja, porque ali um erro
    // troca a pontuacao de uma loja pela de outra. Na busca da tela nao ha
    // esse risco: quem escolhe o resultado e o olho de quem procura.
    const lojas = [{ nome: "Petlove", categoria: "Pet" }, { nome: "Petz", categoria: "Pet" }];
    expect(filtrarPorNome(lojas, "pet")).toHaveLength(2);
    expect(filtrarPorNome(lojas, "petl").map((l) => l.nome)).toEqual(["Petlove"]);
  });
});

describe("CT-164 limiar em branco vira null (RN28)", () => {
  it("campo vazio ou so espaco vira null, nao zero", () => {
    // null e "0" tem significados opostos: um segue o padrao global, o
    // outro e um limiar real de zero pontos. Confundir os dois quebraria
    // RN28 tanto no cadastro (/lojas) quanto na excecao (/avisos).
    expect(numeroOuPadrao("")).toBeNull();
    expect(numeroOuPadrao("   ")).toBeNull();
    expect(numeroOuPadrao(null)).toBeNull();
  });

  it("aceita virgula, que e o que o teclado do celular oferece", () => {
    expect(numeroOuPadrao("2,5")).toBe("2.5");
  });

  it("numero negativo ou texto invalido lanca erro", () => {
    expect(() => numeroOuPadrao("-1")).toThrow();
    expect(() => numeroOuPadrao("abc")).toThrow();
  });
});

describe("CT-165 barra de progresso do cartao (RN30)", () => {
  it("loja nao encontrada nao tem barra, sem dividir por zero", () => {
    // pontos_atuais e pontos_base ausentes juntos: nao ha o que desenhar.
    expect(barraDeProgresso(null, null, null)).toBeNull();
    expect(barraDeProgresso(null, "4", "8")).toBeNull();
  });

  it("larguras ficam entre 0 e 100, com o limiar visivelmente a frente do normal", () => {
    const barra = barraDeProgresso("6", "1", "4");
    expect(barra).not.toBeNull();
    if (!barra) {
      return;
    }
    for (const valor of [barra.atual, barra.base, barra.limiar]) {
      expect(valor).toBeGreaterThanOrEqual(0);
      expect(valor).toBeLessThanOrEqual(100);
    }
    expect(barra.limiar).toBeGreaterThan(barra.base);
  });

  it("sem limiar proprio, usa o dobro da base como referencia", () => {
    const barra = barraDeProgresso("2", "2", null);
    expect(barra).not.toBeNull();
    if (!barra) {
      return;
    }
    // base=2, limiar implicito=4: na mesma escala, o limiar fica na metade do teto.
    expect(barra.limiar).toBeCloseTo(barra.base * 2, 5);
  });

  it("teto nunca zera mesmo com todos os valores em zero", () => {
    const barra = barraDeProgresso("0", "0", "0");
    expect(barra).toEqual({ atual: 0, base: 0, limiar: 0 });
  });
});

describe("CT-158 ancora de categoria", () => {
  it("vira id valido para o indice da pagina", () => {
    expect(ancora("Marketplace / Varejo Geral")).toBe("marketplace-varejo-geral");
    expect(ancora("Casa & Construção")).toBe("casa-construcao");
    expect(ancora("Pet")).toBe("pet");
  });
});
