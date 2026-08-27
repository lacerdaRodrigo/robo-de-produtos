import type { NextConfig } from "next";

const config: NextConfig = {
  poweredByHeader: false,
  reactStrictMode: true,
  experimental: {
    // A API usa TypeScript 5, cuja API de compilador e suportada pelo Next.
    // O modo CLI perde a saida de `tsc --showConfig` em Node 24 e encerra o
    // build antes de gerar o artefato, embora o processo devolva codigo zero.
    useTypeScriptCli: false,
  },
  headers: async () => [
    {
      source: "/:path*",
      headers: [
        { key: "X-Content-Type-Options", value: "nosniff" },
        { key: "X-Frame-Options", value: "DENY" },
        { key: "Referrer-Policy", value: "no-referrer" },
        {
          key: "Content-Security-Policy",
          value:
            "default-src 'none'; base-uri 'none'; frame-ancestors 'none'; form-action 'none'",
        },
      ],
    },
  ],
};

export default config;
