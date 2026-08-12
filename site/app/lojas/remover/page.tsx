import Link from "next/link";
import { redirect } from "next/navigation";

import { loja } from "@/lib/banco";
import { exigirSessao } from "@/lib/sessao";
import { Cabecalho } from "../../componentes/cabecalho";
import { Rodape } from "../../rodape";
import { acaoRemoverLoja } from "../acoes";

export const dynamic = "force-dynamic";

/**
 * Segunda etapa da remocao. Apagar loja e irreversivel — o banco leva junto
 * os apelidos e o historico de pontuacao dela — entao a confirmacao nomeia a
 * loja e diz a consequencia, em vez de um "tem certeza?" generico.
 *
 * Cancelar e um botao, e nao o "voltar" do navegador.
 */
export default async function PaginaDeConfirmacao({
  searchParams,
}: {
  searchParams: Promise<{ id?: string }>;
}) {
  await exigirSessao();

  const { id } = await searchParams;
  const alvo = id ? await loja(Number(id)) : null;
  if (!alvo) {
    redirect("/lojas?erro=nao-achei");
  }

  return (
    <>
      <Cabecalho atual="/lojas" />
      <main className="pagina">
        <h1>Remover {alvo.nome}?</h1>
        <div className="bloco">
          <p>
            A loja sai do seu cadastro, deixa de aparecer na lista de pontuação e nunca mais
            entra num e-mail. Os apelidos dela e o histórico de pontuação vão junto.
          </p>
          <p className="ajuda-do-campo">
            Categoria: {alvo.categoria}
            {alvo.apelidos.length > 0 && ` · apelidos: ${alvo.apelidos.join(", ")}`}
          </p>
          <div className="acoes-do-cartao">
            <form action={acaoRemoverLoja}>
              <input type="hidden" name="id" value={alvo.id} />
              <input type="hidden" name="nome" value={alvo.nome} />
              <button type="submit" className="perigo">
                Sim, remover
              </button>
            </form>
            <Link href="/lojas" className="botao secundario">
              Cancelar
            </Link>
          </div>
        </div>
        <Rodape />
      </main>
    </>
  );
}
