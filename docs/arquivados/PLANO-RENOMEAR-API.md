# Plano de ação — Renomear a API (remover `/v1`, manter domínios)

> **✅ Executado** em 24 de agosto de 2026: as rotas foram movidas para `routes/**`,
> o Flutter renomeou `api_v1.dart` → `api.dart` (classe `Api`) e todos os caminhos
> `/api/v1/...` viraram `/api/...`. Este documento fica como registro da ação.

> **Objetivo:** trocar o prefixo `/api/v1/...` por caminhos por domínio sem versão,
> como `/api/livelo/...` e `/api/inter/...`. Feito de uma vez, sem alias, com o
> histórico preservado pelo git.

**Data:** 24 de agosto de 2026
**Decisões aprovadas**
- Remover o `/v1` do caminho.
- Manter a organização por domínio já existente.
- Sem versionamento de API no caminho.
- Renomear tudo de uma vez (backend + Flutter + testes), sem rota antiga/v1.

---

## 1. Novo mapeamento de rotas

| Antes (`/api/v1/...`) | Depois (`/api/...`) |
|---|---|
| `/api/v1/status` | `/api/status` |
| `/api/v1/resumo` | `/api/resumo` |
| `/api/v1/perfil` | `/api/perfil` |
| `/api/v1/livelo/painel` | `/api/livelo/painel` |
| `/api/v1/livelo/preferencias` | `/api/livelo/preferencias` |
| `/api/v1/livelo/lojas` | `/api/livelo/lojas` |
| `/api/v1/livelo/lojas/[id]` | `/api/livelo/lojas/[id]` |
| `/api/v1/inter/lojas` | `/api/inter/lojas` |
| `/api/v1/inter/cashback` | `/api/inter/cashback` |
| `/api/v1/inter/produtos` | `/api/inter/produtos` |
| `/api/v1/inter/produtos/lojas` | `/api/inter/produtos/lojas` |
| `/api/v1/inter/produtos/historico` | `/api/inter/produtos/historico` |
| `/api/v1/administracao/disparos` | `/api/administracao/disparos` |
| `/api/v1/administracao/limpeza/[dominio]` | `/api/administracao/limpeza/[dominio]` |

O restante do caminho (domínio + ação) permanece igual — só cai a camada `v1`.

---

## 2. Onde mudar

### 2.1 Estrutura de pastas das rotas (`backend/api/routes/`)

Mover de `routes/v1/<dominio>/...` para `routes/<dominio>/...` (removendo a camada
`v1`). Já feito com `git mv`, preservando histórico.

```text
backend/api/routes/
├── status/route.ts
├── resumo/route.ts
├── perfil/route.ts
├── livelo/{painel, preferencias, lojas}/...
├── inter/{cashback, lojas, produtos}/...
└── administracao/{disparos, limpeza/[dominio]}/...
```

### 2.2 Cliente Flutter (`app/lib/core/api/api_v1.dart`)

Como a API agora não tem `v1` no caminho, também vale renomear o arquivo de
`api_v1.dart` para um nome sem versão (ex.: `api.dart`), e a classe interna se já
se chamar `ApiV1` → `Api`. Atualizar as ~21 ocorrências de `/api/v1/...` para
`/api/...`.

> **Cuidado:** `api_v1.dart` é referenciado em `construcao.dart` e talvez em testes.
> Renomear exige atualizar todos os imports. Alternativa mais segura: manter o nome
> do arquivo/classe e só trocar as strings dos caminhos. Decidir na execução.

### 2.3 Testes (Flutter e API)

Arquivos com referências a `/api/v1`:

- `app/test/core/api/api_v1_test.dart` (8)
- `app/test/core/api/cliente_test.dart` (8)
- `app/test/app/paginas/inicio_test.dart`
- `app/test/app/navegacao/moldura_test.dart`
- `app/test/app/autenticacao/portao_test.dart`
- `app/test/app/inicializacao/pagina_abertura_test.dart`
- `app/test/features/administracao/pagina_administracao_test.dart`
- `app/test/features/administracao/zona_perigo_test.dart`
- `app/test/app_smoke_test.dart`

Todos devem usar os novos caminhos `/api/...`.

### 2.4 Testes da API (se existirem)

Verificar `backend/api/` por testes `.teste.ts` que montem URLs com `/api/v1`.
Atualizar conforme o novo padrão.

### 2.5 Documentação

- `backend/api/README.md` — atualizar exemplos e tabela de rotas.
- `README.md` (raiz) — exemplos de `/api/v1/status` e `/api/v1/resumo`.
- `ARQUIVO-PROJETO.md` — caso mencione `/api/v1`.
- `app/README.md` — referência ao endpoint.

---

## 3. Passos de execução

1. **Rotas:** `git mv backend/api/routes/v1/* backend/api/routes/` (remover camada
   `v1`), ajustando se necessário o import relativo dos arquivos `route.ts`.
2. **Lib do Flutter:** renomear `api_v1.dart` → `api.dart` (se decidir) e trocar
   strings `/api/v1` → `/api`.
3. **Imports:** atualizar `construcao.dart` e qualquer import de `api_v1`.
4. **Testes:** trocar `/api/v1` → `/api` nos arquivos listados.
5. **Docs:** atualizar READMEs e ARQUIVO-PROJETO.
6. **Validar:** `npm run checar` e `npm run testar` (em `backend/api/`),
   `flutter analyze` e `flutter test` (em `app/`).

---

## 4. Critérios de aceite

- Nenhum `/api/v1` restante em código (rotas, `lib/`, testes).
- `flutter test` passa e `flutter analyze` limpo.
- `tsc --noEmit` (checar) e testes da API passam, se aplicáveis.
- READMEs não citam mais `v1`.

---

## 5. Fora de escopo

- Não criar alias/redirect de `/api/v1/*`.
- Não renomear as libs de `backend/api/lib` (ex.: `banco.ts`, `api.ts`) salvo se o
  nome `api.ts` colidir com o cliente renomeado — avaliar caso a caso.
- Não mexer nos robôs Python nem nas tabelas do Neon.
