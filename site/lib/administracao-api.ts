/** Validações puras das mutações administrativas da API v1.
 *
 * A rota decide autorização e I/O. Aqui não há banco, Firebase ou Request,
 * para que o contrato seja testável sem infraestrutura externa.
 */
export type SelecaoDeLojaDireta = {
  id: string;
  selecionada: boolean;
};

export type ResultadoDaValidacao<T> =
  | { ok: true; valor: T }
  | { ok: false; mensagem: string };

export function validarSelecaoDeLojaDireta(
  corpo: unknown,
): ResultadoDaValidacao<SelecaoDeLojaDireta> {
  if (!corpo || typeof corpo !== "object" || Array.isArray(corpo)) {
    return { ok: false, mensagem: "corpo da requisicao invalido" };
  }
  const objeto = corpo as Record<string, unknown>;
  const id = typeof objeto.id === "string" ? objeto.id.trim() : "";
  if (!/^[a-zA-Z0-9-]{1,100}$/.test(id)) {
    return { ok: false, mensagem: "loja invalida" };
  }
  if (typeof objeto.selecionada !== "boolean") {
    return { ok: false, mensagem: "selecao invalida" };
  }
  return { ok: true, valor: { id, selecionada: objeto.selecionada } };
}

export type FavoritaInter = {
  id: string;
  favorita: boolean;
};

export function validarFavoritaInter(corpo: unknown): ResultadoDaValidacao<FavoritaInter> {
  if (!corpo || typeof corpo !== "object" || Array.isArray(corpo)) {
    return { ok: false, mensagem: "corpo da requisicao invalido" };
  }
  const objeto = corpo as Record<string, unknown>;
  const id = typeof objeto.id === "string" ? objeto.id.trim() : "";
  if (!/^[a-zA-Z0-9-]{1,100}$/.test(id)) {
    return { ok: false, mensagem: "loja invalida" };
  }
  if (typeof objeto.favorita !== "boolean") {
    return { ok: false, mensagem: "favorita invalida" };
  }
  return { ok: true, valor: { id, favorita: objeto.favorita } };
}

export type SolicitacaoDeDisparo = {
  dominio: "livelo" | "inter" | "produtos_inter";
};

/** O domínio é fechado no servidor; a interface nunca escolhe workflow/URL. */
export function validarSolicitacaoDeDisparo(
  corpo: unknown,
): ResultadoDaValidacao<SolicitacaoDeDisparo> {
  if (!corpo || typeof corpo !== "object" || Array.isArray(corpo)) {
    return { ok: false, mensagem: "corpo da requisicao invalido" };
  }
  const dominio = (corpo as Record<string, unknown>).dominio;
  if (dominio !== "livelo" && dominio !== "inter" && dominio !== "produtos_inter") {
    return { ok: false, mensagem: "dominio de disparo invalido" };
  }
  return { ok: true, valor: { dominio } };
}

function decimalSeguro(
  valor: unknown,
  { obrigatorio, positivo }: { obrigatorio: boolean; positivo: boolean },
): ResultadoDaValidacao<string | null> {
  if (valor === null || valor === undefined || valor === "") {
    return obrigatorio
      ? { ok: false, mensagem: "valor decimal obrigatorio" }
      : { ok: true, valor: null };
  }
  if (typeof valor !== "string") return { ok: false, mensagem: "valor decimal invalido" };
  const texto = valor.trim().replace(",", ".");
  if (!/^\d{1,6}(?:\.\d{1,2})?$/.test(texto)) {
    return { ok: false, mensagem: "valor decimal invalido" };
  }
  if (positivo && /^0+(?:\.0+)?$/.test(texto)) {
    return { ok: false, mensagem: "valor deve ser maior que zero" };
  }
  return { ok: true, valor: texto };
}

export type NovaLojaLivelo = {
  nome: string;
  categoria: string;
  apelidos: string[];
  multiplicador: string | null;
  piso: string | null;
};

export function validarNovaLojaLivelo(corpo: unknown): ResultadoDaValidacao<NovaLojaLivelo> {
  if (!corpo || typeof corpo !== "object" || Array.isArray(corpo)) {
    return { ok: false, mensagem: "corpo da requisicao invalido" };
  }
  const objeto = corpo as Record<string, unknown>;
  const nome = typeof objeto.nome === "string" ? objeto.nome.trim() : "";
  const categoria = typeof objeto.categoria === "string" ? objeto.categoria.trim() : "";
  if (!nome || nome.length > 200) return { ok: false, mensagem: "nome invalido" };
  if (!categoria || categoria.length > 100) return { ok: false, mensagem: "categoria invalida" };
  if (!Array.isArray(objeto.apelidos) || objeto.apelidos.length > 50) {
    return { ok: false, mensagem: "apelidos invalidos" };
  }
  const apelidos = objeto.apelidos.map((valor) => (typeof valor === "string" ? valor.trim() : ""));
  if (apelidos.some((valor) => !valor || valor.length > 200)) {
    return { ok: false, mensagem: "apelidos invalidos" };
  }
  const chaves = [nome, ...apelidos].map((valor) => valor.toLocaleLowerCase("pt-BR"));
  if (new Set(chaves).size !== chaves.length) {
    return { ok: false, mensagem: "nome ou apelido repetido" };
  }
  const multiplicador = decimalSeguro(objeto.multiplicador, {
    obrigatorio: false,
    positivo: true,
  });
  if (!multiplicador.ok) return multiplicador;
  const piso = decimalSeguro(objeto.piso, { obrigatorio: false, positivo: false });
  if (!piso.ok) return piso;
  return {
    ok: true,
    valor: { nome, categoria, apelidos, multiplicador: multiplicador.valor, piso: piso.valor },
  };
}

export type RegraLojaLivelo = { multiplicador: string | null; piso: string | null };

export function validarRegraLojaLivelo(
  corpo: unknown,
): ResultadoDaValidacao<RegraLojaLivelo> {
  if (!corpo || typeof corpo !== "object" || Array.isArray(corpo)) {
    return { ok: false, mensagem: "corpo da requisicao invalido" };
  }
  const objeto = corpo as Record<string, unknown>;
  const multiplicador = decimalSeguro(objeto.multiplicador, {
    obrigatorio: false,
    positivo: true,
  });
  if (!multiplicador.ok) return multiplicador;
  const piso = decimalSeguro(objeto.piso, { obrigatorio: false, positivo: false });
  if (!piso.ok) return piso;
  return { ok: true, valor: { multiplicador: multiplicador.valor, piso: piso.valor } };
}

export type PreferenciasLiveloAdministrativas = {
  multiplicador: string;
  piso: string;
  assinanteClube: boolean;
};

export function validarPreferenciasLivelo(
  corpo: unknown,
): ResultadoDaValidacao<PreferenciasLiveloAdministrativas> {
  if (!corpo || typeof corpo !== "object" || Array.isArray(corpo)) {
    return { ok: false, mensagem: "corpo da requisicao invalido" };
  }
  const objeto = corpo as Record<string, unknown>;
  const multiplicador = decimalSeguro(objeto.multiplicador, {
    obrigatorio: true,
    positivo: true,
  });
  if (!multiplicador.ok) return multiplicador;
  if (multiplicador.valor === null) {
    return { ok: false, mensagem: "valor decimal obrigatorio" };
  }
  const piso = decimalSeguro(objeto.piso, { obrigatorio: true, positivo: false });
  if (!piso.ok) return piso;
  if (piso.valor === null) {
    return { ok: false, mensagem: "valor decimal obrigatorio" };
  }
  if (typeof objeto.assinante_clube !== "boolean") {
    return { ok: false, mensagem: "preferencia do Clube invalida" };
  }
  return {
    ok: true,
    valor: {
      multiplicador: multiplicador.valor,
      piso: piso.valor,
      assinanteClube: objeto.assinante_clube,
    },
  };
}
