import { beforeEach, describe, expect, it, vi } from "vitest";

const bancoFalso = vi.hoisted(() => ({
  consultas: [] as string[],
  resposta: [] as unknown[],
}));

vi.mock("@neondatabase/serverless", () => ({
  neon: vi.fn(() => async (partes: TemplateStringsArray, ...valores: unknown[]) => {
    bancoFalso.consultas.push(
      partes.reduce(
        (consulta, parte, indice) => consulta + String(valores[indice - 1] ?? "") + parte,
      ),
    );
    return bancoFalso.resposta;
  }),
}));

import {
  alterarAcompanhamentoParceiroLivelo,
  historicoLivelo,
  pontuacoes,
} from "@/lib/banco";

describe("pontuacoes", () => {
  beforeEach(() => {
    bancoFalso.consultas.length = 0;
    bancoFalso.resposta = [];
    process.env.DATABASE_URL = "postgresql://teste:teste@localhost/teste";
  });

  it("considera todas as lojas do catalogo, que ja representam as favoritas", async () => {
    await pontuacoes(42);

    expect(bancoFalso.consultas).toHaveLength(1);
    expect(bancoFalso.consultas[0]).toContain("FROM loja l");
    expect(bancoFalso.consultas[0]).not.toContain("l.favorita");
  });

  it("confirma acompanhamento pelo retorno da CTE, sem reler o retrato anterior", async () => {
    bancoFalso.resposta = [{ estado: true }];

    await expect(
      alterarAcompanhamentoParceiroLivelo({
        idExterno: "LIV-1",
        nome: "Loja teste",
        categoria: "Outros",
        acompanhada: true,
      }),
    ).resolves.toBe(true);

    expect(bancoFalso.consultas).toHaveLength(1);
    expect(bancoFalso.consultas[0]).toContain("SELECT 1 FROM atualizada");
    expect(bancoFalso.consultas[0]).toContain("SELECT 1 FROM inserida");
  });

  it("confirma parar de acompanhar depois de remover o vínculo", async () => {
    bancoFalso.resposta = [{ confirmado: true }];

    await expect(
      alterarAcompanhamentoParceiroLivelo({
        idExterno: "LIV-1",
        nome: "Loja teste",
        categoria: "Outros",
        acompanhada: false,
      }),
    ).resolves.toBe(true);

    expect(bancoFalso.consultas[0]).toContain("DELETE FROM loja");
    expect(bancoFalso.consultas[0]).toContain("SELECT TRUE AS confirmado FROM parceiro");
  });

  it("consulta o histórico pela identidade estável do parceiro, sem exigir acompanhamento", async () => {
    await historicoLivelo("NTR");

    expect(bancoFalso.consultas).toHaveLength(1);
    expect(bancoFalso.consultas[0]).toContain("p.parceiro_livelo_id = pl.id");
    expect(bancoFalso.consultas[0]).toContain("pl.id_externo = NTR");
    expect(bancoFalso.consultas[0]).toContain("LIMIT 30");
  });
});
