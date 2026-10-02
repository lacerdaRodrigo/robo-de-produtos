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
| [`app-robo.yml`](workflows/app-robo.yml) | CI mobile quando `app/**` ou o workflow/helper de distribuição muda; distribuição privada de APK debug para testes | distribuição após push humano na `main` ou execução manual com `distribuir=true` | `GOOGLE_DRIVE_OAUTH_CLIENT_JSON`, `GOOGLE_DRIVE_REFRESH_TOKEN`, `GOOGLE_DRIVE_FOLDER_ID`, `EMAIL_DESTINO`, `EMAIL_REMETENTE`, `SENHA_APP_GMAIL` |
| [`notificacoes-outbox.yml`](workflows/notificacoes-outbox.yml) | Acorda a API para processar a outbox FCM; a API envia pelo Firebase Admin SDK | uma vez por hora + manual | `OUTBOX_CRON_SECRET` |
| [`backup-neon.yml`](workflows/backup-neon.yml) | Faz dump Postgres semanal, cifra localmente com `age` e envia somente o arquivo cifrado a uma pasta privada do Drive | segunda-feira 05:15 UTC + manual | `NEON_BACKUP_DATABASE_URL`, `BACKUP_AGE_RECIPIENT`, `GOOGLE_DRIVE_OAUTH_CLIENT_JSON`, `GOOGLE_DRIVE_REFRESH_TOKEN`, `GOOGLE_DRIVE_BACKUP_FOLDER_ID` |

## Dependências

O Dependabot abre atualizações semanais para npm (`backend/api`), pub
(`app`) e pip (`backend/robo`), e atualizações mensais das GitHub Actions.
Atualizações não são auto-merge: passam pelos gates do CI. O job API executa
`npm audit --audit-level=high`; versões vulneráveis não devem ser silenciadas
com exceções sem justificativa e prazo registrados. Correções transitivas que
caibam nas faixas já declaradas são registradas em
`backend/api/package-lock.json` com `npm audit fix`; alterações de faixas
diretas também atualizam `package.json`.

As agendas Livelo (09:10/14:10/20:10), Pichau (09:30/14:30/20:30) e Inter
(10:30/15:30/21:30), no fuso `America/Sao_Paulo`, rodam no worker do Samsung,
não no GitHub Actions. Os horários e a tolerância de atraso estão no
[`PRD operacional dos coletores`](../docs/prd/PRD-EXECUCAO-COLETORES.md).
Um workflow manual verde confirma apenas que o pedido foi registrado na fila;
o resultado da coleta é assíncrono e deve ser conferido no estado persistido e
nos logs locais. Os botões administrativos da API iniciam `robo.yml` e
`inter.yml` usando o secret de servidor `GITHUB_TOKEN_DISPARO`; o cooldown de
cada domínio continua na API. O disparo Pichau permanece manual pelo Actions.

O CI do app valida Android/iOS quando `app/**` ou o workflow/helper de
distribuição muda e não executa
integração, E2E ou smoke. Pull requests apenas validam; a distribuição privada
de APK debug acontece após push humano na `main` que corresponda a esses paths,
ou disparo manual com
`distribuir=true`. Não precisa de keystore release nem dos secrets de assinatura.
O APK não é publicado como artifact do GitHub, porque o repositório é público:
vai para uma pasta privada do Drive e o e-mail contém somente o link autorizado.
Essa distribuição é para testes e aponta para a API atual de produção com App
Check desativado. A assinatura debug pode variar entre execuções; instalar outra
build pode exigir desinstalar a anterior e apagar os dados locais do app.
Os workflows de coleta permanecem separados do workflow de validação Flutter.
O workflow `notificacoes-outbox.yml` não acessa o banco nem o Firebase: chama a
rota interna da API Production com `Authorization: Bearer` e registra somente
contagens operacionais. A mesma variável `OUTBOX_CRON_SECRET` deve existir no
GitHub Actions e na Vercel em `Production`; o valor nunca fica no repositório,
no workflow ou nos logs.
O contrato vigente desse fluxo está em
[`docs/prd/PRD-DISTRIBUICAO-ANDROID.md`](../docs/prd/PRD-DISTRIBUICAO-ANDROID.md);
os itens que dependem de confirmação externa continuam em `docs/PENDENCIAS.md`.

O backup usa credencial Postgres separada, de leitura, associada ao grupo
`radar_backup`; nunca reutiliza a `DATABASE_URL` da API, Samsung ou Actions.
O dump é comprimido por `pg_dump -Fc`, cifra com a chave pública age e só então
é enviado ao Drive. A chave privada age fica offline, fora do GitHub e do Drive.
A pasta de backup deve ser criada pelo script de bootstrap e não pode ser
compartilhada; arquivos públicos ou com usuários adicionais fazem o job falhar.
O job conserva até 12 backups semanais identificados por propriedades privadas
do aplicativo e não remove APKs nem arquivos sem essa marca. O setup, os
segredos necessários e a restauração em banco descartável estão descritos em
[`docs/prd/PRD-BACKUP-NEON.md`](../docs/prd/PRD-BACKUP-NEON.md).

## Permissões

- Todos os workflows usam `contents: read`; só `versao.yml` usa `write` (é
  necessário para criar tag e release).
- `.github/scripts/` tem testes unitários stdlib executados no CI Python; eles
  simulam dump, criptografia, ACL e retenção sem acessar Postgres ou Drive.
- A distribuição interna usa a assinatura debug criada pelo Android SDK no
  runner. Uma eventual distribuição release/Google Play precisa de assinatura
  estável própria e fica fora do fluxo atual de APKs de teste.
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
  tabelas pessoais fora do coletor. Os quatro logins e grants foram validados;
  os secrets de dispatch e a API Production já apontam ao Neon novo. A instalação
  e o worker do Samsung foram validados; o gate de nove execuções agendadas em
  72 horas continua aberto. O responsável confirmou que as migrations `033` e
  `034` foram aplicadas em 2026-09-26; backup, restore descartável e aceite das
  funções destrutivas continuam pendentes.
- O robô Pichau usa somente páginas públicas autorizadas, limita-se a 300
  páginas por execução, preserva as validações de catálogo e não persiste
  imagens, HTML ou cookies.
