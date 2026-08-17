import Link from "next/link";

import {
  cashbacksInter,
  ultimaExecucaoInterValida,
  ultimaTentativaInter,
  type CashbackInter,
} from "@/lib/banco-inter";
import { dataHora } from "@/lib/formato";
import {
  descricaoInter,
  estadoInter,
  filtrarCashbacksInter,
  idadeInter,
  LINK_SHOPPING_INTER,
  ordenarCashbacksInter,
  ordenarCashbacksPorNome,
} from "@/lib/formato-inter";
import { Cabecalho } from "../componentes/cabecalho";
import { SeletorDeRobos } from "../componentes/seletor-robos";
import { Rodape } from "../rodape";
import { BuscaInter } from "./busca-inter";

export const dynamic = "force-dynamic";

function CartaoInter({
  loja,
  coletadoEm,
}: {
  loja: CashbackInter;
  coletadoEm: string;
}) {
  if (!loja.encontrada) {
    return (
      <article className="cartao cartao-inter">
        <span className="nome">{loja.nome}</span>
        <p className="detalhe">
          Não encontrada nesta consulta. Ela continua nas suas favoritas.
        </p>
      </article>
    );
  }

  return (
    <article className="cartao cartao-inter">
      <div className="cartao-inter-topo">
        <span className="logo-loja" aria-hidden="true">{loja.nome.slice(0, 1).toUpperCase()}</span>
        <div className="cartao-titulo">
          <span className="nome">{loja.nome}</span>
          {loja.etiqueta && <span className="etiqueta">{loja.etiqueta}</span>}
        </div>
        <div className="pontos-container cashback-destaque">
          <span className="pontos cashback-texto">{loja.cashback_principal_texto}</span>
          <span className="pontos-sub">Cliente Inter Shopping</span>
        </div>
      </div>

      <details className="detalhes-oferta">
        <summary>Ver condições da oferta</summary>
        <p className="detalhe descricao-inter">{descricaoInter(loja.descricao_principal)}</p>
        <p className="detalhe">Atualizado em {dataHora(coletadoEm)}</p>
        {(loja.cashback_secundario_texto || loja.descricao_secundaria) && (
          <div className="condicoes-inter">
            <strong>Para não-correntista: {loja.cashback_secundario_texto ?? "consulte as condições"}</strong>
            {loja.descricao_secundaria && <p>{loja.descricao_secundaria}</p>}
          </div>
        )}
      </details>

      <div className="acoes-do-cartao">
        <a className="botao secundario" href={LINK_SHOPPING_INTER}>
          Abrir Shopping Inter
        </a>
      </div>
    </article>
  );
}

export default async function PaginaInter({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; ordenar?: string }>;
}) {
  const { q = "", ordenar = "cashback" } = await searchParams;
  let tentativa: Awaited<ReturnType<typeof ultimaTentativaInter>> = null;
  let sucesso: Awaited<ReturnType<typeof ultimaExecucaoInterValida>> = null;
  let todas: CashbackInter[] = [];
  let falhaNoBanco = false;

  try {
    [tentativa, sucesso] = await Promise.all([
      ultimaTentativaInter(),
      ultimaExecucaoInterValida(),
    ]);
    if (sucesso) {
      todas = await cashbacksInter(sucesso.id);
    }
  } catch {
    falhaNoBanco = true;
  }

  const estado = estadoInter({
    estadoTentativa: tentativa?.estado,
    concluidaEm: sucesso?.concluida_em,
  });

  if (falhaNoBanco || !sucesso) {
    return (
      <>
        <Cabecalho atual="/inter" />
        <main className="pagina">
          <SeletorDeRobos atual="/inter" />
          <h1>Shopping Inter</h1>
          <p className="faixa ruim">
            {falhaNoBanco
              ? "Não foi possível consultar os dados do Inter agora. A Livelo continua independente."
              : estado === "atualizando"
                ? "A primeira sincronização do Inter está em andamento."
                : estado === "falha"
                  ? `A primeira sincronização falhou (${tentativa?.codigo_falha ?? "falha"}).`
                  : "O Inter ainda não foi sincronizado."}
          </p>
          <p>
            <Link href="/inter/lojas">Abrir cadastro de lojas do Inter</Link>
          </p>
          <Rodape fonte="inter" />
        </main>
      </>
    );
  }

  const concluidaEm = sucesso.concluida_em ?? sucesso.iniciada_em;
  const idade = idadeInter(concluidaEm);
  const filtradas = filtrarCashbacksInter(todas, q);
  const maiorCashback = ordenarCashbacksInter(todas).find(
    (loja) =>
      loja.encontrada &&
      loja.cashback_principal_valor !== null &&
      Number(loja.cashback_principal_valor) > 0,
  );
  const lojas =
    ordenar === "nome"
      ? ordenarCashbacksPorNome(filtradas)
      : ordenarCashbacksInter(filtradas);

  return (
    <>
      <Cabecalho atual="/inter" />
      <main className="pagina">
          <SeletorDeRobos atual="/inter" />
        <section className="cabecalho-vitrine">
          <div>
            <span className="hero-rotulo">Oportunidades selecionadas</span>
            <h1>Cashback que vale a pena</h1>
            <p>Compare suas lojas favoritas e encontre o melhor retorno sem perder tempo.</p>
          </div>
          <span className={idade.atrasado ? "status-dados atrasado" : "status-dados"}>
            <span aria-hidden="true" />
            Atualizado {idade.texto}
          </span>
        </section>

        {tentativa?.estado === "falha" && tentativa.id !== sucesso.id && (
          <p className="faixa ruim">
            A atualização mais recente falhou ({tentativa.codigo_falha ?? "falha"}).
            Mostrando o último resultado válido.
          </p>
        )}

        <section className="resumo-vitrine" aria-label="Resumo do cashback">
          <article>
            <span className="resumo-icone" aria-hidden="true">★</span>
            <div><strong>{maiorCashback?.cashback_principal_texto ?? "—"}</strong><small>melhor cashback</small></div>
          </article>
          <article>
            <span className="resumo-icone lojas" aria-hidden="true">⌂</span>
            <div><strong>{todas.length}</strong><small>lojas acompanhadas</small></div>
          </article>
          <article>
            <span className="resumo-icone catalogo" aria-hidden="true">✓</span>
            <div><strong>{sucesso.lojas_validas}</strong><small>lojas verificadas</small></div>
          </article>
        </section>

        <section className="explorar-vitrine">
          <div className="titulo-explorar">
            <div><span className="hero-rotulo">Suas favoritas</span><h2>Explore as ofertas</h2></div>
            <Link href="/inter/lojas">Gerenciar lojas</Link>
          </div>
          <div id="busca-principal" className="busca-vitrine">
        <BuscaInter
          acao="/inter"
          valorInicial={q}
          placeholder="Procurar nas suas lojas"
          rotulo="Procurar nas favoritas do Shopping Inter"
          parametrosFixos={{ ordenar }}
        />
          </div>

        <div className="controles-ordenacao">
          <span className="rotulo-ordenacao">Ordenar:</span>
          {[
            ["cashback", "Maior cashback"],
            ["nome", "Nome A-Z"],
          ].map(([valor, rotulo]) => {
            const parametros = new URLSearchParams();
            if (q) {
              parametros.set("q", q);
            }
            parametros.set("ordenar", valor);
            return (
              <Link
                key={valor}
                href={`/inter?${parametros.toString()}`}
                className="botao-ordena"
                aria-current={ordenar === valor ? "true" : undefined}
              >
                {rotulo}
              </Link>
            );
          })}
        </div>

        </section>

        {lojas.length === 0 ? (
          <p className="vazio">
            {todas.length === 0
              ? "Nenhuma loja selecionada. Escolha C&A, Riachuelo ou outra loja no cadastro."
              : `Nenhuma favorita combina com “${q}”.`}{" "}
            <Link href="/inter/lojas">Escolher lojas</Link>
          </p>
        ) : (
          <div className="lista-grade grade-cashback">
            {lojas.map((loja) => (
              <CartaoInter key={loja.id_externo} loja={loja} coletadoEm={concluidaEm} />
            ))}
          </div>
        )}

        <Rodape fonte="inter" versao={sucesso.versao} />
      </main>
    </>
  );
}
