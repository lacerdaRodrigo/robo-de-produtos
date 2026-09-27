import { randomUUID } from "node:crypto";

import { NextResponse } from "next/server";

import { corpoErro, STATUS } from "./api";
import {
  autorizarUsuario,
  consumirLimite,
  hashTecnico,
  registrarAuditoria,
  type EventoAuditoria,
  type PapelUsuarioApp,
  type ResultadoLimite,
  type UsuarioApp,
} from "./banco-autenticacao";
import {
  verificarIdToken,
  verificarTokenAppCheck,
  type IdentidadeFirebase,
} from "./firebase-admin";

export type OpcoesDeAcesso = {
  operacao: string;
  papel?: PapelUsuarioApp;
  sensivel?: boolean;
};

export type AcessoConcedido = {
  ok: true;
  usuario: UsuarioApp;
  requisicaoId: string;
};

export type AcessoRecusado = {
  ok: false;
  resposta: NextResponse;
};

export type ResultadoAcesso = AcessoConcedido | AcessoRecusado;

export type DependenciasDeAcesso = {
  verificarIdToken: (token: string) => Promise<IdentidadeFirebase>;
  verificarAppCheck: (token: string) => Promise<void>;
  autorizarUsuario: (uid: string, email: string) => Promise<UsuarioApp | null>;
  consumirLimite: (
    chave: string,
    maximo: number,
    janelaSegundos: number,
  ) => Promise<ResultadoLimite>;
  registrarAuditoria: (evento: EventoAuditoria) => Promise<void>;
  hash: (tipo: string, valor: string) => string;
  appCheckObrigatorio: boolean;
};

/** Somente o literal `true` ativa o rollout; ausente ou `false` mantem OFF. */
export function lerAppCheckObrigatorio(valor: string | undefined): boolean {
  return valor === "true";
}

const dependenciasPadrao: DependenciasDeAcesso = {
  verificarIdToken,
  verificarAppCheck: verificarTokenAppCheck,
  autorizarUsuario,
  consumirLimite,
  registrarAuditoria,
  hash: hashTecnico,
  appCheckObrigatorio: lerAppCheckObrigatorio(process.env.EXIGIR_APP_CHECK),
};

const JANELA_LEITURA_SEGUNDOS = 60;
const MAXIMO_USUARIO_POR_JANELA = 120;
const JANELA_SENSIVEL_SEGUNDOS = 5 * 60;
const MAXIMO_SENSIVEL_POR_JANELA = 10;

function origem(requisicao: Request): string {
  return requisicao.headers.get("x-forwarded-for")?.split(",")[0]?.trim() || "desconhecida";
}

function idDaRequisicao(requisicao: Request): string {
  const recebido = requisicao.headers.get("x-request-id")?.trim();
  return recebido && /^[a-zA-Z0-9._-]{1,100}$/.test(recebido) ? recebido : randomUUID();
}

export function tokenBearer(cabecalho: string | null): string | null {
  if (!cabecalho) return null;
  const partes = cabecalho.trim().split(/\s+/);
  return partes.length === 2 && partes[0].toLowerCase() === "bearer" && partes[1]
    ? partes[1]
    : null;
}

function respostaErro(
  status: number,
  codigo: string,
  mensagem: string,
  requisicaoId: string,
  tentarNovamenteEm?: number,
): NextResponse {
  const cabecalhos: Record<string, string> = { "x-request-id": requisicaoId };
  if (tentarNovamenteEm) cabecalhos["retry-after"] = String(tentarNovamenteEm);
  return NextResponse.json(corpoErro(codigo, mensagem), { status, headers: cabecalhos });
}

function papelPermite(atual: PapelUsuarioApp, exigido: PapelUsuarioApp): boolean {
  return exigido === "usuario" || atual === "admin";
}

export async function autenticarRequisicao(
  requisicao: Request,
  opcoes: OpcoesDeAcesso,
  deps: DependenciasDeAcesso = dependenciasPadrao,
): Promise<ResultadoAcesso> {
  const requisicaoId = idDaRequisicao(requisicao);
  let identidadeHash: string | null = null;
  let usuario: UsuarioApp | null = null;
  const auditar = async (
    resultado: EventoAuditoria["resultado"],
    codigo: string,
  ): Promise<void> => {
    // Leituras rotineiras e tentativas sem identidade verificada não geram
    // escrita de auditoria. Eventos sensíveis continuam rastreáveis.
    if (!opcoes.sensivel || !identidadeHash) return;
    await deps.registrarAuditoria({
      usuarioId: usuario?.id ?? null,
      identidadeHash,
      origemHash: deps.hash("origem", origem(requisicao)),
      requisicaoId,
      acao: opcoes.operacao,
      resultado,
      codigo,
    });
  };

  try {
    if (deps.appCheckObrigatorio) {
      const appCheck = requisicao.headers.get("x-firebase-appcheck");
      if (!appCheck) {
        return {
          ok: false,
          resposta: respostaErro(
            STATUS.NAO_AUTORIZADO,
            "app-check",
            "aplicativo nao verificado",
            requisicaoId,
          ),
        };
      }
      try {
        await deps.verificarAppCheck(appCheck);
      } catch {
        return {
          ok: false,
          resposta: respostaErro(
            STATUS.NAO_AUTORIZADO,
            "app-check",
            "aplicativo nao verificado",
            requisicaoId,
          ),
        };
      }
    }

    const token = tokenBearer(requisicao.headers.get("authorization"));
    if (!token) {
      return {
        ok: false,
        resposta: respostaErro(
          STATUS.NAO_AUTORIZADO,
          "autenticacao",
          "autenticacao obrigatoria",
          requisicaoId,
        ),
      };
    }

    let identidade: IdentidadeFirebase;
    try {
      identidade = await deps.verificarIdToken(token);
    } catch (erro) {
      if (process.env.DEBUG_AUTH === "true") {
        console.error(
          `[auth] token-invalido-ou-revogado detalhe: ${
            erro instanceof Error ? erro.message.slice(0, 200) : String(erro)
          }`,
        );
      }
      return {
        ok: false,
        resposta: respostaErro(
          STATUS.NAO_AUTORIZADO,
          "autenticacao",
          "sessao invalida ou expirada",
          requisicaoId,
        ),
      };
    }

    identidadeHash = deps.hash("firebase-uid", identidade.uid);
    if (!identidade.email || !identidade.emailVerificado) {
      await auditar("negado", "email-nao-verificado");
      return {
        ok: false,
        resposta: respostaErro(
          STATUS.PROIBIDO,
          "email-nao-verificado",
          "confirme o e-mail antes de entrar",
          requisicaoId,
        ),
      };
    }

    usuario = await deps.autorizarUsuario(identidade.uid, identidade.email);
    if (!usuario || !usuario.ativo) {
      await auditar("negado", "usuario-nao-autorizado");
      return {
        ok: false,
        resposta: respostaErro(
          STATUS.PROIBIDO,
          "acesso-negado",
          "usuario nao autorizado para este piloto",
          requisicaoId,
        ),
      };
    }

    const papelExigido = opcoes.papel ?? "usuario";
    if (!papelPermite(usuario.papel, papelExigido)) {
      await auditar("negado", "papel-insuficiente");
      return {
        ok: false,
        resposta: respostaErro(
          STATUS.PROIBIDO,
          "sem-permissao",
          "voce nao tem permissao para esta acao",
          requisicaoId,
        ),
      };
    }

    const janela = opcoes.sensivel ? JANELA_SENSIVEL_SEGUNDOS : JANELA_LEITURA_SEGUNDOS;
    const maximo = opcoes.sensivel ? MAXIMO_SENSIVEL_POR_JANELA : MAXIMO_USUARIO_POR_JANELA;
    const limiteUsuario = await deps.consumirLimite(
      deps.hash("limite-usuario", `${usuario.id}:${opcoes.operacao}`),
      maximo,
      janela,
    );
    if (!limiteUsuario.permitido) {
      await auditar("negado", "limite-usuario");
      return {
        ok: false,
        resposta: respostaErro(
          STATUS.LIMITE,
          "limite",
          "muitas requisicoes; tente novamente mais tarde",
          requisicaoId,
          limiteUsuario.tentarNovamenteEm,
        ),
      };
    }

    await auditar("sucesso", "permitido");
    return { ok: true, usuario, requisicaoId };
  } catch {
    // Nenhuma excecao crua chega ao cliente; pode conter URL de banco ou
    // detalhes do provedor. O request id permite correlacionar o incidente.
    return {
      ok: false,
      resposta: respostaErro(
        STATUS.INESPERADO,
        "inesperado",
        "nao foi possivel validar o acesso",
        requisicaoId,
      ),
    };
  }
}
