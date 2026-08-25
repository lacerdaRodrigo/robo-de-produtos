# `backend/api/` — API v1 (arquivada)

A **API v1 autenticada** que o Flutter consome. Originalmente vivia dentro da
interface Next.js (`site/`), que foi desativada em 2026-08-24. Foi arquivada aqui
para permitir re-hospedagem posterior, sem perder o contrato.

> **Estado:** arquivada e **não roda** no momento. Endpoint público único é
> `GET /api/v1/status`. As demais rotas exigem Firebase; as mutações
> administrativas exigem papel `admin`. Para republicar, siga o roteiro de
> reativação em [`../../ARQUIVO-PROJETO.md`](../../ARQUIVO-PROJETO.md).

## Estrutura

```text
backend/api/
├── routes/     # rotas HTTP (Next.js App Router), uma pasta por endpoint
│   └── v1/     # administracao, inter, livelo, perfil, resumo, status
├── lib/        # lógica da API (banco, autenticação, formato, limpeza, disparos)
├── examples/   # .env.example (modelo de variáveis)
└── package.json
```

## Rotas (`routes/v1/**`)

| Rota | Métodos | Função | Auth |
|---|---|---|---|
| `status` | GET | Health-check público | — |
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

## Dependências

- `@neondatabase/serverless` (Postgres Neon)
- `firebase-admin` (validação de ID token e App Check)
- `next` 16, `react`, `react-dom`
- Override: `uuid` 11.1.1

Variáveis de ambiente (modelo em `examples/.env.example`): `DATABASE_URL`,
`FIREBASE_PROJECT_ID`, `FIREBASE_SERVICE_ACCOUNT_JSON`, `SEGREDO_LIMITE_API`,
`EXIGIR_APP_CHECK`, e as de e-mail/github do fluxo do robô.

## Como rodar / testar

```bash
npm install
npm run checar   # tsc --noEmit
npm run testar   # vitest run
npm run build    # next build
```

As migrações que a API usa (auth, disparos, catálogo de produtos) estão em
[`../../migracoes/`](../../migracoes/). O contrato completo com o Flutter está
em [`../../app/lib/core/api/`](../../app/lib/core/api/).
