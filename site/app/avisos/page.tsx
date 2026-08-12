import Link from "next/link";

import {
  catalogo,
  lojasComExcecao,
  pontuacoes,
  preferencias,
  ultimaExecucao,
} from "@/lib/banco";
import { normalizar, pontos } from "@/lib/formato";
import { exigirSessao } from "@/lib/sessao";
import { Cabecalho } from "../componentes/cabecalho";
import { Dica } from "../componentes/dica";
import { Rodape } from "../rodape";
import { acaoSalvarExcecao, acaoSalvarPadroes } from "./acoes";

export const dynamic = "force-dynamic";

const RECADOS: Record<string, string> = {
  padroes: "Pronto. O novo ajuste vale na próxima execução do robô.",
  excecao: "Exceção salva. Essa loja passa a seguir a regra própria dela.",
  removida: "Exceção removida. Essa loja volta a seguir o padrão de todas.",
};

const ERROS: Record<string, string> = {
  "padrao-obrigatorio":
    "O padrão de todas não pode ficar vazio — é a régua das lojas que não têm regra própria.",
  numero: "Só números aqui. Use ponto ou vírgula para o decimal, como 2,5.",
};

export default async function PaginaDeAvisos({
  searchParams,
}: {
  searchParams: Promise<{ ok?: string; erro?: string; loja?: string }>;
}) {
  await exigirSessao();

  const { ok, erro, loja: lojaPedida } = await searchParams;
  const [padroes, excecoes, lojas, execucao] = await Promise.all([
    preferencias(),
    lojasComExcecao(),
    catalogo(),
    ultimaExecucao().catch(() => null),
  ]);

  // Contado das pontuações, e não de `execucao.alertas`: remover uma loja
  // apaga o histórico dela (cascata), e o número gravado ficaria maior que a
  // lista que a pessoa vê. Duas contagens diferentes na mesma tela é o tipo
  // de detalhe que faz alguém deixar de confiar no resto.
  const alertasAgora = execucao
    ? (await pontuacoes(execucao.id)).filter((p) => p.alertou).length
    : 0;

  // Veio de "ajustar aviso desta loja" na lista: a loja já chega escolhida,
  // para ninguém ter que procurá-la num select de 132.
  const escolhida = lojaPedida
    ? lojas.find((l) => normalizar(l.nome) === normalizar(lojaPedida))
    : undefined;

  return (
    <>
      <Cabecalho atual="/avisos" />
      <main className="pagina">
        <h1>Quando me avisar</h1>
        <p className="carimbo">
          Vale para todas as suas lojas. O que mudar aqui entra na próxima execução do robô —
          esta tela não dispara nada sozinha.
        </p>

        {ok && RECADOS[ok] && <p className="faixa">{RECADOS[ok]}</p>}
        {erro && <p className="faixa ruim">{ERROS[erro] ?? "Não deu para salvar."}</p>}

        <h2>Padrão de todas as lojas</h2>
        <form action={acaoSalvarPadroes} className="bloco">
          <div className="frase">
            <span>A pontuação precisa ficar</span>
            <input
              className="curto"
              name="multiplicador"
              type="text"
              inputMode="decimal"
              defaultValue={pontos(padroes.multiplicador_padrao)}
              aria-label="Quantas vezes acima do normal"
            />
            <span>vezes acima do normal da loja</span>
            <Dica titulo="vezes acima do normal" secao="normal-da-loja">
              O “normal da loja” é a pontuação dela fora de promoção, informada pela própria
              Livelo. Com <strong>2</strong>, uma loja que dá 3 pontos normalmente só avisa a
              partir de 6.
            </Dica>
          </div>

          <div className="frase">
            <span>e valer no mínimo</span>
            <input
              className="curto"
              name="piso"
              type="text"
              inputMode="decimal"
              defaultValue={pontos(padroes.piso_pontos_padrao)}
              aria-label="Mínimo de pontos por real"
            />
            <span>pontos por real.</span>
            <Dica titulo="mínimo de pontos" secao="como-decide">
              Segura o alarme falso das lojas de pontuação baixa: sair de 1 para 2 pontos
              dobra, mas continuam sendo 2 pontos. Sem esse mínimo, elas avisariam sempre.
            </Dica>
          </div>

          <div className="campo">
            <label className="rotulo-campo" htmlFor="assinante_clube">
              <input
                id="assinante_clube"
                name="assinante_clube"
                type="checkbox"
                defaultChecked={padroes.assinante_clube}
                style={{ width: "auto", minHeight: 0 }}
              />
              Eu assino o Clube Livelo
              <Dica titulo="assinante do Clube" secao="clube">
                Marcado, o robô passa a contar a pontuação do Clube e avisa também das
                promoções exclusivas de assinante. Desmarcado, ele ignora o que você não pode
                aproveitar.
              </Dica>
            </label>
          </div>

          <button type="submit">Salvar</button>
        </form>

        {execucao && (
          <p className="detalhe">
            Para referência: na última execução, {alertasAgora}{" "}
            {alertasAgora === 1 ? "loja sua passou" : "lojas suas passaram"} deste ajuste.{" "}
            <Link href="/">Ver quais</Link>
          </p>
        )}

        <h2>Exceções</h2>
        <p className="detalhe">
          Loja com regra própria ignora o padrão acima. A recomendação é começar sem nenhuma e
          só criar as poucas que incomodarem. <Link href="/ajuda#padrao-ou-excecao">Por quê</Link>
        </p>

        {excecoes.length === 0 ? (
          <p className="vazio">
            Nenhuma exceção. Todas as suas lojas seguem o padrão — que é como se recomenda
            começar.
          </p>
        ) : (
          <div className="rolagem">
            <table>
              <thead>
                <tr>
                  <th>Loja</th>
                  <th>Vezes acima</th>
                  <th>Mínimo</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {excecoes.map((loja) => (
                  <tr key={loja.id}>
                    <td>{loja.nome}</td>
                    <td colSpan={3}>
                      <form action={acaoSalvarExcecao} className="frase">
                        <input type="hidden" name="id" value={loja.id} />
                        <input
                          className="curto"
                          name="multiplicador"
                          type="text"
                          inputMode="decimal"
                          defaultValue={loja.multiplicador ? pontos(loja.multiplicador) : ""}
                          placeholder={pontos(padroes.multiplicador_padrao)}
                          aria-label={`Vezes acima do normal para ${loja.nome}`}
                        />
                        <input
                          className="curto"
                          name="piso"
                          type="text"
                          inputMode="decimal"
                          defaultValue={loja.piso_pontos ? pontos(loja.piso_pontos) : ""}
                          placeholder={pontos(padroes.piso_pontos_padrao)}
                          aria-label={`Mínimo de pontos para ${loja.nome}`}
                        />
                        <button type="submit" className="secundario">
                          Salvar
                        </button>
                      </form>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            <p className="detalhe">
              Apagar os dois campos de uma loja devolve ela ao padrão de todas.
            </p>
          </div>
        )}

        <h3>{escolhida ? `Regra própria para ${escolhida.nome}` : "Criar uma exceção"}</h3>
        <form action={acaoSalvarExcecao} className="bloco">
          <div className="campo">
            <label htmlFor="id">Loja</label>
            <select id="id" name="id" defaultValue={escolhida?.id ?? ""}>
              {lojas.map((l) => (
                <option key={l.id} value={l.id}>
                  {l.nome} — {l.categoria}
                </option>
              ))}
            </select>
          </div>
          <div className="frase">
            <span>Avisar quando ficar</span>
            <input
              className="curto"
              name="multiplicador"
              type="text"
              inputMode="decimal"
              defaultValue={escolhida?.multiplicador ? pontos(escolhida.multiplicador) : ""}
              placeholder={pontos(padroes.multiplicador_padrao)}
              aria-label="Vezes acima do normal"
            />
            <span>vezes acima do normal e valer ao menos</span>
            <input
              className="curto"
              name="piso"
              type="text"
              inputMode="decimal"
              defaultValue={escolhida?.piso_pontos ? pontos(escolhida.piso_pontos) : ""}
              placeholder={pontos(padroes.piso_pontos_padrao)}
              aria-label="Mínimo de pontos por real"
            />
            <span>pontos.</span>
          </div>
          <p className="ajuda-do-campo">
            Deixar um campo vazio faz essa loja usar o padrão de todas naquele critério.
          </p>
          <button type="submit">Salvar exceção</button>
        </form>

        <p className="detalhe">
          Falta uma loja nesta lista? <Link href="/lojas">Cadastrar loja nova</Link>
        </p>

        <Rodape versao={execucao?.versao} />
      </main>
    </>
  );
}
