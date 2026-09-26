# `.github/` — Automação e CI

Workflows de **GitHub Actions** que automatizam coleta, testes, publicação e o
app Flutter. Segredos ficam em **Settings → Secrets and variables → Actions** —
nunca em arquivo versionado.

## Workflows

| Workflow | O que faz | Agenda | Segredos que usa |
|---|---|---|---|
| [`robo.yml`](workflows/robo.yml) | Enfileira disparo manual Livelo; não executa coleta | Manual | `ROBO_DISPATCH_DATABASE_URL` |
| [`inter.yml`](workflows/inter.yml) | Enfileira disparo manual Inter; não executa coleta | Manual | `ROBO_DISPATCH_DATABASE_URL` |
| [`pichau.yml`](workflows/pichau.yml) | Enfileira disparo manual Pichau; não espera o telefone | Manual | `PICHAU_DISPATCH_DATABASE_URL` |
| [`testes.yml`](workflows/testes.yml) | CI de robôs/API: Ruff, Pytest, TypeScript, ESLint e Vitest | a cada push/PR | nenhum |
| [`versao.yml`](workflows/versao.yml) | Semantic-release: bump, CHANGELOG, tag e Release | na `main` | `GITHUB_TOKEN` |
| [`app-robo.yml`](workflows/app-robo.yml) | CI mobile somente quando `app/**` muda; na `main`, gera APK debug e envia cópia privada ao Drive com aviso por e-mail | mudança em `app/**`; distribuição na `main` ou manual | `GOOGLE_DRIVE_OAUTH_CLIENT_JSON`, `GOOGLE_DRIVE_REFRESH_TOKEN`, `GOOGLE_DRIVE_FOLDER_ID`, `EMAIL_DESTINO`, `EMAIL_REMETENTE`, `SENHA_APP_GMAIL` |
| [`notificacoes-outbox.yml`](workflows/notificacoes-outbox.yml) | Acorda a API para processar a outbox FCM; a API envia pelo Firebase Admin SDK | uma vez por hora + manual | `OUTBOX_CRON_SECRET` |

As agendas Livelo (09:10/14:10/20:10), Pichau (09:30/14:30/20:30) e Inter
(10:30/15:30/21:30), no fuso `America/Sao_Paulo`, rodam no worker do Samsung,
não no GitHub Actions. Os horários e a tolerância de atraso estão no
[`PRD operacional dos coletores`](../docs/prd/PRD-EXECUCAO-COLETORES.md).
Um workflow manual verde confirma apenas que o pedido foi registrado na fila;
o resultado da coleta é assíncrono e deve ser conferido no estado persistido e
nos logs locais. Os botões administrativos da API iniciam `robo.yml` e
`inter.yml` usando o secret de servidor `GITHUB_TOKEN_DISPARO`; o cooldown de
cada domínio continua na API. O disparo Pichau permanece manual pelo Actions.

O CI do app valida Android/iOS somente quando `app/**` muda e não executa
integração, E2E ou smoke. Pull requests apenas validam; a distribuição de APK acontece somente após push humano na `main` ou
por disparo manual explícito. A APK não é publicada como artifact do GitHub,
porque o repositório é público: ela vai para uma pasta privada do Drive e o
e-mail contém somente o link autorizado. Essa distribuição não é homologação;
o app aponta para a API atual de produção.
Os workflows de coleta permanecem separados do workflow de validação Flutter.
O workflow `notificacoes-outbox.yml` não acessa o banco nem o Firebase: chama a
rota interna da API Production com `Authorization: Bearer` e registra somente
contagens operacionais. A mesma variável `OUTBOX_CRON_SECRET` deve existir no
GitHub Actions e na Vercel em `Production`; o valor nunca fica no repositório,
no workflow ou nos logs.
O contrato vigente desse fluxo está em
[`docs/prd/PRD-DISTRIBUICAO-ANDROID.md`](../docs/prd/PRD-DISTRIBUICAO-ANDROID.md);
os itens que dependem de confirmação externa continuam em `docs/PENDENCIAS.md`.

## Permissões

- Todos os workflows usam `contents: read`; só `versao.yml` usa `write` (é
  necessário para criar tag e release).
- O workflow da outbox não se sobrepõe a outra execução e usa retry somente na
  chamada de rede; o envio real continua no Firebase Cloud Messaging através do
  Firebase Admin SDK da API.
- Nenhum robô grava no repositório.
- Nenhum workflow abre conexão com o telefone. Os três workflows de coleta
  registram pedidos idempotentes no Neon e encerram; o worker local lê somente
  execuções manuais concluídas pela API pública do GitHub. O telefone não recebe
  token GitHub nem expõe porta pública.
- `ROBO_DISPATCH_DATABASE_URL` deve pertencer a `radar_actions_robo`,
  `PICHAU_DISPATCH_DATABASE_URL` a `radar_actions_pichau` e a API a
  `radar_api`. O Samsung usa `radar_samsung`, com direitos de publicação dos
  coletores. A migration `032` mantém as filas fora do acesso da API e as
  tabelas pessoais fora do coletor. Os logins ainda ficam `NOLOGIN` até que as
  senhas sejam provisionadas por canal seguro; o banco novo segue vazio e não
  deve receber tráfego antes dos testes de acesso.
- O robô Pichau usa somente páginas públicas autorizadas, limita-se a 300
  páginas por execução, preserva as validações de catálogo e não persiste
  imagens, HTML ou cookies.
