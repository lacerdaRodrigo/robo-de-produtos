import { describe, expect, it, vi } from "vitest";

import {
  validarFavoritaInter,
  validarNovaLojaLivelo,
  validarPreferenciasLivelo,
  validarRegraLojaLivelo,
  validarSelecaoDeLojaDireta,
  validarSolicitacaoDeDisparo,
} from "../lib/administracao-api";
import {
  chaveDeIdempotenciaValida,
  solicitarDisparo,
  type DependenciasDeDisparo,
} from "../lib/disparos-api";

describe("CT-294 seleção administrativa de loja direta", () => {
  it("aceita somente identificador seguro e booleano explícito", () => {
    expect(validarSelecaoDeLojaDireta({ id: "a0d3-42", selecionada: true })).toEqual({
      ok: true,
      valor: { id: "a0d3-42", selecionada: true },
    });
    expect(validarSelecaoDeLojaDireta({ id: "a0d3-42", selecionada: false })).toEqual({
      ok: true,
      valor: { id: "a0d3-42", selecionada: false },
    });
  });

  it.each([
    [null],
    [{}],
    [{ id: "", selecionada: true }],
    [{ id: "../../loja", selecionada: true }],
    [{ id: "a0d3-42", selecionada: "true" }],
  ])("rejeita payload administrativo inválido: %o", (corpo) => {
    expect(validarSelecaoDeLojaDireta(corpo).ok).toBe(false);
  });
});

describe("CT-297 administração Livelo preserva decimais textuais", () => {
  it("normaliza vírgula e mantém regras opcionais como texto ou null", () => {
    expect(
      validarNovaLojaLivelo({
        nome: "Loja Nova",
        categoria: "Viagem",
        apelidos: ["Loja N"],
        multiplicador: "2,90",
        piso: "6.00",
      }),
    ).toEqual({
      ok: true,
      valor: {
        nome: "Loja Nova",
        categoria: "Viagem",
        apelidos: ["Loja N"],
        multiplicador: "2.90",
        piso: "6.00",
      },
    });
    expect(validarRegraLojaLivelo({ multiplicador: null, piso: "" })).toEqual({
      ok: true,
      valor: { multiplicador: null, piso: null },
    });
  });

  it("rejeita número JS, zero positivo e grafia repetida", () => {
    expect(
      validarNovaLojaLivelo({
        nome: "Loja",
        categoria: "Casa",
        apelidos: ["loja"],
        multiplicador: "2",
        piso: "0",
      }).ok,
    ).toBe(false);
    expect(validarRegraLojaLivelo({ multiplicador: 2.9, piso: "4" }).ok).toBe(false);
    expect(validarRegraLojaLivelo({ multiplicador: "0", piso: "4" }).ok).toBe(false);
  });

  it("exige os padrões e o booleano explícito do Clube", () => {
    expect(
      validarPreferenciasLivelo({
        multiplicador: "2,9",
        piso: "4.00",
        assinante_clube: true,
      }),
    ).toEqual({
      ok: true,
      valor: { multiplicador: "2.9", piso: "4.00", assinanteClube: true },
    });
    expect(
      validarPreferenciasLivelo({
        multiplicador: "",
        piso: "4",
        assinante_clube: false,
      }).ok,
    ).toBe(false);
    expect(
      validarPreferenciasLivelo({
        multiplicador: "2",
        piso: "4",
        assinante_clube: "true",
      }).ok,
    ).toBe(false);
  });
});

describe("CT-295 favorita administrativa do Inter", () => {
  it("aceita o estado explícito e rejeita valores ambíguos", () => {
    expect(validarFavoritaInter({ id: "a0d3-42", favorita: true })).toEqual({
      ok: true,
      valor: { id: "a0d3-42", favorita: true },
    });
    expect(validarFavoritaInter({ id: "a0d3-42", favorita: false })).toEqual({
      ok: true,
      valor: { id: "a0d3-42", favorita: false },
    });
    expect(validarFavoritaInter({ id: "a0d3-42", favorita: 1 }).ok).toBe(false);
  });
});

describe("CT-296 contrato de disparo administrativo", () => {
  it("aceita somente domínio fechado e chave idempotente segura", () => {
    expect(validarSolicitacaoDeDisparo({ dominio: "produtos_inter" })).toEqual({
      ok: true,
      valor: { dominio: "produtos_inter" },
    });
    expect(validarSolicitacaoDeDisparo({ dominio: "https://github.example" }).ok).toBe(false);
    expect(chaveDeIdempotenciaValida("chave-valida-123456")).toBe(true);
    expect(chaveDeIdempotenciaValida("curta")).toBe(false);
  });

  it("confirma uma reserva e não reenvia uma chave já aceita", async () => {
    const finalizar = vi.fn(async () => undefined);
    const disparar = vi.fn(async () => ({ ok: true as const }));
    const reservar = vi
      .fn<DependenciasDeDisparo["reservar"]>()
      .mockResolvedValue({
        tipo: "reservada" as const,
        id: "10",
        esperaSegundos: 0 as const,
      });
    const deps: DependenciasDeDisparo = {
      reservar,
      finalizar,
      disparar,
    };

    await expect(solicitarDisparo("inter", "chave-valida-123456", "42", deps)).resolves.toEqual({
      estado: "aceito",
      cooldownSegundos: 300,
    });
    expect(finalizar).toHaveBeenCalledWith("10", "aceita");

    reservar.mockResolvedValueOnce({
      tipo: "existente",
      id: "10",
      estado: "aceita",
      esperaSegundos: 200,
    });
    await expect(solicitarDisparo("inter", "chave-valida-123456", "42", deps)).resolves.toEqual({
      estado: "aceito",
      cooldownSegundos: 200,
    });
    expect(disparar).toHaveBeenCalledTimes(1);
  });

  it("respeita cooldown e registra falha controlada do GitHub", async () => {
    const finalizar = vi.fn(async () => undefined);
    const reservar = vi
        .fn<DependenciasDeDisparo["reservar"]>()
        .mockResolvedValueOnce({ tipo: "cooldown" as const, esperaSegundos: 91 })
        .mockResolvedValueOnce({
          tipo: "reservada" as const,
          id: "11",
          esperaSegundos: 0 as const,
        });
    const deps: DependenciasDeDisparo = {
      reservar,
      finalizar,
      disparar: vi.fn(async () => ({ ok: false as const, motivo: "github-500" })),
    };

    await expect(solicitarDisparo("livelo", "chave-valida-123456", "42", deps)).resolves.toEqual({
      estado: "cooldown",
      cooldownSegundos: 91,
    });
    await expect(
      solicitarDisparo("livelo", "outra-chave-valida-123456", "42", deps),
    ).resolves.toEqual({ estado: "falha" });
    expect(finalizar).toHaveBeenCalledWith("11", "falha", "github");
  });
});
