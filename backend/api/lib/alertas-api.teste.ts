import { describe, expect, it } from "vitest";

import {
  idsAlerta,
  validarPreferenciasAlertas,
  validarRelatoProblema,
  validarTokenFcm,
} from "./alertas-api";

describe("contratos da Central de Alertas", () => {
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

  it("rejeita token curto e relato sem mensagem", () => {
    expect(validarTokenFcm({ token: "curto", plataforma: "android", versao_app: "1.0" })).toMatchObject({ ok: false });
    expect(validarRelatoProblema({ categoria: "erro", mensagem: "", tela: "alertas", versao_app: "1.0" })).toMatchObject({ ok: false });
  });
});
