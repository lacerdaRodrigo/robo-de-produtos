import { Cabecalho } from "../../componentes/cabecalho";

export default function LoadingLojasInter() {
  return (
    <>
      <Cabecalho atual="/inter/lojas" />
      <main className="pagina" aria-busy="true">
        <h1>Lojas do Shopping Inter</h1>
        <p className="faixa">Salvando sua escolha e atualizando a lista…</p>
        <div className="lista-grade" aria-hidden="true">
          {Array.from({ length: 4 }, (_, indice) => (
            <article className="cartao carregando-cartao" key={indice}>
              <div className="carregando-linha" />
              <div className="carregando-linha curta" />
            </article>
          ))}
        </div>
      </main>
    </>
  );
}
