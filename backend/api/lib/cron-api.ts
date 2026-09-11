import { randomUUID, timingSafeEqual } from "node:crypto";

function tokenBearer(cabecalho: string | null): string | null {
  if (!cabecalho) return null;
  const partes = cabecalho.trim().split(/\s+/);
  return partes.length === 2 && partes[0].toLowerCase() === "bearer" && partes[1]
    ? partes[1]
    : null;
}

/** Retorna o segredo somente para a comparação; nunca para resposta ou log. */
export function segredoOutboxConfigurado(valor = process.env.OUTBOX_CRON_SECRET): string | null {
  return valor && valor.length > 0 ? valor : null;
}

export function autorizacaoOutboxValida(
  cabecalho: string | null,
  segredo: string | null = segredoOutboxConfigurado(),
): boolean {
  const recebido = tokenBearer(cabecalho);
  if (!recebido || !segredo) return false;
  const bytesRecebidos = Buffer.from(recebido, "utf8");
  const bytesEsperados = Buffer.from(segredo, "utf8");
  return bytesRecebidos.length === bytesEsperados.length
    && timingSafeEqual(bytesRecebidos, bytesEsperados);
}

export function idRequisicaoCron(requisicao: Request): string {
  const recebido = requisicao.headers.get("x-request-id")?.trim();
  return recebido && /^[a-zA-Z0-9._-]{1,100}$/.test(recebido) ? recebido : randomUUID();
}
