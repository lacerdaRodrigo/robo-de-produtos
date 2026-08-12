import { redirect } from "next/navigation";

import { catalogo, categorias, preferencias, ultimaExecucao } from "@/lib/banco";
import { pontos } from "@/lib/formato";
import { temSessao } from "@/lib/sessao";
import { Rodape } from "../rodape";
import {
  acaoAdicionarLoja,
  acaoRemoverLoja,
  acaoSair,
  acaoSalvarLoja,
  acaoSalvarPreferencias,
} from "./acoes";

export const dynamic = "force-dynamic";

const RECADOS: Record<string, string> = {
  preferencias: "Padrões globais salvos. Valem na próxima execução do robô.",
  loja: "Limiar da loja salvo.",
  adicionada: "Loja adicionada. Ela entra no e-mail na próxima execução.",
  removida: "Loja removida do catálogo.",
};

const ERROS: Record<string, string> = {
  "padrao-obrigatorio": "O padrão global não pode ficar vazio — é a régua de quem não tem a própria.",
  "nome-e-categoria": "Nome e categoria são obrigatórios.",
  "nome-ou-apelido-repetido":
    "Nome ou apelido já existe em outra loja. RN04 proíbe ambiguidade: cada grafia aponta para uma loja só.",
};

export default async function PaginaDeAdmin({
  searchParams,
}: {
  searchParams: Promise<{ ok?: string; erro?: string }>;
}) {
  if (!(await temSessao())) {
    redirect("/entrar");
  }

  const [lojas, padroes, listaDeCategorias, execucao] = await Promise.all([
    catalogo(),
    preferencias(),
    categorias(),
    ultimaExecucao(),
  ]);
  const { ok, erro } = await searchParams;

  return (
    <main>
      <div className="linha">
        <h1>Editar</h1>
        <form action={acaoSair}>
          <button type="submit" className="discreto">
            Sair
          </button>
        </form>
      </div>
      <p className="carimbo">
        {lojas.length} lojas no catálogo. O que muda aqui vale na próxima execução do robô — o
        site não dispara nada sozinho.
      </p>

      {ok && RECADOS[ok] && <p className="cartao">{RECADOS[ok]}</p>}
      {erro && <p className="aviso">{ERROS[erro] ?? "Não deu para salvar."}</p>}

      <h2>Padrões globais (RN28)</h2>
      <form action={acaoSalvarPreferencias} className="cartao">
        <div className="linha">
          <label>
            <span className="detalhe">Multiplicador</span>
            <br />
            <input name="multiplicador" type="text" defaultValue={padroes.multiplicador_padrao} />
          </label>
          <label>
            <span className="detalhe">Piso (pontos)</span>
            <br />
            <input name="piso" type="text" defaultValue={padroes.piso_pontos_padrao} />
          </label>
          <label className="detalhe">
            <input name="assinante_clube" type="checkbox" defaultChecked={padroes.assinante_clube} />{" "}
            assino o Clube Livelo
          </label>
          <button type="submit">Salvar padrões</button>
        </div>
        <p className="detalhe">
          Uma loja alerta quando a pontuação atual passa de <em>base × multiplicador</em> e do
          piso, os dois. Loja sem limiar próprio usa estes valores.
        </p>
      </form>

      <h2>Adicionar loja</h2>
      <form action={acaoAdicionarLoja} className="cartao">
        <div className="linha">
          <label>
            <span className="detalhe">Nome exato na Livelo</span>
            <br />
            <input name="nome" type="text" required />
          </label>
          <label>
            <span className="detalhe">Categoria</span>
            <br />
            <input name="categoria" type="text" list="categorias" required />
            <datalist id="categorias">
              {listaDeCategorias.map((categoria) => (
                <option key={categoria} value={categoria} />
              ))}
            </datalist>
          </label>
          <button type="submit">Adicionar</button>
        </div>
        <label className="detalhe">
          Apelidos, um por linha — grafias que a Livelo exibe e o nome canônico não cobre
          (&quot;CEA&quot; para C&amp;A). RN04 exige correspondência exata.
          <br />
          <textarea name="apelidos" rows={2} style={{ width: "100%", marginTop: 4 }} />
        </label>
      </form>

      <h2>Limiar por loja</h2>
      <p className="detalhe">
        Campo vazio significa “usa o padrão global”. A recomendação do PRD-V2 §6.1 é deixar
        tudo vazio no começo e só sobrescrever as poucas que incomodarem.
      </p>
      <div className="rolagem">
        <table>
          <thead>
            <tr>
              <th>Loja</th>
              <th>Categoria</th>
              <th>Multiplicador</th>
              <th>Piso</th>
              <th />
            </tr>
          </thead>
          <tbody>
            {lojas.map((loja) => (
              <tr key={loja.id}>
                <td>
                  {loja.nome}
                  {loja.apelidos.length > 0 && (
                    <div className="detalhe">{loja.apelidos.join(" · ")}</div>
                  )}
                </td>
                <td className="detalhe">{loja.categoria}</td>
                <td colSpan={3}>
                  <form action={acaoSalvarLoja} className="linha">
                    <input type="hidden" name="id" value={loja.id} />
                    <input
                      name="multiplicador"
                      type="text"
                      size={5}
                      defaultValue={loja.multiplicador ? pontos(loja.multiplicador) : ""}
                      placeholder={pontos(padroes.multiplicador_padrao)}
                    />
                    <input
                      name="piso"
                      type="text"
                      size={5}
                      defaultValue={loja.piso_pontos ? pontos(loja.piso_pontos) : ""}
                      placeholder={pontos(padroes.piso_pontos_padrao)}
                    />
                    <button type="submit" className="discreto">
                      Salvar
                    </button>
                  </form>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2>Remover loja</h2>
      <form action={acaoRemoverLoja} className="cartao linha">
        <label>
          <span className="detalhe">Loja</span>
          <br />
          <select name="id" style={{ font: "inherit", padding: 7 }}>
            {lojas.map((loja) => (
              <option key={loja.id} value={loja.id}>
                {loja.nome}
              </option>
            ))}
          </select>
        </label>
        <button type="submit" className="discreto">
          Remover do catálogo
        </button>
      </form>

      <Rodape versao={execucao?.versao} />
    </main>
  );
}
