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
│   └── api/        # /status, /resumo, /perfil, /livelo, /inter, /pichau, /alertas, /notificacoes, /relatos-problema
├── lib/            # lógica da API (banco, autenticação, formato, limpeza, disparos)
├── examples/       # .env.example (modelo de variáveis)
└── package.json
```

## Rotas (`app/api/**`)

| Rota | Métodos | Função | Auth |
|---|---|---|---|
| `status` | GET | Health-check público (`{saudavel:true}`) | — |
| `resumo` | GET | Início agregado (Livelo+Inter+produtos+Pichau) | Firebase |
| `perfil` | GET | Perfil mínimo (gate de entrada) | Firebase |
| `livelo/painel` | GET | Painel Livelo paginado | Firebase |
| `livelo/catalogo` | GET | Catálogo completo, filtros e resumo Livelo (`alertas_ativos` reflete os sinos ligados) | Firebase |
| `livelo/catalogo/[id_externo]/historico` | GET | Últimas 30 medições salvas de qualquer parceiro do catálogo | Firebase |
| `livelo/catalogo/[id_externo]/acompanhamento` | PATCH | Acompanhar/remover parceiro do catálogo | admin |
| `livelo/catalogo/[id_externo]/acompanhamento-pessoal` | PATCH | Acompanhamento individual do usuário | Firebase |
| `livelo/catalogo/[id_externo]/alerta` | PATCH | Ligar/desligar o sino de alerta de uma loja acompanhada | admin |
| `livelo/preferencias` | GET/PATCH | Preferências Livelo | admin |
| `livelo/lojas` | GET/POST | Catálogo/cadastro lojas | admin |
| `livelo/lojas/[id]` | PATCH/DELETE | Regra/remoção loja | admin |
| `inter/lojas` | GET/PATCH | Sites parceiros / favorita | admin |
| `inter/cashback` | GET | Cashback paginado | Firebase |
| `inter/cashback/[id]/acompanhamento` | PATCH | Acompanhamento individual de loja | Firebase |
| `inter/produtos` | GET | Busca produtos paginada | Firebase |
| `inter/produtos/lojas` | GET/PATCH | Seleção lojas diretas | admin |
| `inter/produtos/historico` | GET | Histórico 30 dias | Firebase |
| `inter/produtos/[loja]/[id_externo]/acompanhamento` | PATCH | Acompanhamento pessoal de produto | Firebase |
| `pichau/catalogo` | GET | Catálogo PC Gamer persistido, busca por nome/marca/SKU, abas, disponibilidade, ordenação e paginação | Firebase |
| `pichau/catalogo/[id_externo]/acompanhamento` | PATCH | Acompanhar/remover produto Pichau e atualizar o sino | admin |
| `pichau/catalogo/[id_externo]/historico` | GET | Histórico Pichau limitado a 30 dias | Firebase |
| `administracao/disparos` | GET/POST | Estado/cooldown + solicita coleta | admin |
| `administracao/limpeza/[dominio]` | GET/POST | Resumo + executa limpeza | admin |
| `alertas` | GET/PATCH | Central paginada, filtros e leitura em massa | Firebase |
| `alertas/[id]/leitura` | PATCH | Leitura individual | Firebase |
| `alertas/preferencias` | GET/PATCH | Preferências de push e tipos | Firebase |
| `alertas/acompanhamentos` | PATCH | Acompanhamento pessoal de uma entidade | Firebase |
| `notificacoes/dispositivos` | POST/DELETE | Registro/remoção de token FCM | Firebase |
| `notificacoes/outbox` | POST | Envio idempotente da outbox e expurgo, acionado manualmente | admin |
| `cron/notificacoes/outbox` | POST | Processamento interno da outbox pelo GitHub Actions | `Authorization: Bearer OUTBOX_CRON_SECRET` |
| `relatos-problema` | POST | Relato autenticado sem dados sensíveis | Firebase |

A raiz `/` devolve 404 vazio. Constraints e execução completa em
[`../../ARQUIVO-PROJETO.md`](../../ARQUIVO-PROJETO.md).

## Dependências

- `@neondatabase/serverless` (PostgresNeon)
- `firebase-admin` (validação de ID token/App Check e envio FCM)
- `next` 16, `react`, `react-dom`
- Override: `uuid` 11.1.1

Variáveis de ambiente (modelo em `examples/.env.example`): `DATABASE_URL`,
`FIREBASE_PROJECT_ID`, `FIREBASE_SERVICE_ACCOUNT_JSON`, `SEGREDO_LIMITE_API`,
`EXIGIR_APP_CHECK`, `ALLOWED_ORIGINS`, `GITHUB_TOKEN_DISPARO` e
`OUTBOX_CRON_SECRET`. Não há variável SMTP/e-mail usada por esta API.

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

O catálogo e o PATCH de acompanhamento da Pichau dependem de
`migracoes/025_pichau_acompanhamento.sql`, aplicada manualmente pelo responsável
antes do merge. O coletor preserva a coluna de seleção durante o upsert.

## Central de Alertas

As rotas de alertas dependem de `migracoes/023_alertas_suporte_privacidade.sql`.
As leituras de Livelo e cashback aceitam `escopo=pessoal` (padrão do app) e
usam `acompanhamento_usuario`; somente administradores podem solicitar
`escopo=global`. As rotas administrativas legadas continuam separadas.
O administrador pode chamar `POST /api/notificacoes/outbox` com a autenticação
Firebase e papel `admin`. O GitHub Actions chama somente
`POST /api/cron/notificacoes/outbox` com `Authorization: Bearer
OUTBOX_CRON_SECRET`; as rotas permanecem separadas. O processamento expurga
alertas de 90 dias e relatos de 180 dias, processa retries, recupera linhas
presas em `enviando` há pelo menos 15 minutos e desativa tokens FCM inválidos.
A resposta contém apenas as contagens `processadas`, `enviadas` e
`recuperadas`. O banco não deve ser acessado pelo Flutter. A aplicação da
migration foi confirmada operacionalmente pelo responsável; este checkout não
executa a SQL nem produz validação independente do ambiente alvo.
