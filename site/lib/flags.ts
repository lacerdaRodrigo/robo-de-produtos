import { cookies } from "next/headers";

/**
 * Flags de funcionalidade (V2.3.4+), guardadas em cookie — mesma ideia do
 * tema (lib/tema.ts) e não da tabela `preferencia`: liga/desliga pedaço da
 * interface, não é regra de negócio, então não precisa de banco nem
 * migração pra existir.
 */
async function cookieLigado(nome: string): Promise<boolean> {
  return (await cookies()).get(nome)?.value === "1";
}

async function definirCookie(nome: string, ligado: boolean): Promise<void> {
  const armazem = await cookies();
  if (ligado) {
    armazem.set(nome, "1", { sameSite: "lax", path: "/", maxAge: 60 * 60 * 24 * 365 });
  } else {
    armazem.delete(nome);
  }
}

/** Esconde os campos "vezes acima do normal" e "mínimo de pontos" no
 *  formulário de Adicionar loja, em Lojas. Ausente = campos visíveis, que
 *  é o comportamento de sempre — só quem ligar explicitamente em
 *  /configuracoes deixa de ver, mesmo padrão do toggle de Alertas abaixo. */
const COOKIE_AVISO_OPCIONAL = "esconder_aviso_opcional_no_cadastro";

export async function avisoOpcionalNoCadastroEscondido(): Promise<boolean> {
  return cookieLigado(COOKIE_AVISO_OPCIONAL);
}

export async function definirAvisoOpcionalNoCadastroEscondido(escondido: boolean): Promise<void> {
  return definirCookie(COOKIE_AVISO_OPCIONAL, escondido);
}

/** Esconde a tela de Alertas (menu, rota e o botão "Ajustar alerta" no
 *  Painel). Ausente = tela visível, que é o comportamento de sempre — só
 *  quem ligar explicitamente em /configuracoes deixa de ver. */
const COOKIE_ESCONDER_ALERTAS = "esconder_tela_alertas";

export async function telaDeAlertasEscondida(): Promise<boolean> {
  return cookieLigado(COOKIE_ESCONDER_ALERTAS);
}

export async function definirTelaDeAlertasEscondida(escondida: boolean): Promise<void> {
  return definirCookie(COOKIE_ESCONDER_ALERTAS, escondida);
}
