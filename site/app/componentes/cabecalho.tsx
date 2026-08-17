import Link from "next/link";
import { Fragment } from "react";

import { esperaAteProximoDisparo } from "@/lib/banco";
import { esperaAteProximoDisparoInter } from "@/lib/banco-inter";
import { telaDeAlertasEscondida } from "@/lib/flags";
import { temTokenDeDisparo, temTokenDeDisparoInter } from "@/lib/github";
import { temSessao } from "@/lib/sessao";
import { temaAtual, type Tema } from "@/lib/tema";
import { acaoAlternarTema, acaoSair } from "../acoes";
import { acaoAtualizarInter } from "../inter/lojas/acoes";
import { acaoAtualizarAgora } from "../lojas/acoes";
import { MolduraNavegacao } from "./moldura-navegacao";

/**
 * Barra lateral de todas as telas (V4.6: redesenho de navegação, ver
 * docs/PENDENCIAS.md). Sempre escura, independente do tema claro/escuro do
 * resto da página — é identidade de marca, não conteúdo.
 *
 * Regra deste site: nenhuma tela e alcancavel so digitando a URL. O menu
 * completo aparece em toda pagina, e o que voce ve depende de estar logado:
 * sem sessao, as telas de edicao nem sao anunciadas.
 */
const PUBLICAS = [
  { href: "/", nome: "Robô Livelo", icone: IconePainel },
  { href: "/inter", nome: "Cashback Inter", icone: IconeLojas },
  { href: "/inter/produtos", nome: "Produtos Inter", icone: IconeProdutos },
  { href: "/ajuda", nome: "Ajuda", icone: IconeAjuda },
];

const PRIVADAS = [
  { href: "/avisos", nome: "Alertas Livelo", icone: IconeAlertas },
  { href: "/lojas", nome: "Lojas Livelo", icone: IconeLojas },
  { href: "/inter/lojas", nome: "Lojas Inter", icone: IconeLojas },
  { href: "/inter/produtos/lojas", nome: "Produtos: lojas", icone: IconeProdutos },
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
  const itens = logado
    ? [PUBLICAS[0], PUBLICAS[1], PUBLICAS[2], ...privadas, PUBLICAS[3]]
    : PUBLICAS;

  // "Forçar atualização" (RNF02) mora no menu, logo abaixo de Lojas — so
  // faz sentido pra quem tem sessao, entao so busca o cooldown nesse caso:
  // visitante anonimo nao paga o preco de uma consulta a mais no banco.
  const podeDisparar = logado && temTokenDeDisparo();
  const podeDispararInter = logado && temTokenDeDisparoInter();
  const falta = logado ? await esperaAteProximoDisparo().catch(() => 0) : 0;
  const faltaInter = logado ? await esperaAteProximoDisparoInter().catch(() => 0) : 0;

  return (
    <MolduraNavegacao atual={atual}>
      <aside className="barra-lateral">
      <Link href="/" className="bl-marca">
        {/* Chip claro atras do logo: o quadrado "R$" da marca usa um tom
            quase branco (pensado pra fundo claro do resto do site) e
            sumiria de contraste no fundo escuro da barra lateral. */}
        <span className="bl-marca-icone">
          <img src="/logo.png" alt="" width={22} height={22} />
        </span>
        <span className="bl-marca-nome">Radar de Benefícios</span>
      </Link>

      <nav className="bl-nav" aria-label="Seções">
        {itens.map((item) => (
          <Fragment key={item.href}>
            <Link
              href={item.href}
              className="bl-item"
              aria-current={item.href === atual ? "page" : undefined}
            >
              <item.icone />
              <span className="bl-item-texto">{item.nome}</span>
            </Link>

            {item.href === "/lojas" && logado && (
              <form action={acaoAtualizarAgora} className="bl-form">
                <button
                  type="submit"
                  className="bl-item bl-acao-primaria"
                  disabled={!podeDisparar || falta > 0}
                  title={
                    !podeDisparar
                      ? "Token de disparo não configurado no site"
                      : falta > 0
                        ? `Espere mais ${falta}s antes de tentar de novo`
                        : "O robô lê a Livelo agora e grava a pontuação atualizada"
                  }
                >
                  <IconeExecutar />
                  <span className="bl-item-texto">
                    {falta > 0 ? `Aguarde ${falta}s` : "Forçar atualização"}
                  </span>
                </button>
              </form>
            )}

            {item.href === "/inter/lojas" && logado && (
              <form action={acaoAtualizarInter} className="bl-form">
                <button
                  type="submit"
                  className="bl-item bl-acao-primaria"
                  disabled={!podeDispararInter || faltaInter > 0}
                  title={
                    !podeDispararInter
                      ? "Token de disparo não configurado no site"
                      : faltaInter > 0
                        ? `Espere mais ${faltaInter}s antes de tentar de novo`
                        : "O robô lê o Shopping Inter e grava o cashback atual"
                  }
                >
                  <IconeExecutar />
                  <span className="bl-item-texto">
                    {faltaInter > 0 ? `Aguarde ${faltaInter}s` : "Atualizar Inter"}
                  </span>
                </button>
              </form>
            )}
          </Fragment>
        ))}
      </nav>

      <div className="bl-rodape">
        {logado && (
          <Link
            href="/configuracoes"
            className="bl-item bl-acao"
            aria-current={atual === "/configuracoes" ? "page" : undefined}
            aria-label="Configurações"
            title="Configurações"
          >
            <IconeDeEngrenagem />
            <span className="bl-item-texto">Configurações</span>
          </Link>
        )}

        <form action={acaoAlternarTema} className="bl-form">
          <input type="hidden" name="voltar" value={atual} />
          <button
            type="submit"
            className="bl-item bl-acao"
            aria-label={`${ROTULO_DO_TEMA[tema]} — clique para trocar`}
            title={`${ROTULO_DO_TEMA[tema]} — clique para trocar`}
          >
            <IconeDoTema tema={tema} />
            <span className="bl-item-texto">Tema</span>
          </button>
        </form>

        {logado ? (
          <form action={acaoSair} className="bl-form">
            <button type="submit" className="bl-item bl-acao">
              <IconeSair />
              <span className="bl-item-texto">Sair</span>
            </button>
          </form>
        ) : (
          // O simbolo de entrar leva junto a tela atual, para o login
          // devolver voce exatamente de onde saiu.
          <Link href={`/entrar?voltar=${encodeURIComponent(atual)}`} className="bl-item bl-acao">
            <SetaDeEntrada />
            <span className="bl-item-texto">Entrar</span>
          </Link>
        )}
      </div>
      </aside>
    </MolduraNavegacao>
  );
}

/** RN25: icone e SVG no proprio HTML, nunca arquivo nem CDN de terceiro. */

function IconePainel() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <rect x="3" y="3" width="7" height="7" rx="1.5" stroke="currentColor" strokeWidth="2" />
      <rect x="14" y="3" width="7" height="7" rx="1.5" stroke="currentColor" strokeWidth="2" />
      <rect x="3" y="14" width="7" height="7" rx="1.5" stroke="currentColor" strokeWidth="2" />
      <rect x="14" y="14" width="7" height="7" rx="1.5" stroke="currentColor" strokeWidth="2" />
    </svg>
  );
}

function IconeLojas() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <path
        d="M4 9V4a1 1 0 0 1 1-1h14a1 1 0 0 1 1 1v5M4 9a2 2 0 0 0 2 2h.5A2.5 2.5 0 0 0 9 8.5 2.5 2.5 0 0 0 11.5 11h1A2.5 2.5 0 0 0 15 8.5 2.5 2.5 0 0 0 17.5 11H18a2 2 0 0 0 2-2M4 9v9a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

function IconeProdutos() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <path d="M4 7.5 12 3l8 4.5v9L12 21l-8-4.5v-9Z" stroke="currentColor" strokeWidth="2" strokeLinejoin="round" />
      <path d="m4 7.5 8 4.5 8-4.5M12 12v9" stroke="currentColor" strokeWidth="2" strokeLinejoin="round" />
    </svg>
  );
}

function IconeAlertas() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <path
        d="M18 8a6 6 0 1 0-12 0c0 7-3 9-3 9h18s-3-2-3-9"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path
        d="M13.73 21a2 2 0 0 1-3.46 0"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
      />
    </svg>
  );
}

function IconeAjuda() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <circle cx="12" cy="12" r="9" stroke="currentColor" strokeWidth="2" />
      <path
        d="M9.5 9.5a2.5 2.5 0 1 1 3.5 2.29c-.83.38-1 .77-1 1.71"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <circle cx="12" cy="17" r="1" fill="currentColor" />
    </svg>
  );
}

/** Disparo manual do robô (RNF02) — triângulo de "play", mesmo peso visual
 *  dos demais ícones do menu. */
function IconeExecutar() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <path d="M6 4.5v15l13-7.5-13-7.5Z" fill="currentColor" />
    </svg>
  );
}

function IconeSair() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <path
        d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

/** RN25: icone e SVG no proprio HTML, nunca arquivo de terceiro. */
function SetaDeEntrada() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden="true">
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
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden="true">
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
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden="true">
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
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden="true">
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
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden="true">
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
