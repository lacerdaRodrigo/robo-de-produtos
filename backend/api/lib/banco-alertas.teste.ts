import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

type Outbox = { id: string; usuario_app_id: string; origem: string; coleta_id: string };
type Token = { id: string; token: string };
type Preferencias = { push_global: boolean; preco: boolean; cashback: boolean; pontuacao: boolean };
type Evento = {
  id: string;
  origem: string;
  tipo: string;
  entidade_nome: string;
  valor_atual: string;
  unidade: string;
  loja_nome: string | null;
};
type EstadoEntrega = "pendente" | "enviando" | "enviada" | "falha" | "invalida" | "cancelada";
type EstadoLocal = {
  entregas: Map<string, EstadoEntrega>;
  tentativas: Map<string, number>;
  proximaTentativaEm: Map<string, number>;
  tokensInativos: Set<string>;
  agora: number;
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
const eventoLivelo: Evento = {
  id: "501",
  origem: "livelo",
  tipo: "pontuacao",
  entidade_nome: "Parceira Exemplo",
  valor_atual: "3.000000",
  unidade: "pontos_por_real",
  loja_nome: null,
};

function estadoLocal(): EstadoLocal {
  return {
    entregas: new Map(),
    tentativas: new Map(),
    proximaTentativaEm: new Map(),
    tokensInativos: new Set(),
    agora: 0,
  };
}

function chaveEntrega(eventoId: string, tokenId: string): string {
  return `${eventoId}:${tokenId}`;
}

function configurarBanco(opcoes: {
  outbox?: Outbox | null;
  recuperadas?: Array<{ id: string }>;
  tokens?: Token[];
  eventos?: Evento[];
  preferencias?: Preferencias[];
  estado?: EstadoLocal;
}) {
  const estado = opcoes.estado ?? estadoLocal();
  let reclamacoesOutbox = 0;
  const consultas: Array<{ texto: string; valores: unknown[] }> = [];
  infraestrutura.neon.mockReturnValue(infraestrutura.sql);
  infraestrutura.sql.mockImplementation(
    (strings: TemplateStringsArray, ...valores: unknown[]) => {
      const texto = strings.join(" ");
      consultas.push({ texto, valores });

      if (texto.includes("SELECT expurgar_alertas_suporte")) return Promise.resolve([]);
      if (texto.includes("UPDATE notificacao_entrega_alerta") && texto.includes("processamento interrompido")) {
        return Promise.resolve([]);
      }
      if (texto.includes("UPDATE notificacao_outbox_alerta") && texto.includes("processamento interrompido")) {
        return Promise.resolve(opcoes.recuperadas ?? []);
      }
      if (texto.includes("UPDATE notificacao_outbox_alerta") && texto.includes("SET estado = 'enviando'")) {
        reclamacoesOutbox += 1;
        return Promise.resolve(reclamacoesOutbox === 1 && opcoes.outbox ? [opcoes.outbox] : []);
      }
      if (texto.includes("SELECT id::text, token FROM token_fcm_app")) {
        return Promise.resolve((opcoes.tokens ?? [tokenValido]).filter((token) => !estado.tokensInativos.has(token.id)));
      }
      if (texto.includes("SELECT push_global, preco, cashback, pontuacao")) {
        return Promise.resolve(opcoes.preferencias ?? [preferenciasPadrao]);
      }
      if (texto.includes("SELECT alerta.id::text, alerta.origem")) {
        return Promise.resolve(opcoes.eventos ?? [eventoLivelo]);
      }
      if (texto.includes("INSERT INTO notificacao_entrega_alerta")) {
        const preferencias = opcoes.preferencias?.[0] ?? preferenciasPadrao;
        const eventoIds = (opcoes.eventos ?? [eventoLivelo])
          .filter((evento) => preferencias[evento.tipo as "preco" | "cashback" | "pontuacao"] !== false)
          .map((evento) => evento.id);
        const tokenIds = (opcoes.tokens ?? [tokenValido])
          .filter((token) => !estado.tokensInativos.has(token.id))
          .map((token) => token.id);
        for (const eventoId of eventoIds) {
          for (const tokenId of tokenIds) {
            const chave = chaveEntrega(eventoId, tokenId);
            if (!estado.entregas.has(chave)) estado.entregas.set(chave, "pendente");
          }
        }
        return Promise.resolve([]);
      }
      if (texto.includes("WITH candidata AS") && texto.includes("UPDATE notificacao_entrega_alerta")) {
        const candidatas = Array.from(estado.entregas.entries())
          .filter(([chave, status]) =>
            (status === "pendente" || status === "falha")
            && (estado.proximaTentativaEm.get(chave) ?? 0) <= estado.agora,
          )
          .sort(([chaveEsquerda], [chaveDireita]) =>
            (estado.tentativas.get(chaveEsquerda) ?? 0) - (estado.tentativas.get(chaveDireita) ?? 0)
            || chaveEsquerda.localeCompare(chaveDireita),
          );
        const candidata = candidatas[0];
        if (!candidata) return Promise.resolve([]);
        const [chave] = candidata;
        const [eventoId, tokenId] = chave.split(":");
        estado.entregas.set(chave, "enviando");
        estado.tentativas.set(chave, (estado.tentativas.get(chave) ?? 0) + 1);
        return Promise.resolve([{ evento_alerta_id: eventoId, token_fcm_app_id: tokenId }]);
      }
      if (texto.includes("UPDATE notificacao_entrega_alerta") && texto.includes("SET estado = 'enviando'")) {
        const [eventoId, tokenId] = valores as [string, string];
        const chave = chaveEntrega(eventoId, tokenId);
        const atual = estado.entregas.get(chave);
        if (atual === "pendente" || atual === "falha") {
          estado.entregas.set(chave, "enviando");
          return Promise.resolve([{ evento_alerta_id: eventoId }]);
        }
        return Promise.resolve([]);
      }
      if (texto.includes("UPDATE notificacao_entrega_alerta") && texto.includes("SET estado = 'enviada'")) {
        const [eventoId, tokenId] = valores as [string, string];
        estado.entregas.set(chaveEntrega(eventoId, tokenId), "enviada");
        return Promise.resolve([]);
      }
      if (texto.includes("UPDATE token_fcm_app SET ativo = FALSE")) {
        estado.tokensInativos.add(String(valores[0]));
        return Promise.resolve([]);
      }
      if (texto.includes("SET estado = 'invalida'")) {
        const tokenId = String(valores[0]);
        for (const chave of estado.entregas.keys()) {
          if (chave.endsWith(`:${tokenId}`)) estado.entregas.set(chave, "invalida");
        }
        return Promise.resolve([]);
      }
      if (texto.includes("UPDATE notificacao_entrega_alerta") && texto.includes("SET estado = 'falha'")) {
        const [eventoId, tokenId] = valores as [string, string];
        const chave = chaveEntrega(eventoId, tokenId);
        estado.entregas.set(chave, "falha");
        estado.proximaTentativaEm.set(
          chave,
          estado.agora + Math.min(3_600_000, 30_000 * (estado.tentativas.get(chave) ?? 1)),
        );
        return Promise.resolve([]);
      }
      if (texto.includes("SELECT count(*)::int AS total, min(entrega.proxima_tentativa_em)")) {
        const total = Array.from(estado.entregas.values()).filter(
          (valor) => valor === "pendente" || valor === "enviando" || valor === "falha",
        ).length;
        return Promise.resolve([{ total, proxima_tentativa_em: null }]);
      }
      return Promise.resolve([]);
    },
  );
  return { consultas, estado };
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

  it("envia uma mensagem personalizada por mudança, inclusive preço e cashback do mesmo produto", async () => {
    const eventos: Evento[] = [
      {
        id: "601",
        origem: "inter_produto",
        tipo: "preco",
        entidade_nome: "Notebook A",
        valor_atual: "1299.90",
        unidade: "reais",
        loja_nome: "Loja Exemplo",
      },
      {
        id: "602",
        origem: "inter_produto",
        tipo: "cashback",
        entidade_nome: "Notebook A",
        valor_atual: "8.00",
        unidade: "percentual",
        loja_nome: "Loja Exemplo",
      },
    ];
    const { consultas } = configurarBanco({ outbox: { ...outboxPadrao, origem: "inter_produto" }, eventos });

    const resultado = await processarOutboxAlertas();

    expect(resultado.enviadas).toBe(1);
    expect(infraestrutura.send).toHaveBeenCalledTimes(2);
    expect(infraestrutura.send.mock.calls.map(([mensagem]) => mensagem.notification.body)).toEqual([
      "Olá! Loja Exemplo: Notebook A agora custa R$ 1.299,90.",
      "Olá! Loja Exemplo: cashback de Notebook A agora é 8%.",
    ]);
    expect(infraestrutura.send.mock.calls[0][0].data).toEqual({
      rota: "alertas",
      coleta: outboxPadrao.coleta_id,
      origem: "inter_produto",
    });
    expect(consultas.some((consulta) => consulta.texto.includes("alerta.notificar_push = TRUE"))).toBe(true);
  });

  it("reprocessa somente o aparelho que falhou após outro aceitar a mensagem", async () => {
    const tokenDois: Token = { id: "2", token: "outro-token-fcm-valido-com-mais-de-20" };
    const estado = estadoLocal();
    configurarBanco({ outbox: outboxPadrao, tokens: [tokenValido, tokenDois], estado });
    infraestrutura.send.mockImplementation(({ token }: { token: string }) =>
      token === tokenDois.token
        ? Promise.reject(new Error("indisponibilidade transitória"))
        : Promise.resolve("mensagem-enviada"),
    );

    const primeiraTentativa = await processarOutboxAlertas();

    expect(primeiraTentativa.enviadas).toBe(0);
    expect(estado.entregas.get(chaveEntrega(eventoLivelo.id, tokenValido.id))).toBe("enviada");
    expect(estado.entregas.get(chaveEntrega(eventoLivelo.id, tokenDois.id))).toBe("falha");

    estado.agora = 30_000;
    infraestrutura.send.mockClear();
    infraestrutura.send.mockResolvedValue("mensagem-enviada");
    configurarBanco({ outbox: outboxPadrao, tokens: [tokenValido, tokenDois], estado });
    const segundaTentativa = await processarOutboxAlertas();

    expect(infraestrutura.send).toHaveBeenCalledTimes(1);
    expect(estado.entregas.get(chaveEntrega(eventoLivelo.id, tokenDois.id))).toBe("enviada");
    expect(segundaTentativa.enviadas).toBe(1);
    expect(infraestrutura.send.mock.calls[0][0].token).toBe(tokenDois.token);
  });

  it("limita entregas por execução e deixa o restante para o próximo ciclo", async () => {
    const eventos = Array.from({ length: 26 }, (_, indice) => ({
      ...eventoLivelo,
      id: String(501 + indice),
      entidade_nome: `Parceira ${indice + 1}`,
    }));
    const { consultas, estado } = configurarBanco({ outbox: outboxPadrao, eventos });
    let falhasRestantes = 25;
    infraestrutura.send.mockImplementation(() => {
      if (falhasRestantes > 0) {
        falhasRestantes -= 1;
        return Promise.reject(new Error("indisponibilidade transitória"));
      }
      return Promise.resolve("mensagem-enviada");
    });

    const resultado = await processarOutboxAlertas();

    expect(resultado.processadas).toBe(1);
    expect(resultado.enviadas).toBe(0);
    expect(infraestrutura.send).toHaveBeenCalledTimes(25);
    expect(consultas.some((consulta) => consulta.texto.includes("GREATEST(COALESCE("))).toBe(true);

    infraestrutura.send.mockClear();
    infraestrutura.send.mockResolvedValue("mensagem-enviada");
    configurarBanco({ outbox: outboxPadrao, eventos, estado });
    const cicloSeguinte = await processarOutboxAlertas();

    expect(cicloSeguinte.enviadas).toBe(0);
    expect(infraestrutura.send).toHaveBeenCalledTimes(1);
    expect(infraestrutura.send.mock.calls[0][0].notification.body).toBe(
      "Olá! Parceira 26: pontuação agora é 3 pontos por real.",
    );
  });

  it("desativa token FCM inválido e encerra as entregas desse aparelho", async () => {
    const { consultas } = configurarBanco({ outbox: outboxPadrao });
    infraestrutura.send.mockRejectedValue(
      Object.assign(new Error("token inválido"), { code: "messaging/invalid-registration-token" }),
    );

    const resultado = await processarOutboxAlertas();

    expect(resultado).toEqual({ processadas: 1, enviadas: 1, recuperadas: 0 });
    expect(consultas.some((consulta) => consulta.texto.includes("token_fcm_app SET ativo = FALSE"))).toBe(true);
  });

  it("respeita preferência global e por tipo sem apagar o histórico", async () => {
    configurarBanco({
      outbox: outboxPadrao,
      preferencias: [{ ...preferenciasPadrao, push_global: false }],
    });

    const globalDesligado = await processarOutboxAlertas();

    expect(globalDesligado.enviadas).toBe(1);
    expect(infraestrutura.send).not.toHaveBeenCalled();

    vi.clearAllMocks();
    infraestrutura.send.mockResolvedValue("mensagem-enviada");
    configurarBanco({
      outbox: outboxPadrao,
      preferencias: [{ ...preferenciasPadrao, pontuacao: false }],
    });

    const tipoDesligado = await processarOutboxAlertas();

    expect(tipoDesligado.enviadas).toBe(1);
    expect(infraestrutura.send).not.toHaveBeenCalled();
  });

  it("recupera outbox presa antes de reivindicar novas linhas", async () => {
    const { consultas } = configurarBanco({ outbox: null, recuperadas: [{ id: "99" }] });

    const resultado = await processarOutboxAlertas();

    expect(resultado).toEqual({ processadas: 0, enviadas: 0, recuperadas: 1 });
    expect(consultas.some((consulta) => consulta.texto.includes("UPDATE notificacao_outbox_alerta") && consulta.texto.includes("15 minutes"))).toBe(true);
    expect(infraestrutura.send).not.toHaveBeenCalled();
  });

  it("faz claim idempotente da outbox com lock e envia a mudança registrada", async () => {
    const { consultas } = configurarBanco({ outbox: outboxPadrao });

    const resultado = await processarOutboxAlertas(20);

    expect(resultado.processadas).toBe(1);
    expect(infraestrutura.send).toHaveBeenCalledTimes(1);
    expect(consultas.some((consulta) => consulta.texto.includes("FOR UPDATE SKIP LOCKED"))).toBe(true);
  });
});
