/** @type {import('next').NextConfig} */
const nextConfig = {
  // RNF15: a pagina nao carrega recurso de terceiro. Sem otimizador de
  // imagem porque nao existe imagem — a identidade visual e cor e tipo do
  // sistema (PRD-V2 9.2).
  poweredByHeader: false,
  headers: async () => [
    {
      source: "/:caminho*",
      headers: [
        // Sem script externo, sem frame, sem envio de referer para fora.
        {
          key: "Content-Security-Policy",
          value:
            "default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; " +
            "script-src 'self'; frame-ancestors 'none'; base-uri 'self'; form-action 'self'",
        },
        { key: "Referrer-Policy", value: "no-referrer" },
        { key: "X-Content-Type-Options", value: "nosniff" },
      ],
    },
  ],
};

export default nextConfig;
