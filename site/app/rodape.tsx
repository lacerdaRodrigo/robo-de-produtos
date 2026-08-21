import Image from "next/image";
import Link from "next/link";

import { telaDeAlertasEscondida } from "@/lib/flags";
import { temSessao } from "@/lib/sessao";
import { VERSAO_ATUAL } from "@/lib/versao";

/**
 * PRD-V2 9.3: aviso de nao afiliacao em toda pagina, mais a versao que gerou
 * o dado — e o que torna um defeito rastreavel, como no e-mail.
 *
 * Repete os destinos do menu de proposito: quem chegou ao fim de uma lista de
 * 132 lojas nao deveria ter que rolar de volta ao topo para ir a outro lugar.
 */
export async function Rodape({
  versao,
  fonte = "livelo",
}: {
  versao?: string | null;
  fonte?: "livelo" | "inter";
}) {
  const [alertasEscondidos, logado] = await Promise.all([
    telaDeAlertasEscondida(),
    temSessao(),
  ]);

  return (
    <footer className="rodape">
      <nav className="destinos" aria-label="Ir para">
        <Link href="/">Livelo</Link>
        <Link href="/inter">Shopping Inter</Link>
        {logado && !alertasEscondidos && <Link href="/avisos">Alertas Livelo</Link>}
        {logado && <Link href="/lojas">Lojas Livelo</Link>}
        {logado && <Link href="/inter/lojas">Lojas Inter</Link>}
        <Link href="/versoes">Versões</Link>
        <Link href="/ajuda">Ajuda</Link>
      </nav>
      {fonte === "inter" ? (
        <p>
          Página pessoal, sem afiliação com o Banco Inter ou com as lojas. Cashback e
          condições podem mudar — confirme sempre no{" "}
          <a href="https://shopping.inter.co/site-parceiro/lojas">Shopping Inter</a> antes
          de comprar.
        </p>
      ) : (
        <p>
          Página pessoal, sem qualquer afiliação com a Livelo. Os dados são lidos da página
          pública de parceiros e podem estar desatualizados — confira sempre na{" "}
          <a href="https://www.livelo.com.br/juntar-pontos/todos-os-parceiros">Livelo</a>{" "}
          antes de comprar.
        </p>
      )}
      <p className="marca-rodape">
        <Image src="/logo.png" alt="" width={16} height={16} />
        Radar de Benefícios v{versao ?? VERSAO_ATUAL}
      </p>
    </footer>
  );
}
