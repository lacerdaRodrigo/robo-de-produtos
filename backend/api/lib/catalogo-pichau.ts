import { normalizar } from "./formato";

export const ID_PICHAU_VALIDO = /^[A-Za-z0-9][A-Za-z0-9_-]{0,199}$/;

/** Normalizacao da busca antes de qualquer consulta ao snapshot local. */
export function buscaPichau(q: string): string {
  return normalizar(q).slice(0, 100);
}

export function idPichauValido(id: string): boolean {
  return ID_PICHAU_VALIDO.test(id);
}

export function validarAcompanhamentoPichau(
  corpo: unknown,
): { ok: true; acompanhada: boolean } | { ok: false } {
  if (!corpo || typeof corpo !== "object" || Array.isArray(corpo)) {
    return { ok: false };
  }
  const objeto = corpo as Record<string, unknown>;
  if (Object.keys(objeto).length !== 1 || typeof objeto.acompanhada !== "boolean") {
    return { ok: false };
  }
  return { ok: true, acompanhada: objeto.acompanhada };
}
