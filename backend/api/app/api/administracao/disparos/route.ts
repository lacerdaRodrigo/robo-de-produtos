import { NextResponse } from "next/server";

import { validarSolicitacaoDeDisparo } from "@/lib/administracao-api";
import { autenticarRequisicao } from "@/lib/autenticacao-api";
import { corpoErro, STATUS } from "@/lib/api";
import { resumoLojasDiretas } from "@/lib/banco-produtos-inter";
import {
  chaveDeIdempotenciaValida,
  dominioDeDisparoValido,
  estadoDoDisparo,
  solicitarDisparo,
} from "@/lib/disparos-api";

function respostaComRequisicao(
  corpo: object,
  requisicaoId: string,
  status = 200,
  retryAfter?: number,
) {
  const headers: Record<string, string> = { "x-request-id": requisicaoId };
  if (retryAfter && retryAfter > 0) headers["retry-after"] = String(retryAfter);
  return NextResponse.json(corpo, { status, headers });
}

/** Situação da reserva/cooldown, sem chamar workflow. */
export async function GET(requisicao: Request) {
  const acesso = await autenticarRequisicao(requisicao, {
    operacao: "administracao.disparos.ler",
    papel: "admin",
  });
  if (!acesso.ok) return acesso.resposta;

  const dominio = new URL(requisicao.url).searchParams.get("dominio");
  if (!dominioDeDisparoValido(dominio)) {
    return respostaComRequisicao(
      corpoErro("validacao", "dominio de disparo invalido"),
      acesso.requisicaoId,
      STATUS.INVALIDA,
    );
  }
  try {
    const estado = await estadoDoDisparo(dominio);
    return respostaComRequisicao(
      {
        dominio: estado.dominio,
        cooldown_segundos: estado.cooldownSegundos,
        ultima_solicitacao_em: estado.ultimaSolicitacaoEm,
        ultimo_estado: estado.ultimoEstado,
      },
      acesso.requisicaoId,
    );
  } catch {
    return respostaComRequisicao(
      corpoErro("inesperado", "nao foi possivel consultar o disparo"),
      acesso.requisicaoId,
      STATUS.INESPERADO,
    );
  }
}

/**
 * POST /api/v1/administracao/disparos
 *
 * Exige `Idempotency-Key` e um dos três domínios fechados. O workflow só é
 * escolhido no servidor; o Flutter nunca recebe token do GitHub ou URL de
 * dispatch.
 */
export async function POST(requisicao: Request) {
  const acesso = await autenticarRequisicao(requisicao, {
    operacao: "administracao.disparos.solicitar",
    papel: "admin",
    sensivel: true,
  });
  if (!acesso.ok) return acesso.resposta;

  const chave = requisicao.headers.get("idempotency-key");
  if (!chaveDeIdempotenciaValida(chave)) {
    return respostaComRequisicao(
      corpoErro("validacao", "Idempotency-Key obrigatoria ou invalida"),
      acesso.requisicaoId,
      STATUS.INVALIDA,
    );
  }
  let corpo: unknown;
  try {
    corpo = await requisicao.json();
  } catch {
    return respostaComRequisicao(
      corpoErro("validacao", "corpo da requisicao invalido"),
      acesso.requisicaoId,
      STATUS.INVALIDA,
    );
  }
  const entrada = validarSolicitacaoDeDisparo(corpo);
  if (!entrada.ok) {
    return respostaComRequisicao(
      corpoErro("validacao", entrada.mensagem),
      acesso.requisicaoId,
      STATUS.INVALIDA,
    );
  }

  // Produtos só pode coletar lojas que já foram escolhidas. Diferente de
  // Livelo/V3, uma rodada vazia aqui não recompõe catálogo algum e seria um
  // pedido enganoso para quem tocou no botão.
  if (entrada.valor.dominio === "produtos_inter") {
    try {
      const resumo = await resumoLojasDiretas();
      if (resumo.selecionadas < 1) {
        return respostaComRequisicao(
          corpoErro("sem-selecao", "selecione ao menos uma loja antes de atualizar produtos"),
          acesso.requisicaoId,
          409,
        );
      }
    } catch {
      return respostaComRequisicao(
        corpoErro("inesperado", "nao foi possivel verificar as lojas selecionadas"),
        acesso.requisicaoId,
        STATUS.INESPERADO,
      );
    }
  }

  try {
    const resultado = await solicitarDisparo(
      entrada.valor.dominio,
      chave,
      acesso.usuario.id,
    );
    if (resultado.estado === "cooldown") {
      return respostaComRequisicao(
        corpoErro("cooldown", "aguarde antes de solicitar outra coleta", {
          retryAfterSeconds: resultado.cooldownSegundos,
        }),
        acesso.requisicaoId,
        STATUS.LIMITE,
        resultado.cooldownSegundos,
      );
    }
    if (resultado.estado === "falha") {
      return respostaComRequisicao(
        corpoErro("disparo", "nao foi possivel solicitar a coleta"),
        acesso.requisicaoId,
        STATUS.INESPERADO,
      );
    }
    return respostaComRequisicao(
      {
        dominio: entrada.valor.dominio,
        estado: resultado.estado,
        cooldown_segundos: resultado.cooldownSegundos,
      },
      acesso.requisicaoId,
      202,
    );
  } catch {
    return respostaComRequisicao(
      corpoErro("inesperado", "nao foi possivel solicitar a coleta"),
      acesso.requisicaoId,
      STATUS.INESPERADO,
    );
  }
}
