import Link from "next/link";

import { buscarLojasInter, totalLojasInter } from "@/lib/banco-inter";
import { exigirSessao } from "@/lib/sessao";
import { Cabecalho } from "../../componentes/cabecalho";
import { Rodape } from "../../rodape";
import { BuscaInter } from "../busca-inter";
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
    segundos?: string;
  }>;
}) {
  await exigirSessao();
  const { q = "", ok, erro, nome, segundos } = await searchParams;

  let lojas: Awaited<ReturnType<typeof buscarLojasInter>> = [];
  let total = 0;
  let falhaNoBanco = false;
  try {
    [lojas, total] = await Promise.all([buscarLojasInter(q), totalLojasInter()]);
  } catch {
    falhaNoBanco = true;
  }

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

        <BuscaInter
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
          <div className="lista-grade">
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
        )}
        <Rodape fonte="inter" />
      </main>
    </>
  );
}
