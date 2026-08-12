import { ultimaExecucao } from "@/lib/banco";
import { avisoOpcionalNoCadastroLigado } from "@/lib/flags";
import { exigirSessao } from "@/lib/sessao";
import { Cabecalho } from "../componentes/cabecalho";
import { Rodape } from "../rodape";
import { acaoSalvarConfiguracoes } from "./acoes";

export const dynamic = "force-dynamic";

/**
 * V2.3.4: interruptores de interface, separados das regras de alerta
 * (que moram em /avisos). Guardados em cookie (lib/flags.ts), não no
 * banco — é preferência de quem mexe no site, não dado que o robô lê.
 *
 * O primeiro é o campo de aviso opcional no cadastro — desligado por
 * padrão até a calibragem do limiar global fechar (docs/PENDENCIAS.md).
 * A ideia não é apagar a funcionalidade, só não empurrá-la para quem
 * ainda não decidiu se vai usar.
 */
export default async function PaginaDeConfiguracoes({
  searchParams,
}: {
  searchParams: Promise<{ ok?: string }>;
}) {
  await exigirSessao();

  const { ok } = await searchParams;
  const [avisoOpcionalLigado, execucao] = await Promise.all([
    avisoOpcionalNoCadastroLigado(),
    ultimaExecucao().catch(() => null),
  ]);

  return (
    <>
      <Cabecalho atual="/configuracoes" />
      <main className="pagina">
        <h1>Configurações</h1>
        <p className="carimbo">
          Liga e desliga pedaços da interface. Nada aqui muda como o robô decide um alerta —
          só o que aparece na tela.
        </p>

        {ok === "salvo" && <p className="faixa">Salvo. Vale a partir de agora.</p>}

        <form action={acaoSalvarConfiguracoes} className="bloco">
          <div className="campo">
            <label
              className="rotulo-campo opcao-destaque"
              htmlFor="aviso_opcional_no_cadastro"
            >
              <input
                id="aviso_opcional_no_cadastro"
                name="aviso_opcional_no_cadastro"
                type="checkbox"
                defaultChecked={avisoOpcionalLigado}
                style={{ width: "auto", minHeight: 0 }}
              />
              Aviso opcional no cadastro de loja
            </label>
            <span className="ajuda-do-campo">
              Mostra os campos “vezes acima do normal” e “mínimo de pontos” direto no
              formulário de Adicionar loja, em Lojas. Desligado — o padrão agora —, o
              cadastro fica só com nome, categoria e apelidos. Não afeta o que já existe: as
              exceções por loja continuam em Alertas, para editar quando fizer sentido.
            </span>
          </div>

          <button type="submit">Salvar</button>
        </form>

        <Rodape versao={execucao?.versao} />
      </main>
    </>
  );
}
