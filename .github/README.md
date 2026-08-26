# `.github/` — Automação e CI

Workflows de **GitHub Actions** que automatizam coleta, testes, publicação e o
app Flutter. Segredos ficam em **Settings → Secrets and variables → Actions** —
nunca em arquivo versionado.

## Workflows

| Workflow | O que faz | Agenda | Segredos que usa |
|---|---|---|---|
| [`robo.yml`](workflows/robo.yml) | Roda o robô Livelo (alerta + e-mail) | 09h/14h/20h + manual | `EMAIL_REMETENTE`, `SENHA_APP_GMAIL`, `EMAIL_DESTINO`, `DATABASE_URL` |
| [`inter.yml`](workflows/inter.yml) | Roda o coletor de cashback do Shopping Inter | 09h/14h/20h + manual | `DATABASE_URL`, `LIMIAR_LOJAS_INTER` |
| [`produtos-inter.yml`](workflows/produtos-inter.yml) | Coleta produtos do Compre direto (lojas selecionadas) | 09h30/14h30/20h30 + manual | `DATABASE_URL` |
| [`testes.yml`](workflows/testes.yml) | CI: Ruff + Pytest (≥90%) + testes do app Flutter | a cada push/PR | nenhum |
| [`versao.yml`](workflows/versao.yml) | Semantic-release: bump, CHANGELOG, tag e Release | na `main` | `GITHUB_TOKEN` |
| [`app-robo.yml`](workflows/app-robo.yml) | CI do Flutter (analyze, format, test, build web) | a cada push/PR | nenhum |

> **Nota:** os coletores rodam `python -m robo_livelo.*` a partir da raiz. Com o
> pacote agora em `backend/robo/src/`, reativar a coleta exige ajustar o diretório
> de trabalho (`cd backend/robo && pip install -e .`) e o caminho
> `config/lojas_favoritas.toml` em `principal.py`.

## Permissões

- Todos os workflows usam `contents: read`; só `versao.yml` usa `write` (é
  necessário para criar tag e release).
- Nenhum robô grava no repositório.
