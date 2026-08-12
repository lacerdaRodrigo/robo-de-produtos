import { redirect } from "next/navigation";
import { headers } from "next/headers";

import {
  JANELA_DE_BLOQUEIO_MINUTOS,
  LIMITE_DE_TENTATIVAS,
  registrarTentativa,
  tentativasRecentes,
} from "@/lib/banco";
import { abrirSessao, origemDaRequisicao, senhaConfere, temSessao } from "@/lib/sessao";
import { Rodape } from "../rodape";

export const dynamic = "force-dynamic";

// Server Action: o formulario funciona com JavaScript desligado (RNF14).
async function entrar(dadosDoFormulario: FormData) {
  "use server";

  const origem = origemDaRequisicao(await headers());

  // PRD-V2 9.0: senha unica sem limite de tentativas cai por forca bruta.
  if ((await tentativasRecentes(origem)) >= LIMITE_DE_TENTATIVAS) {
    redirect("/entrar?erro=bloqueado");
  }

  const senha = String(dadosDoFormulario.get("senha") ?? "");
  if (!senhaConfere(senha)) {
    await registrarTentativa(origem, false);
    redirect("/entrar?erro=senha");
  }

  await registrarTentativa(origem, true);
  await abrirSessao();
  redirect("/admin");
}

export default async function PaginaDeEntrada({
  searchParams,
}: {
  searchParams: Promise<{ erro?: string }>;
}) {
  if (await temSessao()) {
    redirect("/admin");
  }
  const { erro } = await searchParams;

  return (
    <main>
      <h1>Entrar</h1>
      <p className="carimbo">
        A leitura é pública; a edição pede senha. Ver PRD-V2 §9.0.
      </p>

      {erro === "senha" && <p className="aviso">Senha incorreta.</p>}
      {erro === "bloqueado" && (
        <p className="aviso">
          Tentativas demais. Espere {JANELA_DE_BLOQUEIO_MINUTOS} minutos e tente de novo.
        </p>
      )}

      <form action={entrar} className="cartao">
        <label htmlFor="senha" className="detalhe">
          Senha
        </label>
        <div className="linha" style={{ marginTop: 6 }}>
          <input id="senha" name="senha" type="password" required autoComplete="current-password" />
          <button type="submit">Entrar</button>
        </div>
      </form>

      <Rodape />
    </main>
  );
}
