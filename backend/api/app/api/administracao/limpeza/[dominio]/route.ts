import { revalidatePath } from "next/cache";
import { NextResponse } from "next/server";

import {
  FRASE_LIMPEZA,
  fraseDaLimpezaConfere,
  type DominioDaLimpeza,
} from "@/lib/confirmacao-limpeza";
import { autenticarRequisicao } from "@/lib/autenticacao-api";
import { corpoErro, STATUS } from "@/lib/api";
import {
  apagarDadosLivelo,
  dominioValido,
  resetarDadosInter,
  resumoDadosInter,
  resumoDadosLivelo,
} from "@/lib/limpeza";

type Contexto = { params: Promise<{ dominio: string }> };

async function dominioDoContexto(contexto: Contexto): Promise<DominioDaLimpeza | null> {
  const valor = (await contexto.params).dominio;
  return dominioValido(valor) ? valor : null;
}

function naoEncontrado(requisicaoId: string) {
  return NextResponse.json(corpoErro("nao-achei", "dominio nao encontrado"), {
    status: STATUS.NAO_ACHEI,
    headers: { "x-request-id": requisicaoId },
  });
}

export async function GET(requisicao: Request, contexto: Contexto) {
  const acesso = await autenticarRequisicao(requisicao, {
    operacao: "administracao.limpeza.resumo",
    papel: "admin",
  });
  if (!acesso.ok) return acesso.resposta;
  const dominio = await dominioDoContexto(contexto);
  if (dominio === null) return naoEncontrado(acesso.requisicaoId);

  try {
    const contagens = dominio === "livelo" ? await resumoDadosLivelo() : await resumoDadosInter();
    return NextResponse.json(
      {
        dominio,
        frase_confirmacao: FRASE_LIMPEZA[dominio],
        contagens,
      },
      { headers: { "x-request-id": acesso.requisicaoId } },
    );
  } catch {
    return NextResponse.json(corpoErro("inesperado", "nao foi possivel consultar os dados"), {
      status: STATUS.INESPERADO,
      headers: { "x-request-id": acesso.requisicaoId },
    });
  }
}

export async function POST(requisicao: Request, contexto: Contexto) {
  const acesso = await autenticarRequisicao(requisicao, {
    operacao: "administracao.limpeza.executar",
    papel: "admin",
    sensivel: true,
  });
  if (!acesso.ok) return acesso.resposta;
  const dominio = await dominioDoContexto(contexto);
  if (dominio === null) return naoEncontrado(acesso.requisicaoId);

  let corpo: unknown;
  try {
    corpo = await requisicao.json();
  } catch {
    corpo = null;
  }
  const frase =
    corpo && typeof corpo === "object" && !Array.isArray(corpo)
      ? (corpo as Record<string, unknown>).frase
      : null;
  if (typeof frase !== "string" || !fraseDaLimpezaConfere(dominio, frase)) {
    return NextResponse.json(corpoErro("confirmacao", "a frase de confirmacao nao confere"), {
      status: STATUS.INVALIDA,
      headers: { "x-request-id": acesso.requisicaoId },
    });
  }

  try {
    if (dominio === "livelo") {
      await apagarDadosLivelo();
      revalidatePath("/");
      revalidatePath("/lojas");
      revalidatePath("/avisos");
    } else {
      await resetarDadosInter();
      revalidatePath("/inter");
      revalidatePath("/inter/lojas");
      revalidatePath("/inter/produtos");
      revalidatePath("/inter/produtos/lojas");
    }
    return NextResponse.json(
      { dominio, concluida: true },
      { headers: { "x-request-id": acesso.requisicaoId } },
    );
  } catch {
    return NextResponse.json(
      corpoErro("inesperado", "nao foi possivel concluir; nenhum dado foi alterado"),
      {
        status: STATUS.INESPERADO,
        headers: { "x-request-id": acesso.requisicaoId },
      },
    );
  }
}
