import { NextResponse } from "next/server";

import { validarNovaLojaLivelo } from "@/lib/administracao-api";
import { autenticarRequisicao } from "@/lib/autenticacao-api";
import { corpoErro, paginacaoEnvelope, paginaValida, porPaginaValida, STATUS } from "@/lib/api";
import { adicionarLojaAdministrativa, catalogo } from "@/lib/banco";
import { filtrarPorNome, normalizar } from "@/lib/formato";
import { paginar } from "@/lib/paginacao";

/** Catálogo Livelo administrativo, incluindo apelidos e regras próprias. */
export async function GET(requisicao: Request) {
  const acesso = await autenticarRequisicao(requisicao, {
    operacao: "livelo.lojas.ler",
    papel: "admin",
  });
  if (!acesso.ok) return acesso.resposta;

  try {
    const url = new URL(requisicao.url);
    const pagina = paginaValida(url.searchParams.get("pagina"));
    const porPagina = porPaginaValida(url.searchParams.get("por_pagina"));
    const filtradas = filtrarPorNome(await catalogo(), url.searchParams.get("q") ?? "");
    const resultado = paginar(filtradas, pagina, porPagina);
    return NextResponse.json({
      itens: resultado.itens,
      ...paginacaoEnvelope(resultado.totalItens, pagina, porPagina),
    });
  } catch {
    return NextResponse.json(corpoErro("inesperado", "nao foi possivel carregar as lojas"), {
      status: STATUS.INESPERADO,
      headers: { "x-request-id": acesso.requisicaoId },
    });
  }
}

/** Cadastra uma favorita sem disparar coleta. */
export async function POST(requisicao: Request) {
  const acesso = await autenticarRequisicao(requisicao, {
    operacao: "livelo.lojas.criar",
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
  const entrada = validarNovaLojaLivelo(corpo);
  if (!entrada.ok) {
    return NextResponse.json(corpoErro("validacao", entrada.mensagem), {
      status: STATUS.INVALIDA,
      headers: { "x-request-id": acesso.requisicaoId },
    });
  }

  try {
    // RN04: nome e apelido não podem capturar duas lojas após normalização.
    const existentes = await catalogo();
    const grafias = new Set(
      existentes.flatMap((loja) => [loja.nome, ...loja.apelidos]).map(normalizar),
    );
    if ([entrada.valor.nome, ...entrada.valor.apelidos].some((valor) => grafias.has(normalizar(valor)))) {
      return NextResponse.json(corpoErro("conflito", "nome ou apelido ja cadastrado"), {
        status: 409,
        headers: { "x-request-id": acesso.requisicaoId },
      });
    }
    const id = await adicionarLojaAdministrativa(entrada.valor);
    return NextResponse.json(
      {
        id: String(id),
        nome: entrada.valor.nome,
        categoria: entrada.valor.categoria,
        apelidos: entrada.valor.apelidos,
        multiplicador: entrada.valor.multiplicador,
        piso_pontos: entrada.valor.piso,
      },
      {
        status: 201,
        headers: { "x-request-id": acesso.requisicaoId },
      },
    );
  } catch (erro) {
    const codigo =
      erro && typeof erro === "object" && "code" in erro
        ? String((erro as { code?: unknown }).code ?? "")
        : "";
    const conflito = codigo === "23505";
    return NextResponse.json(corpoErro(
      conflito ? "conflito" : "inesperado",
      conflito ? "nome ou apelido ja cadastrado" : "nao foi possivel cadastrar a loja",
    ), {
      status: conflito ? 409 : STATUS.INESPERADO,
      headers: { "x-request-id": acesso.requisicaoId },
    });
  }
}
