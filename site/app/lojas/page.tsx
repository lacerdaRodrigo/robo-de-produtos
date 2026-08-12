import Link from "next/link";

import { catalogo, categorias, ultimaExecucao } from "@/lib/banco";
import { filtrarPorNome } from "@/lib/formato";
import { exigirSessao } from "@/lib/sessao";
import { Cabecalho } from "../componentes/cabecalho";
import { Dica } from "../componentes/dica";
import { Rodape } from "../rodape";
import { acaoAdicionarLoja } from "./acoes";

export const dynamic = "force-dynamic";

export default async function PaginaDeLojas({
  searchParams,
}: {
  searchParams: Promise<{ ok?: string; erro?: string; nome?: string; q?: string }>;
}) {
  await exigirSessao();

  const { ok, erro, nome, q = "" } = await searchParams;
  const [todas, listaDeCategorias, execucao] = await Promise.all([
    catalogo(),
    categorias(),
    ultimaExecucao().catch(() => null),
  ]);
  const lojas = filtrarPorNome(todas, q);

  return (
    <>
      <Cabecalho atual="/lojas" />
      <main className="pagina">
        <h1>Cadastrar lojas</h1>
        <p className="carimbo">
          {todas.length} lojas no seu cadastro. Loja nova entra no e-mail e na lista na
          próxima execução do robô.
        </p>

        {ok === "adicionada" && (
          <p className="faixa">
            {nome} entrou no cadastro.{" "}
            <Link href={`/avisos?loja=${encodeURIComponent(nome ?? "")}`}>
              Definir um aviso próprio para ela
            </Link>
          </p>
        )}
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

        <h2>Adicionar</h2>
        <form action={acaoAdicionarLoja} className="bloco">
          <div className="campo">
            <label className="rotulo-campo" htmlFor="nome">
              Nome exato, como a Livelo escreve
              <Dica
                titulo="o nome exato"
                secao="nao-encontrada"
                exemplo="O robô compara letra por letra: “Petlove” e “Petlove Saúde” são lojas diferentes, com pontuações diferentes."
              >
                Escreva igual aparece no site da Livelo, com acento e tudo.
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

          <div className="campo">
            <label className="rotulo-campo" htmlFor="apelidos">
              Apelidos, um por linha
              <Dica
                titulo="os apelidos"
                secao="nao-encontrada"
                exemplo="Exemplo: a C&A aparece lá como “CEA”. Sem esse apelido, ela sumiria da sua lista."
              >
                Outros jeitos que a Livelo escreve o nome dessa mesma loja. Um por linha.
              </Dica>
            </label>
            <textarea id="apelidos" name="apelidos" rows={2} placeholder="Renner Lojas" />
          </div>

          <button type="submit">Adicionar loja</button>
        </form>

        <h2>Suas lojas</h2>
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
            <table>
              <thead>
                <tr>
                  <th>Loja</th>
                  <th>Categoria</th>
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
                    <td>
                      <Link href={`/lojas/remover?id=${loja.id}`} className="botao discreto">
                        Remover
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        <Rodape versao={execucao?.versao} />
      </main>
    </>
  );
}
