import Link from "next/link";

import { pontuacoes, ultimaExecucao, type PontuacaoDeLoja } from "@/lib/banco";
import {
  ancora,
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

function Loja({ loja, logado }: { loja: PontuacaoDeLoja; logado: boolean }) {
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
        <span className="pontos numero">
          {naoEncontrada
            ? "não encontrada"
            : `${loja.prefixo_ate ? "Até " : ""}${pontos(loja.pontos_atuais)} pontos por ${loja.moeda} 1`}
        </span>
      </div>

      {!naoEncontrada ? (
        // RN30: atual, normal da loja e o valor que dispara o aviso, lado a
        // lado. Sem os tres, o ajuste desregula sem ninguem perceber.
        <p className="detalhe numero">
          normal da loja: {pontos(loja.pontos_base)} · avisa a partir de{" "}
          {pontos(loja.valor_de_disparo)}
          {loja.pontos_clube !== null && (
            <>
              {" "}
              · Clube: {pontos(loja.pontos_clube)}
              {rotuloClube ? ` (${rotuloClube})` : ""}
            </>
          )}
        </p>
      ) : (
        <p className="detalhe">
          Não apareceu na página da Livelo nesta execução. Costuma ser mudança de grafia do
          nome. <Link href="/ajuda#nao-encontrada">Entenda</Link>
        </p>
      )}

      {(loja.alertou || loja.fim_promocao) && (
        <p className="detalhe">
          {loja.alertou && <span className="etiqueta alerta">avisou</span>}{" "}
          <Validade fim={loja.fim_promocao} />
        </p>
      )}

      {logado && (
        <div className="acoes-do-cartao">
          <Link
            className="botao secundario"
            href={`/avisos?loja=${encodeURIComponent(loja.nome)}`}
          >
            Ajustar aviso desta loja
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
  const logado = await temSessao();

  let execucao: Awaited<ReturnType<typeof ultimaExecucao>> = null;
  let falhaNoBanco = false;
  try {
    execucao = await ultimaExecucao();
  } catch {
    // Banco fora do ar vira pagina que diz isso, nao erro 500 mudo. Mesma
    // linha do robo: falha nunca e silenciosa (O3).
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

  const todas = await pontuacoes(execucao.id);
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
        <h1>Suas lojas hoje</h1>
        {/* RN26: o carimbo e obrigatorio e sempre visivel. Sem ele, pagina
            velha e pagina mentirosa. */}
        <p className={carimbo.velho ? "carimbo velho" : "carimbo"}>
          Atualizado {carimbo.texto}, em {dataHora(execucao.momento)}
          {carimbo.velho && " — o robô pode estar parado"}
        </p>

        <section className="resumo">
          <div className="item">
            <span className="valor destaque numero">{alertadas.length}</span>
            <span className="rotulo">
              turbinadas{" "}
              <Dica titulo="loja turbinada" secao="como-decide">
                Loja cuja pontuação de hoje passou do que você definiu em{" "}
                <strong>Quando me avisar</strong>: precisa estar algumas vezes acima do
                normal daquela loja e valer um mínimo de pontos.
              </Dica>
            </span>
          </div>
          <div className="item">
            <span className="valor numero">{todas.length}</span>
            <span className="rotulo">lojas suas</span>
          </div>
          <div className="item">
            <span className="valor numero">{execucao.parceiros_lidos}</span>
            <span className="rotulo">
              parceiros lidos{" "}
              <Dica titulo="parceiros lidos" secao="como-decide">
                Quantos parceiros a Livelo tinha na página quando o robô passou. Suas lojas
                são um recorte dessa lista.
              </Dica>
            </span>
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
            {alertadas.map((loja) => (
              <Loja key={`alerta-${loja.nome}`} loja={loja} logado={logado} />
            ))}
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
            {lojasDaCategoria.map((loja) => (
              <Loja key={loja.nome} loja={loja} logado={logado} />
            ))}
          </section>
        ))}

        <Rodape versao={execucao.versao} />
      </main>
    </>
  );
}
