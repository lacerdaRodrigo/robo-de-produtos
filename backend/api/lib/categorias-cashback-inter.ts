export type CategoriaCashbackInter = {
  codigo: string;
  nome: string;
};

export const CATEGORIAS_CASHBACK_INTER: readonly CategoriaCashbackInter[] = [
  { codigo: "beleza", nome: "Beleza" },
  { codigo: "casa", nome: "Casa" },
  { codigo: "eletronicos", nome: "Eletrônicos" },
  { codigo: "esporte", nome: "Esporte" },
  { codigo: "moda", nome: "Moda" },
  { codigo: "outros", nome: "Outros" },
  { codigo: "pets", nome: "Pets" },
];

const CODIGOS_CASHBACK_INTER = new Set(
  CATEGORIAS_CASHBACK_INTER.map((categoria) => categoria.codigo),
);

export function categoriaCashbackInterValida(codigo: string | null): boolean {
  return codigo !== null && CODIGOS_CASHBACK_INTER.has(codigo);
}
