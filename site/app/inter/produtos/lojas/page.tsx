import Link from "next/link";

import { buscarLojasDiretas, resumoLojasDiretas } from "@/lib/banco-produtos-inter";
import { exigirSessao } from "@/lib/sessao";
import { BuscaProgressiva } from "../../../componentes/busca-progressiva";
import { Cabecalho } from "../../../componentes/cabecalho";
import { Rodape } from "../../../rodape";
import { acaoRemoverLojaDireta, acaoSelecionarLojaDireta } from "../acoes";

export const dynamic = "force-dynamic";

export default async function PaginaLojasProdutos({ searchParams }: { searchParams: Promise<{ q?: string; ok?: string; nome?: string; erro?: string }> }) {
  await exigirSessao();
  const { q = "", ok, nome, erro } = await searchParams;
  let lojas: Awaited<ReturnType<typeof buscarLojasDiretas>> = [];
  let resumo = { selecionadas: 0, total: 0 };
  let falhaNoBanco = false;
  try { [lojas, resumo] = await Promise.all([buscarLojasDiretas(q), resumoLojasDiretas()]); } catch { falhaNoBanco = true; }
  return <>
    <Cabecalho atual="/inter/produtos/lojas" />
    <main className="pagina">
      <h1>Lojas de produtos do Inter</h1>
      <p className="carimbo">{resumo.total > 0 ? `${resumo.selecionadas} selecionada(s) de ${resumo.total} vendedor(es) diretos. Cada seleção adiciona uma coleta paginada, três vezes ao dia.` : "O catálogo de vendedores será preenchido pela primeira coleta da V4."}</p>
      {ok === "adicionada" && <p className="faixa">{nome} entrou na coleta de produtos.</p>}
      {ok === "removida" && <p className="faixa">{nome} deixou de receber novas coletas; o histórico expira em 30 dias.</p>}
      {(erro === "nao-achei" || falhaNoBanco) && <p className="faixa ruim">{falhaNoBanco ? "Não foi possível consultar as lojas agora." : "A loja escolhida não foi encontrada."}</p>}
      <BuscaProgressiva
        acao="/inter/produtos/lojas"
        valorInicial={q}
        placeholder="Casas Bahia, Ponto, Pontofrio…"
        rotulo="Procurar vendedor direto"
        classeFormulario="busca-produtos"
        idDoCampo="busca-lojas-diretas"
        tituloDoCampo="Procurar vendedor direto"
      />
      {!falhaNoBanco && lojas.length === 0 ? <p className="vazio">{resumo.total === 0 ? "Ainda não há vendedores sincronizados." : `Nenhuma loja combina com “${q}”.`}</p> : <div className="lista-grade">{lojas.map((loja) => <article className="cartao" key={loja.id_externo}>
        <div className="linha"><div className="cartao-titulo"><span className="nome">{loja.nome}</span><span className="ajuda-do-campo">{loja.slug}</span></div>{loja.selecionada && <span className="etiqueta">Selecionada</span>}</div>
        <p className="detalhe">{loja.ultima_execucao ? `${loja.paginas ?? 0} página(s) na última tentativa (${loja.ultimo_estado}).` : "Ainda não coletada."}</p>
        {!loja.ativa && <p className="faixa ruim">Não encontrada na última sincronização de vendedores.</p>}
        <div className="acoes-do-cartao">{loja.selecionada ? <details className="confirmacao"><summary>Remover da coleta</summary><form action={acaoRemoverLojaDireta}><input type="hidden" name="id" value={loja.id} /><input type="hidden" name="nome" value={loja.nome} /><button className="botao perigoso" type="submit">Confirmar remoção</button></form></details> : <form action={acaoSelecionarLojaDireta}><input type="hidden" name="id" value={loja.id} /><input type="hidden" name="nome" value={loja.nome} /><button className="botao" type="submit" disabled={!loja.ativa}>Selecionar</button></form>}<Link className="botao secundario" href="/inter/produtos">Ver busca</Link></div>
      </article>)}</div>}
      <Rodape fonte="inter" />
    </main>
  </>;
}
