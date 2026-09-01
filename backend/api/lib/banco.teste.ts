import { readFileSync } from "node:fs";
import { resolve } from "node:path";

import { beforeEach, describe, expect, it, vi } from "vitest";

const bancoFalso = vi.hoisted(() => ({
  consultas: [] as string[],
  resposta: [] as unknown[],
  respostas: [] as unknown[][],
}));

vi.mock("@neondatabase/serverless", () => ({
  neon: vi.fn(() => async (partes: TemplateStringsArray, ...valores: unknown[]) => {
    bancoFalso.consultas.push(
      partes.reduce(
        (consulta, parte, indice) => consulta + String(valores[indice - 1] ?? "") + parte,
      ),
    );
    return bancoFalso.respostas.shift() ?? bancoFalso.resposta;
  }),
}));

import {
  alterarAcompanhamentoParceiroLivelo,
  alterarAlertaParceiroLivelo,
  buscarCatalogoLiveloPersistido,
  historicoLivelo,
  pontuacoes,
  resumoCatalogoLiveloPersistido,
  resumoLiveloPersistido,
} from "@/lib/banco";
import { filtrosSqlCatalogoLivelo } from "@/lib/catalogo-livelo";

describe("pontuacoes", () => {
  beforeEach(() => {
    bancoFalso.consultas.length = 0;
    bancoFalso.resposta = [];
    bancoFalso.respostas.length = 0;
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
    bancoFalso.respostas.push([{ total: 0 }], [], []);
    await buscarCatalogoLiveloPersistido({
      ...filtrosSqlCatalogoLivelo("", ""),
      aba: "todas",
      ordenar: "pontos",
    }, 1, 20);
    await resumoCatalogoLiveloPersistido();
    await resumoLiveloPersistido();

    expect(bancoFalso.consultas[0]).toContain("count(*)::int AS total");
    expect(bancoFalso.consultas[1]).toContain("LIMIT 20");
    expect(bancoFalso.consultas[1]).toContain("OFFSET 0");
    expect(bancoFalso.consultas[2]).toContain("count(*) FILTER (WHERE acompanhada)");
    expect(bancoFalso.consultas[2]).toContain("tentativa.qualidade");
    expect(bancoFalso.consultas[3]).toContain("FROM loja WHERE acompanhada = TRUE");
    expect(bancoFalso.consultas[3]).toContain("WHERE qualidade = 'completa'");
  });

  it("expõe RN29 sem trocar o instante do último snapshot completo", async () => {
    bancoFalso.resposta = [{
      ultima_coleta: "2026-08-23T08:00:00.000Z",
      ultima_tentativa_em: "2026-08-23T10:30:00.000Z",
      qualidade: "degradada",
      parceiros_lidos: 250,
      total_catalogo: 250,
      acompanhadas: 3,
      alertas_ativos: 2,
      alertas: 1,
      categorias: [],
      melhor_oferta_id_externo: null,
      melhor_oferta_nome: null,
      melhor_oferta_pontos_atuais: null,
      melhor_oferta_moeda: null,
      melhor_oferta_prefixo_ate: null,
    }];

    const resumo = await resumoCatalogoLiveloPersistido();

    expect(resumo.qualidade).toBe("degradada");
    expect(resumo.ultima_coleta).toBe("2026-08-23T08:00:00.000Z");
    expect(resumo.ultima_tentativa_em).toBe("2026-08-23T10:30:00.000Z");
  });

  it("pagina o catálogo Livelo no SQL e preserva o total filtrado", async () => {
    bancoFalso.respostas.push([{ total: 21 }], []);

    const primeira = await buscarCatalogoLiveloPersistido({
      ...filtrosSqlCatalogoLivelo("", ""),
      aba: "todas",
      ordenar: "pontos",
    }, 1, 10);

    expect(primeira).toEqual({ itens: [], total: 21, pagina: 1 });
    expect(bancoFalso.consultas[0]).toContain("count(*)::int AS total");
    expect(bancoFalso.consultas[1]).toContain("parceiro.pontos_atuais END DESC");
    expect(bancoFalso.consultas[1]).toContain("LIMIT 10");
    expect(bancoFalso.consultas[1]).toContain("OFFSET 0");

    bancoFalso.consultas.length = 0;
    bancoFalso.respostas.push([{ total: 21 }], []);
    const seguinte = await buscarCatalogoLiveloPersistido({
      ...filtrosSqlCatalogoLivelo("", ""),
      aba: "todas",
      ordenar: "nome",
    }, 2, 10);

    expect(seguinte.pagina).toBe(2);
    expect(bancoFalso.consultas[1]).toContain("LIMIT 10");
    expect(bancoFalso.consultas[1]).toContain("OFFSET 10");
  });

  it("aplica busca, aba e categoria antes da contagem e da página Livelo", async () => {
    bancoFalso.respostas.push([{ total: 0 }], []);
    const filtros = filtrosSqlCatalogoLivelo("decoração", "Casa e decoração");

    const resultado = await buscarCatalogoLiveloPersistido({
      ...filtros,
      aba: "acompanhadas",
      ordenar: "nome",
    }, 1, 20);

    expect(resultado).toEqual({ itens: [], total: 0, pagina: 1 });
    for (const consulta of bancoFalso.consultas) {
      expect(consulta).toContain("loja.id IS NOT NULL");
      expect(consulta).toContain("parceiro.categorias && casaedecoracao::text[]");
      expect(consulta).toContain("strpos(");
      expect(consulta).toContain("decoracao");
    }
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
