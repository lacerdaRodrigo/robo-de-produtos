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
