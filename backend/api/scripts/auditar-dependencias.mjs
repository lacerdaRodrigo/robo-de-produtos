import { readFileSync } from "node:fs";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";

const advisoryUrl =
  "https://github.com/advisories/GHSA-vfj7-8cjw-p6xm";
const allowedChain = {
  braces: { advisory: true },
  micromatch: { dependency: "braces" },
  "fast-glob": { dependency: "micromatch" },
  "@next/eslint-plugin-next": { dependency: "fast-glob" },
  "eslint-config-next": { dependency: "@next/eslint-plugin-next" },
};

function fail(message, details = "") {
  console.error(`Auditoria de dependencias reprovada: ${message}`);
  if (details) console.error(details);
  process.exit(1);
}

const apiDirectory = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const audit = spawnSync("npm", ["audit", "--audit-level=high", "--json"], {
  cwd: apiDirectory,
  encoding: "utf8",
  maxBuffer: 10 * 1024 * 1024,
});

if (audit.error) fail("não foi possível executar npm audit", audit.error.message);

let report;
try {
  report = JSON.parse(audit.stdout);
} catch {
  fail("npm audit não retornou JSON válido", audit.stderr || audit.stdout);
}

const vulnerabilities = report.vulnerabilities;
if (!vulnerabilities || typeof vulnerabilities !== "object") {
  fail("relatório npm audit sem a lista de vulnerabilidades", audit.stderr);
}

const allFindings = Object.entries(vulnerabilities);
const blockingFindings = allFindings.filter(([, finding]) =>
  ["high", "critical"].includes(finding.severity),
);
if (blockingFindings.length === 0 && audit.status === 0) {
  console.log("Auditoria completa aprovada: nenhum alerta alto ou crítico.");
  const lowerFindings = allFindings.filter(([, finding]) =>
    !["high", "critical"].includes(finding.severity),
  );
  if (lowerFindings.length > 0) {
    console.warn(
      `Alertas abaixo do limite bloqueante: ${lowerFindings
        .map(([name, finding]) => `${name} (${finding.severity})`)
        .join(", ")}`,
    );
  }
  process.exit(0);
}

if (audit.status !== 1) {
  fail(`npm audit terminou com código inesperado ${audit.status}`, audit.stderr);
}

const names = blockingFindings.map(([name]) => name);
const expectedNames = Object.keys(allowedChain);
if (
  names.length !== expectedNames.length ||
  expectedNames.some((name) => !names.includes(name))
) {
  fail(
    "há alertas além da exceção temporária documentada",
    JSON.stringify(vulnerabilities, null, 2),
  );
}

const lockPath = resolve(apiDirectory, "package-lock.json");
let lock;
try {
  lock = JSON.parse(readFileSync(lockPath, "utf8"));
} catch (error) {
  fail("não foi possível ler package-lock.json", error.message);
}

for (const name of expectedNames) {
  const vulnerability = vulnerabilities[name];
  if (!["high", "critical"].includes(vulnerability.severity)) {
    fail(`${name} não consta como alerta alto ou crítico`);
  }

  const pathEntry = lock.packages?.[`node_modules/${name}`];
  if (!pathEntry || pathEntry.dev !== true) {
    fail(`${name} não está confirmado como dependência de desenvolvimento`);
  }

  const via = vulnerability.via;
  const expected = allowedChain[name];
  if (!Array.isArray(via) || via.length !== 1) {
    fail(`${name} tem uma cadeia de alertas diferente da exceção aprovada`);
  }

  if (expected.advisory) {
    if (typeof via[0] !== "object" || via[0].url !== advisoryUrl) {
      fail(`${name} não corresponde ao advisory temporário documentado`);
    }
  } else if (via[0] !== expected.dependency) {
    fail(`${name} não segue a cadeia de dependências documentada`);
  }
}

console.warn(
  "Auditoria completa: exceção temporária aplicada somente ao GHSA-vfj7-8cjw-p6xm na cadeia de lint de desenvolvimento:",
);
console.warn(`  ${expectedNames.join(" -> ")}`);
console.warn(
  "Todos os outros alertas altos/críticos, caminhos ou dependências fora de dev continuam bloqueando o CI.",
);
