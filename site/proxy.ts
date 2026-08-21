import { NextResponse, type NextRequest } from "next/server";

/**
 * Content-Security-Policy com nonce por requisicao.
 *
 * A versao anterior desta politica declarava `script-src 'self'` e quebrou a
 * pagina inteira em producao: o Next embute o payload de dados em `<script>`
 * inline, o navegador recusou os 43 scripts inline, o React encontrou um
 * stream vazio e apagou o HTML que o servidor tinha mandado certo. Com
 * JavaScript desligado a pagina funcionava; ligado, ficava em branco.
 *
 * O nonce e a forma de manter a politica estrita sem liberar `unsafe-inline`:
 * o Next assina os proprios scripts com ele, e `strict-dynamic` estende a
 * permissao aos pedacos que esses scripts carregam. O custo esta registrado
 * no PRD-V2 §9.2: nonce muda a cada requisicao, entao a pagina passa a ser
 * renderizada a cada visita em vez de servida do cache.
 */
export function proxy(requisicao: NextRequest) {
  const nonce = Buffer.from(crypto.randomUUID()).toString("base64");

  const politica = [
    "default-src 'self'",
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,
    // RN25: nenhuma fonte, imagem ou folha de estilo de terceiro. O
    // `unsafe-inline` de estilo cobre os `style=` dos componentes, que nao
    // executam codigo.
    "style-src 'self' 'unsafe-inline'",
    "img-src 'self' data:",
    "font-src 'self'",
    "connect-src 'self'",
    "frame-ancestors 'none'",
    "base-uri 'self'",
    "form-action 'self'",
  ].join("; ");

  const cabecalhos = new Headers(requisicao.headers);
  cabecalhos.set("x-nonce", nonce);
  cabecalhos.set("Content-Security-Policy", politica);

  const resposta = NextResponse.next({ request: { headers: cabecalhos } });
  resposta.headers.set("Content-Security-Policy", politica);
  return resposta;
}

export const config = {
  matcher: [
    // Tudo, menos o que a propria Vercel serve estaticamente — arquivo
    // estatico nao executa script e nao precisa de nonce.
    {
      source: "/((?!_next/static|_next/image|favicon.ico).*)",
      missing: [
        { type: "header", key: "next-router-prefetch" },
        { type: "header", key: "purpose", value: "prefetch" },
      ],
    },
  ],
};
