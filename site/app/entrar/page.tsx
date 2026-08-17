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
      <main className="pagina pagina-entrada">
        <section className="entrada-visual">
          <span className="hero-rotulo">Área de controle</span>
          <h1>Bem-vindo de volta</h1>
          <p>Entre para configurar lojas, alertas e execuções. A consulta pública continua livre.</p>
          <div className="entrada-beneficios">
            <span><strong>01</strong> Seus dados protegidos</span>
            <span><strong>02</strong> Controle dos três robôs</span>
            <span><strong>03</strong> Histórico sempre disponível</span>
          </div>
        </section>

        <section className="entrada-formulario">
          <div>
            <span className="hero-rotulo">Acesso seguro</span>
            <h2>Entrar para editar</h2>
            <p>Use a senha administrativa do Radar.</p>
          </div>

          {erro === "senha" && <p className="faixa ruim">Senha incorreta.</p>}
          {erro === "bloqueado" && (
            <p className="faixa ruim">
              Tentativas demais. Espere {JANELA_DE_BLOQUEIO_MINUTOS} minutos e tente de novo —
              é o que impede alguém de descobrir a senha no chute.
            </p>
          )}

          <form action={entrar}>
            <input type="hidden" name="voltar" value={destino} />
            <div className="campo">
              <label htmlFor="senha">Senha</label>
              <input id="senha" name="senha" type="password" required autoComplete="current-password" autoFocus placeholder="Digite sua senha" />
            </div>
            <button type="submit">Acessar painel</button>
          </form>
          <small>A visualização dos benefícios não exige login.</small>
        </section>

        <Rodape />
      </main>
    </>
  );
}
