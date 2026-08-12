import type { Numerico } from "./banco";

/**
 * Formatacao pt-BR sem converter para `number` em momento algum.
 *
 * O robo usa Decimal justamente para o e-mail nao mostrar
 * "2.9000000000000004" (PRD 5.4). Fazer `Number(valor)` aqui jogaria fora
 * esse cuidado no ultimo metro.
 */
export function pontos(valor: Numerico): string {
  if (valor === null || valor === undefined) {
    return "—";
  }
  const texto = String(valor);
  const [inteiro, decimal = ""] = texto.split(".");
  const decimalLimpo = decimal.replace(/0+$/, "");
  return decimalLimpo ? `${inteiro},${decimalLimpo}` : inteiro;
}

const FUSO = "America/Sao_Paulo";

export function dataHora(iso: string): string {
  return new Intl.DateTimeFormat("pt-BR", {
    dateStyle: "short",
    timeStyle: "short",
    timeZone: FUSO,
  }).format(new Date(iso));
}

export function dia(iso: string): string {
  return new Intl.DateTimeFormat("pt-BR", {
    day: "2-digit",
    month: "2-digit",
    timeZone: FUSO,
  }).format(new Date(iso));
}

/** RN22: promocao que acaba hoje merece destaque proprio. */
export function terminaHoje(iso: string | null): boolean {
  if (!iso) {
    return false;
  }
  const formatador = new Intl.DateTimeFormat("pt-BR", { timeZone: FUSO });
  return formatador.format(new Date(iso)) === formatador.format(new Date());
}

/** RN23: `CLUB` e ganho exclusivo de assinante; `PROMOTION_CLUB` a base
 *  subiu para todo mundo e o Clube subiu mais. Mesma distincao do e-mail. */
export function rotuloDoClube(campanha: string | null): string | null {
  const valor = (campanha ?? "").trim().toUpperCase();
  if (valor === "CLUB") {
    return "exclusivo assinantes Clube";
  }
  if (valor === "PROMOTION_CLUB") {
    return "assinantes Clube ganham mais";
  }
  return null;
}

/** Quanto tempo faz desde a ultima execucao. Sustenta RN26: o carimbo so
 *  cumpre o papel se der para perceber que envelheceu. */
export function idade(iso: string): { texto: string; velho: boolean } {
  const minutos = Math.floor((Date.now() - new Date(iso).getTime()) / 60000);
  if (minutos < 1) {
    return { texto: "agora há pouco", velho: false };
  }
  if (minutos < 60) {
    return { texto: `há ${minutos} min`, velho: false };
  }
  const horas = Math.floor(minutos / 60);
  if (horas < 24) {
    return { texto: `há ${horas} h`, velho: horas >= 12 };
  }
  const dias = Math.floor(horas / 24);
  return { texto: dias === 1 ? "há 1 dia" : `há ${dias} dias`, velho: true };
}

/** RN03: mesma normalizacao do robo — acento, caixa e espaco nas bordas nao
 *  podem separar "Boticário" de "boticario" na busca da pagina. */
export function normalizar(texto: string): string {
  return texto
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .trim();
}

/** Filtro da busca (`?q=`). Vazio devolve tudo — busca sem termo nao esconde
 *  nada, so recarrega a lista. */
export function filtrarPorNome<T extends { nome: string; categoria?: string | null }>(
  itens: T[],
  termo: string,
): T[] {
  const alvo = normalizar(termo);
  if (!alvo) {
    return itens;
  }
  return itens.filter(
    (item) =>
      normalizar(item.nome).includes(alvo) ||
      normalizar(item.categoria ?? "").includes(alvo),
  );
}

/** Ancora da categoria no indice da pagina (`#beleza`). */
export function ancora(categoria: string): string {
  return normalizar(categoria).replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
}

/**
 * Larguras (0 a 100) da barra de progresso do cartão de loja: onde fica a
 * pontuação atual, o normal da loja e o limiar que dispara o aviso (RN30).
 *
 * `Number()` aqui é diferente do que o PRD 5.4 proíbe: o resultado nunca
 * vira texto na tela, só a largura de uma barra — não reabre o problema
 * do "2.9000000000000004" porque ninguém lê essa casa decimal.
 */
export function barraDeProgresso(
  atual: Numerico,
  base: Numerico,
  limiar: Numerico,
): { atual: number; base: number; limiar: number } | null {
  if (atual === null || base === null) {
    return null;
  }
  const nAtual = Number(atual);
  const nBase = Number(base);
  const nLimiar = limiar !== null ? Number(limiar) : nBase * 2;
  const teto = Math.max(nAtual, nLimiar) * 1.2 || 1;
  const larguraDe = (valor: number) => Math.min(100, (valor / teto) * 100);
  return { atual: larguraDe(nAtual), base: larguraDe(nBase), limiar: larguraDe(nLimiar) };
}

/**
 * Campo vazio significa "usa o padrao global" (RN28) — mesma semantica do
 * NULL na coluna. Zero e vazio nao podem se confundir, por isso a string
 * vazia vira `null` e nunca `"0"`.
 *
 * Aceita virgula porque teclado de celular em portugues oferece virgula.
 */
export function numeroOuPadrao(valor: FormDataEntryValue | null): string | null {
  const texto = String(valor ?? "").trim().replace(",", ".");
  if (!texto) {
    return null;
  }
  const numero = Number(texto);
  if (Number.isNaN(numero) || numero < 0) {
    throw new Error(`valor invalido: ${texto}`);
  }
  return texto;
}
