import Link from "next/link";

import { pontuacoes, ultimaExecucao, type PontuacaoDeLoja } from "@/lib/banco";
import { telaDeAlertasEscondida } from "@/lib/flags";
import {
  barraDeProgresso,
  dia,
  dataHora,
  filtrarPorNome,
  idade,
  ordenarLojas,
  ORDENACOES,
  pontos,
  rotuloDoClube,
  terminaHoje,
  type Ordenacao,
} from "@/lib/formato";
import { temSessao } from "@/lib/sessao";
import { Cabecalho } from "./componentes/cabecalho";
import { Rodape } from "./rodape";

// Renderizada a cada visita: o nonce da CSP muda por requisicao (ver
// middleware.ts) e nonce nao sobrevive a pagina estatica.
export const dynamic = "force-dynamic";

function Validade({ fim }: { fim: string | null }) {
  if (!fim) {
    return null;
  }
  return terminaHoje(fim) ? (
    <span className="etiqueta hoje">Termina hoje!</span>
  ) : (
    <span className="etiqueta">Até {dia(fim)}</span>
  );
}

function BarraDeProgresso({ loja }: { loja: PontuacaoDeLoja }) {
  const barra = barraDeProgresso(loja.pontos_atuais, loja.pontos_base, loja.valor_de_disparo);
  if (!barra) {
    return null;
  }
  return (
    <div className="barra-progresso">
      <div className="barra-fundo">
        <div
          className={loja.alertou ? "barra-atual alerta" : "barra-atual"}
          style={{ width: `${barra.atual}%` }}
        />
        <div className="marcador-normal" style={{ left: `${barra.base}%` }} title={`Normal: ${pontos(loja.pontos_base)}`} />
        <div
          className="marcador-normal alvo"
          style={{ left: `${barra.limiar}%` }}
          title={`Avisa a partir de: ${pontos(loja.valor_de_disparo)}`}
        />
      </div>
      <div className="barra-legendas">
        <span>Normal: {pontos(loja.pontos_base)}</span>
        <span>Aviso: {pontos(loja.valor_de_disparo)}</span>
      </div>
    </div>
  );
}

function Loja({
  loja,
  podeAjustarAlerta,
}: {
  loja: PontuacaoDeLoja;
  podeAjustarAlerta: boolean;
}) {
  const rotuloClube = rotuloDoClube(loja.campanha);
  const naoEncontrada = loja.pontos_atuais === null;

  return (
    <article className={loja.alertou ? "cartao alertou" : "cartao"}>
      <div className="linha">
        <div className="cartao-titulo">
          {loja.link ? (
            <a className="nome" href={loja.link}>
              {loja.nome}
            </a>
          ) : (
            <span className="nome">{loja.nome}</span>
          )}
          {loja.categoria && <span className="etiqueta">{loja.categoria}</span>}
        </div>
        <div className="pontos-container">
          <span className="pontos numero">
            {naoEncontrada ? "—" : `${loja.prefixo_ate ? "Até " : ""}${pontos(loja.pontos_atuais)}`}
          </span>
          {!naoEncontrada && (
            <span className="pontos-sub">
              pontos por {loja.moeda} 1
            </span>
          )}
        </div>
      </div>

      {!naoEncontrada ? (
        // RN30: atual, normal da loja e o valor que dispara o aviso, lado a
        // lado — agora também como barra visual, não só como texto.
        <BarraDeProgresso loja={loja} />
      ) : (
        <p className="detalhe">
          Não apareceu na página da Livelo nesta execução. Costuma ser mudança de grafia do
          nome. <Link href="/ajuda#nao-encontrada">Entenda</Link>
        </p>
      )}

      {!naoEncontrada && loja.descricao_campanha && (
        // Letra miúda da própria Livelo (legalTerms) — dá para decidir se a
        // promoção serve sem abrir o app dela.
        <p className="detalhe descricao-campanha">{loja.descricao_campanha}</p>
      )}

      <div className="detalhe-rodape">
        {!naoEncontrada && loja.pontos_clube !== null && (
          <p className="detalhe numero">
            Clube: {pontos(loja.pontos_clube)}
            {rotuloClube ? ` (${rotuloClube})` : ""}
          </p>
        )}
        {(loja.alertou || loja.fim_promocao) && (
          <div className="etiqueta-container">
            {loja.alertou && <span className="etiqueta alerta">Alerta ativo</span>}
            <Validade fim={loja.fim_promocao} />
          </div>
        )}
      </div>

      {(loja.link || podeAjustarAlerta) && (
        <div className="acoes-do-cartao">
          {loja.link && (
            <a className="botao secundario" href={loja.link}>
              Ir para a Livelo
            </a>
          )}
          {podeAjustarAlerta && (
            <Link
              className="botao secundario"
              href={`/avisos?loja=${encodeURIComponent(loja.nome)}`}
            >
              Ajustar alerta
            </Link>
          )}
        </div>
      )}
    </article>
  );
}

/** Painel: hero escuro com o resumo da execução e as lojas de maior
 *  pontuação agora — "Top 3 Oportunidade" no mockup V4.6. Ordenar so
 *  para escolher as 3 primeiras, nunca para exibir texto (PRD 5.4) —
 *  mesma ressalva de `barraDeProgresso` em lib/formato.ts. */
function HeroDoPainel({
  alertadas,
  todas,
  parceirosLidos,
}: {
  alertadas: PontuacaoDeLoja[];
  todas: PontuacaoDeLoja[];
  parceirosLidos: number;
}) {
  const top3 = todas
    .filter((l) => l.pontos_atuais !== null)
    .sort((a, b) => Number(b.pontos_atuais) - Number(a.pontos_atuais))
    .slice(0, 3);

  return (
    <div className="hero-painel">
      <div className="hero-cabecalho">
        <div>
          <span className="hero-rotulo">Visão do extrator</span>
          <h1>Visão Geral</h1>
        </div>
        {alertadas.length > 0 && (
          <span className="hero-badge-alerta">
            <span className="hero-badge-ponto" aria-hidden="true" />
            {alertadas.length} {alertadas.length === 1 ? "alerta ativo" : "alertas ativos"}
          </span>
        )}
      </div>

      <div className="hero-metricas">
        <span>{todas.length} lojas monitoradas</span>
        <span>{parceirosLidos} parceiros lidos</span>
      </div>

      {top3.length > 0 && (
        <div className="hero-top3">
          {top3.map((loja, indice) => (
            <div key={loja.nome} className="hero-top3-item">
              <span className="hero-rotulo">Top {indice + 1} oportunidade</span>
              <div className="hero-top3-linha">
                <span className="hero-top3-nome">{loja.nome}</span>
                <span className="hero-top3-pontos numero">
                  {loja.prefixo_ate ? "Até " : ""}
                  {pontos(loja.pontos_atuais)}
                </span>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

const ROTULO_DA_ORDENACAO: Record<Ordenacao, string> = {
  pontos: "Maior pontuação",
  alerta: "Em alerta",
  nome: "Nome A-Z",
};

export default async function Pagina({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; ordenar?: string }>;
}) {
  const { q = "", ordenar: ordenarBruto } = await searchParams;
  const ordenar: Ordenacao = (ORDENACOES as readonly string[]).includes(ordenarBruto ?? "")
    ? (ordenarBruto as Ordenacao)
    : "pontos";
  const [logado, alertasEscondidos] = await Promise.all([temSessao(), telaDeAlertasEscondida()]);
  const podeAjustarAlerta = logado && !alertasEscondidos;

  let execucao: Awaited<ReturnType<typeof ultimaExecucao>> = null;
  let todas: PontuacaoDeLoja[] = [];
  let falhaNoBanco = false;
  try {
    execucao = await ultimaExecucao();
    if (execucao) {
      todas = await pontuacoes(execucao.id);
    }
  } catch {
    // Banco fora do ar (ou coluna nova que ainda nao existe, ex.: migracao
    // pendente) vira pagina que diz isso, nao erro 500 mudo. Mesma linha do
    // robo: falha nunca e silenciosa (O3).
    falhaNoBanco = true;
  }

  if (falhaNoBanco || !execucao) {
    return (
      <>
        <Cabecalho atual="/" />
        <main className="pagina">
          <h1>Pontuação Livelo</h1>
          <p className="faixa ruim">
            {falhaNoBanco
              ? "Não deu para ler o banco agora. A página volta sozinha quando ele responder — nada foi perdido, o robô continua registrando cada execução."
              : "Nenhuma execução registrada ainda. A página fica assim até o robô rodar pela primeira vez com o banco configurado."}
          </p>
          <Rodape />
        </main>
      </>
    );
  }

  const lojas = filtrarPorNome(todas, q);
  const alertadas = lojas.filter((l) => l.alertou);
  const carimbo = idade(execucao.momento);

  // Grade unica, ordenavel — substitui o agrupamento por categoria do
  // redesenho anterior (redesenho V4.6, mockup enviado em 2026-08-13).
  const lojasOrdenadas = ordenarLojas(lojas, ordenar);
  const semResultadoDeBusca = q !== "" && lojas.length === 0;
  const semLojasEmAlerta = ordenar === "alerta" && lojasOrdenadas.length === 0 && lojas.length > 0;

  return (
    <>
      <Cabecalho atual="/" />
      <main className="pagina">
        {/* RN26: o carimbo e obrigatorio e sempre visivel. Sem ele, pagina
            velha e pagina mentirosa. */}
        <p className={carimbo.velho ? "carimbo velho" : "carimbo"}>
          Sincronizado {carimbo.texto} ({dataHora(execucao.momento)})
          {carimbo.velho && " — o robô pode estar parado"}
        </p>

        <HeroDoPainel
          alertadas={alertadas}
          todas={todas}
          parceirosLidos={execucao.parceiros_lidos}
        />

        <form className="busca" action="/" method="get" role="search">
          <input
            type="search"
            name="q"
            defaultValue={q}
            placeholder="Procurar loja ou categoria"
            aria-label="Procurar loja ou categoria"
          />
          <button type="submit" className="secundario">
            Procurar
          </button>
        </form>

        {semResultadoDeBusca && (
          <p className="detalhe">
            Nenhuma loja sua combina com &quot;{q}&quot;. <Link href="/">Ver todas de novo</Link>
          </p>
        )}

        {q && !semResultadoDeBusca && (
          <p className="detalhe">
            {lojas.length} de {todas.length} lojas combinam com &quot;{q}&quot;.{" "}
            <Link href="/">Ver todas de novo</Link>
          </p>
        )}

        {!semResultadoDeBusca && (
          <>
            <div className="controles-ordenacao">
              <span className="rotulo-ordenacao">Ordenar:</span>
              {ORDENACOES.map((opcao) => {
                const parametros = new URLSearchParams();
                if (q) {
                  parametros.set("q", q);
                }
                parametros.set("ordenar", opcao);
                return (
                  <Link
                    key={opcao}
                    href={`/?${parametros.toString()}`}
                    className="botao-ordena"
                    aria-current={ordenar === opcao ? "true" : undefined}
                  >
                    {ROTULO_DA_ORDENACAO[opcao]}
                  </Link>
                );
              })}
            </div>

            {semLojasEmAlerta ? (
              <p className="vazio">Nenhuma loja sua cruzou o próprio limite nesta execução.</p>
            ) : (
              // RN24: todas as favoritas, em promocao ou nao. E o motivo do
              // site existir — responder "quanto a Renner da hoje?" sem
              // abrir a Livelo.
              <div className="lista-grade">
                {lojasOrdenadas.map((loja) => (
                  <Loja key={loja.nome} loja={loja} podeAjustarAlerta={podeAjustarAlerta} />
                ))}
              </div>
            )}
          </>
        )}

        <Rodape versao={execucao.versao} />
      </main>
    </>
  );
}
