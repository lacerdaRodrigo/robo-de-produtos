import { describe, expect, it } from "vitest";

import {
  idsAlerta,
  origemAlerta,
  validarPreferenciasAlertas,
  validarRelatoProblema,
  validarTokenFcm,
} from "./alertas-api";

describe("contratos da Central de Alertas", () => {
  it("aceita somente as quatro origens reais de alertas", () => {
    expect(origemAlerta("inter_cashback")).toBe("inter_cashback");
    expect(origemAlerta("inter_produto")).toBe("inter_produto");
    expect(origemAlerta("livelo")).toBe("livelo");
    expect(origemAlerta("pichau")).toBe("pichau");
    expect(origemAlerta(null)).toBeNull();
    expect(origemAlerta("")).toBeNull();
    expect(origemAlerta("desconhecida")).toBeNull();
  });

  it("aceita somente ids numericos limitados", () => {
    expect(idsAlerta(["1", "2", "2"])).toEqual(["1", "2"]);
    expect(idsAlerta(["1", "abc"])).toBeNull();
    expect(idsAlerta(new Array(101).fill("1"))).toBeNull();
  });

  it("valida preferencia de push sem default silencioso", () => {
    expect(validarPreferenciasAlertas({ push_global: true, preco: true, cashback: false, pontuacao: true })).toEqual({
      ok: true,
      valor: { push_global: true, preco: true, cashback: false, pontuacao: true },
    });
    expect(validarPreferenciasAlertas({ push_global: true })).toMatchObject({ ok: false });
  });

  it("rejeita token curto, relato curto e categorias fora da V15", () => {
    expect(validarTokenFcm({ token: "curto", plataforma: "android", versao_app: "1.0" })).toMatchObject({ ok: false });
    expect(validarRelatoProblema({ categoria: "catalog", mensagem: "curto", tela: "alertas", versao_app: "1.0" })).toMatchObject({ ok: false });
    expect(validarRelatoProblema({ categoria: "erro", mensagem: "Descrição válida com mais de dez caracteres.", tela: "alertas", versao_app: "1.0" })).toMatchObject({ ok: false });
    for (const categoria of ["catalog", "access", "notification", "privacy", "other"]) {
      expect(validarRelatoProblema({ categoria, mensagem: "Descrição válida com mais de dez caracteres.", tela: "alertas", versao_app: "1.0" })).toMatchObject({ ok: true });
    }
  });
});
