import { readFileSync } from "node:fs";
import { resolve } from "node:path";

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
  alterarAlertaParceiroLivelo,
  catalogoLiveloPersistido,
  historicoLivelo,
  pontuacoes,
  resumoLiveloPersistido,
} from "@/lib/banco";

describe("pontuacoes", () => {
  beforeEach(() => {
    bancoFalso.consultas.length = 0;
    bancoFalso.resposta = [];
    process.env.DATABASE_URL = "postgresql://teste:teste@localhost/teste";
  });

  it("considera somente lojas com acompanhamento ativo", async () => {
    await pontuacoes(42);

    expect(bancoFalso.consultas).toHaveLength(1);
    expect(bancoFalso.consultas[0]).toContain("FROM loja l");
    expect(bancoFalso.consultas[0]).toContain("l.acompanhada = TRUE");
  });

  it("acompanha e reacompanha reutilizando a linha ligada ao parceiro", async () => {
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
    expect(bancoFalso.consultas[0]).toContain("acompanhada = TRUE");
    expect(bancoFalso.consultas[0]).toContain("loja.parceiro_livelo_id = parceiro.id");
    expect(bancoFalso.consultas[0]).toContain("NOT EXISTS (SELECT 1 FROM atualizada)");
    expect(bancoFalso.consultas[0].indexOf("UPDATE loja")).toBeLessThan(
      bancoFalso.consultas[0].indexOf("INSERT INTO loja"),
    );
    expect(bancoFalso.consultas[0]).not.toContain("INSERT INTO parceiro_livelo");
  });

  it("desacompanha sem apagar a identidade e desativa o alerta", async () => {
    bancoFalso.resposta = [{ confirmado: true }];

    await expect(
      alterarAcompanhamentoParceiroLivelo({
        idExterno: "LIV-1",
        nome: "Loja teste",
        categoria: "Outros",
        acompanhada: false,
      }),
    ).resolves.toBe(true);

    expect(bancoFalso.consultas[0]).toContain("UPDATE loja");
    expect(bancoFalso.consultas[0]).toContain("acompanhada = FALSE");
    expect(bancoFalso.consultas[0]).toContain("alerta_ativo = FALSE");
    expect(bancoFalso.consultas[0]).not.toContain("DELETE FROM loja");
    expect(bancoFalso.consultas[0]).toContain("SELECT TRUE AS confirmado FROM parceiro");
  });

  it("consulta o histórico pela identidade estável do parceiro, sem exigir acompanhamento", async () => {
    await historicoLivelo("NTR");

    expect(bancoFalso.consultas).toHaveLength(1);
    expect(bancoFalso.consultas[0]).toContain("p.parceiro_livelo_id = pl.id");
    expect(bancoFalso.consultas[0]).toContain("l.id = p.loja_id");
    expect(bancoFalso.consultas[0]).toContain("pl.id_externo = NTR");
    expect(bancoFalso.consultas[0]).toContain("LIMIT 30");
  });

  it("impede alerta em parceiro desacompanado", async () => {
    bancoFalso.resposta = [];

    await expect(alterarAlertaParceiroLivelo("LIV-1", true)).resolves.toBe(false);

    expect(bancoFalso.consultas[0]).toContain("acompanhada = TRUE");
  });

  it("catálogo e resumo expõem somente acompanhamentos ativos", async () => {
    await catalogoLiveloPersistido();
    await resumoLiveloPersistido();

    expect(bancoFalso.consultas[0]).toContain("loja.acompanhada = TRUE");
    expect(bancoFalso.consultas[1]).toContain("FROM loja WHERE acompanhada = TRUE");
  });

  it("protege medições legadas contra exclusão física da loja", () => {
    const migracao = readFileSync(
      resolve(process.cwd(), "../../migracoes/016_preserva_historico_livelo.sql"),
      "utf8",
    );

    expect(migracao).toContain(
      "ADD COLUMN IF NOT EXISTS acompanhada BOOLEAN NOT NULL DEFAULT TRUE",
    );
    expect(migracao).toContain("FOREIGN KEY (loja_id) REFERENCES loja(id) ON DELETE RESTRICT");
    expect(migracao).not.toContain("ON DELETE CASCADE");
    expect(migracao).not.toMatch(/DELETE\s+FROM\s+(loja|pontuacao)/i);
  });
});
