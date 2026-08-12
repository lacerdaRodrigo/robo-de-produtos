import Link from "next/link";

import { pontuacoes, ultimaExecucao, type PontuacaoDeLoja } from "@/lib/banco";
import { telaDeAlertasEscondida } from "@/lib/flags";
import {
  ancora,
  barraDeProgresso,
  dia,
  dataHora,
  filtrarPorNome,
  idade,
  pontos,
  rotuloDoClube,
  terminaHoje,
} from "@/lib/formato";
import { temSessao } from "@/lib/sessao";
import { Cabecalho } from "./componentes/cabecalho";
import { Dica } from "./componentes/dica";
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
        {loja.link ? (
          <a className="nome" href={loja.link}>
            {loja.nome}
          </a>
        ) : (
          <span className="nome">{loja.nome}</span>
        )}
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

      {podeAjustarAlerta && (
        <div className="acoes-do-cartao">
          <Link
            className="botao secundario"
            href={`/avisos?loja=${encodeURIComponent(loja.nome)}`}
          >
            Ajustar alerta
          </Link>
        </div>
      )}
    </article>
  );
}

export default async function Pagina({
  searchParams,
}: {
  searchParams: Promise<{ q?: string }>;
}) {
  const { q = "" } = await searchParams;
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

  const porCategoria = new Map<string, PontuacaoDeLoja[]>();
  for (const loja of lojas) {
    const categoria = loja.categoria ?? "Sem categoria";
    porCategoria.set(categoria, [...(porCategoria.get(categoria) ?? []), loja]);
  }

  return (
    <>
      <Cabecalho atual="/" />
      <main className="pagina">
        <h1>Visão Geral</h1>
        {/* RN26: o carimbo e obrigatorio e sempre visivel. Sem ele, pagina
            velha e pagina mentirosa. */}
        <p className={carimbo.velho ? "carimbo velho" : "carimbo"}>
          Sincronizado {carimbo.texto} ({dataHora(execucao.momento)})
          {carimbo.velho && " — o robô pode estar parado"}
        </p>

        <section className="resumo">
          <div className="item turbinadas">
            <span className="rotulo">
              Turbinadas hoje{" "}
              <Dica titulo="loja turbinada" secao="como-decide">
                Loja cuja pontuação de hoje passou do que você definiu em{" "}
                <strong>Quando me avisar</strong>: precisa estar algumas vezes acima do
                normal daquela loja e valer um mínimo de pontos.
              </Dica>
            </span>
            <span className="valor destaque numero">{alertadas.length}</span>
          </div>
          <div className="item">
            <span className="rotulo">Lojas monitoradas</span>
            <span className="valor numero">{todas.length}</span>
          </div>
          <div className="item">
            <span className="rotulo">
              Parceiros lidos{" "}
              <Dica titulo="parceiros lidos" secao="como-decide">
                Quantos parceiros a Livelo tinha na página quando o robô passou. Suas lojas
                são um recorte dessa lista.
              </Dica>
            </span>
            <span className="valor numero">{execucao.parceiros_lidos}</span>
          </div>
        </section>

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

        {q && (
          <p className="detalhe">
            {lojas.length === 0
              ? `Nenhuma loja sua combina com "${q}".`
              : `${lojas.length} de ${todas.length} lojas combinam com "${q}".`}{" "}
            <Link href="/">Ver todas de novo</Link>
          </p>
        )}

        {!q && porCategoria.size > 1 && (
          <nav className="indice" aria-label="Ir para categoria">
            {[...porCategoria.keys()].map((categoria) => (
              <a key={categoria} href={`#${ancora(categoria)}`}>
                {categoria}
              </a>
            ))}
          </nav>
        )}

        {alertadas.length > 0 && (
          <>
            <h2>Turbinadas agora</h2>
            <div className="lista-grade">
              {alertadas.map((loja) => (
                <Loja key={`alerta-${loja.nome}`} loja={loja} podeAjustarAlerta={podeAjustarAlerta} />
              ))}
            </div>
          </>
        )}

        {alertadas.length === 0 && !q && (
          <p className="vazio">
            Nenhuma loja sua cruzou o próprio limite nesta execução. A lista completa continua
            abaixo, com a pontuação de cada uma.
          </p>
        )}

        {/* RN24: todas as favoritas, em promocao ou nao. E o motivo do site
            existir — responder "quanto a Renner da hoje?" sem abrir a Livelo. */}
        {[...porCategoria.entries()].map(([categoria, lojasDaCategoria]) => (
          <section key={categoria} id={ancora(categoria)}>
            <h2>{categoria}</h2>
            <div className="lista-grade">
              {lojasDaCategoria.map((loja) => (
                <Loja key={loja.nome} loja={loja} podeAjustarAlerta={podeAjustarAlerta} />
              ))}
            </div>
          </section>
        ))}

        <Rodape versao={execucao.versao} />
      </main>
    </>
  );
}
