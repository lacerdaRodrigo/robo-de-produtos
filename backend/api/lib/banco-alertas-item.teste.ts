import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

type Consulta = { texto: string; valores: unknown[] };

const infraestrutura = vi.hoisted(() => ({
  neon: vi.fn(),
  sql: vi.fn(),
  origem: "livelo",
  alertaEncontrado: true,
  entidadeEncontrada: true,
  consultas: [] as Consulta[],
}));

vi.mock("@neondatabase/serverless", () => ({ neon: infraestrutura.neon }));

import { buscarItemAlerta } from "./banco-alertas";

const casos = [
  {
    origem: "livelo",
    consultaEntidade: "FROM parceiro_livelo parceiro",
    idExato: "parceiro.id = ?",
    campos: [
      "id_externo", "nome", "categorias", "pontos_atuais", "pontos_anteriores",
      "pontos_base", "pontos_clube", "moeda", "prefixo_ate", "em_promocao",
      "campanha", "descricao_campanha", "inicio_promocao", "fim_promocao",
      "link", "acompanhada", "alerta_ativo", "alerta", "atualizado_em",
    ],
  },
  {
    origem: "inter_cashback",
    consultaEntidade: "FROM loja_inter loja",
    idExato: "loja.id = ?",
    campos: [
      "id", "id_externo", "slug", "nome", "cashback_principal_texto",
      "cashback_principal_valor", "cashback_secundario_texto",
      "cashback_secundario_valor", "etiqueta", "descricao_principal",
      "descricao_secundaria", "categoria", "encontrada", "favorita", "link",
    ],
  },
  {
    origem: "inter_produto",
    consultaEntidade: "FROM produto_direto_inter produto",
    idExato: "produto.id = ?",
    campos: [
      "id_externo", "nome", "marca", "categoria", "caminho",
      "preco_cheio_texto", "preco_cheio_valor", "preco_atual_texto",
      "preco_atual_valor", "desconto_texto", "desconto_percentual_texto",
      "cashback_texto", "cashback_percentual_texto", "preco_liquido_texto",
      "parcelamento", "estoque", "etiquetas", "atualizada_em", "loja_slug",
      "loja_nome", "acompanhado",
    ],
  },
  {
    origem: "pichau",
    consultaEntidade: "FROM pichau_produto produto",
    idExato: "produto.id = ?",
    campos: [
      "id_externo", "sku", "nome", "marca", "categoria_externa", "url_produto",
      "presente_no_catalogo", "disponibilidade", "acompanhada",
      "preco_original_texto", "preco_pix_texto", "desconto_pix_texto",
      "preco_cartao_texto", "parcelamento", "sem_juros", "etiquetas",
      "atualizado_em", "origem",
    ],
  },
] as const;

function configurarBanco() {
  infraestrutura.consultas.length = 0;
  infraestrutura.neon.mockReturnValue(infraestrutura.sql);
  infraestrutura.sql.mockImplementation(
    (strings: TemplateStringsArray, ...valores: unknown[]) => {
      const texto = strings.join("?");
      infraestrutura.consultas.push({ texto, valores });
      if (texto.includes("FROM evento_alerta")) {
        return Promise.resolve(
          infraestrutura.alertaEncontrado
            ? [{ origem: infraestrutura.origem, entidade_id: "501" }]
            : [],
        );
      }
      if (!infraestrutura.entidadeEncontrada) return Promise.resolve([]);
      if (texto.includes("FROM parceiro_livelo parceiro")) {
        return Promise.resolve([{
          id_externo: "loja-8",
          nome: "Loja teste",
          categorias: ["casaedecoracao"],
          pontos_atuais: "6",
          pontos_anteriores: "5",
          pontos_base: "2",
          pontos_clube: "7",
          moeda: "pontos_por_real",
          prefixo_ate: false,
          em_promocao: true,
          campanha: null,
          descricao_campanha: null,
          inicio_promocao: null,
          fim_promocao: null,
          link: "https://example.test/loja-8",
          acompanhada: true,
          alerta_ativo: true,
          alerta: true,
          atualizado_em: "2026-09-28T12:00:00.000Z",
          parceiros_lidos: 50,
        }]);
      }
      if (texto.includes("FROM loja_inter loja")) {
        return Promise.resolve([{
          id: "501",
          id_externo: "inter-8",
          slug: "loja-teste",
          nome: "Loja teste",
          cashback_principal_texto: "Até 6%",
          cashback_principal_valor: "6.00",
          cashback_secundario_texto: null,
          cashback_secundario_valor: null,
          etiqueta: null,
          descricao_principal: null,
          descricao_secundaria: null,
          categoria: "outros",
          encontrada: true,
          favorita: true,
        }]);
      }
      if (texto.includes("FROM produto_direto_inter produto")) {
        return Promise.resolve([{
          id_externo: "produto-8",
          nome: "Produto teste",
          marca: "Marca",
          categoria: "Casa",
          caminho: "/produto-8",
          preco_cheio_texto: "R$ 120,00",
          preco_cheio_valor: "120.00",
          preco_atual_texto: "R$ 100,00",
          preco_atual_valor: "100.00",
          desconto_texto: "17% OFF",
          desconto_percentual_texto: "17%",
          cashback_texto: null,
          cashback_percentual_texto: null,
          preco_liquido_texto: null,
          parcelamento: null,
          estoque: 2,
          etiquetas: [],
          atualizada_em: "2026-09-28T12:00:00.000Z",
          loja_slug: "loja-direta",
          loja_nome: "Loja direta",
          acompanhado: true,
        }]);
      }
      return Promise.resolve([{
        id_externo: "pichau-8",
        sku: "SKU-8",
        nome: "Produto teste",
        marca: "Marca",
        categoria_externa: "Hardware",
        url_produto: "https://pichau.example/produto-8",
        presente_no_catalogo: true,
        disponibilidade: "disponivel",
        acompanhada: true,
        preco_original_texto: "R$ 120,00",
        preco_pix_texto: "R$ 100,00",
        desconto_pix_texto: "17% OFF",
        preco_cartao_texto: "R$ 110,00",
        parcelamento: "10x de R$ 11,00",
        sem_juros: true,
        etiquetas: [],
        atualizado_em: "2026-09-28T12:00:00.000Z",
      }]);
    },
  );
}

describe("resolução pontual de item de alerta", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.stubEnv("DATABASE_URL", "postgres://teste.local/radar");
    infraestrutura.origem = "livelo";
    infraestrutura.alertaEncontrado = true;
    infraestrutura.entidadeEncontrada = true;
    configurarBanco();
  });

  afterEach(() => {
    vi.unstubAllEnvs();
  });

  it.each(casos)("busca somente a entidade de origem $origem pelo ID interno", async (caso) => {
    infraestrutura.origem = caso.origem;

    const resultado = await buscarItemAlerta("42", "71");

    expect(resultado?.origem).toBe(caso.origem);
    expect(resultado?.item).toBeTruthy();
    expect(Object.keys(resultado!.item).sort()).toEqual([...caso.campos].sort());
    expect(infraestrutura.consultas).toHaveLength(2);
    const [consultaAlerta, consultaEntidade] = infraestrutura.consultas;
    expect(consultaAlerta.texto).toContain("FROM evento_alerta");
    expect(consultaAlerta.texto).toContain("WHERE id = ?::bigint");
    expect(consultaAlerta.texto).toContain("AND usuario_app_id = ?::bigint");
    expect(consultaAlerta.valores).toEqual(["71", "42"]);
    expect(consultaEntidade.texto).toContain(caso.consultaEntidade);
    expect(consultaEntidade.texto).toContain(caso.idExato);
    expect(consultaEntidade.valores).toContain("501");
    expect(consultaEntidade.texto).not.toContain("count(*)");
    expect(consultaEntidade.texto).not.toContain("OFFSET");
  });

  it("monta o link oficial de Sites parceiros a partir do slug do DTO", async () => {
    infraestrutura.origem = "inter_cashback";

    const resultado = await buscarItemAlerta("42", "71");

    expect(resultado?.item).toMatchObject({
      id_externo: "inter-8",
      slug: "loja-teste",
      link: "https://shopping.inter.co/site-parceiro/lojas/loja-teste",
    });
  });

  it("usa a mesma ausência para alerta de outra conta e alerta inexistente", async () => {
    infraestrutura.alertaEncontrado = false;

    await expect(buscarItemAlerta("99", "71")).resolves.toBeNull();
    expect(infraestrutura.consultas).toHaveLength(1);
    expect(infraestrutura.consultas[0].valores).toEqual(["71", "99"]);

    infraestrutura.consultas.length = 0;
    await expect(buscarItemAlerta("42", "404")).resolves.toBeNull();
    expect(infraestrutura.consultas).toHaveLength(1);
  });

  it("retorna ausência indistinguível quando a entidade foi removida", async () => {
    infraestrutura.entidadeEncontrada = false;

    await expect(buscarItemAlerta("42", "71")).resolves.toBeNull();
    expect(infraestrutura.consultas).toHaveLength(2);
  });
});
