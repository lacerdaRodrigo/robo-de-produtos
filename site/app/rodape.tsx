import Link from "next/link";

/** PRD-V2 9.3: aviso de nao afiliacao em toda pagina, mais a versao que
 *  gerou o dado — e o que torna um defeito rastreavel, como no e-mail. */
export function Rodape({ versao }: { versao?: string | null }) {
  return (
    <footer className="rodape">
      <p>
        Página pessoal, sem qualquer afiliação com a Livelo. Os dados são lidos da página
        pública de parceiros e podem estar desatualizados — confira sempre na{" "}
        <a href="https://www.livelo.com.br/juntar-pontos/todos-os-parceiros">Livelo</a> antes
        de comprar.
      </p>
      <p>
        robô-livelo {versao ? `v${versao}` : ""} · <Link href="/entrar">editar</Link>
      </p>
    </footer>
  );
}
