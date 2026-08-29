import "server-only";

import { neon } from "@neondatabase/serverless";

import type { DominioDaLimpeza } from "./confirmacao-limpeza";

function conectar() {
  const url = process.env.DATABASE_URL;
  if (!url) {
    throw new Error("DATABASE_URL nao configurada no ambiente do site.");
  }
  return neon(url);
}

export type ResumoDadosLivelo = {
  parceirosCatalogo: number;
  lojas: number;
  apelidos: number;
  execucoes: number;
  pontuacoes: number;
  disparos: number;
};

export type ResumoDadosInter = {
  lojasParceiras: number;
  favoritas: number;
  execucoesParceiras: number;
  cashbacks: number;
  vendedoresDiretos: number;
  selecionadas: number;
  produtos: number;
  ofertasAtuais: number;
  medicoes: number;
  execucoesProdutos: number;
};

export async function resumoDadosLivelo(): Promise<ResumoDadosLivelo> {
  const sql = conectar();
  const linhas = (await sql(
    'SELECT (SELECT count(*)::int FROM parceiro_livelo) AS "parceirosCatalogo", ' +
      "(SELECT count(*)::int FROM loja) AS lojas, " +
      "(SELECT count(*)::int FROM apelido) AS apelidos, " +
      "(SELECT count(*)::int FROM execucao) AS execucoes, " +
      "(SELECT count(*)::int FROM pontuacao) AS pontuacoes, " +
      "(SELECT count(*)::int FROM disparo_manual) AS disparos",
  )) as ResumoDadosLivelo[];
  return linhas[0] ?? {
    parceirosCatalogo: 0,
    lojas: 0,
    apelidos: 0,
    execucoes: 0,
    pontuacoes: 0,
    disparos: 0,
  };
}

export async function resumoDadosInter(): Promise<ResumoDadosInter> {
  const sql = conectar();
  const linhas = (await sql(
    'SELECT (SELECT count(*)::int FROM loja_inter) AS "lojasParceiras", ' +
      "(SELECT count(*)::int FROM favorita_inter) AS favoritas, " +
      '(SELECT count(*)::int FROM execucao_inter) AS "execucoesParceiras", ' +
      "(SELECT count(*)::int FROM cashback_inter) AS cashbacks, " +
      '(SELECT count(*)::int FROM loja_direta_inter) AS "vendedoresDiretos", ' +
      "(SELECT count(*)::int FROM loja_direta_inter WHERE selecionada = TRUE) AS selecionadas, " +
      "(SELECT count(*)::int FROM produto_direto_inter) AS produtos, " +
      "(SELECT count(*)::int FROM oferta_direta_inter_atual) AS \"ofertasAtuais\", " +
      "(SELECT count(*)::int FROM medicao_produto_direto_inter) AS medicoes, " +
      '(SELECT count(*)::int FROM execucao_produtos_inter) AS "execucoesProdutos"',
  )) as ResumoDadosInter[];
  return (
    linhas[0] ?? {
      lojasParceiras: 0,
      favoritas: 0,
      execucoesParceiras: 0,
      cashbacks: 0,
      vendedoresDiretos: 0,
      selecionadas: 0,
      produtos: 0,
      ofertasAtuais: 0,
      medicoes: 0,
      execucoesProdutos: 0,
    }
  );
}

const TABELAS_LIVELO = [
  "pontuacao",
  "apelido",
  "loja",
  "parceiro_livelo",
  "execucao",
  "preferencia",
  "disparo_manual",
];

const TABELAS_INTER = [
  "cashback_inter",
  "favorita_inter",
  "execucao_inter",
  "loja_inter",
  "disparo_manual_inter",
  "medicao_produto_direto_inter",
  "estagio_produto_inter",
  "produto_direto_inter",
  "oferta_direta_inter_atual",
  "execucao_loja_produtos_inter",
  "execucao_produtos_inter",
  "loja_direta_inter",
];

function truncar(tabelas: string[]): string {
  return "TRUNCATE TABLE " + tabelas.join(", ") + " RESTART IDENTITY";
}

export async function apagarDadosLivelo(): Promise<void> {
  const sql = conectar();
  await sql.transaction((tx) => [
    tx(truncar(TABELAS_LIVELO)),
    tx(
      "INSERT INTO preferencia (chave, valor) VALUES " +
        "('multiplicador_padrao', '2.0'), " +
        "('piso_pontos_padrao', '4'), " +
        "('assinante_clube', 'false')",
    ),
  ]);
}

export async function resetarDadosInter(): Promise<void> {
  const sql = conectar();
  await sql.transaction((tx) => [tx(truncar(TABELAS_INTER))]);
}

export function dominioValido(valor: string): valor is DominioDaLimpeza {
  return valor === "livelo" || valor === "inter";
}
