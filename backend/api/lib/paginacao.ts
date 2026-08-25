export const ITENS_POR_PAGINA = 10;

export type ResultadoPaginado<T> = {
  itens: T[];
  pagina: number;
  totalPaginas: number;
  totalItens: number;
  primeiroItem: number;
  ultimoItem: number;
};

export function paginar<T>(
  itens: T[],
  paginaBruta: string | number | undefined,
  porPagina = ITENS_POR_PAGINA,
): ResultadoPaginado<T> {
  const tamanho = Number.isFinite(porPagina) && porPagina > 0 ? Math.floor(porPagina) : ITENS_POR_PAGINA;
  const totalItens = itens.length;
  const totalPaginas = Math.max(1, Math.ceil(totalItens / tamanho));
  const solicitada =
    typeof paginaBruta === "number"
      ? paginaBruta
      : Number.parseInt(paginaBruta ?? "", 10);
  const paginaValida = Number.isFinite(solicitada) && solicitada > 0 ? Math.floor(solicitada) : 1;
  const pagina = Math.min(paginaValida, totalPaginas);
  const inicio = (pagina - 1) * tamanho;
  const fim = Math.min(inicio + tamanho, totalItens);

  return {
    itens: itens.slice(inicio, fim),
    pagina,
    totalPaginas,
    totalItens,
    primeiroItem: totalItens === 0 ? 0 : inicio + 1,
    ultimoItem: fim,
  };
}

export function paginasVisiveis(pagina: number, totalPaginas: number, limite = 5): number[] {
  const quantidade = Math.min(Math.max(1, limite), totalPaginas);
  const primeiro = Math.max(1, Math.min(pagina - Math.floor(quantidade / 2), totalPaginas - quantidade + 1));
  return Array.from({ length: quantidade }, (_, indice) => primeiro + indice);
}
