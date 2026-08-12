import Link from "next/link";

/**
 * PRD-V2 9.3: aviso de nao afiliacao em toda pagina, mais a versao que gerou
 * o dado — e o que torna um defeito rastreavel, como no e-mail.
 *
 * Repete os destinos do menu de proposito: quem chegou ao fim de uma lista de
 * 132 lojas nao deveria ter que rolar de volta ao topo para ir a outro lugar.
 */
export function Rodape({ versao }: { versao?: string | null }) {
  return (
    <footer className="rodape">
      <nav className="destinos" aria-label="Ir para">
        <Link href="/">Pontuação</Link>
        <Link href="/avisos">Quando me avisar</Link>
        <Link href="/lojas">Cadastrar lojas</Link>
        <Link href="/ajuda">Ajuda</Link>
      </nav>
      <p>
        Página pessoal, sem qualquer afiliação com a Livelo. Os dados são lidos da página
        pública de parceiros e podem estar desatualizados — confira sempre na{" "}
        <a href="https://www.livelo.com.br/juntar-pontos/todos-os-parceiros">Livelo</a> antes
        de comprar.
      </p>
      <p>robô-livelo {versao ? `v${versao}` : ""}</p>
    </footer>
  );
}
