import { describe, expect, it, vi } from "vitest";

import {
  autenticarRequisicao,
  tokenBearer,
  type DependenciasDeAcesso,
} from "../lib/autenticacao-api";
import type { UsuarioApp } from "../lib/banco-autenticacao";

const usuarioAtivo: UsuarioApp = {
  id: "42",
  email: "piloto@example.com",
  papel: "usuario",
  ativo: true,
};

function dependencias(
  sobrescritas: Partial<DependenciasDeAcesso> = {},
): DependenciasDeAcesso {
  return {
    verificarIdToken: vi.fn(async () => ({
      uid: "firebase-123",
      email: usuarioAtivo.email,
      emailVerificado: true,
    })),
    verificarAppCheck: vi.fn(async () => undefined),
    autorizarUsuario: vi.fn(async () => usuarioAtivo),
    consumirLimite: vi.fn(async () => ({
      permitido: true,
      tentarNovamenteEm: 1,
    })),
    registrarAuditoria: vi.fn(async () => undefined),
    hash: vi.fn((tipo, valor) => `${tipo}:${valor}`),
    appCheckObrigatorio: false,
    ...sobrescritas,
  };
}

function requisicao(cabecalhos: Record<string, string> = {}): Request {
  return new Request("https://radar.example/api/v1/perfil", {
    headers: { authorization: "Bearer token-valido", ...cabecalhos },
  });
}

async function corpoDaRecusa(resultado: Awaited<ReturnType<typeof autenticarRequisicao>>) {
  if (resultado.ok) throw new Error("o teste esperava acesso recusado");
  return resultado.resposta.json() as Promise<{
    erro: { codigo: string; mensagem: string };
  }>;
}

describe("token Bearer", () => {
  it("aceita esquema sem diferenciar maiusculas e rejeita formatos ambiguos", () => {
    expect(tokenBearer("Bearer abc")).toBe("abc");
    expect(tokenBearer("bearer abc")).toBe("abc");
    expect(tokenBearer("Basic abc")).toBeNull();
    expect(tokenBearer("Bearer")).toBeNull();
    expect(tokenBearer("Bearer abc extra")).toBeNull();
    expect(tokenBearer(null)).toBeNull();
  });
});

describe("gate de autenticacao da API v1", () => {
  it("concede acesso somente apos os dois limites, token e convite", async () => {
    const deps = dependencias();
    const resultado = await autenticarRequisicao(
      requisicao({ "x-request-id": "req-teste-1" }),
      { operacao: "perfil.ler" },
      deps,
    );

    expect(resultado.ok).toBe(true);
    if (!resultado.ok) return;
    expect(resultado.usuario).toEqual(usuarioAtivo);
    expect(resultado.requisicaoId).toBe("req-teste-1");
    expect(deps.verificarAppCheck).not.toHaveBeenCalled();
    expect(deps.consumirLimite).toHaveBeenCalledTimes(2);
    expect(deps.registrarAuditoria).toHaveBeenLastCalledWith(
      expect.objectContaining({ resultado: "sucesso", codigo: "permitido" }),
    );
  });

  it("nega quando o Bearer esta ausente", async () => {
    const deps = dependencias();
    const resultado = await autenticarRequisicao(
      requisicao({ authorization: "" }),
      { operacao: "perfil.ler" },
      deps,
    );

    expect(resultado.ok).toBe(false);
    expect((await corpoDaRecusa(resultado)).erro.codigo).toBe("autenticacao");
    if (!resultado.ok) expect(resultado.resposta.status).toBe(401);
    expect(deps.verificarIdToken).not.toHaveBeenCalled();
  });

  it("nao revela se o token e invalido, expirado ou revogado", async () => {
    const deps = dependencias({
      verificarIdToken: vi.fn(async () => {
        throw new Error("revogado");
      }),
    });
    const resultado = await autenticarRequisicao(
      requisicao(),
      { operacao: "perfil.ler" },
      deps,
    );

    expect(resultado.ok).toBe(false);
    expect((await corpoDaRecusa(resultado)).erro.mensagem).toBe("sessao invalida ou expirada");
    if (!resultado.ok) expect(resultado.resposta.status).toBe(401);
  });

  it("exige e-mail verificado", async () => {
    const deps = dependencias({
      verificarIdToken: vi.fn(async () => ({
        uid: "firebase-123",
        email: usuarioAtivo.email,
        emailVerificado: false,
      })),
    });
    const resultado = await autenticarRequisicao(
      requisicao(),
      { operacao: "perfil.ler" },
      deps,
    );

    expect((await corpoDaRecusa(resultado)).erro.codigo).toBe("email-nao-verificado");
    if (!resultado.ok) expect(resultado.resposta.status).toBe(403);
    expect(deps.autorizarUsuario).not.toHaveBeenCalled();
  });

  it.each([
    ["sem convite", null],
    ["inativo", { ...usuarioAtivo, ativo: false }],
  ])("nega usuario %s", async (_cenario, usuario) => {
    const deps = dependencias({ autorizarUsuario: vi.fn(async () => usuario) });
    const resultado = await autenticarRequisicao(
      requisicao(),
      { operacao: "perfil.ler" },
      deps,
    );

    expect((await corpoDaRecusa(resultado)).erro.codigo).toBe("acesso-negado");
    if (!resultado.ok) expect(resultado.resposta.status).toBe(403);
  });

  it("exige papel admin quando a operacao pedir", async () => {
    const resultado = await autenticarRequisicao(
      requisicao(),
      { operacao: "admin.executar", papel: "admin", sensivel: true },
      dependencias(),
    );

    expect((await corpoDaRecusa(resultado)).erro.codigo).toBe("sem-permissao");
    if (!resultado.ok) expect(resultado.resposta.status).toBe(403);
  });

  it("valida App Check quando o rollout estiver habilitado", async () => {
    const ausente = dependencias({ appCheckObrigatorio: true });
    const resultadoAusente = await autenticarRequisicao(
      requisicao(),
      { operacao: "perfil.ler" },
      ausente,
    );
    expect((await corpoDaRecusa(resultadoAusente)).erro.codigo).toBe("app-check");
    if (!resultadoAusente.ok) expect(resultadoAusente.resposta.status).toBe(401);
    expect(ausente.verificarIdToken).not.toHaveBeenCalled();

    const invalido = dependencias({
      appCheckObrigatorio: true,
      verificarAppCheck: vi.fn(async () => {
        throw new Error("invalido");
      }),
    });
    const resultadoInvalido = await autenticarRequisicao(
      requisicao({ "x-firebase-appcheck": "app-check-invalido" }),
      { operacao: "perfil.ler" },
      invalido,
    );
    const erroInvalido = (await corpoDaRecusa(resultadoInvalido)).erro;
    expect(erroInvalido).toEqual({
      codigo: "app-check",
      mensagem: "aplicativo nao verificado",
    });
    if (!resultadoInvalido.ok) expect(resultadoInvalido.resposta.status).toBe(401);

    const valido = dependencias({ appCheckObrigatorio: true });
    const resultadoValido = await autenticarRequisicao(
      requisicao({ "x-firebase-appcheck": "app-check-valido" }),
      { operacao: "perfil.ler" },
      valido,
    );
    expect(resultadoValido.ok).toBe(true);
    expect(valido.verificarAppCheck).toHaveBeenCalledWith("app-check-valido");
    expect(valido.verificarIdToken).toHaveBeenCalledWith("token-valido");
  });

  it("App Check obrigatorio nao substitui a autenticacao Firebase", async () => {
    const deps = dependencias({ appCheckObrigatorio: true });
    const resultado = await autenticarRequisicao(
      requisicao({
        authorization: "",
        "x-firebase-appcheck": "app-check-valido",
      }),
      { operacao: "perfil.ler" },
      deps,
    );

    expect((await corpoDaRecusa(resultado)).erro.codigo).toBe("autenticacao");
    expect(deps.verificarAppCheck).toHaveBeenCalledWith("app-check-valido");
    expect(deps.verificarIdToken).not.toHaveBeenCalled();
  });

  it("devolve 429 e Retry-After para limite por IP", async () => {
    const deps = dependencias({
      consumirLimite: vi.fn(async () => ({
        permitido: false,
        tentarNovamenteEm: 37,
      })),
    });
    const resultado = await autenticarRequisicao(
      requisicao(),
      { operacao: "perfil.ler" },
      deps,
    );

    expect((await corpoDaRecusa(resultado)).erro.codigo).toBe("limite");
    if (!resultado.ok) {
      expect(resultado.resposta.status).toBe(429);
      expect(resultado.resposta.headers.get("retry-after")).toBe("37");
    }
  });

  it("devolve 429 no segundo limite, por usuario e operacao", async () => {
    const consumirLimite = vi
      .fn<DependenciasDeAcesso["consumirLimite"]>()
      .mockResolvedValueOnce({ permitido: true, tentarNovamenteEm: 1 })
      .mockResolvedValueOnce({ permitido: false, tentarNovamenteEm: 18 });
    const resultado = await autenticarRequisicao(
      requisicao(),
      { operacao: "perfil.ler" },
      dependencias({ consumirLimite }),
    );

    expect((await corpoDaRecusa(resultado)).erro.codigo).toBe("limite");
    if (!resultado.ok) expect(resultado.resposta.headers.get("retry-after")).toBe("18");
  });

  it("converte falha interna em erro neutro com request id", async () => {
    const resultado = await autenticarRequisicao(
      requisicao({ "x-request-id": "req-incidente" }),
      { operacao: "perfil.ler" },
      dependencias({
        consumirLimite: vi.fn(async () => {
          throw new Error("postgres://usuario:segredo@host");
        }),
      }),
    );

    const corpo = await corpoDaRecusa(resultado);
    expect(corpo.erro.mensagem).not.toContain("segredo");
    if (!resultado.ok) {
      expect(resultado.resposta.status).toBe(500);
      expect(resultado.resposta.headers.get("x-request-id")).toBe("req-incidente");
    }
  });
});
