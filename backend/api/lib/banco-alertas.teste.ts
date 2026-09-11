import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

type Outbox = { id: string; usuario_app_id: string; origem: string; coleta_id: string };
type Token = { id: string; token: string };
type Preferencias = { push_global: boolean; preco: boolean; cashback: boolean; pontuacao: boolean };

const infraestrutura = vi.hoisted(() => ({
  neon: vi.fn(),
  sql: vi.fn(),
  send: vi.fn(),
}));

vi.mock("@neondatabase/serverless", () => ({ neon: infraestrutura.neon }));
vi.mock("./firebase-admin", () => ({
  mensageriaFirebase: () => ({ send: infraestrutura.send }),
}));

import { processarOutboxAlertas } from "./banco-alertas";

const outboxPadrao: Outbox = {
  id: "17",
  usuario_app_id: "42",
  origem: "livelo",
  coleta_id: "coleta-2026-09-10",
};
const tokenValido: Token = { id: "1", token: "token-fcm-valido-com-mais-de-20" };
const preferenciasPadrao: Preferencias = {
  push_global: true,
  preco: true,
  cashback: true,
  pontuacao: true,
};

function configurarBanco(opcoes: {
  outbox?: Outbox | null;
  recuperadas?: Array<{ id: string }>;
  tokens?: Token[];
  contagens?: Array<{ tipo: string; total: number }>;
  preferencias?: Preferencias[];
}) {
  let reclamacoes = 0;
  const consultas: Array<{ texto: string; valores: unknown[] }> = [];
  infraestrutura.neon.mockReturnValue(infraestrutura.sql);
  infraestrutura.sql.mockImplementation(
    (strings: TemplateStringsArray, ...valores: unknown[]) => {
      const texto = strings.join(" ");
      consultas.push({ texto, valores });
      if (texto.includes("SELECT expurgar_alertas_suporte")) return Promise.resolve([]);
      if (texto.includes("processamento interrompido")) {
        return Promise.resolve(opcoes.recuperadas ?? []);
      }
      if (texto.includes("SET estado = 'enviando'")) {
        reclamacoes += 1;
        return Promise.resolve(reclamacoes === 1 && opcoes.outbox ? [opcoes.outbox] : []);
      }
      if (texto.includes("SELECT id, token")) return Promise.resolve(opcoes.tokens ?? [tokenValido]);
      if (texto.includes("SELECT tipo, count(*)")) return Promise.resolve(opcoes.contagens ?? [{ tipo: "pontuacao", total: 1 }]);
      if (texto.includes("SELECT push_global")) return Promise.resolve(opcoes.preferencias ?? [preferenciasPadrao]);
      return Promise.resolve([]);
    },
  );
  return consultas;
}

describe("processamento da outbox de alertas", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.stubEnv("DATABASE_URL", "postgres://teste.local/radar");
    infraestrutura.send.mockResolvedValue("mensagem-enviada");
  });

  afterEach(() => {
    vi.unstubAllEnvs();
  });

  it("reprocessa falha transitória e mantém a linha em falha para retry", async () => {
    const consultas = configurarBanco({ outbox: outboxPadrao });
    infraestrutura.send.mockRejectedValue(new Error("indisponibilidade transitória"));

    const resultado = await processarOutboxAlertas();

    expect(resultado).toEqual({ processadas: 1, enviadas: 0, recuperadas: 0 });
    expect(consultas.some((consulta) => consulta.texto.includes("proxima_tentativa_em = now() + make_interval"))).toBe(true);
  });

  it("desativa token FCM inválido e conclui com os tokens restantes", async () => {
    const tokenInvalido: Token = { id: "2", token: "token-fcm-invalido-com-mais-de-20" };
    const consultas = configurarBanco({ outbox: outboxPadrao, tokens: [tokenValido, tokenInvalido] });
    infraestrutura.send.mockImplementation(({ token }: { token: string }) =>
      token === tokenInvalido.token
        ? Promise.reject(Object.assign(new Error("token inválido"), { code: "messaging/invalid-registration-token" }))
        : Promise.resolve("mensagem-enviada"));

    const resultado = await processarOutboxAlertas();

    expect(resultado).toEqual({ processadas: 1, enviadas: 1, recuperadas: 0 });
    expect(infraestrutura.send).toHaveBeenCalledTimes(2);
    const consultaTokens = consultas.find((consulta) => consulta.texto.includes("token_fcm_app SET ativo = FALSE"));
    expect(consultaTokens).toBeDefined();
    expect(consultaTokens?.valores).toContainEqual([tokenInvalido.token]);
  });

  it("respeita preferência global e por tipo sem apagar o histórico", async () => {
    configurarBanco({
      outbox: outboxPadrao,
      preferencias: [{ ...preferenciasPadrao, push_global: false }],
    });

    const globalDesligado = await processarOutboxAlertas();
    expect(globalDesligado).toEqual({ processadas: 1, enviadas: 1, recuperadas: 0 });
    expect(infraestrutura.send).not.toHaveBeenCalled();

    vi.clearAllMocks();
    infraestrutura.send.mockResolvedValue("mensagem-enviada");
    configurarBanco({
      outbox: outboxPadrao,
      contagens: [{ tipo: "pontuacao", total: 1 }],
      preferencias: [{ ...preferenciasPadrao, pontuacao: false }],
    });

    const tipoDesligado = await processarOutboxAlertas();
    expect(tipoDesligado).toEqual({ processadas: 1, enviadas: 1, recuperadas: 0 });
    expect(infraestrutura.send).not.toHaveBeenCalled();
  });

  it("recupera linha presa em enviando antes de buscar novas linhas", async () => {
    const consultas = configurarBanco({ outbox: null, recuperadas: [{ id: "99" }] });

    const resultado = await processarOutboxAlertas();

    expect(resultado).toEqual({ processadas: 0, enviadas: 0, recuperadas: 1 });
    expect(consultas.some((consulta) => consulta.texto.includes("estado = 'enviando'") && consulta.texto.includes("15 minutes"))).toBe(true);
    expect(infraestrutura.send).not.toHaveBeenCalled();
  });

  it("faz claim idempotente com lock e não envia a mesma linha duas vezes na rodada", async () => {
    const consultas = configurarBanco({ outbox: outboxPadrao });

    const resultado = await processarOutboxAlertas(20);

    expect(resultado.processadas).toBe(1);
    expect(infraestrutura.send).toHaveBeenCalledTimes(1);
    expect(consultas.some((consulta) => consulta.texto.includes("FOR UPDATE SKIP LOCKED"))).toBe(true);
  });
});
