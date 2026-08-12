import Link from "next/link";

let contador = 0;

/**
 * Ponto de interrogacao que explica um termo (RNF14: sem JavaScript).
 *
 * O balao aparece no `:hover` do mouse e no `:focus-within` do teclado e do
 * toque — clicar no botao da foco, e foco basta para o CSS mostrar. Nao ha
 * estado, nao ha script, e o texto continua no DOM para leitor de tela achar
 * pelo `aria-describedby`.
 *
 * `children` diz o que a coisa e, em uma frase. `exemplo` mostra a mesma
 * coisa com numero de verdade, separado — e o exemplo que faz a ficha cair,
 * mas so funciona se estiver visivelmente apartado da definicao.
 *
 * `secao` aponta para a pergunta correspondente na Ajuda.
 */
export function Dica({
  titulo,
  children,
  exemplo,
  secao,
}: {
  titulo: string;
  children: React.ReactNode;
  exemplo?: React.ReactNode;
  secao?: string;
}) {
  const id = `dica-${(contador += 1)}`;
  return (
    <span className="dica">
      <button type="button" aria-label={`O que é ${titulo}`} aria-describedby={id}>
        ?
      </button>
      <span className="balao" id={id} role="tooltip">
        {children}
        {exemplo && <span className="exemplo">{exemplo}</span>}
        {secao && (
          <span className="exemplo">
            <Link href={`/ajuda#${secao}`}>Ler mais na Ajuda</Link>
          </span>
        )}
      </span>
    </span>
  );
}
