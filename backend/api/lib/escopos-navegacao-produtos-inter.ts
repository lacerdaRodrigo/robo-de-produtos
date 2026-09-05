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
      "Side by Side",
      "Frigobar",
      "Freezer",
      "Freezer Horizontal",
      "Lava e Seca",
      "Lava-Louças",
      "Máquina de Lavar",
      "Secadoras de Roupas",
      "Tanquinho",
    ],
  },
  {
    id: "geladeiras",
    categorias: [
      "Geladeira / Refrigerador",
      "Side by Side",
      "Frigobar",
    ],
  },
  {
    id: "freezers",
    categorias: ["Freezer", "Freezer Horizontal"],
  },
  {
    id: "lavadoras",
    categorias: [
      "Lava e Seca",
      "Lava-Louças",
      "Máquina de Lavar",
      "Secadoras de Roupas",
      "Tanquinho",
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

  // Folhas mais específicas da árvore de navegação. Os escopos amplos acima
  // permanecem válidos para compatibilidade com clientes já publicados.
  { id: "celulares-android", categorias: ["Android"] },
  { id: "celulares-smartphones", categorias: ["Smartphones"] },
  { id: "tv-smart", categorias: ["Smart TV"] },
  { id: "tv-convencional", categorias: ["TVs"] },
  { id: "suportes-tv", categorias: ["Suportes para Tv"] },
  { id: "notebooks", categorias: ["Notebooks", "Notebooks gamer"] },
  { id: "tablets", categorias: ["Tablet"] },
  { id: "monitores", categorias: ["Monitores"] },
  { id: "e-readers", categorias: ["E-reader"] },
  { id: "caixas-acusticas", categorias: ["Caixas Acústicas"] },
  { id: "fones", categorias: ["Fones de Ouvido", "Headset"] },
  { id: "som-portatil", categorias: ["Som Portátil"] },
  { id: "soundbars", categorias: ["Soundbar"] },
  { id: "fritadeiras", categorias: ["Fritadeiras"] },
  { id: "liquidificadores", categorias: ["Liquidificadores", "Liquidificadores e Acessórios"] },
  { id: "cafeteiras", categorias: ["Cafeteiras", "Cafeteiras Elétricas", "Cafeteiras Expresso"] },
  { id: "chaleiras", categorias: ["Chaleiras Elétricas"] },
  { id: "mixers", categorias: ["Mixer"] },
  { id: "panelas-eletricas", categorias: ["Panelas Elétricas"] },
  { id: "processadores", categorias: ["Processador de Alimentos"] },
  { id: "sofas", categorias: ["Sofás"] },
  { id: "racks-paineis", categorias: ["Racks e Painéis"] },
  { id: "guarda-roupas", categorias: ["Guarda-roupas e Roupeiros", "Guarda-roupas Modulados"] },
  { id: "comodas", categorias: ["Cômodas"] },
  { id: "escritorio", categorias: ["Escrivaninhas", "Cadeiras"] },
  { id: "poltronas", categorias: ["Poltronas"] },
  { id: "panelas", categorias: ["Panelas", "Conjuntos de Panela"] },
  { id: "copos", categorias: ["Copos"] },
  { id: "potes", categorias: ["Potes e Tigelas"] },
  { id: "formas", categorias: ["Formas e Assadeiras"] },
  { id: "organizacao", categorias: ["Organização", "Utilidades Domésticas"] },
  { id: "bases", categorias: ["Base"] },
  { id: "batons", categorias: ["Batom"] },
  { id: "blushes", categorias: ["Blush"] },
  { id: "glosses", categorias: ["Gloss"] },
  { id: "olhos", categorias: ["Delineador"] },
  { id: "esmaltes", categorias: ["Esmaltes"] },
  { id: "shampoos", categorias: ["Shampoo"] },
  { id: "condicionadores", categorias: ["Condicionadores"] },
  { id: "tratamento-cabelos", categorias: ["Cabelos", "Hidratação", "Finalizador", "Tratamento e Máscaras"] },
  { id: "cuidados-faciais", categorias: ["Cuidados Faciais", "Limpeza de Pele", "Limpadores Faciais"] },
  { id: "corpo-banho", categorias: ["Hidratantes Corpo", "Corpo e Banho"] },
  { id: "protetores-solares", categorias: ["Protetor Solar"] },
  { id: "perfumes", categorias: ["Perfumes", "Perfume para o Corpo"] },
  { id: "desodorantes", categorias: ["Desodorante"] },
  { id: "biscoitos", categorias: ["Biscoito"] },
  { id: "chocolates", categorias: ["Chocolate"] },
  { id: "mercearia", categorias: ["Cereais", "Farinhas e Grãos", "Pães e Torradas", "Mercado"] },
  { id: "bebidas-agua", categorias: ["Bebidas"] },
  { id: "chas-cafes", categorias: ["Chás", "Café e cappuccino"] },
  { id: "sucos-aguas", categorias: ["Sucos e Refrescos", "Água mineral", "Água de coco"] },
  { id: "balas-doces", categorias: ["Balas e Drops", "Doces"] },
  { id: "chicletes", categorias: ["Chiclete"] },
  { id: "salgadinhos", categorias: ["Salgadinhos e snacks"] },
  { id: "suplementos-vitaminas", categorias: ["Suplementos e Vitaminas", "Suplementação", "Vitamina"] },
  { id: "mamadeiras", categorias: ["Mamadeiras"] },
  { id: "fraldas", categorias: ["Fralda"] },
  { id: "bercos", categorias: ["Berços e Cercados Portáteis"] },
  { id: "amamentacao", categorias: ["Amamentação", "Troca do Bebê"] },
  { id: "bonecas", categorias: ["Bonecas"] },
  { id: "bonecos", categorias: ["Bonecos"] },
  { id: "jogos", categorias: ["Jogos"] },
  { id: "pelucias", categorias: ["Pelúcias"] },
  { id: "racao", categorias: ["Ração", "Ração para Pássaros"] },
  { id: "saude-pet", categorias: ["Antipulgas", "Farmácia pet"] },
  { id: "higiene-pet", categorias: ["Areia Higiênica"] },
  { id: "acessorios-pet", categorias: ["Pet Shop"] },
  { id: "bicicletas", categorias: ["Bicicletas", "Bicicletas Ergométricas", "Bicicletas Infantojuvenis"] },
  { id: "patinetes-patins", categorias: ["Patinetes", "Patins"] },
  { id: "fitness", categorias: ["Pilates e Yoga", "Esteiras Ergométricas"] },
  { id: "piscinas", categorias: ["Piscinas"] },
  { id: "furadeiras", categorias: ["Furadeiras"] },
  { id: "parafusadeiras", categorias: ["Parafusadeiras"] },
  { id: "ferramentas-basicas", categorias: ["Ferramentas Elétricas", "Ferramentas Manuais"] },
  { id: "eletrica", categorias: ["Lâmpadas"] },
  { id: "torneiras", categorias: ["Torneiras"] },
  { id: "pneus", categorias: ["Pneus", "Pneus, Rodas e Calotas"] },
  { id: "limpeza-auto", categorias: ["Limpeza de Automóveis"] },
  { id: "roupas", categorias: ["Blusas e Camisetas", "Casacos e Jaquetas"] },
  { id: "calcados", categorias: ["Chinelos"] },
  { id: "acessorios-moda", categorias: ["Mochilas", "Moda", "Feminino", "Masculino"] },
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
