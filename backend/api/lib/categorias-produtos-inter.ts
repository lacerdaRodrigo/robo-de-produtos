export type ValidacaoSelecaoCategorias =
  | {
      ok: true;
      valor: { categorias: string[]; sem_categoria: boolean };
    }
  | { ok: false; mensagem: string };

const MAXIMO_CATEGORIAS = 2_000;
const MAXIMO_TEXTO_CATEGORIA = 500;

export function validarSelecaoCategoriasProdutosInter(
  corpo: unknown,
): ValidacaoSelecaoCategorias {
  if (!corpo || typeof corpo !== "object" || Array.isArray(corpo)) {
    return { ok: false, mensagem: "corpo da requisicao invalido" };
  }

  const objeto = corpo as {
    categorias?: unknown;
    sem_categoria?: unknown;
  };
  const categorias = objeto.categorias;
  if (!Array.isArray(categorias)) {
    return { ok: false, mensagem: "categorias deve ser uma lista" };
  }
  if (categorias.length > MAXIMO_CATEGORIAS) {
    return {
      ok: false,
      mensagem: `categorias deve conter no maximo ${MAXIMO_CATEGORIAS} itens`,
    };
  }
  if (
    categorias.some(
      (categoria) =>
        typeof categoria !== "string" ||
        categoria.length === 0 ||
        categoria.length > MAXIMO_TEXTO_CATEGORIA ||
        categoria !== categoria.trim(),
    )
  ) {
    return { ok: false, mensagem: "categorias contem valor externo invalido" };
  }

  if (
    objeto.sem_categoria !== undefined &&
    typeof objeto.sem_categoria !== "boolean"
  ) {
    return { ok: false, mensagem: "sem_categoria deve ser booleano" };
  }

  return {
    ok: true,
    valor: {
      categorias: [...new Set(categorias as string[])],
      sem_categoria: objeto.sem_categoria === true,
    },
  };
}
