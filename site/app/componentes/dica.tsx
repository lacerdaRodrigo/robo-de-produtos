import Link from "next/link";

/**
 * Ponto de interrogacao que explica um termo (RNF14: sem JavaScript).
 *
 * O balao aparece no `:hover` do mouse e no `:focus-within` do teclado e do
 * toque — clicar no botao da foco, e foco basta para o CSS mostrar. Nao ha
 * estado, nao ha script, e o texto continua no DOM para leitor de tela achar
 * pelo `aria-describedby`.
 *
 * `secao` aponta para a pergunta correspondente na Ajuda, para quando a
 * explicacao curta nao bastar.
 */
export function Dica({
  titulo,
  children,
  secao,
}: {
  titulo: string;
  children: React.ReactNode;
  secao?: string;
}) {
  // Todas as dicas atuais informam uma secao unica por pagina. O ID
  // deterministico evita estado global durante SSR e continua estavel sem JS.
  const id = `dica-${secao ?? titulo.toLocaleLowerCase("pt-BR").replace(/\W+/g, "-")}`;
  return (
    <span className="dica">
      <button type="button" aria-label={`O que é ${titulo}`} aria-describedby={id}>
        ?
      </button>
      <span className="balao" id={id} role="tooltip">
        {children}
        {secao && (
          <>
            {" "}
            <Link href={`/ajuda#${secao}`}>Ler mais na Ajuda</Link>
          </>
        )}
      </span>
    </span>
  );
}
