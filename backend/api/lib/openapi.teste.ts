import { readdirSync, readFileSync } from "node:fs";
import { resolve } from "node:path";

import { describe, expect, it } from "vitest";

type Spec = {
  openapi: string;
  paths: Record<string, Record<string, Operation>>;
  components: {
    securitySchemes: Record<string, unknown>;
    schemas: Record<string, unknown>;
  };
};

type Operation = {
  operationId?: string;
  security?: Array<Record<string, string[]>>;
  parameters?: Array<{ name: string; in: string; required?: boolean }>;
  requestBody?: { content?: Record<string, { schema?: unknown }> };
  responses?: Record<string, { description?: string; content?: Record<string, { schema?: unknown }> }>;
};

const spec = JSON.parse(
  readFileSync(resolve(process.cwd(), "../../docs/openapi.json"), "utf8"),
) as Spec;

const operacoesEsperadas: Record<string, string[]> = {
  "/api/status": ["get"],
  "/api/perfil": ["get"],
  "/api/resumo": ["get"],
  "/api/relatos-problema": ["get", "post"],
  "/api/administracao/disparos": ["get", "post"],
  "/api/administracao/limpeza/{dominio}": ["get", "post"],
  "/api/livelo/catalogo": ["get"],
  "/api/livelo/catalogo/{id_externo}/acompanhamento": ["patch"],
  "/api/livelo/catalogo/{id_externo}/acompanhamento-pessoal": ["patch"],
  "/api/livelo/catalogo/{id_externo}/alerta": ["patch"],
  "/api/livelo/catalogo/{id_externo}/historico": ["get"],
  "/api/livelo/lojas": ["get", "post"],
  "/api/livelo/lojas/{id}": ["patch", "delete"],
  "/api/livelo/painel": ["get"],
  "/api/livelo/preferencias": ["get", "patch"],
  "/api/inter/cashback": ["get"],
  "/api/inter/cashback/categorias": ["get"],
  "/api/inter/cashback/{id}/acompanhamento": ["patch"],
  "/api/inter/lojas": ["get", "patch"],
  "/api/inter/lojas/categoria": ["patch"],
  "/api/inter/produtos": ["get"],
  "/api/inter/produtos/categorias": ["get", "patch"],
  "/api/inter/produtos/lojas": ["get", "patch"],
  "/api/inter/produtos/historico": ["get"],
  "/api/inter/produtos/{loja}/{id_externo}/acompanhamento": ["patch"],
  "/api/alertas": ["get", "patch"],
  "/api/alertas/{id}/item": ["get"],
  "/api/alertas/{id}/leitura": ["patch"],
  "/api/alertas/acompanhamentos": ["get", "patch"],
  "/api/alertas/preferencias": ["get", "patch"],
  "/api/notificacoes/dispositivos": ["post", "delete"],
  "/api/notificacoes/outbox": ["post"],
  "/api/cron/notificacoes/outbox": ["post"],
  "/api/pichau/catalogo": ["get"],
  "/api/pichau/catalogo/{id_externo}/historico": ["get"],
  "/api/pichau/catalogo/{id_externo}/acompanhamento": ["patch"],
  "/api/pichau/catalogo/{id_externo}/acompanhamento-pessoal": ["patch"],
};

function rotasDoHandler(diretorio: string): Map<string, string[]> {
  const arquivos: string[] = [];
  const visitarDiretorio = (atual: string): void => {
    for (const entrada of readdirSync(atual, { withFileTypes: true })) {
      const arquivo = resolve(atual, entrada.name);
      if (entrada.isDirectory()) visitarDiretorio(arquivo);
      else if (entrada.name === "route.ts") arquivos.push(arquivo);
    }
  };
  visitarDiretorio(diretorio);

  const rotas = new Map<string, string[]>();
  for (const arquivo of arquivos) {
    const relativo = arquivo.slice(diretorio.length + 1);
    const segmento = relativo.replace(/(^|\/)\[([^\]]+)\](?=\/|$)/g, "$1{$2}");
    const caminho = `/api/${segmento.replace(/\/route\.ts$/, "").replaceAll("\\", "/")}`;
    const fonte = readFileSync(arquivo, "utf8");
    const metodos = [...fonte.matchAll(/export\s+async\s+function\s+(GET|POST|PATCH|DELETE|PUT|OPTIONS|HEAD)\s*\(/g)]
      .map((match) => match[1].toLowerCase())
      .sort();
    rotas.set(caminho, metodos);
  }
  return rotas;
}

function papeisDoHandler(diretorio: string): Map<string, Map<string, string | null>> {
  const arquivos: string[] = [];
  const visitarDiretorio = (atual: string): void => {
    for (const entrada of readdirSync(atual, { withFileTypes: true })) {
      const arquivo = resolve(atual, entrada.name);
      if (entrada.isDirectory()) visitarDiretorio(arquivo);
      else if (entrada.name === "route.ts") arquivos.push(arquivo);
    }
  };
  visitarDiretorio(diretorio);

  const papeis = new Map<string, Map<string, string | null>>();
  const exportacao = /export\s+async\s+function\s+(GET|POST|PATCH|DELETE|PUT|OPTIONS|HEAD)\s*\([^)]*\)\s*\{/g;
  for (const arquivo of arquivos) {
    const relativo = arquivo.slice(diretorio.length + 1);
    const segmento = relativo.replace(/(^|\/)\[([^\]]+)\](?=\/|$)/g, "$1{$2}");
    const caminho = `/api/${segmento.replace(/\/route\.ts$/, "").replaceAll("\\", "/")}`;
    const fonte = readFileSync(arquivo, "utf8");
    const funcoes = [...fonte.matchAll(exportacao)];
    const metodos = new Map<string, string | null>();
    funcoes.forEach((funcao, indice) => {
      const inicio = (funcao.index ?? 0) + funcao[0].length;
      const fim = funcoes[indice + 1]?.index ?? fonte.length;
      const corpo = fonte.slice(inicio, fim);
      const papel = /papel:\s*["']admin["']/.test(corpo)
        ? "admin"
        : /autenticarRequisicao\s*\(/.test(corpo)
          ? "usuario"
          : null;
      metodos.set(funcao[1].toLowerCase(), papel);
    });
    papeis.set(caminho, metodos);
  }
  return papeis;
}

function resolveRef(reference: string): unknown {
  expect(reference.startsWith("#/"), `referência interna esperada: ${reference}`).toBe(true);
  return reference
    .slice(2)
    .split("/")
    .map((segment) => segment.replaceAll("~1", "/").replaceAll("~0", "~"))
    .reduce<unknown>((value, segment) => {
      expect(value).toBeTypeOf("object");
      return (value as Record<string, unknown>)[segment];
    }, spec);
}

const papeisReais = papeisDoHandler(resolve(process.cwd(), "app/api"));

describe("contrato estrutural de docs/openapi.json", () => {
  it("declara OpenAPI 3.1 e exatamente os 37 paths/50 métodos dos handlers", () => {
    expect(spec.openapi).toBe("3.1.0");
    expect(Object.keys(spec.paths).sort()).toEqual(Object.keys(operacoesEsperadas).sort());

    const operacoes = Object.entries(spec.paths).flatMap(([path, item]) =>
      Object.keys(item).map((method) => `${method.toLowerCase()} ${path}`),
    );
    const esperadas = Object.entries(operacoesEsperadas).flatMap(([path, methods]) =>
      methods.map((method) => `${method} ${path}`),
    );
    expect(operacoes.sort()).toEqual(esperadas.sort());
    expect(Object.keys(spec.paths)).toHaveLength(37);
    expect(operacoes).toHaveLength(50);

    const rotasReais = rotasDoHandler(resolve(process.cwd(), "app/api"));
    const inventarioReal = Object.fromEntries(
      [...rotasReais.entries()].sort(([a], [b]) => a.localeCompare(b)),
    );
    const inventarioDocumentado = Object.fromEntries(
      Object.entries(operacoesEsperadas)
        .sort(([a], [b]) => a.localeCompare(b))
        .map(([path, methods]) => [path, [...methods].sort()]),
    );
    expect(inventarioReal).toEqual(inventarioDocumentado);
  });

  it("usa operationIds únicos, respostas e segurança referenciável", () => {
    const autenticacaoApi = readFileSync(resolve(process.cwd(), "lib/autenticacao-api.ts"), "utf8");
    expect(autenticacaoApi).toContain('const papelExigido = opcoes.papel ?? "usuario";');
    expect(autenticacaoApi).toContain('return exigido === "usuario" || atual === "admin";');
    const ids: string[] = [];
    for (const [path, item] of Object.entries(spec.paths)) {
      for (const [method, operation] of Object.entries(item)) {
        expect(operation.operationId, `${method.toUpperCase()} ${path}`).toBeTruthy();
        ids.push(operation.operationId as string);
        expect(operation.responses, `${method.toUpperCase()} ${path} sem responses`).toBeTruthy();
        const success = Object.entries(operation.responses ?? {}).filter(([status]) => /^2\d\d$/.test(status));
        expect(success.length, `${method.toUpperCase()} ${path} sem sucesso 2xx`).toBeGreaterThan(0);
        for (const [status, response] of Object.entries(operation.responses ?? {})) {
          expect(response.description, `${method.toUpperCase()} ${path} resposta ${status}`).toBeTruthy();
          for (const media of Object.values(response.content ?? {})) {
            expect(media.schema, `${method.toUpperCase()} ${path} resposta ${status} sem schema`).toBeTruthy();
          }
        }

        for (const requirement of operation.security ?? []) {
          for (const scheme of Object.keys(requirement)) {
            expect(spec.components.securitySchemes[scheme], `security scheme ${scheme}`).toBeTruthy();
          }
        }
        if (path === "/api/status") {
          expect(operation.security).toEqual([]);
        } else {
          const scheme = path === "/api/cron/notificacoes/outbox" ? "CronBearer" : "FirebaseBearer";
          expect(operation.security).toEqual([{ [scheme]: [] }]);
          if (scheme === "FirebaseBearer") {
            expect(operation.parameters?.some((parameter) =>
              parameter.in === "header" && parameter.name === "x-firebase-appcheck",
            )).toBe(true);
            const papelReal = papeisReais.get(path)?.get(method);
            expect(papelReal, `${method.toUpperCase()} ${path} sem papel detectado no handler`).toBeTruthy();
            expect(operation["x-required-role" as keyof Operation], `${method.toUpperCase()} ${path} papel`).toBe(
              papelReal === "admin" ? "admin" : "usuario; admin também satisfaz este papel",
            );
          }
        }

        const pathNames = [...path.matchAll(/\{([^}]+)\}/g)].map((match) => match[1]);
        const declaredPathNames = (operation.parameters ?? [])
          .filter((parameter) => parameter.in === "path")
          .map((parameter) => parameter.name);
        expect(declaredPathNames.sort(), `${method.toUpperCase()} ${path} path params`).toEqual(pathNames.sort());
        for (const parameter of operation.parameters ?? []) {
          if (parameter.in === "path") expect(parameter.required).toBe(true);
        }
        for (const media of Object.values(operation.requestBody?.content ?? {})) {
          expect(media.schema, `${method.toUpperCase()} ${path} body sem schema`).toBeTruthy();
        }
      }
    }
    expect(new Set(ids).size).toBe(50);
  });

  it("resolve todas as referências JSON Schema internas sem validador externo", () => {
    const referencias: string[] = [];
    const visitar = (value: unknown): void => {
      if (Array.isArray(value)) {
        value.forEach(visitar);
        return;
      }
      if (!value || typeof value !== "object") return;
      const record = value as Record<string, unknown>;
      if (typeof record.$ref === "string") referencias.push(record.$ref);
      Object.values(record).forEach(visitar);
    };
    visitar(spec);
    expect(referencias.length).toBeGreaterThan(0);
    for (const reference of referencias) expect(resolveRef(reference)).toBeTruthy();
  });
});
