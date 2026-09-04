import { NextResponse } from "next/server";

import { autenticarRequisicao } from "@/lib/autenticacao-api";
import {
  listarCategoriasInterUsuario,
  substituirCategoriasInterUsuario,
} from "@/lib/banco-categorias-produtos-inter";
import { corpoErro, STATUS } from "@/lib/api";
import { validarSelecaoCategoriasProdutosInter } from "@/lib/categorias-produtos-inter";

/** Lista categorias reais presentes no catálogo ativo do Shopping Inter. */
export async function GET(requisicao: Request) {
  const acesso = await autenticarRequisicao(requisicao, {
    operacao: "inter.produtos.categorias.ler",
  });
  if (!acesso.ok) return acesso.resposta;
  try {
    return NextResponse.json(
      await listarCategoriasInterUsuario(acesso.usuario.id),
      {
        headers: { "x-request-id": acesso.requisicaoId },
      },
    );
  } catch {
    return NextResponse.json(
      corpoErro("inesperado", "nao foi possivel carregar as categorias"),
      {
        status: STATUS.INESPERADO,
        headers: { "x-request-id": acesso.requisicaoId },
      },
    );
  }
}

/**
 * Substitui categorias externas acompanhadas. `sem_categoria` representa o
 * agrupamento de produtos cuja origem não informou categoryName.
 */
export async function PATCH(requisicao: Request) {
  const acesso = await autenticarRequisicao(requisicao, {
    operacao: "inter.produtos.categorias.salvar",
  });
  if (!acesso.ok) return acesso.resposta;

  let corpo: unknown;
  try {
    corpo = await requisicao.json();
  } catch {
    corpo = null;
  }
  const entrada = validarSelecaoCategoriasProdutosInter(corpo);
  if (!entrada.ok) {
    return NextResponse.json(corpoErro("validacao", entrada.mensagem), {
      status: STATUS.INVALIDA,
      headers: { "x-request-id": acesso.requisicaoId },
    });
  }

  try {
    const resultado = await substituirCategoriasInterUsuario(
      acesso.usuario.id,
      entrada.valor.categorias,
      entrada.valor.sem_categoria,
    );
    if (!resultado.ok) {
      const invalidas = [
        ...resultado.invalidas,
        ...(resultado.sem_categoria_indisponivel ? ["Sem categoria"] : []),
      ];
      return NextResponse.json(
        corpoErro(
          "validacao",
          `categorias inexistentes no catálogo atual: ${invalidas.join(", ")}`,
        ),
        {
          status: STATUS.INVALIDA,
          headers: { "x-request-id": acesso.requisicaoId },
        },
      );
    }
    return NextResponse.json(
      await listarCategoriasInterUsuario(acesso.usuario.id),
      { headers: { "x-request-id": acesso.requisicaoId } },
    );
  } catch {
    return NextResponse.json(
      corpoErro("inesperado", "nao foi possivel salvar as categorias"),
      {
        status: STATUS.INESPERADO,
        headers: { "x-request-id": acesso.requisicaoId },
      },
    );
  }
}
