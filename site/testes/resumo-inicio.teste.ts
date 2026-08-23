import { describe, expect, it } from "vitest";

import {
  carregarResumoInicio,
  type DependenciasResumoInicio,
} from "../lib/resumo-inicio";

const agora = new Date("2026-08-23T12:00:00.000Z");

function dependencias(): DependenciasResumoInicio {
  return {
    livelo: async () => ({
      ultimo_sucesso_em: "2026-08-23T08:00:00.000Z",
      lojas_acompanhadas: 126,
      alertas_ultima_coleta: 2,
    }),
    cashbackInter: async () => ({
      ultima_tentativa_em: "2026-08-23T07:00:00.000Z",
      ultima_tentativa_estado: "sucesso",
      ultimo_sucesso_em: "2026-08-23T07:10:00.000Z",
      lojas_acompanhadas: 4,
      lojas_encontradas_ultima_coleta: 3,
    }),
    produtos: async () => ({
      ultima_tentativa_em: "2026-08-23T06:00:00.000Z",
      ultima_tentativa_estado: "sucesso",
      dados_mais_antigos_em: "2026-08-23T06:05:00.000Z",
      dados_mais_recentes_em: "2026-08-23T06:30:00.000Z",
      qualidade: "completa",
      lojas_selecionadas: 3,
      lojas_sem_coleta: 0,
      produtos_ativos: 3310,
    }),
  };
}

describe("resumo real do Início", () => {
  it("mantém os três domínios e seus recortes independentes", async () => {
    const resumo = await carregarResumoInicio(dependencias(), agora);

    expect(resumo.estado_geral).toBe("atualizado");
    expect(resumo.gerado_em).toBe("2026-08-23T12:00:00.000Z");
    expect(resumo.livelo).toMatchObject({ estado: "atualizado", alertas_ultima_coleta: 2 });
    expect(resumo.cashback_inter).toMatchObject({
      estado: "atualizado",
      lojas_acompanhadas: 4,
    });
    expect(resumo.produtos).toMatchObject({ estado: "atualizado", produtos_ativos: 3310 });
  });

  it("falha nova do cashback não apaga o último sucesso", async () => {
    const deps = dependencias();
    deps.cashbackInter = async () => ({
      ultima_tentativa_em: "2026-08-23T11:00:00.000Z",
      ultima_tentativa_estado: "falha",
      ultimo_sucesso_em: "2026-08-23T07:10:00.000Z",
      lojas_acompanhadas: 4,
      lojas_encontradas_ultima_coleta: 3,
    });

    const resumo = await carregarResumoInicio(deps, agora);

    expect(resumo.cashback_inter.estado).toBe("falha_recente");
    expect(resumo.cashback_inter.ultimo_sucesso_em).toBe("2026-08-23T07:10:00.000Z");
    expect(resumo.estado_geral).toBe("atencao");
  });

  it("distingue coleta de produtos parcial, degradada e atrasada", async () => {
    const deps = dependencias();
    const base = await deps.produtos();

    deps.produtos = async () => ({ ...base, ultima_tentativa_estado: "parcial" });
    expect((await carregarResumoInicio(deps, agora)).produtos.estado).toBe("parcial");

    deps.produtos = async () => ({ ...base, qualidade: "degradada" });
    expect((await carregarResumoInicio(deps, agora)).produtos.estado).toBe("degradado");

    deps.produtos = async () => ({
      ...base,
      dados_mais_antigos_em: "2026-08-22T20:00:00.000Z",
    });
    expect((await carregarResumoInicio(deps, agora)).produtos.estado).toBe("atrasado");
  });

  it("isola falha de leitura sem fabricar zero para o domínio", async () => {
    const deps = dependencias();
    deps.livelo = async () => {
      throw new Error("detalhe sensível do banco");
    };

    const resumo = await carregarResumoInicio(deps, agora);

    expect(resumo.livelo).toEqual({
      estado: "indisponivel",
      ultimo_sucesso_em: null,
      lojas_acompanhadas: 0,
      alertas_ultima_coleta: 0,
    });
    expect(JSON.stringify(resumo)).not.toContain("sensível");
    expect(resumo.cashback_inter.estado).toBe("atualizado");
    expect(resumo.estado_geral).toBe("atencao");
  });

  it("distingue ausência total de indisponibilidade total", async () => {
    const vazias: DependenciasResumoInicio = {
      livelo: async () => ({
        ultimo_sucesso_em: null,
        lojas_acompanhadas: 0,
        alertas_ultima_coleta: 0,
      }),
      cashbackInter: async () => ({
        ultima_tentativa_em: null,
        ultima_tentativa_estado: null,
        ultimo_sucesso_em: null,
        lojas_acompanhadas: 0,
        lojas_encontradas_ultima_coleta: 0,
      }),
      produtos: async () => ({
        ultima_tentativa_em: null,
        ultima_tentativa_estado: null,
        dados_mais_antigos_em: null,
        dados_mais_recentes_em: null,
        qualidade: null,
        lojas_selecionadas: 0,
        lojas_sem_coleta: 0,
        produtos_ativos: 0,
      }),
    };
    expect((await carregarResumoInicio(vazias, agora)).estado_geral).toBe("sem_dados");

    const falhas: DependenciasResumoInicio = {
      livelo: async () => Promise.reject(new Error("x")),
      cashbackInter: async () => Promise.reject(new Error("x")),
      produtos: async () => Promise.reject(new Error("x")),
    };
    expect((await carregarResumoInicio(falhas, agora)).estado_geral).toBe("indisponivel");
  });
});
