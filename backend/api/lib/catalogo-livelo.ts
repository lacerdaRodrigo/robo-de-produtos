import type { ParceiroLiveloPersistido } from "./banco";
import { normalizar } from "./formato";

const ROTULOS_CATEGORIA: Readonly<Record<string, string>> = {
  alimentosebebidas: "Alimentos e bebidas",
  beleza: "Beleza",
  casaedecoracao: "Casa e decoração",
  construcaoeferramentas: "Construção e ferramentas",
  eletrodomesticos: "Eletrodomésticos",
  marketplace: "Marketplace",
  modaebeleza: "Moda e beleza",
  modaeacessorios: "Moda e acessórios",
  perfumariaecosmeticos: "Perfumaria e cosméticos",
  pet: "Pet",
  viagem: "Viagem",
};

export type AbaCatalogoLivelo = "todas" | "acompanhadas" | "alertas";
export type OrdenacaoCatalogoLivelo = "pontos" | "nome";

export type ParceiroCatalogoLivelo = Omit<
  ParceiroLiveloPersistido,
  "categorias" | "parceiros_lidos"
> & { categorias: string[] };

export function categoriasEmPortugues(codigos: readonly string[]): string[] {
  const rotulos = new Set<string>();
  for (const codigoBruto of codigos) {
    const codigo = normalizar(String(codigoBruto)).replace(/[^a-z0-9]/g, "");
    if (!codigo || codigo === "todos") continue;
    rotulos.add(ROTULOS_CATEGORIA[codigo] ?? "Outros");
  }
  if (rotulos.size === 0) rotulos.add("Outros");
  return [...rotulos].sort((a, b) => a.localeCompare(b, "pt-BR"));
}

export function apresentarParceiroLivelo(
  parceiro: ParceiroLiveloPersistido,
): ParceiroCatalogoLivelo {
  return {
    id_externo: parceiro.id_externo,
    nome: parceiro.nome,
    categorias: categoriasEmPortugues(parceiro.categorias ?? []),
    pontos_atuais: parceiro.pontos_atuais,
    pontos_anteriores: parceiro.pontos_anteriores,
    pontos_base: parceiro.pontos_base,
    pontos_clube: parceiro.pontos_clube,
    moeda: parceiro.moeda,
    prefixo_ate: parceiro.prefixo_ate,
    em_promocao: parceiro.em_promocao,
    campanha: parceiro.campanha,
    descricao_campanha: parceiro.descricao_campanha,
    inicio_promocao: parceiro.inicio_promocao,
    fim_promocao: parceiro.fim_promocao,
    link: parceiro.link,
    acompanhada: parceiro.acompanhada,
    alerta_ativo: parceiro.alerta_ativo ?? false,
    alerta: parceiro.alerta,
    atualizado_em: parceiro.atualizado_em,
  };
}

function compararDecimalPositivo(a: string, b: string): number {
  const normalizarDecimal = (valor: string) => {
    const [inteiroBruto, fracaoBruta = ""] = valor.replace(/^\+/, "").split(".");
    const inteiro = inteiroBruto.replace(/^0+(?=\d)/, "") || "0";
    const fracao = fracaoBruta.replace(/0+$/, "");
    return { inteiro, fracao };
  };
  const esquerda = normalizarDecimal(a);
  const direita = normalizarDecimal(b);
  if (esquerda.inteiro.length !== direita.inteiro.length) {
    return esquerda.inteiro.length - direita.inteiro.length;
  }
  const inteiros = esquerda.inteiro.localeCompare(direita.inteiro);
  if (inteiros !== 0) return inteiros;
  const tamanho = Math.max(esquerda.fracao.length, direita.fracao.length);
  return esquerda.fracao.padEnd(tamanho, "0").localeCompare(direita.fracao.padEnd(tamanho, "0"));
}

export function filtrarEOrdenarCatalogoLivelo(
  parceiros: ParceiroCatalogoLivelo[],
  filtros: {
    q: string;
    aba: AbaCatalogoLivelo;
    categoria: string;
    ordenar: OrdenacaoCatalogoLivelo;
  },
): ParceiroCatalogoLivelo[] {
  const busca = normalizar(filtros.q);
  const categoria = normalizar(filtros.categoria);
  const filtrados = parceiros.filter((parceiro) => {
    if (filtros.aba === "acompanhadas" && !parceiro.acompanhada) return false;
    if (filtros.aba === "alertas" && !(parceiro.acompanhada && parceiro.alerta)) return false;
    if (
      categoria &&
      !parceiro.categorias.some((rotulo) => normalizar(rotulo) === categoria)
    ) return false;
    if (!busca) return true;
    return (
      normalizar(parceiro.nome).includes(busca) ||
      parceiro.categorias.some((rotulo) => normalizar(rotulo).includes(busca))
    );
  });

  return [...filtrados].sort((a, b) => {
    if (filtros.ordenar === "nome") {
      return a.nome.localeCompare(b.nome, "pt-BR") || a.id_externo.localeCompare(b.id_externo);
    }
    const pontos = compararDecimalPositivo(b.pontos_atuais, a.pontos_atuais);
    return pontos || a.nome.localeCompare(b.nome, "pt-BR") || a.id_externo.localeCompare(b.id_externo);
  });
}

export function melhorOfertaLivelo(
  parceiros: ParceiroCatalogoLivelo[],
): Pick<ParceiroCatalogoLivelo, "id_externo" | "nome" | "pontos_atuais" | "moeda" | "prefixo_ate"> | null {
  const primeira = filtrarEOrdenarCatalogoLivelo(parceiros, {
    q: "",
    aba: "todas",
    categoria: "",
    ordenar: "pontos",
  })[0];
  if (!primeira) return null;
  return {
    id_externo: primeira.id_externo,
    nome: primeira.nome,
    pontos_atuais: primeira.pontos_atuais,
    moeda: primeira.moeda,
    prefixo_ate: primeira.prefixo_ate,
  };
}

export function validarAcompanhamentoLivelo(
  corpo: unknown,
): { ok: true; acompanhada: boolean } | { ok: false } {
  if (!corpo || typeof corpo !== "object" || Array.isArray(corpo)) return { ok: false };
  const objeto = corpo as Record<string, unknown>;
  if (Object.keys(objeto).length !== 1 || typeof objeto.acompanhada !== "boolean") {
    return { ok: false };
  }
  return { ok: true, acompanhada: objeto.acompanhada };
}

export function validarAlertaLivelo(
  corpo: unknown,
): { ok: true; ativo: boolean } | { ok: false } {
  if (!corpo || typeof corpo !== "object" || Array.isArray(corpo)) return { ok: false };
  const objeto = corpo as Record<string, unknown>;
  if (Object.keys(objeto).length !== 1 || typeof objeto.ativo !== "boolean") return { ok: false };
  return { ok: true, ativo: objeto.ativo };
}
