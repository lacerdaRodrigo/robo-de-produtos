import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

type Outbox = { id: string; usuario_app_id: string; origem: string; coleta_id: string };
type Token = { id: string; token: string };
type Preferencias = { push_global: boolean; preco: boolean; cashback: boolean; pontuacao: boolean };
type EventoPush = {
  origem: string;
  tipo: "preco" | "cashback" | "pontuacao";
  entidade_nome: string;
  valor_anterior: string | null;
  valor_atual: string | null;
  unidade: string;
  direcao: "aumento" | "reducao";
};

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
  eventos?: EventoPush[];
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
      if (texto.includes("FROM evento_alerta") && texto.includes("entidade_nome")) return Promise.resolve(opcoes.eventos ?? []);
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

  it("envia produto Pichau com preço, direção, valores e total restante na Central", async () => {
    configurarBanco({
      outbox: { ...outboxPadrao, origem: "pichau" },
      contagens: [{ tipo: "preco", total: 3 }],
      eventos: [
        {
          origem: "pichau",
          tipo: "preco",
          entidade_nome: "Placa de vídeo RTX 5070",
          valor_anterior: "3499.900000",
          valor_atual: "3299.9",
          unidade: "reais",
          direcao: "reducao",
        },
        {
          origem: "pichau",
          tipo: "preco",
          entidade_nome: "Processador Ryzen 7",
          valor_anterior: "1999",
          valor_atual: "2099",
          unidade: "reais",
          direcao: "aumento",
        },
        {
          origem: "pichau",
          tipo: "preco",
          entidade_nome: "Terceiro produto que fica na Central",
          valor_anterior: "100",
          valor_atual: "90",
          unidade: "reais",
          direcao: "reducao",
        },
      ],
    });

    await processarOutboxAlertas();

    const mensagem = infraestrutura.send.mock.calls[0][0];
    expect(mensagem.notification.title).toContain("Pichau");
    expect(mensagem.notification.body).toContain("produto Placa de vídeo RTX 5070");
    expect(mensagem.notification.body).toContain("preço diminuiu, de R$ 3.499,90 para R$ 3.299,90");
    expect(mensagem.notification.body).toContain("produto Processador Ryzen 7: preço aumentou");
    expect(mensagem.notification.body).toContain("Mais 1 alteração na Central.");
    expect(mensagem.notification.body).not.toContain("Terceiro produto");
    expect(mensagem.android.notification.channelId).toBe("alertas");
    expect(mensagem.data).toEqual({ rota: "alertas", coleta: outboxPadrao.coleta_id, origem: "pichau" });
  });

  it.each([
    { total: 1, corpo: "1 alteração na Central." },
    { total: 2, corpo: "2 alterações na Central." },
  ])("usa singular ou plural na contagem sem detalhes ($total)", async ({ total, corpo }) => {
    configurarBanco({
      outbox: { ...outboxPadrao, origem: "pichau" },
      contagens: [{ tipo: "preco", total }],
      eventos: [],
    });

    await processarOutboxAlertas();

    const mensagem = infraestrutura.send.mock.calls[0][0];
    expect(mensagem.notification.body).toBe(corpo);
  });

  it("identifica parceiro Livelo e formata pontuação textual", async () => {
    configurarBanco({
      outbox: { ...outboxPadrao, origem: "livelo" },
      contagens: [{ tipo: "pontuacao", total: 1 }],
      eventos: [{
        origem: "livelo",
        tipo: "pontuacao",
        entidade_nome: "Loja Parceira",
        valor_anterior: "2.000000",
        valor_atual: "3.500000",
        unidade: "pontos_por_real",
        direcao: "aumento",
      }],
    });

    await processarOutboxAlertas();

    const mensagem = infraestrutura.send.mock.calls[0][0];
    expect(mensagem.notification.title).toContain("Livelo");
    expect(mensagem.notification.body).toContain("parceiro Loja Parceira");
    expect(mensagem.notification.body).toContain("pontuação aumentou, de 2 pontos por real para 3,5 pontos por real");
  });

  it("identifica loja e produto do Inter e descreve mudanças de cashback ou preço", async () => {
    const cenarios: Array<{
      origem: string;
      tipo: EventoPush["tipo"];
      entidade_nome: string;
      unidade: string;
      direcao: EventoPush["direcao"];
      trecho: string;
    }> = [
      { origem: "inter_cashback", tipo: "cashback", entidade_nome: "Loja Inter", unidade: "percentual", direcao: "reducao", trecho: "loja Loja Inter: cashback diminuiu, de 10% para 8,5%" },
      { origem: "inter_produto", tipo: "preco", entidade_nome: "Fone Bluetooth", unidade: "reais", direcao: "aumento", trecho: "produto Fone Bluetooth: preço aumentou, de R$ 199,90 para R$ 219,90" },
    ];

    for (const cenario of cenarios) {
      vi.clearAllMocks();
      infraestrutura.send.mockResolvedValue("mensagem-enviada");
      configurarBanco({
        outbox: { ...outboxPadrao, origem: cenario.origem },
        contagens: [{ tipo: cenario.tipo, total: 1 }],
        eventos: [{
          origem: cenario.origem,
          tipo: cenario.tipo,
          entidade_nome: cenario.entidade_nome,
          valor_anterior: cenario.tipo === "cashback" ? "10.000000" : "199.900000",
          valor_atual: cenario.tipo === "cashback" ? "8.500000" : "219.900000",
          unidade: cenario.unidade,
          direcao: cenario.direcao,
        }],
      });

      await processarOutboxAlertas();

      const mensagem = infraestrutura.send.mock.calls[0][0];
      expect(mensagem.notification.title).toContain("Inter");
      expect(mensagem.notification.body).toContain(cenario.trecho);
    }
  });
});
