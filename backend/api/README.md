# `backend/api/` — API autenticada (Flutter)

A **API autenticada** que o Flutter consome. Foi movida da interface Next.js
legada (`site/`, desativada em 2026-08-24) para este diretório, preservando o
contrato. É publicável em produção (Vercel, Root Directory = `backend/api`).

> **Estado:** a partir de 2026-08-23 o shell publicável foi reconstruído aqui:
> rotas do App Router em `app/api/**`, `next.config.ts` com headers de
> segurança, middleware de allowlist de origem (CORS) e `GET /status` mínimo.
> Para republicar, siga [`ARQUIVO-PROJETO`](../../ARQUIVO-PROJETO.md).

## Estrutura

```text
backend/api/
├── app/            # rotas HTTP (Next.js App Router), uma pasta por endpoint
│   └── api/        #  /status, /resumo, /perfil, /livelo, /inter, /administracao
├── lib/            # lógica da API (banco, autenticação, formato, limpeza, disparos)
├── examples/       # .env.example (modelo de variáveis)
└── package.json
```

## Rotas (`app/api/**`)

| Rota | Métodos | Função | Auth |
|---|---|---|---|
| `status` | GET | Health-check público (`{saudavel:true}`) | — |
| `resumo` | GET | Início agregado (Livelo+Inter+produtos) | Firebase |
| `perfil` | GET | Perfil mínimo (gate de entrada) | Firebase |
| `livelo/painel` | GET | Painel Livelo paginado | Firebase |
| `livelo/catalogo` | GET | Catálogo completo, filtros e resumo Livelo | Firebase |
| `livelo/catalogo/[id_externo]/acompanhamento` | PATCH | Acompanhar/remover parceiro do catálogo | admin |
| `livelo/preferencias` | GET/PATCH | Preferências Livelo | admin |
| `livelo/lojas` | GET/POST | Catálogo/cadastro lojas | admin |
| `livelo/lojas/[id]` | PATCH/DELETE | Regra/remoção loja | admin |
| `inter/lojas` | GET/PATCH | Sites parceiros / favorita | admin |
| `inter/cashback` | GET | Cashback paginado | Firebase |
| `inter/produtos` | GET | Busca produtos paginada | Firebase |
| `inter/produtos/lojas` | GET/PATCH | Seleção lojas diretas | admin |
| `inter/produtos/historico` | GET | Histórico 30 dias | Firebase |
| `administracao/disparos` | GET/POST | Estado/cooldown + solicita coleta | admin |
| `administracao/limpeza/[dominio]` | GET/POST | Resumo + executa limpeza | admin |

A raiz `/` devolve 404 vazio. Constraints e execução completa em
[`../../ARQUIVO-PROJETO.md`](../../ARQUIVO-PROJETO.md).

## Dependências

- `@neondatabase/serverless` (PostgresNeon)
- `firebase-admin` (validação de ID token e App Check)
- `next` 16, `react`, `react-dom`
- Override: `uuid` 11.1.1

Variáveis de ambiente (modelo em `examples/.env.example`): `DATABASE_URL`,
`FIREBASE_PROJECT_ID`, `FIREBASE_SERVICE_ACCOUNT_JSON`, `SEGREDO_LIMITE_API`,
`EXIGIR_APP_CHECK`, `ALLOWED_ORIGINS`, e as de e-mail/github do fluxo do robô.

## Como rodar / testar

```bash
npm install
npm run checar   # tsc --noEmit
npm run testar   # vitest run (testes em lib/*.teste.ts)
npm run build    # next build
```

As migrações que a API usa (auth, disparos, catálogo de produtos) estão em
[`../../migracoes/`](../../migracoes/). O contrato completo com o Flutter está
em [`../../app/lib/core/api/`](../../app/lib/core/api/).
