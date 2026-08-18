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
import { paginar, paginasVisiveis } from "@/lib/paginacao";
import { temSessao } from "@/lib/sessao";
import { BuscaProgressiva } from "./componentes/busca-progressiva";
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

const ROTULO_DA_ORDENACAO: Record<Ordenacao, string> = {
  pontos: "Maior pontuação",
  alerta: "Em alerta",
  nome: "Nome A-Z",
};

export default async function Pagina({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; ordenar?: string; pagina?: string }>;
}) {
  const { q = "", ordenar: ordenarBruto, pagina: paginaBruta } = await searchParams;
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
  const carimbo = idade(execucao.momento);

  // Grade unica, ordenavel — substitui o agrupamento por categoria do
  // redesenho anterior (redesenho V4.6, mockup enviado em 2026-08-13).
  const lojasOrdenadas = ordenarLojas(lojas, ordenar);
  const paginacao = paginar(lojasOrdenadas, paginaBruta);
  const numerosDePagina = paginasVisiveis(paginacao.pagina, paginacao.totalPaginas);
  const linkDaPagina = (numero: number) => {
    const parametros = new URLSearchParams();
    if (q) {
      parametros.set("q", q);
    }
    parametros.set("ordenar", ordenar);
    parametros.set("pagina", String(numero));
    return `/?${parametros.toString()}`;
  };
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
        <p className="detalhe">{execucao.parceiros_lidos} lojas encontradas na última consulta.</p>


        <div id="busca-principal">
          <BuscaProgressiva
            acao="/"
            valorInicial={q}
            placeholder="Procurar loja ou categoria"
            rotulo="Procurar loja ou categoria"
            parametrosFixos={{ ordenar }}
          />
        </div>

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
              <>
                <div className="lista-grade">
                  {paginacao.itens.map((loja) => (
                    <Loja key={loja.nome} loja={loja} podeAjustarAlerta={podeAjustarAlerta} />
                  ))}
                </div>

                {paginacao.totalItens > 0 && (
                  <nav className="paginacao" aria-label="Paginação das lojas">
                    <p className="paginacao-resumo">
                      Mostrando {paginacao.primeiroItem}–{paginacao.ultimoItem} de {paginacao.totalItens} lojas
                    </p>
                    <div className="paginacao-botoes">
                      {paginacao.pagina > 1 ? (
                        <Link className="botao-paginacao navegacao" href={linkDaPagina(paginacao.pagina - 1)}>
                          Anterior
                        </Link>
                      ) : (
                        <span className="botao-paginacao navegacao desabilitado" aria-disabled="true">
                          Anterior
                        </span>
                      )}
                      {numerosDePagina.map((numero) => (
                        <Link
                          key={numero}
                          className="botao-paginacao numero"
                          href={linkDaPagina(numero)}
                          aria-current={numero === paginacao.pagina ? "page" : undefined}
                        >
                          {numero}
                        </Link>
                      ))}
                      {paginacao.pagina < paginacao.totalPaginas ? (
                        <Link className="botao-paginacao navegacao" href={linkDaPagina(paginacao.pagina + 1)}>
                          Próxima
                        </Link>
                      ) : (
                        <span className="botao-paginacao navegacao desabilitado" aria-disabled="true">
                          Próxima
                        </span>
                      )}
                    </div>
                  </nav>
                )}
              </>
            )}
          </>
        )}

        <Rodape versao={execucao.versao} />
      </main>
    </>
  );
}
