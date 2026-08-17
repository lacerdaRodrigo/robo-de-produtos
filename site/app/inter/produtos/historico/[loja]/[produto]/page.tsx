import Link from "next/link";
import { notFound } from "next/navigation";

import { historicoProdutoDireto } from "@/lib/banco-produtos-inter";
import { dataHora } from "@/lib/formato";
import { moeda } from "@/lib/formato-produtos-inter";
import { Cabecalho } from "../../../../../componentes/cabecalho";
import { Rodape } from "../../../../../rodape";

export const dynamic = "force-dynamic";

export default async function PaginaHistoricoProduto({ params }: { params: Promise<{ loja: string; produto: string }> }) {
  const { loja, produto } = await params;
  let historico;
  try { historico = await historicoProdutoDireto(loja, produto); } catch { historico = null; }
  if (!historico) notFound();
  const { produto: item, minimo, maximo, medicoes } = historico;
  return <>
    <Cabecalho atual="/inter/produtos" />
    <main className="pagina">
      <p><Link href="/inter/produtos">← Produtos do Shopping Inter</Link></p>
      <h1>{item.nome}</h1>
      <p className="carimbo">{item.loja_nome} · ID {item.id_externo}</p>
      {!item.ativo && <p className="faixa ruim">Este produto não apareceu na coleta mais recente; o histórico continua disponível.</p>}
      <section className="resumo-historico"><div><span>Preço atual</span><strong>{moeda(item.preco_atual_valor) ?? "não informado"}</strong></div><div><span>Menor em 30 dias</span><strong>{moeda(minimo) ?? "sem medição"}</strong></div><div><span>Maior em 30 dias</span><strong>{moeda(maximo) ?? "sem medição"}</strong></div></section>
      <h2>Histórico de 30 dias</h2>
      {medicoes.length === 0 ? <p className="vazio">Ainda não há medições deste produto.</p> : <div className="tabela-rolavel"><table><thead><tr><th>Quando</th><th>Preço</th><th>Cashback</th><th>Após cashback</th></tr></thead><tbody>{medicoes.map((medicao) => <tr key={`${medicao.momento}-${medicao.preco_atual_valor}`}><td>{dataHora(medicao.momento)}</td><td>{moeda(medicao.preco_atual_valor) ?? "—"}</td><td>{moeda(medicao.cashback_valor) ?? "—"}</td><td>{moeda(medicao.preco_liquido_valor) ?? "—"}</td></tr>)}</tbody></table></div>}
      <Rodape fonte="inter" />
    </main>
  </>;
}
