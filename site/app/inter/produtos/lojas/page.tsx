import Link from "next/link";

import {
  buscarLojasDiretas,
  resumoLojasDiretas,
  totalLojasDiretas,
} from "@/lib/banco-produtos-inter";
import { ITENS_POR_PAGINA, paginasVisiveis } from "@/lib/paginacao";
import { exigirSessao } from "@/lib/sessao";
import { BuscaProgressiva } from "../../../componentes/busca-progressiva";
import { Cabecalho } from "../../../componentes/cabecalho";
import { ConfirmacaoEmTela } from "../../../componentes/confirmacao-em-tela";
import { Rodape } from "../../../rodape";
import {
  acaoAtualizarProdutosInter,
  acaoRemoverLojaDireta,
  acaoSelecionarLojaDireta,
} from "../acoes";

export const dynamic = "force-dynamic";

export default async function PaginaLojasProdutos({
  searchParams,
}: {
  searchParams: Promise<{
    q?: string;
    ok?: string;
    nome?: string;
    erro?: string;
    pagina?: string;
  }>;
}) {
  await exigirSessao();
  const { q = "", ok, nome, erro, pagina: paginaBruta } = await searchParams;

  let lojas: Awaited<ReturnType<typeof buscarLojasDiretas>> = [];
  let resumo = { selecionadas: 0, total: 0 };
  let totalFiltrado = 0;
  let pagina = 1;
  let totalPaginas = 1;
  let falhaNoBanco = false;

  try {
    [resumo, totalFiltrado] = await Promise.all([
      resumoLojasDiretas(),
      totalLojasDiretas(q),
    ]);
    totalPaginas = Math.max(1, Math.ceil(totalFiltrado / ITENS_POR_PAGINA));
    const paginaSolicitada = Number.parseInt(paginaBruta ?? "", 10);
    pagina =
      Number.isFinite(paginaSolicitada) && paginaSolicitada > 0
        ? Math.min(paginaSolicitada, totalPaginas)
        : 1;
    lojas = await buscarLojasDiretas(q, pagina, ITENS_POR_PAGINA);
  } catch {
    falhaNoBanco = true;
  }

  const numerosDePagina = paginasVisiveis(pagina, totalPaginas);
  const linkDaPagina = (numero: number) => {
    const parametros = new URLSearchParams();
    if (q) {
      parametros.set("q", q);
    }
    parametros.set("pagina", String(numero));
    return `/inter/produtos/lojas?${parametros.toString()}`;
  };

  return (
    <>
      <Cabecalho atual="/inter/produtos/lojas" />
      <main className="pagina">
        <h1>Lojas de produtos do Inter</h1>
        <p className="carimbo">
          {resumo.total > 0
            ? `${resumo.selecionadas} selecionada(s) de ${resumo.total} vendedor(es) diretos. Cada seleção adiciona uma coleta paginada, três vezes ao dia.`
            : "O catálogo de vendedores será preenchido pela primeira coleta da V4."}
        </p>

        {ok === "adicionada" && <p className="faixa">{nome} entrou na coleta de produtos.</p>}
        {ok === "removida" && (
          <p className="faixa">
            {nome} deixou de receber novas coletas; o histórico expira em 30 dias.
          </p>
        )}
        {(erro === "nao-achei" || falhaNoBanco) && (
          <p className="faixa ruim">
            {falhaNoBanco
              ? "Não foi possível consultar as lojas agora."
              : "A loja escolhida não foi encontrada."}
          </p>
        )}
        {ok === "disparado" && (
          <p className="faixa">
            Atualização dos produtos solicitada. A coleta será executada para todas as lojas selecionadas.
          </p>
        )}
        {erro === "sem-lojas" && (
          <p className="faixa ruim">Selecione pelo menos uma loja antes de atualizar os produtos.</p>
        )}
        {erro === "sem-token" && (
          <p className="faixa ruim">O token de disparo do GitHub não está configurado.</p>
        )}
        {erro === "disparo" && (
          <p className="faixa ruim">O GitHub recusou o pedido de atualização dos produtos.</p>
        )}

        <div className="acoes-do-cartao">
          <form action={acaoAtualizarProdutosInter}>
            <button className="botao" type="submit" disabled={resumo.selecionadas === 0}>
              Atualizar produtos agora
            </button>
          </form>
          <p className="detalhe">
            Executa uma rodada única para todas as {resumo.selecionadas} lojas selecionadas.
          </p>
        </div>

        <BuscaProgressiva
          acao="/inter/produtos/lojas"
          valorInicial={q}
          placeholder="Casas Bahia, Ponto, Pontofrio…"
          rotulo="Procurar vendedor direto"
          classeFormulario="busca-produtos"
          idDoCampo="busca-lojas-diretas"
          tituloDoCampo="Procurar vendedor direto"
        />

        {!falhaNoBanco && lojas.length === 0 ? (
          <p className="vazio">
            {resumo.total === 0
              ? "Ainda não há vendedores sincronizados."
              : `Nenhuma loja combina com “${q}”.`}
          </p>
        ) : (
          <>
            <div className="lista-grade">
              {lojas.map((loja) => (
                <article className="cartao" key={loja.id_externo}>
                  <div className="linha">
                    <div className="cartao-titulo">
                      <span className="nome">{loja.nome}</span>
                      <span className="ajuda-do-campo">{loja.slug}</span>
                    </div>
                    {loja.selecionada && <span className="etiqueta">Selecionada</span>}
                  </div>
                  <p className="detalhe">
                    {loja.ultima_execucao
                      ? `${loja.paginas ?? 0} página(s) na última tentativa (${loja.ultimo_estado}).`
                      : "Ainda não coletada."}
                  </p>
                  {!loja.ativa && (
                    <p className="faixa ruim">
                      Não encontrada na última sincronização de vendedores.
                    </p>
                  )}
                  <div className="acoes-do-cartao">
                    {loja.selecionada ? (
                      <ConfirmacaoEmTela
                        rotuloAbrir="Remover da coleta"
                        titulo={`Remover ${loja.nome}?`}
                        mensagem="A loja deixará de receber novas coletas. O histórico existente continuará disponível por 30 dias."
                      >
                        <form action={acaoRemoverLojaDireta}>
                          <input type="hidden" name="id" value={loja.id} />
                          <input type="hidden" name="nome" value={loja.nome} />
                          <input type="hidden" name="q" value={q} />
                          <input type="hidden" name="pagina" value={pagina} />
                          <button className="botao perigoso" type="submit">
                            Confirmar remoção
                          </button>
                        </form>
                      </ConfirmacaoEmTela>
                    ) : (
                      <form action={acaoSelecionarLojaDireta}>
                        <input type="hidden" name="id" value={loja.id} />
                        <input type="hidden" name="nome" value={loja.nome} />
                        <input type="hidden" name="q" value={q} />
                        <input type="hidden" name="pagina" value={pagina} />
                        <button className="botao" type="submit" disabled={!loja.ativa}>
                          Selecionar
                        </button>
                      </form>
                    )}
                    <Link className="botao secundario" href="/inter/produtos">
                      Ver busca
                    </Link>
                  </div>
                </article>
              ))}
            </div>

            <nav className="paginacao" aria-label="Paginação das lojas de produtos do Inter">
              <p className="paginacao-resumo">
                Mostrando {(pagina - 1) * ITENS_POR_PAGINA + 1}–
                {Math.min(pagina * ITENS_POR_PAGINA, totalFiltrado)} de {totalFiltrado} lojas
              </p>
              <div className="paginacao-botoes">
                {pagina > 1 ? (
                  <Link className="botao-paginacao navegacao" href={linkDaPagina(pagina - 1)}>
                    Anterior
                  </Link>
                ) : (
                  <span className="botao-paginacao navegacao desabilitado" aria-disabled="true">
                    Anterior
                  </span>
                )}
                {numerosDePagina.map((numero) => (
                  <Link
                    key={numero}
                    className="botao-paginacao numero"
                    href={linkDaPagina(numero)}
                    aria-current={numero === pagina ? "page" : undefined}
                  >
                    {numero}
                  </Link>
                ))}
                {pagina < totalPaginas ? (
                  <Link className="botao-paginacao navegacao" href={linkDaPagina(pagina + 1)}>
                    Próxima
                  </Link>
                ) : (
                  <span className="botao-paginacao navegacao desabilitado" aria-disabled="true">
                    Próxima
                  </span>
                )}
              </div>
            </nav>
          </>
        )}
        <Rodape fonte="inter" />
      </main>
    </>
  );
}
