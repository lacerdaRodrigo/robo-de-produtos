import { afterEach, describe, expect, it, vi } from "vitest";

describe("carregamento do Firebase Admin", () => {
  afterEach(() => {
    vi.doUnmock("firebase-admin/app-check");
    vi.resetModules();
  });

  it("nao carrega App Check antes de o rollout pedir a verificacao", async () => {
    vi.resetModules();
    vi.doMock("firebase-admin/app-check", () => {
      throw new Error("App Check foi carregado cedo demais");
    });

    const modulo = await import("../lib/firebase-admin");

    expect(modulo.verificarIdToken).toBeTypeOf("function");
    await expect(modulo.verificarTokenAppCheck("token")).rejects.toThrow();
  });
});
