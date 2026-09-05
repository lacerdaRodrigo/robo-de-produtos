/**
 * Portas de entrada editoriais do catálogo. Valores continuam sendo categorias
 * externas exatas recebidas do Inter; este arquivo não reclassifica produto.
 */
export type EscopoNavegacaoProdutosInter = {
  id: string;
  categorias: readonly string[];
};

const ESCOPOS: readonly EscopoNavegacaoProdutosInter[] = [
  {
    id: "celulares",
    categorias: ["Android", "Smartphones"],
  },
  {
    id: "tv-imagem",
    categorias: ["Smart TV", "TVs", "Suportes para Tv"],
  },
  {
    id: "computadores",
    categorias: ["Notebooks", "Notebooks gamer", "Tablet", "Monitores", "E-reader"],
  },
  {
    id: "audio",
    categorias: ["Caixas Acústicas", "Fones de Ouvido", "Headset", "Som Portátil", "Soundbar"],
  },
];

export function categoriasDoEscopoNavegacaoProdutosInter(
  id: string | null,
): readonly string[] | null {
  if (!id) return null;
  return ESCOPOS.find((escopo) => escopo.id === id)?.categorias ?? null;
}
