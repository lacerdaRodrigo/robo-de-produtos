# `backend/api/` — API autenticada (Flutter)

A **API autenticada** que o Flutter consome. Foi movida da interface Next.js
legada (`site/`, desativada em 2026-08-24) para este diretório, preservando o
contrato. É publicável em produção (Vercel, Root Directory = `backend/api`).

> **Estado no repositório:** rotas do App Router em `app/api/**`, headers de
> segurança, middleware de allowlist de origem (CORS) e `GET /status` mínimo.
> Deploy e configuração operacional não fazem parte das validações locais.

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
| `livelo/catalogo` | GET | Catálogo completo, filtros e resumo Livelo (`alertas_ativos` reflete os sinos ligados) | Firebase |
| `livelo/catalogo/[id_externo]/historico` | GET | Últimas 30 medições salvas de qualquer parceiro do catálogo | Firebase |
| `livelo/catalogo/[id_externo]/acompanhamento` | PATCH | Acompanhar/remover parceiro do catálogo | admin |
| `livelo/catalogo/[id_externo]/alerta` | PATCH | Ligar/desligar o sino de alerta de uma loja acompanhada | admin |
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
`EXIGIR_APP_CHECK`, `ALLOWED_ORIGINS` e `GITHUB_TOKEN_DISPARO`. Não há variável
SMTP/e-mail usada por esta API.

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
