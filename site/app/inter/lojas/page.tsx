import Link from "next/link";

import { buscarLojasInter, totalLojasInter } from "@/lib/banco-inter";
import { ITENS_POR_PAGINA, paginasVisiveis } from "@/lib/paginacao";
import { exigirSessao } from "@/lib/sessao";
import { BuscaProgressiva } from "../../componentes/busca-progressiva";
import { Cabecalho } from "../../componentes/cabecalho";
import { Rodape } from "../../rodape";
import { acaoAcompanharInter, acaoRemoverInter } from "./acoes";

export const dynamic = "force-dynamic";

export default async function PaginaLojasInter({
  searchParams,
}: {
  searchParams: Promise<{
    q?: string;
    ok?: string;
    erro?: string;
    nome?: string;
    atualizacao?: string;
    segundos?: string;
    pagina?: string;
  }>;
}) {
  await exigirSessao();
  const { q = "", ok, erro, nome, atualizacao, segundos, pagina: paginaBruta } = await searchParams;

  let lojas: Awaited<ReturnType<typeof buscarLojasInter>> = [];
  let total = 0;
  let totalFiltrado = 0;
  let pagina = 1;
  let totalPaginas = 1;
  let falhaNoBanco = false;
  try {
    [total, totalFiltrado] = await Promise.all([totalLojasInter(), totalLojasInter(q)]);
    totalPaginas = Math.max(1, Math.ceil(totalFiltrado / ITENS_POR_PAGINA));
    const paginaSolicitada = Number.parseInt(paginaBruta ?? "", 10);
    pagina =
      Number.isFinite(paginaSolicitada) && paginaSolicitada > 0
        ? Math.min(paginaSolicitada, totalPaginas)
        : 1;
    lojas = await buscarLojasInter(q, pagina, ITENS_POR_PAGINA);
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
    return `/inter/lojas?${parametros.toString()}`;
  };

  return (
    <>
      <Cabecalho atual="/inter/lojas" />
      <main className="pagina">
        <h1>Lojas do Shopping Inter</h1>
        <p className="carimbo">
          {total > 0
            ? `${total} lojas sincronizadas. Procure pelo nome e escolha quais acompanhar.`
            : "O catálogo será preenchido na primeira execução do robô do Inter."}
        </p>

        {ok === "adicionada" && <p className="faixa">{nome} entrou nas suas favoritas.</p>}
        {ok === "adicionada" && atualizacao === "solicitada" && (
          <p className="faixa">A consulta do Inter foi solicitada. Confira em breve na tela de cashback.</p>
        )}
        {ok === "adicionada" && atualizacao === "pendente" && (
          <p className="faixa">A loja foi salva. A próxima atualização automática respeitará o intervalo mínimo.</p>
        )}
        {ok === "adicionada" && atualizacao === "sem-token" && (
          <p className="faixa ruim">A loja foi salva, mas falta configurar o token para atualizar o Inter automaticamente.</p>
        )}
        {ok === "adicionada" && atualizacao === "falhou" && (
          <p className="faixa ruim">A loja foi salva, mas o pedido de atualização do Inter falhou.</p>
        )}
        {ok === "removida" && <p className="faixa">{nome} saiu das suas favoritas.</p>}
        {ok === "disparado" && (
          <p className="faixa">
            Pedido enviado. Aguarde a execução e confira o resultado no{" "}
            <Link href="/inter">Shopping Inter</Link>.
          </p>
        )}
        {erro === "espere" && (
          <p className="faixa ruim">Espere mais {segundos ?? "alguns"} segundos.</p>
        )}
        {erro === "sem-token" && (
          <p className="faixa ruim">O token de disparo do GitHub não está configurado.</p>
        )}
        {erro === "disparo" && (
          <p className="faixa ruim">O GitHub recusou o pedido de atualização do Inter.</p>
        )}
        {(erro === "nao-achei" || falhaNoBanco) && (
          <p className="faixa ruim">
            {falhaNoBanco
              ? "Não foi possível consultar o catálogo do Inter agora."
              : "A loja escolhida não foi encontrada."}
          </p>
        )}

        <BuscaProgressiva
          acao="/inter/lojas"
          valorInicial={q}
          placeholder="C&A, Riachuelo, Magazine Luiza…"
          rotulo="Procurar loja do Shopping Inter"
        />

        {!falhaNoBanco && lojas.length === 0 ? (
          <p className="vazio">
            {total === 0
              ? "Sincronize o Inter para carregar o catálogo."
              : `Nenhuma loja combina com “${q}”.`}
          </p>
        ) : (
          <>
            <div className="lista-grade" id="lista-lojas-inter">
              {lojas.map((loja) => (
                <article className="cartao" key={loja.id_externo}>
                  <div className="linha">
                    <div className="cartao-titulo">
                      <span className="nome">{loja.nome}</span>
                      <span className="ajuda-do-campo">{loja.slug}</span>
                    </div>
                    <div className="pontos-container">
                      <span className="pontos cashback-texto">
                        {loja.cashback_principal_texto}
                      </span>
                      <span className="pontos-sub">Cliente Inter Shopping</span>
                    </div>
                  </div>
                  {!loja.ativa && (
                    <p className="faixa ruim">Não encontrada na última consulta.</p>
                  )}
                  <div className="acoes-do-cartao">
                    <form action={loja.favorita ? acaoRemoverInter : acaoAcompanharInter}>
                      <input type="hidden" name="id" value={loja.id} />
                      <input type="hidden" name="nome" value={loja.nome} />
                      <input type="hidden" name="q" value={q} />
                      <input type="hidden" name="pagina" value={String(pagina)} />
                      <button
                        type="submit"
                        className={loja.favorita ? "secundario" : undefined}
                        disabled={!loja.ativa && !loja.favorita}
                      >
                        {loja.favorita ? "Remover das favoritas" : "Acompanhar"}
                      </button>
                    </form>
                  </div>
                </article>
              ))}
            </div>

            <nav className="paginacao" aria-label="Paginação das lojas do Shopping Inter">
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
