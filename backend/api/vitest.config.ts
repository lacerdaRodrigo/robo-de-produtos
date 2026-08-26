import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    include: ["**/*.teste.ts"],
    environment: "node",
  },
  resolve: {
    alias: {
      "@": new URL("./", import.meta.url).pathname,
    },
  },
});