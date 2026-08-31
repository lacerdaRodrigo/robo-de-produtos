# `.github/` — Automação e CI

Workflows de **GitHub Actions** que automatizam coleta, testes, publicação e o
app Flutter. Segredos ficam em **Settings → Secrets and variables → Actions** —
nunca em arquivo versionado.

## Workflows

| Workflow | O que faz | Agenda | Segredos que usa |
|---|---|---|---|
| [`robo.yml`](workflows/robo.yml) | Coleta Livelo e publica catálogo/retrato | 09h/14h/20h + manual | `DATABASE_URL` |
| [`inter.yml`](workflows/inter.yml) | Roda o coletor de cashback do Shopping Inter | 09h/14h/20h + manual | `DATABASE_URL`, `LIMIAR_LOJAS_INTER` |
| [`produtos-inter.yml`](workflows/produtos-inter.yml) | Coleta produtos do Compre direto (lojas selecionadas) | 09h30/14h30/20h30 + manual | `DATABASE_URL` |
| [`testes.yml`](workflows/testes.yml) | CI de robôs/API: Ruff, Pytest, TypeScript, ESLint e Vitest | a cada push/PR | nenhum |
| [`versao.yml`](workflows/versao.yml) | Semantic-release: bump, CHANGELOG, tag e Release | na `main` | `GITHUB_TOKEN` |
| [`app-robo.yml`](workflows/app-robo.yml) | CI mobile: format, analyze e unitários/widgets permitidos | a cada push/PR | nenhum |

O CI do app não executa Web, golden, integration, E2E ou smoke e não faz deploy.
Os workflows de coleta permanecem separados do workflow de validação Flutter.

## Permissões

- Todos os workflows usam `contents: read`; só `versao.yml` usa `write` (é
  necessário para criar tag e release).
- Nenhum robô grava no repositório.
