import Link from "next/link";

import { preferencias, ultimaExecucao } from "@/lib/banco";
import { pontos } from "@/lib/formato";
import { Cabecalho } from "../componentes/cabecalho";
import { Rodape } from "../rodape";

export const dynamic = "force-dynamic";

/**
 * Escrita para o autor daqui a seis meses, que e quem mais vai precisar.
 *
 * Cada `<details>` e uma pergunta; `<details>` abre e fecha sem JavaScript
 * (RNF14) e o `id` permite que os tooltips apontem direto para a resposta.
 */
export default async function PaginaDeAjuda() {
  let padroes = { multiplicador_padrao: "2.0", piso_pontos_padrao: "4", assinante_clube: false };
  let versao: string | null = null;
  try {
    padroes = await preferencias();
    versao = (await ultimaExecucao())?.versao ?? null;
  } catch {
    // A ajuda tem que abrir mesmo com o banco fora do ar: e justamente
    // quando alguem vem procurar o que esta acontecendo.
  }

  const multiplicador = pontos(padroes.multiplicador_padrao);
  const piso = pontos(padroes.piso_pontos_padrao);

  return (
    <>
      <Cabecalho atual="/ajuda" />
      <main className="pagina">
        <h1>Como este sistema funciona</h1>
        <p className="carimbo">
          Um robô lê a página pública de parceiros da Livelo três vezes por dia, compara com as
          suas lojas e manda um e-mail. Este site mostra o que ele viu na última passada.
        </p>

        <h2>O aviso</h2>

        <details className="pergunta" id="como-decide" open>
          <summary>Como o robô decide que uma loja merece aviso?</summary>
          <div className="resposta">
            <p>
              Duas condições, e as duas precisam valer ao mesmo tempo. Com o seu ajuste de
              hoje:
            </p>
            <p>
              <strong>
                A pontuação precisa estar {multiplicador} vezes acima do normal daquela loja
              </strong>{" "}
              — e não acima de um número fixo. Uma loja que normalmente dá 1 ponto e passa a
              dar {multiplicador} já dobrou; uma que sempre dá 6 pontos não é oportunidade
              nenhuma, é o preço de sempre.
            </p>
            <p>
              <strong>E precisa valer no mínimo {piso} pontos por real.</strong> Sem isso,
              uma loja que sai de 1 para 2 pontos avisaria toda vez. Dobrou, mas são 2 pontos.
            </p>
            <p>
              Onde mudar: <Link href="/avisos">Quando me avisar</Link>.
            </p>
          </div>
        </details>

        <details className="pergunta" id="normal-da-loja">
          <summary>O que é o “normal da loja” e de onde vem esse número?</summary>
          <div className="resposta">
            <p>
              É a pontuação que a loja dá fora de promoção, e quem informa é a própria Livelo
              — o robô não calcula nem adivinha, apenas lê o campo que vem na página.
            </p>
            <p>
              É por isso que o aviso é por múltiplo e não por valor fixo: cada loja tem uma
              escala diferente, e comparar cada uma com ela mesma é o que faz sentido.
            </p>
          </div>
        </details>

        <details className="pergunta" id="promocao-sem-aviso">
          <summary>A Livelo diz que a loja está em promoção, mas não fui avisado. Por quê?</summary>
          <div className="resposta">
            <p>
              Porque a etiqueta “Promoção” da Livelo mente nos dois sentidos, e foi medido:
            </p>
            <p>
              Havia lojas <strong>etiquetadas sem aumento nenhum</strong> — a pontuação
              aberta continuava igual, e o ganho existia só para assinante do Clube. E havia
              lojas que <strong>triplicaram sem etiqueta nenhuma</strong>. O robô ignora a
              etiqueta e olha os números.
            </p>
            <p>
              Se você quer ser avisado de mais coisas, o caminho é baixar o mínimo de pontos
              ou o número de vezes em <Link href="/avisos">Quando me avisar</Link>.
            </p>
          </div>
        </details>

        <h2>O Clube</h2>

        <details className="pergunta" id="clube">
          <summary>Qual a diferença entre “exclusivo assinantes Clube” e “assinantes Clube ganham mais”?</summary>
          <div className="resposta">
            <p>
              <strong>Exclusivo assinantes Clube:</strong> a pontuação aberta não se moveu. O
              ganho existe só para quem paga a assinatura — se você não assina, essa promoção
              não é sua, e por isso ela não dispara aviso.
            </p>
            <p>
              <strong>Assinantes Clube ganham mais:</strong> a pontuação subiu para todo
              mundo, e para assinante subiu mais ainda. Essa serve para você; o número maior
              ao lado é que não é seu.
            </p>
            <p>
              Hoje o sistema está configurado como{" "}
              <strong>{padroes.assinante_clube ? "assinante" : "não assinante"}</strong> do
              Clube. Dá para mudar em <Link href="/avisos">Quando me avisar</Link>.
            </p>
          </div>
        </details>

        <h2>Quando algo parece errado</h2>

        <details className="pergunta" id="nao-encontrada">
          <summary>Uma loja aparece como “não encontrada”. O que houve?</summary>
          <div className="resposta">
            <p>
              A loja está no seu cadastro, mas o nome dela não apareceu na página da Livelo
              naquela passada. Quase sempre é a Livelo tendo mudado a grafia — de “C&amp;A”
              para “CEA”, por exemplo.
            </p>
            <p>
              O sistema exige nome exato de propósito: aceitar pedaço de nome faria “Petlove”
              capturar “Petlove Saúde”, que é outro parceiro com outra pontuação. A correção é
              cadastrar a grafia nova como apelido em{" "}
              <Link href="/lojas">Cadastrar lojas</Link>.
            </p>
          </div>
        </details>

        <details className="pergunta" id="carimbo">
          <summary>O que é o carimbo de atualização, e o que fazer se ficar vermelho?</summary>
          <div className="resposta">
            <p>
              É a hora em que o robô passou pela última vez. Fica vermelho depois de doze
              horas — o robô roda três vezes por dia, então esse atraso significa que alguma
              execução falhou.
            </p>
            <p>
              O que verificar, nesta ordem: se chegou e-mail hoje; se o GitHub avisou de
              falha; e a aba Actions do repositório. A página velha não some nem mente — ela
              mostra a data para você poder desconfiar dela.
            </p>
          </div>
        </details>

        <details className="pergunta" id="sem-email">
          <summary>Parou de chegar e-mail. O que verificar?</summary>
          <div className="resposta">
            <p>
              O e-mail chega em <strong>toda</strong> execução, mesmo sem nenhuma promoção —
              justamente para o silêncio significar uma coisa só: o robô parou.
            </p>
            <p>
              Então: nenhum e-mail é sinal de problema, não de dia fraco. Confira o carimbo
              desta página e a aba Actions. O GitHub desativa agendamento em repositório
              parado há muito tempo, e essa morte não avisa ninguém.
            </p>
          </div>
        </details>

        <h2>Ajustar</h2>

        <details className="pergunta" id="padrao-ou-excecao">
          <summary>Devo mudar o padrão de todas ou criar uma exceção?</summary>
          <div className="resposta">
            <p>
              Comece sempre pelo padrão. Configurar uma regra para cada uma das suas lojas na
              largada é armadilha: você chuta todas, erra a maioria e nunca revisa.
            </p>
            <p>
              Depois de algumas semanas recebendo, você vai saber quais lojas incomodam — aí
              cria exceção só para elas. A capacidade existe desde o primeiro dia; o uso dela
              deve ser preguiçoso.
            </p>
          </div>
        </details>

        <details className="pergunta" id="quando-vale">
          <summary>Mudei um ajuste. Quando ele começa a valer?</summary>
          <div className="resposta">
            <p>
              Na próxima execução do robô, não agora. Este site não dispara nada: ele lê o que
              o robô gravou e escreve o que o robô vai ler.
            </p>
            <p>
              Os números desta página continuam sendo os da última passada até a próxima
              acontecer.
            </p>
          </div>
        </details>

        <Rodape versao={versao} />
      </main>
    </>
  );
}
