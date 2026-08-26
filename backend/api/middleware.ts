import { NextRequest, NextResponse } from "next/server";

/**
 * Portão de origem na borda do servidor.
 *
 * A API autentica toda rota de dado, mas um browser malicioso ainda poderia
 * acionar endpoints só com token e o browser coopera. Aqui fechamos origem:
 * - Requisição com cabeçalho `Origin`: precisa estar na allowlist, senão 403.
 * - Sem `Origin` (APK/celular nativo, curl, CI): passa — a autenticação
 *   (Firebase + App Check) cuida. É o modelo esperado de cliente nativo.
 * - Pré-flight CORS (OPTIONS) só devolve permissão para origem listada.
 *
 * A allowlist vem de `ALLOWED_ORIGINS` (lista separada por vírgula). Usar
 * exatamente o Origin do Flutter Web publicado.
 */
const ORIGENS_PERMITIDAS = (process.env.ALLOWED_ORIGINS ?? "")
  .split(",")
  .map((o) => o.trim())
  .filter(Boolean);

function origemPermitida(origem: string | null): boolean {
  if (!origem) return true; // cliente nativo / sem navegador
  return ORIGENS_PERMITIDAS.includes(origem);
}

function respostaCors(origem: string): NextResponse {
  const resposta = new NextResponse(null, { status: 204 });
  resposta.headers.set("Access-Control-Allow-Origin", origem);
  resposta.headers.set("Vary", "Origin");
  resposta.headers.set("Access-Control-Allow-Methods", "GET, POST, PATCH, DELETE, OPTIONS");
  resposta.headers.set("Access-Control-Allow-Headers", "Authorization, Content-Type, Idempotency-Key, x-firebase-appcheck");
  resposta.headers.set("Access-Control-Max-Age", "86400");
  return resposta;
}

export function middleware(requisicao: NextRequest): NextResponse | undefined {
  // HTTPS obrigatório em produção (no Vercel já é; por segurança explícita).
  if (
    process.env.NODE_ENV === "production" &&
    requisicao.headers.get("x-forwarded-proto") !== "https"
  ) {
    const url = requisicao.nextUrl.clone();
    url.protocol = "https";
    return NextResponse.redirect(url);
  }

  const origem = requisicao.headers.get("origin");

  if (requisicao.method === "OPTIONS") {
    if (origem && origemPermitida(origem)) {
      return respostaCors(origem);
    }
    return new NextResponse(null, { status: 204 });
  }

  if (!origemPermitida(origem)) {
    // Origem de navegador fora da lista: nega antes de tocar a rota.
    return new NextResponse(null, { status: 403 });
  }

  const resposta = NextResponse.next();
  if (origem) {
    resposta.headers.set("Access-Control-Allow-Origin", origem);
    resposta.headers.set("Vary", "Origin");
  }
  return resposta;
}

export const config = {
  matcher: "/api/:path*",
};