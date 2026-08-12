import Link from "next/link";

import { telaDeAlertasEscondida } from "@/lib/flags";
import { temSessao } from "@/lib/sessao";
import { temaAtual, type Tema } from "@/lib/tema";
import { acaoAlternarTema, acaoSair } from "../acoes";

/**
 * Cabecalho de todas as telas.
 *
 * Regra deste site: nenhuma tela e alcancavel so digitando a URL. O menu
 * completo aparece em toda pagina, e o que voce ve depende de estar logado:
 * sem sessao, as telas de edicao nem sao anunciadas.
 */
const PUBLICAS = [
  { href: "/", nome: "Painel" },
  { href: "/ajuda", nome: "Ajuda" },
];

const PRIVADAS = [
  { href: "/avisos", nome: "Alertas" },
  { href: "/lojas", nome: "Lojas" },
];

const ROTULO_DO_TEMA: Record<Tema, string> = {
  auto: "Tema: automático (segue o sistema)",
  claro: "Tema: claro",
  escuro: "Tema: escuro",
};

export async function Cabecalho({ atual }: { atual: string }) {
  const [logado, tema, alertasEscondidos] = await Promise.all([
    temSessao(),
    temaAtual(),
    telaDeAlertasEscondida(),
  ]);
  const privadas = alertasEscondidos
    ? PRIVADAS.filter((item) => item.href !== "/avisos")
    : PRIVADAS;
  const itens = logado ? [PUBLICAS[0], ...privadas, PUBLICAS[1]] : PUBLICAS;

  return (
    <header className="topo">
      <div className="topo-interno">
        <div className="topo-linha">
          <Link href="/" className="marca">
            Pontuação Livelo
          </Link>
          <div className="acoes-do-topo">
            <form action={acaoAlternarTema}>
              <input type="hidden" name="voltar" value={atual} />
              <button
                type="submit"
                className="discreto botao-tema"
                aria-label={`${ROTULO_DO_TEMA[tema]} — clique para trocar`}
                title={`${ROTULO_DO_TEMA[tema]} — clique para trocar`}
              >
                <IconeDoTema tema={tema} />
              </button>
            </form>
            {logado && (
              <Link
                href="/configuracoes"
                className="botao discreto botao-tema"
                aria-label="Configurações"
                title="Configurações"
              >
                <IconeDeEngrenagem />
              </Link>
            )}
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

/** Sol (claro), lua (escuro) ou meio-a-meio (automático) — o botão mostra
 *  o tema em vigor agora, e o título diz para onde o clique leva. */
function IconeDoTema({ tema }: { tema: Tema }) {
  if (tema === "claro") {
    return (
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" aria-hidden="true">
        <circle cx="12" cy="12" r="4" stroke="currentColor" strokeWidth="2" />
        <path
          d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M4.93 19.07l1.41-1.41M17.66 6.34l1.41-1.41"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
        />
      </svg>
    );
  }
  if (tema === "escuro") {
    return (
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" aria-hidden="true">
        <path
          d="M20 14.5A8.5 8.5 0 0 1 9.5 4a8.5 8.5 0 1 0 10.5 10.5Z"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
      </svg>
    );
  }
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <circle cx="12" cy="12" r="9" stroke="currentColor" strokeWidth="2" />
      <path d="M12 3a9 9 0 0 1 0 18Z" fill="currentColor" />
    </svg>
  );
}

/** Engrenagem: leva para /configuracoes, onde ficam as flags de
 *  funcionalidade (V2.3.4) — coisas que ligam/desligam pedaço da
 *  interface, distintas das regras de alerta que moram em /avisos. */
function IconeDeEngrenagem() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <circle cx="12" cy="12" r="3" stroke="currentColor" strokeWidth="2" />
      <path
        d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1Z"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}
