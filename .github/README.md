# Automação e CI

Os workflows usam segredos cadastrados em **Settings → Secrets and variables
→ Actions**. Valores de credenciais nunca pertencem ao repositório ou aos
logs.

## Workflows

| Arquivo | Função | Gatilho | Segredos |
|---|---|---|---|
| `robo.yml` | Coleta e publica Livelo | 09h/14h/20h e manual | `DATABASE_URL` |
| `inter.yml` | Atualiza cashback e produtos Inter | 09h/14h/20h e manual | `DATABASE_URL`, `LIMIAR_LOJAS_INTER` |
| `pichau.yml` | Enfileira a coleta no Samsung e espera o resultado | 09h/14h/20h e manual | `PICHAU_DISPATCH_DATABASE_URL` |
| `testes.yml` | Ruff, Pytest, tipos, ESLint, Vitest, build e auditoria npm | push, PR e manual | nenhum |
| `app-robo.yml` | Gates Flutter e distribuição interna da APK | push, PR e manual | Drive e e-mail somente no job de distribuição |
| `versao.yml` | Versão, changelog, tag e release | `main` | `GITHUB_TOKEN` |

## Controles comuns

- As Actions de terceiros ficam fixadas por SHA completo.
- Checkouts somente de leitura usam `persist-credentials: false`.
- Todos os workflows usam `contents: read`; somente o versionamento recebe
  escrita para tag e release.
- Dependabot acompanha GitHub Actions, Python em `backend/robo`, npm em
  `backend/api` e Pub em `app`.
- O CI da API falha quando `npm audit --audit-level=high` encontra
  vulnerabilidade alta ou crítica.

## Pichau

O Ubuntu não coleta a Pichau. O workflow usa exclusivamente a role dispatcher,
via `PICHAU_DISPATCH_DATABASE_URL`, para inserir/consultar
`pichau_android_fila`. Não há fallback para a credencial ampla.

O worker do Termux reivindica a solicitação e publica com a role própria do
telefone. Nenhum token GitHub é armazenado no Android. Appium escuta somente em
`127.0.0.1`; endpoint Wi-Fi, serial, código de pareamento e credenciais não
entram no workflow nem nos logs.

## APK interna

O contrato completo está em
[`docs/prd/PRD-DISTRIBUICAO-APK.md`](../docs/prd/PRD-DISTRIBUICAO-APK.md).

Pull requests e branches de trabalho apenas validam. A distribuição acontece
em push humano na `main` ou por execução manual feita na própria `main` com
`distribuir=true`. A APK não é enviada como artifact do GitHub: segue para o
Drive privado, com ACL limitada ao proprietário e ao destinatário em modo
somente leitura, retenção de dez arquivos e aviso por e-mail.

O build atual é debug, aponta para a API de produção e desativa App Check.
Portanto, serve apenas para distribuição interna e não atende aos requisitos de
release público.

Segredos usados nesse job:

- `GOOGLE_DRIVE_OAUTH_CLIENT_JSON`;
- `GOOGLE_DRIVE_REFRESH_TOKEN`;
- `GOOGLE_DRIVE_FOLDER_ID`;
- `EMAIL_DESTINO`;
- `EMAIL_REMETENTE`;
- `SENHA_APP_GMAIL`.

## Escopo do gate Flutter

O workflow executa formatação, análise estática e os testes unitários/widgets
mobile permitidos. Não executa Web, integração, E2E, smoke, performance ou
regressão visual automatizada.
