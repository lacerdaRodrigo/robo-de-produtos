import { NextResponse } from "next/server";

import { autenticarRequisicao } from "@/lib/autenticacao-api";
import {
  listarCategoriasRadarUsuario,
  substituirCategoriasRadarUsuario,
} from "@/lib/banco-categorias-produtos-inter";
import { corpoErro, STATUS } from "@/lib/api";
import { validarSelecaoCategoriasProdutosInter } from "@/lib/categorias-produtos-inter";

/** Lista a taxonomia ativa e o interesse persistente da pessoa autenticada. */
export async function GET(requisicao: Request) {
  const acesso = await autenticarRequisicao(requisicao, {
    operacao: "inter.produtos.categorias.ler",
  });
  if (!acesso.ok) return acesso.resposta;
  try {
    return NextResponse.json(
      await listarCategoriasRadarUsuario(acesso.usuario.id),
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

/** Substitui os nós escolhidos; lista vazia significa nenhum interesse ativo. */
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
    const resultado = await substituirCategoriasRadarUsuario(
      acesso.usuario.id,
      entrada.valor.categorias,
    );
    if (!resultado.ok) {
      return NextResponse.json(
        corpoErro(
          "validacao",
          `categorias inexistentes ou inativas: ${resultado.invalidas.join(", ")}`,
        ),
        {
          status: STATUS.INVALIDA,
          headers: { "x-request-id": acesso.requisicaoId },
        },
      );
    }
    return NextResponse.json(
      await listarCategoriasRadarUsuario(acesso.usuario.id),
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
