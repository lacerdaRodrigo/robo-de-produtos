/** @type {import('next').NextConfig} */
const nextConfig = {
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
