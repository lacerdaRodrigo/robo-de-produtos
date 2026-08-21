/** @type {import('next').NextConfig} */
const nextConfig = {
  // O Next externaliza firebase-admin por padrao. Na Vercel, esse caminho tenta
  // carregar `jose` (ESM) via `require()` dentro de jwks-rsa (CommonJS) e a
  // funcao cai antes de validar o token. Empacotar a cadeia preserva o interop
  // ESM/CJS do Turbopack.
  transpilePackages: ["firebase-admin", "jwks-rsa", "jose"],
  // A Content-Security-Policy nao mora aqui: ela precisa de um nonce por
  // requisicao, e cabecalho estatico nao consegue isso. Ver proxy.ts.
  poweredByHeader: false,
  headers: async () => [
    {
      source: "/:caminho*",
      headers: [
        { key: "Referrer-Policy", value: "no-referrer" },
        { key: "X-Content-Type-Options", value: "nosniff" },
      ],
    },
  ],
};

export default nextConfig;
