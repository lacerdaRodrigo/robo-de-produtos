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

export function correspondeBuscaProdutos(nomeBusca: string, termo: string): boolean {
  const tokens = normalizarBuscaProdutosInter(termo).split(" ").filter(Boolean);
  return tokens.length > 0 && tokens.every((token) => nomeBusca.includes(token));
}

export function moeda(texto: string | null): string | null {
  if (texto === null) return null;
  return new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" }).format(Number(texto));
}

export function percentual(texto: string | null): string | null {
  if (texto === null) return null;
  const localizado = texto.replace(".", ",");
  return localizado.includes("%") ? localizado : `${localizado}%`;
}
