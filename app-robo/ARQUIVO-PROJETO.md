# Arquivo do projeto — Radar de Benefícios

> **Intent a este documento:** registrar o estado e a memória do projeto depois da
> desativação da interface Next.js (`site/`), consolidando o conhecimento do legado
> dentro de `app-robo/`. É um guia de reativação e reconstrução, não um contrato novo.

**Data-base:** 24 de agosto de 2026
**Repositório:** `lacerdaRodrigo/robo-livelo`
**Branch da operação:** `feat/arquivar-site-e-api`

---

## 1. O que mudou nesta operação

- A interface legada **Next.js** (`site/`) foi desativada e removida da raiz — incluindo
  o deploy na Vercel (`https://robo-livelo.vercel.app`).
- A **API v1** (que vivia dentro do `site/`) foi arquivada em [`apis/`](apis/).
- O **backend Python** (robôs Livelo, Inter Sites parceiros e Compre direto), os
  **workflows** de GitHub Actions, `config/`, `scripts/` e `pyproject.toml` ficaram
  **vivos na raiz** e continuam rodando — a coleta segue gravando no Postgres (Neon).
- Documentação, protótipos, migrações e memórias foram consolidados dentro de `app-robo/`.

> **Decisão de produto registrada:** o Flutter é a única interface prevista ao fim
> da transição (PLANO.md). Esta operação removeu a interface Next.js. O backend de
> dados e os robôs **não** foram desligados para permitir re-hospedar a API depois.

---

## 2. Onde está cada coisa agora

| Conteúdo | Local | Estado |
|---|---|---|
| Aplicativo Flutter (Web, Android, iOS) | `app-robo/` | Ativo — única interface |
| API v1 arquivada (rotas + libs + package.json) | `app-robo/apis/` | Arquivada, não roda |
| Liste de variáveis de ambiente da API | `app-robo/apis/examples/.env.example` | Referência |
| Robôs Python (Livelo, Inter, produtos) | `src/robo_livelo/` (raiz) | Ativo |
| Testes do robô | `testes/` (raiz) | Ativo |
| Migrações SQL (001–012) | `app-robo/migracoes/` | Arquivadas |
| Doc do produto (PRDs, arquitetura, email, etc.) | `app-robo/docs/` | Arquivada |
| Protótipos Web/Mobile | `app-robo/design-app/` | Arquivado |
| Workflows GitHub Actions | `.github/workflows/` (raiz) | Ativo |
| Catálogo Livelo (132 lojas) | `config/lojas_favoritas.toml` (raiz) | Ativo |
| Scripts utilitários | `scripts/` (raiz) | Ativo |

---

## 3. Como reativar a API (fluxo de retorno à hospedagem)

A API v1 arquivada em `app-robo/apis/` é o backend que o Flutter consome. Para
republicá-la em um host Next/Vercel depois:

1. **Restaurar o projeto Next** a partir de
`app-robo/apis/` (`api/v1/**` + `lib/**` + `package.json`) e recriar a parte de
SSR/UI se ainda for usada (as telas legadas foram removidas).
2. **Aplicar as migrações** necessárias aos dados do Neon:
   `app-robo/migracoes/` (010 a 012 para auth/limite/auditoria, disparos idempotentes e catálogo de produtos).
3. **Cadastrar as variáveis de ambiente** (modelo em
   `apis/examples/.env.example`); segredos ficam somente no servidor/cofre.
4. **Configurar o Firebase** (Admin SDK, permissões, App Check opcional) e o
   convite de usuário no Postgres.
5. **Definir a URL pública** que o Flutter consumirá (padrão atual:
   `--dart-define=API_URL=...`; default no código é `https://app-robo.vercel.app`).

> **Nota:** o código do Flutter aponta por padrão para `https://app-robo.vercel.app`,
> mas o deploy legado que hospedava a API era `robo-livelo.vercel.app`. Confira a URL
> real no build do aparelho antes de religar o circuito.

---

## 4. API v1 — inventário (arquivado)

Tudo em `app-robo/apis/`. Endpoint público único: `GET /api/v1/status`.
Demais exigem Firebase + papel; as mutações administrativas exigem `admin`.

### 4.1 Rotas

| Rota | Métodos | Função | Auth |
|---|---|---|---|
| `api/v1/status` | GET | Health-check público | — |
| `api/v1/resumo` | GET | Início agregado (Livelo+Inter+produtos) | Firebase |
| `api/v1/perfil` | GET | Perfil mínimo (gate de entrada) | Firebase |
| `api/v1/livelo/painel` | GET | Painel Livelo paginado | Firebase |
| `api/v1/livelo/preferencias` | GET/PATCH | Preferências Livelo | admin |
| `api/v1/livelo/lojas` | GET/POST | Catálogo/cadastro lojas | admin |
| `api/v1/livelo/lojas/[id]` | PATCH/DELETE | Regra/remoção loja | admin |
| `api/v1/inter/lojas` | GET/PATCH | Sites parceiros / favorita | admin |
| `api/v1/inter/cashback` | GET | Cashback paginado | Firebase |
| `api/v1/inter/produtos` | GET | Busca produtos paginada | Firebase |
| `api/v1/inter/produtos/lojas` | GET/PATCH | Seleção lojas diretas | admin |
| `api/v1/inter/produtos/historico` | GET | Histórico 30 dias | Firebase |
| `api/v1/administracao/disparos` | GET/POST | Estado/cooldown + solicita coleta | admin |
| `api/v1/administracao/limpeza/[dominio]` | GET/POST | Resumo + executa limpeza | admin |

### 4.2 Libs

- Core: `api.ts`, `autenticacao-api.ts`, `banco-autenticacao.ts`, `firebase-admin.ts`
- Dados: `banco.ts`, `banco-inter.ts`, `banco-produtos-inter.ts`
- Admin: `administracao-api.ts`, `confirmacao-limpeza.ts`, `disparos-api.ts`, `limpeza.ts`
- Resumo: `resumo-inicio.ts`
- Formato: `formato.ts`, `formato-inter.ts`, `formato-produtos-inter.ts`, `paginacao.ts`
- Auxiliares: `github.ts`, `flags.ts`

Dependências da API: `@neondatabase/serverless`, `firebase-admin`, `next`, `react`,
`react-dom` (modelo completo em `apis/package.json`). Override: `uuid` 11.1.1.

---

## 5. Domínios isolados (regra de ouro — manter)

O produto tem **3 integrações isoladas**, com tabelas, processos e workflows próprios:

1. **Livelo** — filtra lojas favoritas e alerta por e-mail quando a pontuação cruza a régua (V2).
2. **Inter — Sites parceiros** — catálogo de cashback (V3).
3. **Inter — Compre direto** — coleta de produtos para lojas escolhidas, busca local e histórico de 30 dias (V4).

Regras que não podem regredir (origem: `app-robo/CLAUDE.md`):

- O núcleo Python **não faz I/O**; o mundo entra por portas/adaptadores.
- Livelo, Sites e Compre direto continuam **isolados** (domínio, processo, tabela, workflow).
- Dinheiro/cashback/pontuação usam `Decimal`/`NUMERIC` — nunca `float`/`double`.
- Texto/link externo é **hostil**: validar, escapar, nunca executar como HTML.
- Nenhum segredo em log, repositório, bundle Web, APK ou IPA.
- Não autenticar na Livelo/Inter; sem proxy rotativo, CAPTCHA ou disfarce.
- Falha, parcial, atrasado, ausência e zero são **estados diferentes**.
- Ações administrativas revalidadas no servidor (autoria, auditoria, idempotência).

---

## 6. Segredos (nunca no repositório)

Segredos dão origem a `apis/examples/.env.example` (modelo sem valor real):

- `DATABASE_URL` — Neon Postgres
- `SENHA_APP_GMAIL`, `EMAIL_REMETENTE`, `EMAIL_DESTINO` — e-mail diário
- `SENHA_SITE`, `SEGREDO_SESSAO` — sessão legada do site
- `GITHUB_TOKEN_DISPARO` — disparo de workflows (fine-grained, Actions read+write)
- `FIREBASE_PROJECT_ID`, `FIREBASE_SERVICE_ACCOUNT_JSON` — Firebase Admin
- `SEGREDO_LIMITE_API` — HMAC de pseudonimização de IP/UID
- `EXIGIR_APP_CHECK` — `false` por padrão

> `app-robo/.env` real está no disco mas **ignorado no git**. Nunca commitar.

---

## 7. Numeração e cadência

- Testes Python usam prefixo `teste_`; gates: Ruff + Pytest com cobertura ≥ 90% do núcleo.
- CI mantenha Pytest/Ruff, Flutter analyze/test e builds. Workflows em `.github/workflows/`.
- Toda regra numerada nos PRDs (`docs/PRD*.md`) exige varredura de consistência ao mudar.
- O objetivo: Web, Android e iOS usam o **mesmo** projeto Flutter, como cliente da API.

---

## 8. O que não foi executado

Para manter os robôs ativos e evitar risco na operação de arquivo, **não** foi feito:

- Nenhuma alteração em `src/`, `testes/`, `scripts/`, `config/`, `pyproject.toml`.
- Nenhuma migração de produção aplicada (o banco ficou como estava).
- Nenhum deploy, smoke ou alteração em `.github/workflows/`.
- Não foi desligado nada no GitHub Actions — os robôs seguem rodando.

A desativação da API v1 e a parada dos robôs, se desejada, é ação **separada e
explícita** que não está contemplada neste arquivo.