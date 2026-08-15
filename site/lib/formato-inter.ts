export const LINK_SHOPPING_INTER = "https://shopping.inter.co/site-parceiro/lojas";
export const DESCRICAO_INTER_AUSENTE =
  "O Inter não informou condições adicionais nesta consulta";

export type CashbackOrdenavel = {
  nome: string;
  slug: string;
  cashback_principal_valor: string | null;
  encontrada: boolean;
};

/** PRD-V3 §15.3: mesma normalização persistida em `*_busca` no Postgres. */
export function normalizarBuscaInter(texto: string): string {
  return texto
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .trim()
    .replace(/\s+/g, " ");
}

export function filtrarCashbacksInter<T extends { nome: string; slug: string }>(
  itens: T[],
  termo: string,
): T[] {
  const alvo = normalizarBuscaInter(termo);
  if (!alvo) {
    return itens;
  }
  return itens.filter(
    (item) =>
      normalizarBuscaInter(item.nome).includes(alvo) ||
      normalizarBuscaInter(item.slug).includes(alvo),
  );
}

/** RN37/RN38: positivos, zero/ausente, e por último não encontradas. */
export function ordenarCashbacksInter<T extends CashbackOrdenavel>(itens: T[]): T[] {
  return [...itens].sort((a, b) => {
    if (a.encontrada !== b.encontrada) {
      return a.encontrada ? -1 : 1;
    }
    const valorA = a.cashback_principal_valor;
    const valorB = b.cashback_principal_valor;
    const positivoA = valorA !== null && Number(valorA) > 0;
    const positivoB = valorB !== null && Number(valorB) > 0;
    if (positivoA !== positivoB) {
      return positivoA ? -1 : 1;
    }
    if (positivoA && positivoB) {
      const diferenca = Number(valorB) - Number(valorA);
      if (diferenca !== 0) {
        return diferenca;
      }
    }
    return a.nome.localeCompare(b.nome, "pt-BR");
  });
}

export function ordenarCashbacksPorNome<T extends { nome: string }>(itens: T[]): T[] {
  return [...itens].sort((a, b) => a.nome.localeCompare(b.nome, "pt-BR"));
}

export function descricaoInter(texto: string | null): string {
  return texto?.trim() || DESCRICAO_INTER_AUSENTE;
}

export function idadeInter(
  iso: string,
  agora: number = Date.now(),
): { texto: string; atrasado: boolean } {
  const minutos = Math.max(0, Math.floor((agora - new Date(iso).getTime()) / 60000));
  if (minutos < 1) {
    return { texto: "agora há pouco", atrasado: false };
  }
  if (minutos < 60) {
    return { texto: `há ${minutos} min`, atrasado: false };
  }
  const horas = Math.floor(minutos / 60);
  if (horas < 24) {
    return { texto: `há ${horas} h`, atrasado: false };
  }
  const dias = Math.floor(horas / 24);
  return {
    texto: dias === 1 ? "há 1 dia" : `há ${dias} dias`,
    atrasado: true,
  };
}

export type EstadoInter = "sem-execucao" | "atualizando" | "falha" | "atrasado" | "atual";

export function estadoInter(entrada: {
  estadoTentativa?: string | null;
  concluidaEm?: string | null;
  agora?: number;
}): EstadoInter {
  if (!entrada.concluidaEm) {
    return entrada.estadoTentativa === "iniciada"
      ? "atualizando"
      : entrada.estadoTentativa === "falha"
        ? "falha"
        : "sem-execucao";
  }
  if (entrada.estadoTentativa === "falha") {
    return "falha";
  }
  return idadeInter(entrada.concluidaEm, entrada.agora).atrasado ? "atrasado" : "atual";
}
