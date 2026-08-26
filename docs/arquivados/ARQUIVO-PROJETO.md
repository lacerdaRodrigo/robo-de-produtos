# Arquivo do projeto — reativação da API

Estado e memória da reorganização de 2026-08-24: a interface Web legada
(`site/`) foi desativada, a API autenticada foi movida para `backend/api/` e a
raiz do repositório passou a chamar `robo`. Este arquivo é o guia para voltar a
pôr a API no ar e reaproximar a experiência que o Flutter consumia.

## Resumo da arquitetura após a reorganização

- **Interface única:** Flutter em `app/` (Web, Android e iOS).
- **Backend robôs:** Python em `backend/robo/src/robo_livelo/`, processado pelo
  GitHub Actions (`.github/workflows/robo.yml`, `inter.yml`,
  `produtos-inter.yml`).
- **API autenticada:** em `backend/api/`, usando rotas do Next.js App Router sob
  `app/api/**`. Foi o que permitiu desligar o site em `site/` sem perder o
  contrato com o Flutter.
- **Banco:** Postgres no Neon, schema em `migracoes/`.

## O que falta (na ordem de execução de reativação)

1. **Subir a API na Vercel.**
   - Projeto apontando para este repositório, **Root Directory = `backend/api`**,
     Node 22.
   - Variáveis de ambiente (modelo em `backend/api/examples/.env.example`):
     `DATABASE_URL`, `FIREBASE_PROJECT_ID`, `FIREBASE_SERVICE_ACCOUNT_JSON`,
     `SEGREDO_LIMITE_API`, `GITHUB_TOKEN_DISPARO`, `EXIGIR_APP_CHECK`
     (provisório `false`), `ALLOWED_ORIGINS` (origin do Flutter Web publicado).
   - Smoke: `GET /api/status` público + login → perfil → resumo no app.
   - [X] Esqueleto do API publicável foi reconstruído em 2026-08-23 a partir
     da feature branch: `app/`, `tsconfig.json`, `next.config.ts` (headers de
     segurança), middleware CORS allowlist, rotas movidas para `api/app/api/**`,
     `GET /status` mínimo e raiz `/` em 404.

2. **Reativar os robôs no GitHub Actions.** Os workflows `robo.yml`,
   `inter.yml` e `produtos-inter.yml` agora apontam para `backend/robo` como
   working directory. Confirmar os segredos `DATABASE_URL` e e-mail ainda estão
   cadastrados no repositório.

3. **Aplicar as migrações pendentes no Neon.** Em `migracoes/`, conferir `009`
   (coleta degradada) e `012` (reparo de divergência). A `011` (disparos
   administrativos idempotentes) continua guardada e exige autorização
   operacional separada.

## Estado dos arquivos principais

- `app/lib/core/ambiente.dart`: default `API_URL` = `https://app-robo.vercel.app`.
- `backend/api/lib/autenticacao-api.ts`: porta de autenticação (Firebase ID
  token + App Check + papel no Postgres + rate limit + auditoria).
- `backend/api/middleware.ts`: allowlist de origem (CORS) e HTTPS em produção.
- `backend/api/app/api/status/route.ts`: `{ saudavel: true }`, sem dado.
- `backend/api/app/page.tsx`: raiz devolve 404.

## Regras de segurança que não regredir

- Nenhuma rota de dado é pública; só `GET /status` é aberto e sem dado.
- Segredo nunca em log, bundle, repositório. `ALLOWED_ORIGINS` não é segredo.
- `EXIGIR_APP_CHECK` só vira `true` depois de observar web/iOS e o APK nativo.