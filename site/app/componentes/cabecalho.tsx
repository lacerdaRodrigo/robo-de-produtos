import Link from "next/link";

import { temSessao } from "@/lib/sessao";
import { acaoSair } from "../acoes";

/**
 * Cabecalho de todas as telas.
 *
 * Regra deste site: nenhuma tela e alcancavel so digitando a URL. O menu
 * completo aparece em toda pagina, e o que voce ve depende de estar logado:
 * sem sessao, as telas de edicao nem sao anunciadas.
 */
const PUBLICAS = [
  { href: "/", nome: "Pontuação" },
  { href: "/ajuda", nome: "Ajuda" },
];

const PRIVADAS = [
  { href: "/avisos", nome: "Quando me avisar" },
  { href: "/lojas", nome: "Cadastrar lojas" },
];

export async function Cabecalho({ atual }: { atual: string }) {
  const logado = await temSessao();
  const itens = logado
    ? [PUBLICAS[0], ...PRIVADAS, PUBLICAS[1]]
    : PUBLICAS;

  return (
    <header className="topo">
      <div className="topo-interno">
        <div className="topo-linha">
          <Link href="/" className="marca">
            Pontuação Livelo
          </Link>
          {logado ? (
            <form action={acaoSair}>
              <button type="submit" className="discreto">
                Sair
              </button>
            </form>
          ) : (
            // O simbolo de entrar leva junto a tela atual, para o login
            // devolver voce exatamente de onde saiu.
            <Link
              href={`/entrar?voltar=${encodeURIComponent(atual)}`}
              className="botao discreto"
              aria-label="Entrar para editar"
            >
              <SetaDeEntrada /> Entrar
            </Link>
          )}
        </div>
        <nav className="menu" aria-label="Seções">
          {itens.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              aria-current={item.href === atual ? "page" : undefined}
            >
              {item.nome}
            </Link>
          ))}
        </nav>
      </div>
    </header>
  );
}

/** RN25: icone e SVG no proprio HTML, nunca arquivo de terceiro. */
function SetaDeEntrada() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <path
        d="M10 17l5-5-5-5M15 12H3M13 3h6a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-6"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}
