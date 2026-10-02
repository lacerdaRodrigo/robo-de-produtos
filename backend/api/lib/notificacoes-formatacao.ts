export type EventoPush = {
  origem: string;
  tipo: string;
  entidade_nome: string;
  valor_atual: string;
  loja_nome: string | null;
};

function decimalPtBr(valor: string, casasMinimas = 0): string {
  const partes = /^(-?)(\d+)(?:\.(\d+))?$/.exec(valor.trim());
  if (!partes) return valor.trim().replace(".", ",");

  const [, sinal, inteiro, casasBrutas = ""] = partes;
  const casas = casasBrutas.replace(/0+$/, "").padEnd(casasMinimas, "0");
  const inteiroAgrupado = inteiro.replace(/\B(?=(\d{3})+(?!\d))/g, ".");
  return `${sinal}${inteiroAgrupado}${casas ? `,${casas}` : ""}`;
}

function nomeParaPush(valor: string | null | undefined, fallback: string): string {
  const normalizado = (valor ?? "")
    .replace(/[\u0000-\u001f\u007f-\u009f]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
  if (!normalizado) return fallback;
  const caracteres = Array.from(normalizado);
  return caracteres.length <= 48
    ? normalizado
    : `${caracteres.slice(0, 47).join("")}…`;
}

function valorMonetario(valor: string): string {
  return `R$ ${decimalPtBr(valor, 2)}`;
}

function valorPercentual(valor: string): string {
  return `${decimalPtBr(valor)}%`;
}

function valorPontuacao(valor: string): string {
  return `${decimalPtBr(valor)} pontos por real`;
}

/** Monta o corpo em português a partir do evento persistido, sem converter NUMERIC para Number. */
export function formatarCorpoPush(evento: EventoPush): string {
  const nome = nomeParaPush(evento.entidade_nome, "um item acompanhado");
  const loja = nomeParaPush(evento.loja_nome, "a loja");

  if (evento.origem === "pichau" && evento.tipo === "preco") {
    return `Olá! Pichau: ${nome} agora custa ${valorMonetario(evento.valor_atual)} no Pix.`;
  }

  if (evento.origem === "inter_produto" && evento.tipo === "preco") {
    return `Olá! ${loja}: ${nome} agora custa ${valorMonetario(evento.valor_atual)}.`;
  }

  if (evento.origem === "inter_produto" && evento.tipo === "cashback") {
    return `Olá! ${loja}: cashback de ${nome} agora é ${valorPercentual(evento.valor_atual)}.`;
  }

  if (evento.origem === "inter_cashback" && evento.tipo === "cashback") {
    return `Olá! ${nome}: cashback agora é ${valorPercentual(evento.valor_atual)}.`;
  }

  if (evento.origem === "livelo" && evento.tipo === "pontuacao") {
    return `Olá! ${nome}: pontuação agora é ${valorPontuacao(evento.valor_atual)}.`;
  }

  return `Olá! Houve uma alteração em ${nome}.`;
}
