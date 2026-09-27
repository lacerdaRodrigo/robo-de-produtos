import { NextRequest } from "next/server";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

describe("portão de origem da API", () => {
  beforeEach(() => {
    vi.resetModules();
    vi.stubEnv("ALLOWED_ORIGINS", "https://app.example.com");
    vi.stubEnv("NODE_ENV", "test");
  });

  afterEach(() => {
    vi.unstubAllEnvs();
  });

  it("permite navegador listado e devolve CORS explícito", async () => {
    const { proxy } = await import("../proxy");
    const requisicao = new NextRequest("https://api.example.com/api/status", {
      headers: { origin: "https://app.example.com" },
    });

    const resposta = proxy(requisicao);

    expect(resposta?.status).toBe(200);
    expect(resposta?.headers.get("Access-Control-Allow-Origin")).toBe(
      "https://app.example.com",
    );
    expect(resposta?.headers.get("Vary")).toBe("Origin");
  });

  it("nega origem de navegador fora da allowlist antes da rota", async () => {
    const { proxy } = await import("../proxy");
    const requisicao = new NextRequest("https://api.example.com/api/status", {
      headers: { origin: "https://attacker.example" },
    });

    expect(proxy(requisicao)?.status).toBe(403);
  });

  it("aceita cliente nativo sem Origin e responde preflight permitido", async () => {
    const { proxy } = await import("../proxy");
    const semOrigem = new NextRequest("https://api.example.com/api/status");
    const preflight = new NextRequest("https://api.example.com/api/status", {
      method: "OPTIONS",
      headers: { origin: "https://app.example.com" },
    });

    expect(proxy(semOrigem)?.status).toBe(200);
    expect(proxy(preflight)?.status).toBe(204);
    expect(proxy(preflight)?.headers.get("Access-Control-Allow-Origin")).toBe(
      "https://app.example.com",
    );
  });

  it("redireciona para HTTPS no ambiente de produção", async () => {
    vi.stubEnv("NODE_ENV", "production");
    const { proxy } = await import("../proxy");
    const requisicao = new NextRequest("http://api.example.com/api/status", {
      headers: {
        origin: "https://app.example.com",
        "x-forwarded-proto": "http",
      },
    });

    const resposta = proxy(requisicao);

    expect(resposta?.status).toBe(307);
    expect(resposta?.headers.get("location")).toBe(
      "https://api.example.com/api/status",
    );
  });
});
