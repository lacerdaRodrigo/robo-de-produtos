import { NextResponse } from "next/server";

import { validarCategoriaLojaInter } from "@/lib/administracao-api";
import { autenticarRequisicao } from "@/lib/autenticacao-api";
import { definirCategoriaCashbackInter } from "@/lib/banco-inter";
import { CATEGORIAS_CASHBACK_INTER } from "@/lib/categorias-cashback-inter";
import { corpoErro, STATUS } from "@/lib/api";

/**
 * PATCH /api/v1/inter/lojas/categoria
 *
 * Corpo: `{ "id": "…", "categoria": "moda" }`.
 * O mapeamento é editorial e protegido; a leitura do catálogo continua sendo
 * feita pela rota autenticada de cashback.
 */
export async function PATCH(requisicao: Request) {
  const acesso = await autenticarRequisicao(requisicao, {
    operacao: "inter.lojas.categoria",
    papel: "admin",
    sensivel: true,
  });
  if (!acesso.ok) return acesso.resposta;

  let corpo: unknown;
  try {
    corpo = await requisicao.json();
  } catch {
    corpo = null;
  }
  const entrada = validarCategoriaLojaInter(
    corpo,
    CATEGORIAS_CASHBACK_INTER.map((categoria) => categoria.codigo),
  );
  if (!entrada.ok) {
    return NextResponse.json(corpoErro("validacao", entrada.mensagem), {
      status: STATUS.INVALIDA,
      headers: { "x-request-id": acesso.requisicaoId },
    });
  }

  try {
    const alterada = await definirCategoriaCashbackInter(
      entrada.valor.id,
      entrada.valor.categoria,
    );
    if (!alterada) {
      return NextResponse.json(corpoErro("nao-achei", "loja nao encontrada"), {
        status: STATUS.NAO_ACHEI,
        headers: { "x-request-id": acesso.requisicaoId },
      });
    }
    return NextResponse.json(entrada.valor, {
      headers: { "x-request-id": acesso.requisicaoId },
    });
  } catch {
    return NextResponse.json(
      corpoErro("inesperado", "nao foi possivel atualizar a categoria"),
      {
        status: STATUS.INESPERADO,
        headers: { "x-request-id": acesso.requisicaoId },
      },
    );
  }
}
