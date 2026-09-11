import { beforeEach, describe, expect, it, vi } from "vitest";

const dependencias = vi.hoisted(() => ({
  autenticar: vi.fn(),
  resolver: vi.fn(),
  alterar: vi.fn(),
}));

vi.mock("@/lib/autenticacao-api", () => ({
  autenticarRequisicao: dependencias.autenticar,
}));

vi.mock("@/lib/banco-alertas", () => ({
  entidadeAcompanhavelIdPorChave: dependencias.resolver,
  alterarAcompanhamentoPessoal: dependencias.alterar,
}));

import { PATCH as acompanharLivelo } from "@/app/api/livelo/catalogo/[id_externo]/acompanhamento-pessoal/route";
import { PATCH as acompanharCashback } from "@/app/api/inter/cashback/[id]/acompanhamento/route";

describe("acompanhamento pessoal da Central", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    dependencias.autenticar.mockResolvedValue({
      ok: true,
      usuario: { id: "42", papel: "usuario" },
      requisicaoId: "req-teste",
    });
    dependencias.resolver.mockResolvedValue("17");
    dependencias.alterar.mockResolvedValue(true);
  });

  it("resolve a chave externa da Livelo e grava somente para o usuário autenticado", async () => {
    const resposta = await acompanharLivelo(
      new Request("http://localhost/api/livelo/catalogo/NAT/acompanhamento-pessoal", {
        method: "PATCH",
        body: JSON.stringify({ ativo: true }),
      }),
      { params: Promise.resolve({ id_externo: "NAT" }) },
    );

    expect(resposta.status).toBe(200);
    expect(dependencias.resolver).toHaveBeenCalledWith("livelo", "NAT");
    expect(dependencias.alterar).toHaveBeenCalledWith("42", "livelo", "17", true);
  });

  it("rejeita chave inválida do cashback antes de tocar no banco", async () => {
    const resposta = await acompanharCashback(
      new Request("http://localhost/api/inter/cashback/nao-numerico/acompanhamento", {
        method: "PATCH",
        body: JSON.stringify({ ativo: true }),
      }),
      { params: Promise.resolve({ id: "nao-numerico" }) },
    );

    expect(resposta.status).toBe(400);
    expect(dependencias.resolver).not.toHaveBeenCalled();
    expect(dependencias.alterar).not.toHaveBeenCalled();
  });
});
