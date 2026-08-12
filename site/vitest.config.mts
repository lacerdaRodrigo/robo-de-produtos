import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    // Mesma convencao do robo: arquivo de teste em portugues, com `teste` no
    // nome em vez do `test` que a ferramenta usa por padrao.
    include: ["testes/**/*.teste.ts"],
  },
});
