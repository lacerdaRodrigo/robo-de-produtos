import { NextResponse } from "next/server";

import { autenticarRequisicao } from "@/lib/autenticacao-api";
import { corpoErro, STATUS } from "@/lib/api";
import {
  alterarAcompanhamentoParceiroLivelo,
  parceiroLiveloPorIdExterno,
} from "@/lib/banco";
import { categoriasEmPortugues, validarAcompanhamentoLivelo } from "@/lib/catalogo-livelo";

type Contexto = { params: Promise<{ id_externo: string }> };
const ID_VALIDO = /^[A-Za-z0-9][A-Za-z0-9_-]{0,99}$/;

export async function PATCH(requisicao: Request, contexto: Contexto) {
  const acesso = await autenticarRequisicao(requisicao, {
    operacao: "livelo.catalogo.acompanhamento",
    papel: "admin",
    sensivel: true,
  });
  if (!acesso.ok) return acesso.resposta;

  const idExterno = (await contexto.params).id_externo.trim();
  let corpo: unknown;
  try {
    corpo = await requisicao.json();
  } catch {
    corpo = null;
  }
  const entrada = validarAcompanhamentoLivelo(corpo);
  if (!ID_VALIDO.test(idExterno) || !entrada.ok) {
    return NextResponse.json(corpoErro("validacao", "acompanhamento invalido"), {
      status: STATUS.INVALIDA,
      headers: { "x-request-id": acesso.requisicaoId },
    });
  }

  try {
    const parceiro = await parceiroLiveloPorIdExterno(idExterno);
    if (!parceiro) {
      return NextResponse.json(corpoErro("nao-achei", "parceiro nao encontrado"), {
        status: STATUS.NAO_ACHEI,
        headers: { "x-request-id": acesso.requisicaoId },
      });
    }
    const categoria = categoriasEmPortugues(parceiro.categorias)[0] ?? "Outros";
    const estadoConfirmado = await alterarAcompanhamentoParceiroLivelo({
      idExterno,
      nome: parceiro.nome,
      categoria,
      acompanhada: entrada.acompanhada,
    });
    if (!estadoConfirmado) throw new Error("acompanhamento nao confirmado");
    return NextResponse.json({
      id_externo: idExterno,
      acompanhada: entrada.acompanhada,
      aplicada_na_proxima_coleta: true,
    }, { headers: { "x-request-id": acesso.requisicaoId } });
  } catch {
    return NextResponse.json(corpoErro("inesperado", "nao foi possivel alterar o acompanhamento"), {
      status: STATUS.INESPERADO,
      headers: { "x-request-id": acesso.requisicaoId },
    });
  }
}
