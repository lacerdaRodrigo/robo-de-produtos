import {
  resumoCashbackInterPersistido,
  type ResumoCashbackInterPersistido,
} from "./banco-inter";
import {
  resumoProdutosPersistido,
  type ResumoProdutosPersistido,
} from "./banco-produtos-inter";
import { resumoLiveloPersistido, type ResumoLiveloPersistido } from "./banco";

export type EstadoGeralResumo = "atualizado" | "atencao" | "sem_dados" | "indisponivel";
export type EstadoLiveloResumo = "atualizado" | "atrasado" | "sem_dados" | "indisponivel";
export type EstadoCashbackResumo =
  | "atualizado"
  | "atrasado"
  | "atualizando"
  | "falha_recente"
  | "sem_dados"
  | "indisponivel";
export type EstadoProdutosResumo =
  | "atualizado"
  | "atrasado"
  | "atualizando"
  | "parcial"
  | "falha_recente"
  | "degradado"
  | "sem_dados"
  | "indisponivel";

export type ResumoInicio = {
  gerado_em: string;
  estado_geral: EstadoGeralResumo;
  livelo: ResumoLiveloPersistido & {
    estado: EstadoLiveloResumo;
    agendamento: { estado: "prevista" | "aguardando"; referencia_em: string };
  };
  cashback_inter: ResumoCashbackInterPersistido & { estado: EstadoCashbackResumo };
  produtos: ResumoProdutosPersistido & { estado: EstadoProdutosResumo };
  atividade_recente: AtividadeRecente[];
};

export type AtividadeRecente = {
  dominio: "livelo" | "cashback_inter" | "produtos_inter";
  estado: string;
  momento: string | null;
};

export type DependenciasResumoInicio = {
  livelo: () => Promise<ResumoLiveloPersistido>;
  cashbackInter: () => Promise<ResumoCashbackInterPersistido>;
  produtos: () => Promise<ResumoProdutosPersistido>;
};

const dependenciasPadrao: DependenciasResumoInicio = {
  livelo: resumoLiveloPersistido,
  cashbackInter: resumoCashbackInterPersistido,
  produtos: resumoProdutosPersistido,
};

const LIMITE_LIVELO_MS = 12 * 60 * 60 * 1000;
const LIMITE_CASHBACK_MS = 24 * 60 * 60 * 1000;
const LIMITE_PRODUTOS_MS = 12 * 60 * 60 * 1000;

function instante(valor: string | null): number | null {
  if (!valor) return null;
  const milissegundos = new Date(valor).getTime();
  return Number.isFinite(milissegundos) ? milissegundos : null;
}

function atrasado(valor: string | null, agora: Date, limite: number): boolean {
  const momento = instante(valor);
  return momento === null || agora.getTime() - momento > limite;
}

function tentativaPosterior(
  tentativa: string | null,
  ultimoSucesso: string | null,
): boolean {
  const inicio = instante(tentativa);
  const sucesso = instante(ultimoSucesso);
  return inicio !== null && (sucesso === null || inicio > sucesso);
}

function estadoLivelo(dados: ResumoLiveloPersistido, agora: Date): EstadoLiveloResumo {
  if (!dados.ultimo_sucesso_em) return "sem_dados";
  return atrasado(dados.ultimo_sucesso_em, agora, LIMITE_LIVELO_MS)
    ? "atrasado"
    : "atualizado";
}

const HORARIOS_LIVELO = [9, 14, 20] as const;
function partesBrasilia(data: Date) {
  const partes = new Intl.DateTimeFormat("en-US", { timeZone: "America/Sao_Paulo", year: "numeric", month: "2-digit", day: "2-digit", hour: "2-digit", hourCycle: "h23" }).formatToParts(data);
  const valor = (tipo: string) => partes.find((parte) => parte.type === tipo)?.value ?? "0";
  return { ano: Number(valor("year")), mes: Number(valor("month")), dia: Number(valor("day")), hora: Number(valor("hour")) };
}
function janelaBrasilia(ano: number, mes: number, dia: number, hora: number): Date {
  return new Date(Date.UTC(ano, mes - 1, dia, hora + 3));
}
function agendamentoLivelo(dados: ResumoLiveloPersistido, agora: Date) {
  const brasilia = partesBrasilia(agora);
  const janelas = HORARIOS_LIVELO.map((hora) => janelaBrasilia(brasilia.ano, brasilia.mes, brasilia.dia, hora));
  const sucesso = instante(dados.ultimo_sucesso_em);
  const pendente = janelas.find((janela) => janela <= agora && (sucesso === null || sucesso < janela));
  if (pendente) return { estado: "aguardando" as const, referencia_em: pendente.toISOString() };
  const proxima = janelas.find((janela) => janela > agora);
  if (proxima) return { estado: "prevista" as const, referencia_em: proxima.toISOString() };
  const amanha = new Date(Date.UTC(brasilia.ano, brasilia.mes - 1, brasilia.dia + 1));
  return { estado: "prevista" as const, referencia_em: janelaBrasilia(amanha.getUTCFullYear(), amanha.getUTCMonth() + 1, amanha.getUTCDate(), 9).toISOString() };
}

function atividadeRecente(
  livelo: ResumoInicio["livelo"],
  cashback: ResumoInicio["cashback_inter"],
  produtos: ResumoInicio["produtos"],
): AtividadeRecente[] {
  const atividade: AtividadeRecente[] = [
    { dominio: "livelo", estado: livelo.estado, momento: livelo.ultimo_sucesso_em },
    { dominio: "cashback_inter", estado: cashback.estado, momento: cashback.ultima_tentativa_em ?? cashback.ultimo_sucesso_em },
    { dominio: "produtos_inter", estado: produtos.estado, momento: produtos.ultima_tentativa_em ?? produtos.dados_mais_recentes_em },
  ];
  return atividade.sort((a, b) => {
    const diferenca = (instante(b.momento) ?? -Infinity) - (instante(a.momento) ?? -Infinity);
    return diferenca || a.dominio.localeCompare(b.dominio);
  });
}

function estadoCashback(
  dados: ResumoCashbackInterPersistido,
  agora: Date,
): EstadoCashbackResumo {
  if (
    dados.ultima_tentativa_estado === "iniciada" &&
    tentativaPosterior(dados.ultima_tentativa_em, dados.ultimo_sucesso_em)
  ) {
    return "atualizando";
  }
  if (
    dados.ultima_tentativa_estado === "falha" &&
    tentativaPosterior(dados.ultima_tentativa_em, dados.ultimo_sucesso_em)
  ) {
    return "falha_recente";
  }
  if (!dados.ultimo_sucesso_em) return "sem_dados";
  return atrasado(dados.ultimo_sucesso_em, agora, LIMITE_CASHBACK_MS)
    ? "atrasado"
    : "atualizado";
}

function estadoProdutos(dados: ResumoProdutosPersistido, agora: Date): EstadoProdutosResumo {
  if (dados.ultima_tentativa_estado === "iniciada") return "atualizando";
  if (dados.ultima_tentativa_estado === "parcial") return "parcial";
  if (dados.ultima_tentativa_estado === "falha") return "falha_recente";
  if (dados.lojas_selecionadas === 0 || !dados.dados_mais_recentes_em) return "sem_dados";
  if (dados.lojas_sem_coleta > 0) return "parcial";
  if (dados.qualidade === "degradada") return "degradado";
  return atrasado(dados.dados_mais_antigos_em, agora, LIMITE_PRODUTOS_MS)
    ? "atrasado"
    : "atualizado";
}

const liveloIndisponivel: ResumoInicio["livelo"] = {
  estado: "indisponivel",
  ultimo_sucesso_em: null,
  lojas_acompanhadas: 0,
  alertas_ultima_coleta: 0,
  agendamento: { estado: "prevista", referencia_em: "" },
};
const cashbackIndisponivel: ResumoInicio["cashback_inter"] = {
  estado: "indisponivel",
  ultima_tentativa_em: null,
  ultima_tentativa_estado: null,
  ultimo_sucesso_em: null,
  lojas_acompanhadas: 0,
  lojas_encontradas_ultima_coleta: 0,
};
const produtosIndisponivel: ResumoInicio["produtos"] = {
  estado: "indisponivel",
  ultima_tentativa_em: null,
  ultima_tentativa_estado: null,
  dados_mais_antigos_em: null,
  dados_mais_recentes_em: null,
  qualidade: null,
  lojas_selecionadas: 0,
  lojas_sem_coleta: 0,
  produtos_ativos: 0,
};

export async function carregarResumoInicio(
  deps: DependenciasResumoInicio = dependenciasPadrao,
  agora = new Date(),
): Promise<ResumoInicio> {
  const [liveloLido, cashbackLido, produtosLidos] = await Promise.allSettled([
    deps.livelo(),
    deps.cashbackInter(),
    deps.produtos(),
  ]);

  const livelo: ResumoInicio["livelo"] =
    liveloLido.status === "fulfilled"
      ? { ...liveloLido.value, estado: estadoLivelo(liveloLido.value, agora), agendamento: agendamentoLivelo(liveloLido.value, agora) }
      : { ...liveloIndisponivel, agendamento: agendamentoLivelo(liveloIndisponivel, agora) };
  const cashback: ResumoInicio["cashback_inter"] =
    cashbackLido.status === "fulfilled"
      ? { ...cashbackLido.value, estado: estadoCashback(cashbackLido.value, agora) }
      : cashbackIndisponivel;
  const produtos: ResumoInicio["produtos"] =
    produtosLidos.status === "fulfilled"
      ? { ...produtosLidos.value, estado: estadoProdutos(produtosLidos.value, agora) }
      : produtosIndisponivel;

  const estados = [livelo.estado, cashback.estado, produtos.estado];
  const estadoGeral: EstadoGeralResumo = estados.every((estado) => estado === "atualizado")
    ? "atualizado"
    : estados.every((estado) => estado === "sem_dados")
      ? "sem_dados"
      : estados.every((estado) => estado === "indisponivel")
        ? "indisponivel"
        : "atencao";

  return {
    gerado_em: agora.toISOString(),
    estado_geral: estadoGeral,
    livelo,
    cashback_inter: cashback,
    produtos,
    atividade_recente: atividadeRecente(livelo, cashback, produtos),
  };
}
