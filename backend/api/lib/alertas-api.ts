export const TIPOS_ALERTA = ["preco", "cashback", "pontuacao"] as const;
export type TipoAlerta = (typeof TIPOS_ALERTA)[number];

export type PreferenciasAlertasEntrada = {
  push_global: boolean;
  preco: boolean;
  cashback: boolean;
  pontuacao: boolean;
};

export function tipoAlerta(valor: string | null): TipoAlerta | null {
  return TIPOS_ALERTA.includes(valor as TipoAlerta) ? (valor as TipoAlerta) : null;
}

export function idsAlerta(valor: unknown): string[] | null {
  if (!Array.isArray(valor) || valor.length > 100) return null;
  const ids = valor.map((item) => String(item));
  return ids.every((id) => /^\d{1,20}$/.test(id)) ? [...new Set(ids)] : null;
}

export function validarPreferenciasAlertas(
  valor: unknown,
): { ok: true; valor: PreferenciasAlertasEntrada } | { ok: false; mensagem: string } {
  if (!valor || typeof valor !== "object" || Array.isArray(valor)) {
    return { ok: false, mensagem: "preferencias invalidas" };
  }
  const corpo = valor as Record<string, unknown>;
  const chaves = ["push_global", "preco", "cashback", "pontuacao"] as const;
  if (chaves.some((chave) => typeof corpo[chave] !== "boolean")) {
    return { ok: false, mensagem: "preferencias devem ser booleanas" };
  }
  return {
    ok: true,
    valor: {
      push_global: corpo.push_global as boolean,
      preco: corpo.preco as boolean,
      cashback: corpo.cashback as boolean,
      pontuacao: corpo.pontuacao as boolean,
    },
  };
}

export function validarTokenFcm(
  valor: unknown,
): { ok: true; valor: { token: string; plataforma: string; versao_app: string } } | { ok: false; mensagem: string } {
  if (!valor || typeof valor !== "object" || Array.isArray(valor)) {
    return { ok: false, mensagem: "dispositivo invalido" };
  }
  const corpo = valor as Record<string, unknown>;
  const token = typeof corpo.token === "string" ? corpo.token.trim() : "";
  const plataforma = typeof corpo.plataforma === "string" ? corpo.plataforma.trim() : "";
  const versao = typeof corpo.versao_app === "string" ? corpo.versao_app.trim() : "";
  if (token.length < 20 || token.length > 4096 || versao.length < 1 || versao.length > 80) {
    return { ok: false, mensagem: "token ou versao invalidos" };
  }
  if (!["android", "ios", "web", "desconhecida"].includes(plataforma)) {
    return { ok: false, mensagem: "plataforma invalida" };
  }
  return { ok: true, valor: { token, plataforma, versao_app: versao } };
}

export function validarRelatoProblema(
  valor: unknown,
): { ok: true; valor: { categoria: string; mensagem: string; tela: string; versao_app: string; sistema: string | null } } | { ok: false; mensagem: string } {
  if (!valor || typeof valor !== "object" || Array.isArray(valor)) {
    return { ok: false, mensagem: "relato invalido" };
  }
  const corpo = valor as Record<string, unknown>;
  const categoria = typeof corpo.categoria === "string" ? corpo.categoria.trim() : "";
  const mensagem = typeof corpo.mensagem === "string" ? corpo.mensagem.trim() : "";
  const tela = typeof corpo.tela === "string" ? corpo.tela.trim() : "";
  const versao = typeof corpo.versao_app === "string" ? corpo.versao_app.trim() : "";
  const sistema = corpo.sistema == null ? null : String(corpo.sistema).trim();
  if (!["erro", "dados", "conta", "outro"].includes(categoria)) {
    return { ok: false, mensagem: "categoria invalida" };
  }
  if (mensagem.length < 1 || mensagem.length > 2000 || tela.length < 1 || tela.length > 120 || versao.length < 1 || versao.length > 80 || (sistema !== null && sistema.length > 200)) {
    return { ok: false, mensagem: "relato fora do tamanho permitido" };
  }
  return { ok: true, valor: { categoria, mensagem, tela, versao_app: versao, sistema } };
}

export function idNumerico(valor: string): number | null {
  return /^\d{1,20}$/.test(valor) ? Number(valor) : null;
}
