export const LINK_SHOPPING_INTER = "https://shopping.inter.co/site-parceiro/lojas";
export const DESCRICAO_INTER_AUSENTE =
  "O Inter não informou condições adicionais nesta consulta";

/** Destino oficial do card de uma loja no catálogo de Sites parceiros. */
export function linkShoppingInterDaLoja(slug: string): string {
  const slugNormalizado = slug.trim();
  return `${LINK_SHOPPING_INTER}/${encodeURIComponent(slugNormalizado)}`;
}

export type CashbackOrdenavel = {
  nome: string;
  slug: string;
  cashback_principal_valor: string | null;
  encontrada: boolean;
};

function partesDecimais(valor: string | null): [string, string] | null {
  if (valor === null) return null;
  const resultado = valor.trim().replace(",", ".").match(/^\+?(\d+)(?:\.(\d+))?$/);
  if (!resultado) return null;
  const inteiro = resultado[1].replace(/^0+(?=\d)/, "");
  const fracao = (resultado[2] ?? "").replace(/0+$/, "");
  return [inteiro, fracao];
}

/** Compara decimais textuais sem converter a regra financeira para Number. */
export function compararDecimaisInter(a: string | null, b: string | null): number {
  const partesA = partesDecimais(a);
  const partesB = partesDecimais(b);
  if (partesA === null || partesB === null) {
    if (partesA === partesB) return 0;
    return partesA === null ? -1 : 1;
  }
  if (partesA[0].length !== partesB[0].length) {
    return partesA[0].length < partesB[0].length ? -1 : 1;
  }
  if (partesA[0] !== partesB[0]) return partesA[0] < partesB[0] ? -1 : 1;
  const escala = Math.max(partesA[1].length, partesB[1].length);
  const fracaoA = partesA[1].padEnd(escala, "0");
  const fracaoB = partesB[1].padEnd(escala, "0");
  if (fracaoA === fracaoB) return 0;
  return fracaoA < fracaoB ? -1 : 1;
}

/**
 * Forma canônica usada pela busca do Inter.
 *
 * O `e` aproxima o uso comercial de `&`; os demais separadores não carregam
 * significado para a busca. A consulta SQL aplica a mesma transformação aos
 * campos `*_busca` já persistidos, sem exigir migration ou recarga do catálogo.
 */
export function normalizarBuscaInter(texto: string): string {
  return texto
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .trim()
    .replace(/&/g, "e")
    .replace(/[^a-z0-9]+/g, "");
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
    const positivoA = compararDecimaisInter(valorA, "0") > 0;
    const positivoB = compararDecimaisInter(valorB, "0") > 0;
    if (positivoA !== positivoB) {
      return positivoA ? -1 : 1;
    }
    if (positivoA && positivoB) {
      const diferenca = compararDecimaisInter(valorB, valorA);
      if (diferenca !== 0) return diferenca;
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
