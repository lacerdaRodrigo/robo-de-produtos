import { ultimaExecucao } from "@/lib/banco";
import { avisoOpcionalNoCadastroLigado, telaDeAlertasEscondida } from "@/lib/flags";
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
 * O aviso opcional no cadastro começa desligado, até a calibragem do
 * limiar global fechar (docs/PENDENCIAS.md). Esconder a tela de Alertas
 * começa desligado também — a tela continua visível, que é o comportamento
 * de sempre —, e quem quiser escondê-la liga aqui.
 */
export default async function PaginaDeConfiguracoes({
  searchParams,
}: {
  searchParams: Promise<{ ok?: string }>;
}) {
  await exigirSessao();

  const { ok } = await searchParams;
  const [avisoOpcionalLigado, alertasEscondidos, execucao] = await Promise.all([
    avisoOpcionalNoCadastroLigado(),
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
              <span>Aviso opcional no cadastro de loja</span>
              <span className="interruptor">
                <input
                  id="aviso_opcional_no_cadastro"
                  name="aviso_opcional_no_cadastro"
                  type="checkbox"
                  defaultChecked={avisoOpcionalLigado}
                />
                <span className="trilho" aria-hidden="true" />
              </span>
            </label>
            <span className="ajuda-do-campo">
              Mostra os campos “vezes acima do normal” e “mínimo de pontos” direto no
              formulário de Adicionar loja, em Lojas. Desligado — o padrão agora —, o
              cadastro fica só com nome, categoria e apelidos. Não afeta o que já existe: as
              exceções por loja continuam em Alertas, para editar quando fizer sentido.
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
