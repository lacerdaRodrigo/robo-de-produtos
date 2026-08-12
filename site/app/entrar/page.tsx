import { headers } from "next/headers";
import { redirect } from "next/navigation";

import {
  JANELA_DE_BLOQUEIO_MINUTOS,
  LIMITE_DE_TENTATIVAS,
  registrarTentativa,
  tentativasRecentes,
} from "@/lib/banco";
import {
  abrirSessao,
  destinoSeguro,
  origemDaRequisicao,
  senhaConfere,
  temSessao,
} from "@/lib/sessao";
import { Cabecalho } from "../componentes/cabecalho";
import { Rodape } from "../rodape";

export const dynamic = "force-dynamic";

// Server Action: o formulario funciona com JavaScript desligado (RNF14).
async function entrar(dadosDoFormulario: FormData) {
  "use server";

  const destino = destinoSeguro(String(dadosDoFormulario.get("voltar") ?? ""));
  const origem = origemDaRequisicao(await headers());

  // PRD-V2 9.0: senha unica sem limite de tentativas cai por forca bruta.
  if ((await tentativasRecentes(origem)) >= LIMITE_DE_TENTATIVAS) {
    redirect(`/entrar?erro=bloqueado&voltar=${encodeURIComponent(destino)}`);
  }

  const senha = String(dadosDoFormulario.get("senha") ?? "");
  if (!senhaConfere(senha)) {
    await registrarTentativa(origem, false);
    redirect(`/entrar?erro=senha&voltar=${encodeURIComponent(destino)}`);
  }

  await registrarTentativa(origem, true);
  await abrirSessao();
  redirect(destino);
}

export default async function PaginaDeEntrada({
  searchParams,
}: {
  searchParams: Promise<{ erro?: string; voltar?: string }>;
}) {
  const { erro, voltar } = await searchParams;
  const destino = destinoSeguro(voltar);

  if (await temSessao()) {
    redirect(destino);
  }

  return (
    <>
      <Cabecalho atual="/entrar" />
      <main className="pagina">
        <h1>Entrar para editar</h1>
        <p className="carimbo">
          Ver a pontuação não pede senha. Ela existe para que só você mude o que o robô faz.
        </p>

        {erro === "senha" && <p className="faixa ruim">Senha incorreta.</p>}
        {erro === "bloqueado" && (
          <p className="faixa ruim">
            Tentativas demais. Espere {JANELA_DE_BLOQUEIO_MINUTOS} minutos e tente de novo —
            é o que impede alguém de descobrir a senha no chute.
          </p>
        )}

        <form action={entrar} className="bloco">
          <input type="hidden" name="voltar" value={destino} />
          <div className="campo">
            <label htmlFor="senha">Senha</label>
            <input
              id="senha"
              name="senha"
              type="password"
              required
              autoComplete="current-password"
              autoFocus
            />
          </div>
          <button type="submit">Entrar</button>
        </form>

        <Rodape />
      </main>
    </>
  );
}
