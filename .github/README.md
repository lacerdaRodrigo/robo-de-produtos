# `.github/` — Automação e CI

Workflows de **GitHub Actions** que automatizam coleta, testes, publicação e o
app Flutter. Segredos ficam em **Settings → Secrets and variables → Actions** —
nunca em arquivo versionado.

## Workflows

| Workflow | O que faz | Agenda | Segredos que usa |
|---|---|---|---|
| [`robo.yml`](workflows/robo.yml) | Coleta Livelo e publica catálogo/retrato | 09h10/14h10/20h10 + manual | `DATABASE_URL` |
| [`inter.yml`](workflows/inter.yml) | Atualiza cashback, sincroniza as lojas e coleta os produtos selecionados do Shopping Inter | 10h30/15h30/21h30 + botão do app | `DATABASE_URL`, `LIMIAR_LOJAS_INTER` |
| [`pichau.yml`](workflows/pichau.yml) | Enfileira a coleta PC Gamer no executor Android e aguarda a publicação | 09h30/14h30/20h30 + manual | `PICHAU_DISPATCH_DATABASE_URL` ou `DATABASE_URL` |
| [`testes.yml`](workflows/testes.yml) | CI de robôs/API: Ruff, Pytest, TypeScript, ESLint e Vitest | a cada push/PR | nenhum |
| [`versao.yml`](workflows/versao.yml) | Semantic-release: bump, CHANGELOG, tag e Release | na `main` | `GITHUB_TOKEN` |
| [`app-robo.yml`](workflows/app-robo.yml) | CI mobile; na `main` aprovada, gera APK debug e envia cópia privada ao Drive com aviso por e-mail | a cada push/PR; distribuição na `main` ou manual | `GOOGLE_DRIVE_OAUTH_CLIENT_JSON`, `GOOGLE_DRIVE_REFRESH_TOKEN`, `GOOGLE_DRIVE_FOLDER_ID`, `EMAIL_DESTINO`, `EMAIL_REMETENTE`, `SENHA_APP_GMAIL` |

O CI do app não executa Web, integration, E2E ou smoke. Pull requests apenas
validam; a distribuição de APK acontece somente após push humano na `main` ou
por disparo manual explícito. A APK não é publicada como artifact do GitHub,
porque o repositório é público: ela vai para uma pasta privada do Drive e o
e-mail contém somente o link autorizado. Essa distribuição não é homologação;
o app aponta para a API atual de produção.
Os workflows de coleta permanecem separados do workflow de validação Flutter.
O contrato vigente desse fluxo está em
[`docs/prd/PRD-DISTRIBUICAO-ANDROID.md`](../docs/prd/PRD-DISTRIBUICAO-ANDROID.md);
os itens que dependem de confirmação externa continuam em `docs/PENDENCIAS.md`.

## Permissões

- Todos os workflows usam `contents: read`; só `versao.yml` usa `write` (é
  necessário para criar tag e release).
- Nenhum robô grava no repositório.
- O workflow Pichau não acessa o telefone diretamente: grava uma solicitação
  idempotente com o commit disparador na fila Postgres e aguarda o worker
  Termux. Antes da coleta, o worker atualiza o checkout por fast-forward e
  confirma que contém aquele commit; divergência falha como `pichau-checkout`.
  O telefone usa o remoto Git já configurado, não recebe token do workflow nem
  expõe porta pública.
- O robô Pichau usa somente páginas públicas autorizadas, limita-se a 300
  páginas por execução, preserva as validações de catálogo e não persiste
  imagens, HTML ou cookies.
