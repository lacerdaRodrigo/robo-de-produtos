import Link from "next/link";
import { notFound } from "next/navigation";

import { FRASE_LIMPEZA, type DominioDaLimpeza } from "@/lib/confirmacao-limpeza";
import {
  resumoDadosInter,
  resumoDadosLivelo,
  type ResumoDadosInter,
  type ResumoDadosLivelo,
} from "@/lib/limpeza";
import { exigirSessao } from "@/lib/sessao";
import { Cabecalho } from "../../../componentes/cabecalho";
import { Rodape } from "../../../rodape";
import { acaoApagarDadosLivelo, acaoResetarDadosInter } from "../../acoes";

export const dynamic = "force-dynamic";

function dominioValido(valor: string): valor is DominioDaLimpeza {
  return valor === "livelo" || valor === "inter";
}

function LinhaResumo({ nome, valor }: { nome: string; valor: number }) {
  return (
    <li>
      <span>{nome}</span>
      <strong>{valor.toLocaleString("pt-BR")}</strong>
    </li>
  );
}

function ResumoLivelo({ resumo }: { resumo: ResumoDadosLivelo }) {
  return (
    <ul className="lista-resumo">
      <LinhaResumo nome="Lojas" valor={resumo.lojas} />
      <LinhaResumo nome="Apelidos" valor={resumo.apelidos} />
      <LinhaResumo nome="Execuções" valor={resumo.execucoes} />
      <LinhaResumo nome="Pontuações" valor={resumo.pontuacoes} />
      <LinhaResumo nome="Disparos manuais" valor={resumo.disparos} />
    </ul>
  );
}

function ResumoInter({ resumo }: { resumo: ResumoDadosInter }) {
  return (
    <ul className="lista-resumo">
      <LinhaResumo nome="Lojas parceiras" valor={resumo.lojasParceiras} />
      <LinhaResumo nome="Favoritas" valor={resumo.favoritas} />
      <LinhaResumo nome="Execuções de parceiros" valor={resumo.execucoesParceiras} />
      <LinhaResumo nome="Snapshots de cashback" valor={resumo.cashbacks} />
      <LinhaResumo nome="Vendedores diretos" valor={resumo.vendedoresDiretos} />
      <LinhaResumo nome="Vendedores selecionados" valor={resumo.selecionadas} />
      <LinhaResumo nome="Produtos" valor={resumo.produtos} />
      <LinhaResumo nome="Ofertas atuais" valor={resumo.ofertasAtuais} />
      <LinhaResumo nome="Medições de produtos" valor={resumo.medicoes} />
      <LinhaResumo nome="Execuções de produtos" valor={resumo.execucoesProdutos} />
    </ul>
  );
}

export default async function PaginaConfirmacaoLimpeza({
  params,
  searchParams,
}: {
  params: Promise<{ dominio: string }>;
  searchParams: Promise<{ erro?: string }>;
}) {
  await exigirSessao();
  const { dominio: dominioBruto } = await params;
  if (!dominioValido(dominioBruto)) notFound();
  const dominio = dominioBruto;
  const { erro } = await searchParams;

  let resumo: ResumoDadosLivelo | ResumoDadosInter | null = null;
  let falhaNoBanco = false;
  try {
    resumo = dominio === "livelo" ? await resumoDadosLivelo() : await resumoDadosInter();
  } catch {
    falhaNoBanco = true;
  }

  const livelo = dominio === "livelo";
  const titulo = livelo ? "Apagar dados da Livelo?" : "Resetar dados do Inter?";
  const frase = FRASE_LIMPEZA[dominio];

  return (
    <>
      <Cabecalho atual="/configuracoes" />
      <main className="pagina">
        <h1>{titulo}</h1>
        <p className="carimbo">Confirmação administrativa</p>
        {erro === "frase" && <p className="faixa ruim">A frase não confere. Nada foi apagado.</p>}
        {erro === "banco" && (
          <p className="faixa ruim">Não foi possível concluir a limpeza. Nenhum dado foi alterado.</p>
        )}
        <section className="bloco">
          <p>
            {livelo
              ? "Esta ação remove lojas, apelidos, regras, execuções, pontuações e disparos manuais da Livelo."
              : "Esta ação remove Sites parceiros e Compre direto do Inter, incluindo seleções, catálogos, produtos e histórico."}
          </p>
          <p className="detalhe">
            A ação é definitiva, não possui backup no aplicativo e não encerra seu login.
            Os workflows continuam agendados normalmente.
          </p>
          <h2>Prévia do que será removido</h2>
          {falhaNoBanco ? (
            <p className="faixa ruim">Não foi possível consultar as contagens. Tente novamente mais tarde.</p>
          ) : livelo ? (
            <ResumoLivelo resumo={resumo as ResumoDadosLivelo} />
          ) : (
            <ResumoInter resumo={resumo as ResumoDadosInter} />
          )}
          {!falhaNoBanco && (
            <form action={livelo ? acaoApagarDadosLivelo : acaoResetarDadosInter}>
              <div className="campo">
                <label htmlFor="frase">
                  Digite exatamente <strong>{frase}</strong> para continuar
                </label>
                <input id="frase" name="frase" required autoComplete="off" />
              </div>
              <div className="acoes-do-cartao">
                <button type="submit" className="perigo">
                  {livelo ? "Apagar definitivamente" : "Resetar definitivamente"}
                </button>
                <Link className="botao secundario" href="/configuracoes">
                  Cancelar
                </Link>
              </div>
            </form>
          )}
        </section>
        <Rodape />
      </main>
    </>
  );
}
