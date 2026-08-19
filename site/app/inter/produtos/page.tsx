import Link from "next/link";

import {
  buscarProdutosDiretos,
  resumoLojasDiretas,
  totalProdutosDiretos,
  type ProdutoDireto,
} from "@/lib/banco-produtos-inter";
import { moeda, percentual } from "@/lib/formato-produtos-inter";
import { dataHora } from "@/lib/formato";
import { BuscaProgressiva } from "../../componentes/busca-progressiva";
import { Cabecalho } from "../../componentes/cabecalho";
import { Rodape } from "../../rodape";

export const dynamic = "force-dynamic";

function CartaoProduto({ produto }: { produto: ProdutoDireto }) {
  return (
    <article className="cartao produto-cartao">
      <div className="cartao-titulo">
        <span className="nome">{produto.nome}</span>
        {produto.marca && <span className="ajuda-do-campo">{produto.marca}</span>}
      </div>
      {produto.categoria && <p className="detalhe">{produto.categoria}</p>}
      <div className="produto-precos">
        {produto.preco_cheio_valor && produto.preco_cheio_valor !== produto.preco_atual_valor && (
          <span className="produto-antigo">{moeda(produto.preco_cheio_valor)}</span>
        )}
        <strong className="produto-atual">{moeda(produto.preco_atual_valor) ?? "Preço não informado"}</strong>
      </div>
      {(produto.desconto_texto || produto.desconto_percentual_texto) && (
        <p className="detalhe">
          Desconto: {[produto.desconto_texto, percentual(produto.desconto_percentual_texto)].filter(Boolean).join(" · ")}
        </p>
      )}
      {(produto.cashback_texto || produto.cashback_percentual_texto) && (
        <p className="detalhe">Cashback: {[produto.cashback_texto, percentual(produto.cashback_percentual_texto)].filter(Boolean).join(" · ")}</p>
      )}
      {produto.preco_liquido_texto && <p className="detalhe"><strong>Após cashback:</strong> <strong className="produto-atual preco-liquido-destaque">{produto.preco_liquido_texto}</strong></p>}
      {produto.parcelamento && <p className="detalhe">{produto.parcelamento}</p>}
      {produto.estoque !== null && <p className="detalhe">Estoque: {produto.estoque}</p>}
      {produto.etiquetas?.length > 0 && <p className="etiquetas-produto">{produto.etiquetas.map((etiqueta) => <span className="etiqueta" key={etiqueta}>{etiqueta}</span>)}</p>}
      <div className="acoes-do-cartao">
        <a className="botao secundario" href={`https://shopping.inter.co${produto.caminho}`}>Abrir no Shopping Inter</a>
        <Link className="botao secundario" href={`/inter/produtos/historico/${encodeURIComponent(produto.loja_slug)}/${encodeURIComponent(produto.id_externo)}`}>Histórico</Link>
      </div>
    </article>
  );
}

export default async function PaginaProdutosInter({ searchParams }: { searchParams: Promise<{ q?: string }> }) {
  const { q = "" } = await searchParams;
  let produtos: ProdutoDireto[] = [];
  let resumo = { selecionadas: 0, total: 0 };
  let totalProdutos = 0;
  let falhaNoBanco = false;
  try {
    [produtos, resumo, totalProdutos] = await Promise.all([
      buscarProdutosDiretos(q),
      resumoLojasDiretas(),
      totalProdutosDiretos(),
    ]);
  } catch { falhaNoBanco = true; }
  const grupos = produtos.reduce<Record<string, ProdutoDireto[]>>((resultado, produto) => {
    (resultado[produto.loja_nome] ??= []).push(produto);
    return resultado;
  }, {});
  return <>
    <Cabecalho atual="/inter/produtos" />
    <main className="pagina">
      <h1>Produtos do Shopping Inter</h1>
      <p className="carimbo">
        {totalProdutos.toLocaleString("pt-BR")} {totalProdutos === 1 ? "produto disponível" : "produtos disponíveis"} em{" "}
        {resumo.selecionadas} {resumo.selecionadas === 1 ? "loja direta selecionada" : "lojas diretas selecionadas"}.
        Nenhuma busca consulta o Inter.
      </p>
      {falhaNoBanco ? <p className="faixa ruim">Não foi possível consultar o catálogo agora.</p> : <>
        <div id="busca-principal">
          <BuscaProgressiva
            acao="/inter/produtos"
            valorInicial={q}
            placeholder="celular Motorola Edge 60 Pro"
            rotulo="Procurar produto, marca ou categoria"
            classeFormulario="busca-produtos"
            idDoCampo="busca-produtos"
            tituloDoCampo="Produto, marca ou categoria"
            textoDoBotao="Buscar"
          />
        </div>
        {!q ? <p className="vazio">Digite o produto que procura. <Link href="/inter/produtos/lojas">Escolher lojas</Link></p> : produtos.length === 0 ? <p className="vazio">Nenhum produto atual combina com “{q}”.</p> : Object.entries(grupos).map(([loja, itens]) => <section key={loja} className="grupo-produtos"><h2>{loja} <span>{itens.length} resultado(s)</span></h2><p className="detalhe">Atualizado em {dataHora(itens[0].atualizada_em)}</p><div className="lista-grade">{itens.map((produto) => <CartaoProduto key={`${produto.loja_slug}-${produto.id_externo}`} produto={produto} />)}</div></section>)}
      </>}
      <Rodape fonte="inter" />
    </main>
  </>;
}
