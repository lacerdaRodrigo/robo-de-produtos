# `backend/api/` — API autenticada (Flutter)

A **API autenticada** que o Flutter consome. Foi movida da interface Next.js
legada (`site/`, desativada em 2026-08-24) para este diretório, preservando o
contrato. Está publicada na Vercel com Root Directory = `backend/api`.

> **Estado em 2026-08-27:** a API responde em
> [`/api/status`](https://robo-de-produtos.vercel.app/api/status). As rotas do
> App Router ficam em `app/api/**`; o CI valida tipos, lint, 83 testes e build.

## Estrutura

```text
backend/api/
├── app/            # rotas HTTP (Next.js App Router), uma pasta por endpoint
│   └── api/        #  /status, /resumo, /perfil, /livelo, /inter, /administracao
├── lib/            # lógica da API (banco, autenticação, formato, limpeza, disparos)
├── testes/         # contratos recuperados da antiga interface Next.js
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

A raiz `/` devolve 404 vazio. O Flutter acessa somente as rotas `/api/**`.

## Dependências

- `@neondatabase/serverless` (PostgresNeon)
- `firebase-admin` (validação de ID token e App Check)
- `next` 16, `react`, `react-dom`
- Override: `uuid` 11.1.1

Variáveis de ambiente (modelo em `examples/.env.example`): `DATABASE_URL`,
`FIREBASE_PROJECT_ID`, `FIREBASE_SERVICE_ACCOUNT_JSON`, `SEGREDO_LIMITE_API`,
`GITHUB_TOKEN_DISPARO`, `EXIGIR_APP_CHECK` e `ALLOWED_ORIGINS`.
Responsabilidades, tipos e rotação estão em
[`../../docs/CONFIGURACAO.md`](../../docs/CONFIGURACAO.md).

## Como rodar / testar

```bash
npm ci
npm run checar   # tsc --noEmit
npm run lint     # ESLint
npm run testar   # Vitest (lib/*.teste.ts e testes/*.teste.ts)
npm run build    # next build
```

As migrações que a API usa (auth, disparos, catálogo de produtos) estão em
[`../../migracoes/`](../../migracoes/). O contrato completo com o Flutter está
em [`../../app/lib/core/api/`](../../app/lib/core/api/).
