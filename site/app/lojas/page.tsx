import Link from "next/link";

import {
  catalogo,
  categorias,
  esperaAteProximoDisparo,
  INTERVALO_MINIMO_MINUTOS,
  preferencias,
  ultimaExecucao,
} from "@/lib/banco";
import { avisoOpcionalNoCadastroEscondido } from "@/lib/flags";
import { temTokenDeDisparo } from "@/lib/github";
import { filtrarPorNome, pontos } from "@/lib/formato";
import { exigirSessao } from "@/lib/sessao";
import { Cabecalho } from "../componentes/cabecalho";
import { Dica } from "../componentes/dica";
import { Rodape } from "../rodape";
import { acaoAdicionarLoja, acaoAtualizarAgora } from "./acoes";

export const dynamic = "force-dynamic";

export default async function PaginaDeLojas({
  searchParams,
}: {
  searchParams: Promise<{
    ok?: string;
    erro?: string;
    nome?: string;
    q?: string;
    segundos?: string;
  }>;
}) {
  await exigirSessao();

  const { ok, erro, nome, q = "", segundos } = await searchParams;
  const [todas, listaDeCategorias, execucao, falta, padroes, avisoOpcionalEscondido] =
    await Promise.all([
      catalogo(),
      categorias(),
      ultimaExecucao().catch(() => null),
      esperaAteProximoDisparo().catch(() => 0),
      preferencias(),
      avisoOpcionalNoCadastroEscondido(),
    ]);
  const podeDisparar = temTokenDeDisparo();
  const lojas = filtrarPorNome(todas, q);

  return (
    <>
      <Cabecalho atual="/lojas" />
      <main className="pagina">
        <h1>Suas lojas</h1>
        <p className="carimbo">
          {todas.length} lojas no seu cadastro. Loja nova entra no e-mail e na lista na
          próxima execução do robô.
        </p>

        {ok === "adicionada" && <p className="faixa">{nome} entrou no cadastro.</p>}
        {ok === "removida" && <p className="faixa">{nome} saiu do cadastro.</p>}
        {erro === "nome-e-categoria" && (
          <p className="faixa ruim">Nome e categoria são obrigatórios.</p>
        )}
        {erro === "repetido" && (
          <p className="faixa ruim">
            Esse nome ou apelido já pertence a outra loja. Cada grafia precisa apontar para
            uma loja só, senão o robô não saberia qual é qual.
          </p>
        )}
        {erro === "nao-achei" && <p className="faixa ruim">Essa loja não existe mais.</p>}
        {erro === "numero" && (
          <p className="faixa ruim">Só números aqui. Use ponto ou vírgula para o decimal, como 2,5.</p>
        )}
        {ok === "disparado" && (
          <p className="faixa">
            Pedido enviado. O robô leva cerca de um minuto para ler a Livelo e gravar. Recarregue
            esta página ou veja o resultado em <Link href="/">Pontuação</Link>.
          </p>
        )}
        {erro === "espere" && (
          <p className="faixa ruim">
            Espere mais {segundos ?? "alguns"} segundos. O robô só pode ser chamado de{" "}
            {INTERVALO_MINIMO_MINUTOS} em {INTERVALO_MINIMO_MINUTOS} minutos — é o combinado
            de não bater na página da Livelo mais do que o necessário.
          </p>
        )}
        {erro === "sem-token" && (
          <p className="faixa ruim">
            Falta o token do GitHub no ambiente do site (`GITHUB_TOKEN_DISPARO`). Sem ele o
            site não consegue pedir uma execução.
          </p>
        )}
        {erro === "disparo" && (
          <p className="faixa ruim">
            O GitHub recusou o pedido. O robô continua rodando nos horários de sempre.
          </p>
        )}

        <h2>Adicionar loja</h2>
        <form action={acaoAdicionarLoja} className="bloco">
          <div className="grade-2col">
            <div className="campo">
              <label className="rotulo-campo" htmlFor="nome">
                Nome exato, como a Livelo escreve
                <Dica titulo="nome exato" secao="nao-encontrada">
                  O robô só reconhece a loja por correspondência exata. Aceitar pedaço de nome
                  faria “Petlove” capturar “Petlove Saúde”, que é outro parceiro com outra
                  pontuação.
                </Dica>
              </label>
              <input id="nome" name="nome" type="text" required placeholder="Renner" />
            </div>

            <div className="campo">
              <label htmlFor="categoria">Categoria</label>
              <input
                id="categoria"
                name="categoria"
                type="text"
                list="categorias"
                required
                placeholder="Moda"
              />
              <datalist id="categorias">
                {listaDeCategorias.map((categoria) => (
                  <option key={categoria} value={categoria} />
                ))}
              </datalist>
              <span className="ajuda-do-campo">
                Serve para agrupar na lista e no e-mail. Pode ser uma existente ou uma nova.
              </span>
            </div>
          </div>

          {!avisoOpcionalEscondido && (
            <div className="campo">
              <span className="rotulo-campo">
                Regra de aviso opcional
                <Dica titulo="avisar quando ficar" secao="normal-da-loja">
                  O “normal da loja” é a pontuação dela fora de promoção, informada pela
                  própria Livelo. Com <strong>2</strong>, uma loja que dá 3 pontos normalmente
                  só avisa a partir de 6.
                </Dica>
              </span>
              <div className="frase">
                <input
                  className="curto"
                  name="multiplicador"
                  type="text"
                  inputMode="decimal"
                  placeholder={pontos(padroes.multiplicador_padrao)}
                  aria-label="Vezes acima do normal"
                />
                <span>vezes acima do normal e valer ao menos</span>
                <input
                  className="curto"
                  name="piso"
                  type="text"
                  inputMode="decimal"
                  placeholder={pontos(padroes.piso_pontos_padrao)}
                  aria-label="Mínimo de pontos por real"
                />
                <span>pontos.</span>
              </div>
              <span className="ajuda-do-campo">
                Opcional. Em branco, essa loja segue o padrão de todas as lojas — hoje{" "}
                {pontos(padroes.multiplicador_padrao)}x, valendo ao menos{" "}
                {pontos(padroes.piso_pontos_padrao)} pontos. Dá para ajustar por loja depois
                em <Link href="/avisos">Quando me avisar</Link>.
              </span>
            </div>
          )}

          <button type="submit">Adicionar loja</button>
        </form>

        <h2>Lojas cadastradas</h2>
        <form className="busca" action="/lojas" method="get" role="search">
          <input
            type="search"
            name="q"
            defaultValue={q}
            placeholder="Procurar no cadastro"
            aria-label="Procurar no cadastro"
          />
          <button type="submit" className="secundario">
            Procurar
          </button>
        </form>

        {lojas.length === 0 ? (
          <p className="vazio">
            Nenhuma loja combina com “{q}”. <Link href="/lojas">Ver todas</Link>
          </p>
        ) : (
          <div className="rolagem">
            <table className="tabela-lojas">
              <thead>
                <tr>
                  <th>Loja</th>
                  <th>Categoria</th>
                  <th>Limiar</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {lojas.map((loja) => (
                  <tr key={loja.id}>
                    <td>
                      {loja.nome}
                      {loja.apelidos.length > 0 && (
                        <div className="ajuda-do-campo">{loja.apelidos.join(" · ")}</div>
                      )}
                    </td>
                    <td className="ajuda-do-campo">{loja.categoria}</td>
                    <td className="ajuda-do-campo">
                      {loja.multiplicador || loja.piso_pontos ? (
                        <>
                          {loja.multiplicador ? `${pontos(loja.multiplicador)}x` : "padrão"}, mín{" "}
                          {loja.piso_pontos ? pontos(loja.piso_pontos) : "padrão"}
                        </>
                      ) : (
                        "Padrão de todas"
                      )}
                    </td>
                    <td>
                      <Link
                        href={`/lojas/remover?id=${loja.id}`}
                        className="botao discreto"
                        aria-label={`Remover ${loja.nome}`}
                        title={`Remover ${loja.nome}`}
                      >
                        <IconeLixeira />
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        <div className="bloco destaque">
          <div className="linha">
            <div>
              <strong>Terminou de mexer?</strong>
              <p className="ajuda-do-campo" style={{ margin: 0 }}>
                O robô lê a Livelo agora e a lista de pontuação já sai com as suas mudanças.
                Sem isso, elas entram no próximo horário: 9h, 14h ou 20h.
              </p>
            </div>
            <form action={acaoAtualizarAgora}>
              <button type="submit" disabled={!podeDisparar || falta > 0}>
                {falta > 0 ? `Aguarde ${falta}s` : "Forçar atualização"}
              </button>
            </form>
          </div>
        </div>

        <Rodape versao={execucao?.versao} />
      </main>
    </>
  );
}

/** RN25: icone e SVG no proprio HTML, nunca arquivo de terceiro. */
function IconeLixeira() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <path
        d="M3 6h18M8 6V4a1 1 0 0 1 1-1h6a1 1 0 0 1 1 1v2m3 0-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6h14Z"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}
