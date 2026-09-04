export type ValidacaoSelecaoCategorias =
  | { ok: true; valor: { categorias: string[] } }
  | { ok: false; mensagem: string };

const PADRAO_SLUG = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;
const MAXIMO_CATEGORIAS = 500;

export function validarSelecaoCategoriasProdutosInter(
  corpo: unknown,
): ValidacaoSelecaoCategorias {
  if (!corpo || typeof corpo !== "object" || Array.isArray(corpo)) {
    return { ok: false, mensagem: "corpo da requisicao invalido" };
  }
  const categorias = (corpo as { categorias?: unknown }).categorias;
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
        categoria.length > 120 ||
        !PADRAO_SLUG.test(categoria),
    )
  ) {
    return { ok: false, mensagem: "categorias contem identificador invalido" };
  }
  return {
    ok: true,
    valor: { categorias: [...new Set(categorias as string[])] },
  };
}
