import { afterEach, describe, expect, it, vi } from "vitest";

import { dispararRobo } from "@/lib/github";

describe("dispararRobo", () => {
  afterEach(() => {
    delete process.env.GITHUB_TOKEN_DISPARO;
    vi.unstubAllGlobals();
  });

  it("dispara a coleta Livelo sem inputs obsoletos", async () => {
    process.env.GITHUB_TOKEN_DISPARO = "token-de-teste";
    const requisicao = vi.fn().mockResolvedValue({ status: 204 });
    vi.stubGlobal("fetch", requisicao);

    await expect(dispararRobo()).resolves.toEqual({ ok: true });

    const [url, opcoes] = requisicao.mock.calls[0];
    expect(url).toContain("/actions/workflows/robo.yml/dispatches");
    expect(JSON.parse(opcoes.body)).toEqual({ ref: "main" });
  });
});
