import { describe, expect, it } from "vitest";

import type { ParceiroLiveloPersistido } from "../lib/banco";
import {
  apresentarParceiroLivelo,
  categoriasEmPortugues,
  filtrarEOrdenarCatalogoLivelo,
  filtrosSqlCatalogoLivelo,
  melhorOfertaLivelo,
  validarAlertaLivelo,
  validarAcompanhamentoLivelo,
} from "../lib/catalogo-livelo";

function parceiro(
  id: string,
  nome: string,
  pontos: string,
  categorias: string[],
  acompanhada = false,
  alerta = false,
): ParceiroLiveloPersistido {
  return {
    id_externo: id,
    nome,
    categorias,
    pontos_atuais: pontos,
    pontos_anteriores: null,
    pontos_base: "1",
    pontos_clube: null,
    moeda: "R$",
    prefixo_ate: false,
    em_promocao: false,
    campanha: null,
    descricao_campanha: null,
    inicio_promocao: null,
    fim_promocao: null,
    link: null,
    acompanhada,
    alerta,
    atualizado_em: "2026-08-28T12:00:00Z",
    parceiros_lidos: 252,
  };
}

describe("catálogo Livelo autenticado", () => {
  const itens = [
    apresentarParceiroLivelo(parceiro("A", "Loja Ágil", "9.90", ["marketplace"], true, true)),
    apresentarParceiroLivelo(parceiro("B", "Beleza Já", "12", ["beleza"], true)),
    apresentarParceiroLivelo(parceiro("C", "Sem grupo", "2.9", ["codigo-novo"])),
  ];

  it("mapeia categorias conhecidas e reserva desconhecidas em Outros", () => {
    expect(categoriasEmPortugues(["todos", "casaedecoracao", "novo"])).toEqual([
      "Casa e decoração",
      "Outros",
    ]);
    expect(filtrosSqlCatalogoLivelo("decoracao", "Casa e decoração")).toMatchObject({
      busca: "decoracao",
      codigosBusca: ["casaedecoracao"],
      codigosCategoria: ["casaedecoracao"],
      categoriaIncluiOutros: false,
    });
    expect(filtrosSqlCatalogoLivelo("out", "Outros")).toMatchObject({
      buscaIncluiOutros: true,
      categoriaIncluiOutros: true,
    });
  });

  it("filtra busca, aba e categoria sem perder identidade", () => {
    expect(filtrarEOrdenarCatalogoLivelo(itens, {
      q: "agil",
      aba: "acompanhadas",
      categoria: "Marketplace",
      ordenar: "nome",
    }).map((item) => item.id_externo)).toEqual(["A"]);
    expect(filtrarEOrdenarCatalogoLivelo(itens, {
      q: "",
      aba: "alertas",
      categoria: "",
      ordenar: "pontos",
    }).map((item) => item.id_externo)).toEqual(["A"]);
  });

  it("filtra pontuação comum ampliada sem usar Clube ou converter para float", () => {
    const acima = apresentarParceiroLivelo({
      ...parceiro("D", "Pontos maiores", "10.01", ["marketplace"]),
      pontos_base: "10",
      pontos_clube: "15",
    });
    const igual = apresentarParceiroLivelo({
      ...parceiro("E", "Pontos iguais", "10.0", ["marketplace"]),
      pontos_base: "10",
    });
    const ausente = apresentarParceiroLivelo({
      ...parceiro("F", "Sem base", "99", ["marketplace"]),
      pontos_base: null,
    });
    const ampliada = filtrarEOrdenarCatalogoLivelo(
      [acima, igual, ausente],
      {
        q: "",
        aba: "todas",
        categoria: "",
        ordenar: "pontos",
        somentePontuacaoComumAmpliada: true,
      },
    );

    expect(ampliada.map((item) => item.id_externo)).toEqual(["D"]);
  });

  it("ordena validade crescente e mantém validade ausente por último", () => {
    const itens = [
      apresentarParceiroLivelo({ ...parceiro("A", "Sem fim", "1", []), fim_promocao: null }),
      apresentarParceiroLivelo({ ...parceiro("B", "Depois", "1", []), fim_promocao: "2026-10-02" }),
      apresentarParceiroLivelo({ ...parceiro("C", "Antes", "1", []), fim_promocao: "2026-09-30" }),
    ];

    expect(filtrarEOrdenarCatalogoLivelo(itens, {
      q: "",
      aba: "todas",
      categoria: "",
      ordenar: "validade",
    }).map((item) => item.id_externo)).toEqual(["C", "B", "A"]);
  });

  it("ordena pontos textuais com precisão e encontra a melhor oferta", () => {
    const ordenados = filtrarEOrdenarCatalogoLivelo(itens, {
      q: "",
      aba: "todas",
      categoria: "",
      ordenar: "pontos",
    });
    expect(ordenados.map((item) => item.pontos_atuais)).toEqual(["12", "9.90", "2.9"]);
    expect(melhorOfertaLivelo(itens)?.id_externo).toBe("B");
  });

  it("não escolhe uma loja geral quando não há acompanhadas", () => {
    expect(melhorOfertaLivelo([itens[2]])).toBeNull();
  });

  it("aceita somente o booleano de acompanhamento, sem nome ou link do cliente", () => {
    expect(validarAcompanhamentoLivelo({ acompanhada: true })).toEqual({
      ok: true,
      acompanhada: true,
    });
    expect(validarAcompanhamentoLivelo({ acompanhada: true, nome: "hostil" }).ok).toBe(false);
    expect(validarAcompanhamentoLivelo({ acompanhada: "true" }).ok).toBe(false);
  });

  it("aceita somente o booleano do sino", () => {
    expect(validarAlertaLivelo({ ativo: true })).toEqual({ ok: true, ativo: true });
    expect(validarAlertaLivelo({ ativo: "true" }).ok).toBe(false);
    expect(validarAlertaLivelo({ ativo: false, nome: "hostil" }).ok).toBe(false);
  });
});
