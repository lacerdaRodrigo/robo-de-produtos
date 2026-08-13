import { ultimaExecucao } from "@/lib/banco";
import { avisoOpcionalNoCadastroEscondido, telaDeAlertasEscondida } from "@/lib/flags";
import { exigirSessao } from "@/lib/sessao";
import { Cabecalho } from "../componentes/cabecalho";
import { Rodape } from "../rodape";
import { acaoSalvarConfiguracoes } from "./acoes";

export const dynamic = "force-dynamic";

/**
 * V2.3.4+: interruptores de interface, separados das regras de alerta
 * (que moram em /avisos). Guardados em cookie (lib/flags.ts), não no
 * banco — é preferência de quem mexe no site, não dado que o robô lê.
 *
 * Os dois começam desligados (cinza): os campos do aviso opcional e a tela
 * de Alertas ficam visíveis, que é o comportamento de sempre. Ligar (verde)
 * esconde — mesmo sentido nos dois toggles, então verde sempre significa
 * "sumiu da tela".
 */
export default async function PaginaDeConfiguracoes({
  searchParams,
}: {
  searchParams: Promise<{ ok?: string }>;
}) {
  await exigirSessao();

  const { ok } = await searchParams;
  const [avisoOpcionalEscondido, alertasEscondidos, execucao] = await Promise.all([
    avisoOpcionalNoCadastroEscondido(),
    telaDeAlertasEscondida(),
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
            <label className="linha-interruptor" htmlFor="aviso_opcional_no_cadastro">
              <span>Esconder regra de aviso opcional no cadastro de loja</span>
              <span className="interruptor">
                <input
                  id="aviso_opcional_no_cadastro"
                  name="aviso_opcional_no_cadastro"
                  type="checkbox"
                  defaultChecked={avisoOpcionalEscondido}
                />
                <span className="trilho" aria-hidden="true" />
              </span>
            </label>
            <span className="ajuda-do-campo">
              Tira os campos “vezes acima do normal” e “mínimo de pontos” do formulário de
              Adicionar loja, em Lojas — fica só nome e categoria. Desligado — o padrão —,
              os campos continuam visíveis. Não afeta o que já existe: as exceções por loja
              continuam em Alertas, para editar quando fizer sentido.
            </span>
          </div>

          <div className="campo">
            <label className="linha-interruptor" htmlFor="esconder_tela_alertas">
              <span>Esconder a tela de Alertas</span>
              <span className="interruptor">
                <input
                  id="esconder_tela_alertas"
                  name="esconder_tela_alertas"
                  type="checkbox"
                  defaultChecked={alertasEscondidos}
                />
                <span className="trilho" aria-hidden="true" />
              </span>
            </label>
            <span className="ajuda-do-campo">
              Tira “Alertas” do menu e o botão “Ajustar alerta” dos cartões do Painel. A tela
              de padrão global e exceções por loja (“Quando me avisar”) fica inacessível até
              religar aqui. Desligado — o padrão —, ela continua como sempre foi.
            </span>
          </div>

          <button type="submit">Salvar</button>
        </form>

        <Rodape versao={execucao?.versao} />
      </main>
    </>
  );
}
