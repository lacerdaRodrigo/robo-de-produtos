export type DominioDaLimpeza = "livelo" | "inter";

export const FRASE_LIMPEZA: Record<DominioDaLimpeza, string> = {
  livelo: "APAGAR LIVELO",
  inter: "RESETAR INTER",
};

export function fraseDaLimpezaConfere(
  dominio: DominioDaLimpeza,
  entrada: string,
): boolean {
  return entrada.trim() === FRASE_LIMPEZA[dominio];
}
