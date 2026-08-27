# `.github/` — Automação e CI

Workflows de **GitHub Actions** que automatizam coleta, testes, publicação e o
app Flutter. Segredos ficam em **Settings → Secrets and variables → Actions** —
nunca em arquivo versionado.

## Workflows

| Workflow | O que faz | Agenda | Segredos que usa |
|---|---|---|---|
| [`robo.yml`](workflows/robo.yml) | Roda o robô Livelo (alerta + retrato) | 09h/14h/20h + manual | `DATABASE_URL` |
| [`inter.yml`](workflows/inter.yml) | Roda o coletor de cashback do Shopping Inter | 09h/14h/20h + manual | `DATABASE_URL`, `LIMIAR_LOJAS_INTER` |
| [`produtos-inter.yml`](workflows/produtos-inter.yml) | Coleta produtos do Compre direto (lojas selecionadas) | 09h30/14h30/20h30 + manual | `DATABASE_URL` |
| [`testes.yml`](workflows/testes.yml) | CI dos robôs e da API: Ruff, Pytest, TypeScript, ESLint, Vitest e build | a cada push/PR | nenhum |
| [`versao.yml`](workflows/versao.yml) | Semantic-release: bump, CHANGELOG, tag e Release | na `main` | `GITHUB_TOKEN` |
| [`app-robo.yml`](workflows/app-robo.yml) | CI do Flutter (analyze, format, test, build web) | a cada push/PR | nenhum |

Os coletores e os respectivos caches já usam `backend/robo` como diretório de
trabalho. A API usa Node 22 e executa seus gates a partir de `backend/api`.

## Permissões

- Todos os workflows usam `contents: read`; só `versao.yml` usa `write` (é
  necessário para criar tag e release).
- Nenhum robô grava no repositório.
