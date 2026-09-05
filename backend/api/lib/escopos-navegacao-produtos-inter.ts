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
  {
    id: "refrigeracao-lavanderia",
    categorias: [
      "Geladeira / Refrigerador",
      "Freezer",
      "Freezer Horizontal",
      "Frigobar",
      "Lava e Seca",
      "Lava-Louças",
      "Máquina de Lavar",
    ],
  },
  {
    id: "fogoes-fornos",
    categorias: [
      "Fogões",
      "Piso 4 Bocas",
      "Piso 5 Bocas",
      "Cooktop",
      "Forno Elétrico",
      "Fornos",
    ],
  },
  { id: "microondas", categorias: ["Micro-ondas"] },
  { id: "eletroportateis", categorias: ["Fritadeiras", "Liquidificadores", "Liquidificadores e Acessórios", "Cafeteiras", "Cafeteiras Elétricas", "Cafeteiras Expresso", "Chaleiras Elétricas", "Mixer", "Panelas Elétricas", "Processador de Alimentos"] },
  { id: "moveis", categorias: ["Sofás", "Racks e Painéis", "Guarda-roupas e Roupeiros", "Guarda-roupas Modulados", "Cômodas", "Escrivaninhas", "Cadeiras", "Poltronas"] },
  { id: "utilidades", categorias: ["Panelas", "Conjuntos de Panela", "Copos", "Potes e Tigelas", "Formas e Assadeiras", "Organização", "Utilidades Domésticas"] },
  { id: "maquiagem", categorias: ["Base", "Batom", "Blush", "Gloss", "Delineador", "Esmaltes", "Maquiagem"] },
  { id: "cabelos", categorias: ["Cabelos", "Shampoo", "Condicionadores", "Hidratação", "Finalizador", "Tratamento e Máscaras"] },
  { id: "pele", categorias: ["Cuidados Faciais", "Limpeza de Pele", "Limpadores Faciais", "Hidratantes Corpo", "Corpo e Banho", "Protetor Solar"] },
  { id: "perfumaria", categorias: ["Perfumes", "Desodorante", "Perfume para o Corpo"] },
  { id: "alimentos", categorias: ["Biscoito", "Chocolate", "Cereais", "Farinhas e Grãos", "Pães e Torradas", "Mercado"] },
  { id: "bebidas", categorias: ["Bebidas", "Chás", "Café e cappuccino", "Sucos e Refrescos", "Água mineral", "Água de coco"] },
  { id: "snacks", categorias: ["Balas e Drops", "Chiclete", "Salgadinhos e snacks", "Doces"] },
  { id: "suplementos", categorias: ["Suplementos e Vitaminas", "Suplementação", "Vitamina"] },
  { id: "bebe", categorias: ["Mamadeiras", "Fralda", "Berços e Cercados Portáteis", "Amamentação", "Troca do Bebê"] },
  { id: "brinquedos", categorias: ["Brinquedos", "Bonecas", "Bonecos", "Jogos", "Pelúcias"] },
  { id: "pet", categorias: ["Ração", "Antipulgas", "Areia Higiênica", "Farmácia pet", "Pet Shop"] },
  { id: "esporte", categorias: ["Bicicletas", "Patinetes", "Pilates e Yoga", "Piscinas", "Esteiras Ergométricas"] },
  { id: "ferramentas", categorias: ["Furadeiras", "Parafusadeiras", "Ferramentas Elétricas", "Ferramentas Manuais", "Lâmpadas", "Torneiras"] },
  { id: "auto", categorias: ["Pneus", "Pneus, Rodas e Calotas", "Limpeza de Automóveis"] },
  { id: "moda", categorias: ["Blusas e Camisetas", "Casacos e Jaquetas", "Chinelos", "Mochilas", "Moda", "Feminino", "Masculino"] },
];

export const ESCOPO_OUTROS_NOVAS_CATEGORIAS = "outros-novas-categorias";

export function escopoEhOutrosNovasCategorias(id: string | null): boolean {
  return id === ESCOPO_OUTROS_NOVAS_CATEGORIAS;
}

export function categoriasMapeadasNavegacaoProdutosInter(): readonly string[] {
  return [...new Set(ESCOPOS.flatMap((escopo) => escopo.categorias))];
}

export function categoriasDoEscopoNavegacaoProdutosInter(
  id: string | null,
): readonly string[] | null {
  if (!id) return null;
  return ESCOPOS.find((escopo) => escopo.id === id)?.categorias ?? null;
}
