/** Regras de apresentacao e busca local da V4 (PRD-V4 RN67 a RN74). */

const IGNORADAS = new Set(["a", "as", "da", "das", "de", "do", "dos", "e", "o", "os", "para", "por"]);

export function normalizarBuscaProdutosInter(texto: string): string {
  return texto
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .match(/[a-z0-9]+/g)
    ?.filter((palavra) => !IGNORADAS.has(palavra))
    .map((palavra) => (palavra === "celular" ? "smartphone" : palavra))
    .join(" ") ?? "";
}
