# Fase 1 — Inventário e contratos do `app-robo`

**Status:** registro da Fase 1 do [`PLANO.md`](PLANO.md). Atualização da Fase 3B:
API e autenticação estão publicadas e validadas em produção; este documento
preserva o inventário que orientou o código.
**Data-base:** 19 de agosto de 2026. Repositório `main` na versão `1.30.2`.
**Fonte do inventário:** leitura do `site/` (rotas, Server Actions, `lib/`), sem alterar nada.

> Este documento mapeia o que o site legado faz, classifica cada operação, e fixa os
> contratos JSON e de paginação que o Flutter vai consumir. Ele **não** implementa a API.
> A criação da API é a Fase 3; no fim deste arquivo ficam as decisões que precisam de
> confirmação do responsável antes do código.

---

## 1. Conclusão do inventário

O site atual **não tem API REST**. Tudo o que o Flutter precisaria consumir hoje existe como:

- **leitura direta no Postgres** durante o render do servidor (`lib/banco*.ts`), ou
- **Server Actions** (`"use server"` + `FormData`) para qualquer mutação ou disparo.

Ou seja: o Flutter **não pode ser ligado no site como está**. Ele precisa de uma camada de
API HTTP autenticada. O plano previa isso e essa é exatamente a saída esperada da Fase 1.

### 1.1 Duas lacunas de produto que o plano exige e o site não tem

| Lacuna | Onde hoje | Exigência do plano (§4.3.1, §12.3) |
|---|---|---|
| **Busca de produtos sem paginação** | `banco-produtos-inter.ts::buscarProdutosDiretos` retorna em **uma chamada, `LIMIT 500`**, sem metadados de página | API pesquisa no banco e entrega páginas de **20 (padrão) / no máx. 50**, com `total_itens`, `total_paginas`, `tem_proxima` |
| **Sem filtros de produto** | busca só por texto (`q`), sem marca/categoria/loja/preço | Filtros no servidor: loja, marca, categoria, faixa de preço; ordenação estável |

Essas duas falhas ficam **no servidor**, não no cliente. O Flutter nunca vai baixar o
catálogo para filtrar/paginar (regra do §4.3).

---

## 2. Inventário do `site/`

### 2.1 Rotas e classificação de acesso

| Rota | Público | Exige sessão | Dados que lê (função em `lib/`) |
|---|---|---|---|
| `/` (Painel) | sim | partes admin | `ultimaExecucao`, `pontuacoes`; flags `tema` |
| `/avisos` | não | sim | `lojasComExcecao`, `preferencias` |
| `/lojas` | não | sim | `catalogo`, `categorias`, `esperaAteProximoDisparo` |
| `/lojas/remover` | não | sim | ídem `/lojas` |
| `/entrar` | sim | — | senha única + `tentativasRecentes` |
| `/ajuda` | sim | — | estático |
| `/configuracoes` | não | sim | flags + resumos de limpeza |
| `/configuracoes/limpeza/[dominio]` | não | sim | `resumoDadosLivelo` / `resumoDadosInter` |
| `/versoes` | sim | — | `versao` |
| `/inter` | sim | — | `ultimaTentativaInter`, `ultimaExecucaoInterValida`, `cashbacksInter` |
| `/inter/lojas` | não | sim | `buscarLojasInter`, `totalLojasInter`, `esperaAteProximoDisparoInter` |
| `/inter/produtos` | sim | — | `buscarProdutosDiretos`, `totalProdutosDiretos` |
| `/inter/produtos/lojas` | não | sim | `buscarLojasDiretas`, `totalLojasDiretas`, `resumoLojasDiretas` |
| `/inter/produtos/historico/[loja]/[produto]` | sim | — | `historicoProdutoDireto` |

### 2.2 Catálogo de Server Actions (mutação/disparo)

| Action | Rota | Dados (FormData) | Efeito |
|---|---|---|---|
| `acaoAlternarTema` / `acaoSair` | global | `voltar` | cookie de tema / encerra sessão |
| `acaoAdicionarLoja` | `/lojas` | `nome`, `categoria`, `apelidos`, `multiplicador`, `piso` | insere loja + apelidos + limiar |
| `acaoRemoverLoja` | `/lojas` | `id`, `nome` | deleta loja |
| `acaoAtualizarAgora` | `/lojas` | — | dispatch `robo.yml` (cooldown 5 min) |
| `acaoSalvarPadroes` | `/avisos` | `multiplicador`, `piso`, `assinante_clube` | upsert `preferencia` |
| `acaoSalvarExcecao` | `/avisos` | `id`, `multiplicador`, `piso` | limiar por loja (RN28) |
| `acaoAcompanharInter` | `/inter/lojas` | `id`, `nome`, `q`, `pagina` | `favorita_inter` + dispatch `inter.yml` se liberado |
| `acaoRemoverInter` | `/inter/lojas` e `/inter` | `id`, `q`, `ordenar` | remove `favorita_inter` |
| `acaoAtualizarInter` | `/inter/lojas` | — | dispatch `inter.yml` |
| `acaoSelecionarLojaDireta` | `/inter/produtos/lojas` | `id`, `nome`, `q`, `pagina` | `selecionada = true` (RN53/RN56) |
| `acaoRemoverLojaDireta` | `/inter/produtos/lojas` | `id`, `nome`, `q`, `pagina` | `selecionada = false` |
| `acaoAtualizarProdutosInter` | `/inter/produtos/lojas` | — | dispatch `produtos-inter.yml` (exige ≥1 selecionada) |
| `acaoSalvarConfiguracoes` | `/configuracoes` | `aviso_opcional_no_cadastro`, `esconder_tela_alertas` | flags em cookie |
| `acaoApagarDadosLivelo` / `acaoResetarDadosInter` | `/configuracoes/limpeza/[dominio]` | `frase` | transação atômica (PRD-V5) |

---

## 3. Contratos de dados que a API reutiliza

Regra transversal (herdada do PRD 5.4 e RNF20/RNF29): **todo valor numérico trafega como
string**, nunca como `float`/`double`. No site isso é o tipo `Numerico = string | null`.
A API JSON mantém exatamente isso.

Modelos existentes que virarão os corpos de resposta (tipos já definidos em `site/lib/`):

- **PontuacaoDeLoja / Loja / Preferencias / Execucao** (Livelo) — `banco.ts`
- **CashbackInter / LojaCatalogoInter / TentativaInter** (Sites parceiros) — `banco-inter.ts`
- **ProdutoDireto / LojaDireta / HistoricoProduto** (Compre direto) — `banco-produtos-inter.ts`
- **ResumoDadosLivelo / ResumoDadosInter** (limpeza) — `limpeza.ts`

---

## 4. Contrato da API v1 (proposta; fecha tecnologia na Fase 3)

### 4.1 Base e hospedagem

- Caminho recomendado: `site/app/api/v1/…`, no backend já publicado (Plano §4.2).
- Não haverá segundo servidor no piloto. Confirmação final no gate da Fase 3 contra limites reais da Vercel.

### 4.2 Autenticação

- O site atual usa **cookie + senha única** (`sessao.ts`). Isso não serve para o Flutter
  móvel e não é multiusuário.
- A API exige **token emitido por provedor** (direção do Plano §5.3: Firebase Authentication),
  **validado no servidor** antes de qualquer leitura pessoal ou mutação. Existir no provedor
  não basta — o e-mail precisa estar autorizado e o perfil ativo no banco.
- Método fechado na Fase 3B: **e-mail e senha do Firebase Authentication**, sem
  cadastro público; recuperação e confirmação de e-mail ficam a cargo do Firebase.

### 4.3 Paginação única (padrão do produto)

Aplicada a busca de lojas, produtos e histórico:

```
GET /api/v1/…?pagina=1&por_pagina=20
```

- `pagina` — inteiro ≥ 1, padrão `1`.
- `por_pagina` — inteiro 1–50, padrão `20`. **Não existe `all`** nem modo sem paginação.
- Resposta:

```json
{
  "itens": [ { } ],
  "pagina": 1,
  "por_pagina": 20,
  "total_itens": 200,
  "total_paginas": 10,
  "tem_proxima": true,
  "atualizado_em": "2026-08-19T00:00:00Z",
  "qualidade": "completa"
}
```

- A API **nunca corta total silenciosamente**: todas as páginas usam a mesma busca, filtros e
  ordenação, sem item perdido ou duplicado entre páginas (Plano §4.3.1, §12.3).

### 4.4 Ordenação estável

- Livelo Painel: `pontos` (padrão), `alerta`, `nome` — iguais a `ordenarLojas` do site.
- Sites parceiros: `cashback` (padrão, RN37), `nome`.
- **Produtos: menor preço atual crescente, depois nome, depois ID** (RN71, já no site).

### 4.5 Card de produto — campos da mesma medição (RN72)

O card inteiro vem de **uma única medição** (nunca se mistura horário de coleta):

| Campo | Tipo | Observação |
|---|---|---|
| `id_externo`, `nome`, `marca`, `categoria` | string | marca/categoria podem vir null |
| `preco_cheio_texto` / `preco_cheio_valor` | string \| null | valor = string decimal |
| `preco_atual_texto` / `preco_atual_valor` | string | **nunca vira zero se ausente** |
| `desconto_texto`, `desconto_percentual_texto` | string \| null | |
| `cashback_texto`, `cashback_percentual_texto` | string \| null | |
| `preco_liquido_texto` | string \| null | rótulo "após cashback" (RN73) |
| `parcelamento`, `estoque`, `etiquetas[]` | string \| number \| null | |
| `caminho` | string | relativo; o cliente **reconstrói o link sob `https://shopping.inter.co/`** e nunca usa destino externo (RN75) |
| `loja_slug`, `loja_nome` | string | agrupamento no cliente |

### 4.6 Histórico de produto

```
GET /api/v1/inter/produtos/historico?loja=<slug>&produto=<id_externo>&pagina=1&por_pagina=30
```
- `por_pagina` padrão `30`, **máximo `100`** (Plano §4.3.1).
- Retorna `minimo` / `maximo` de **preço atual em 30 dias** + `medicoes` cronológicas (mais recente primeiro).

### 4.7 Erros

A API responde sempre com corpo JSON mínimo e `status` HTTP coerente:

| Status | Significado |
|---|---|
| 400 | entrada inválida (ex.: `q` fora de 2–100) |
| 401 | sem token / token inválido/expirado |
| 403 | token válido, mas sem papel para a ação |
| 404 | recurso inexistente (loja, produto, domínio de limpeza) |
| 429 | rate limit / cooldown de disparo |
| 500 | sem vazar URL de banco nem segredo — mensagem genérica |

Corpo de erro:

```json
{ "erro": { "codigo": "validacao", "mensagem": "termo de busca invalido" } }
```

Nunca imprime `DATABASE_URL`, payload completo, credencial ou exceção bruta (RNF26, RNF34).

---

## 5. Disparo dos robôs pela API

A API **não** recebe arquivo, branch, URL ou slug arbitrário do cliente. Ela:

1. exige autenticação + papel `admin`;
2. aceita somente workflow de lista fixa (`robo.yml`, `inter.yml`, `produtos-inter.yml`);
3. aplica cooldown e idempotência (sem criar execução repetida);
4. registra solicitante, data, origem, workflow e resultado;
5. devolve estado consultável (não bloqueia a tela);
6. rele as lojas selecionadas do banco (nunca do cliente).

---

## 6. Decisões que precisam de confirmação (gates)

Item do plano | Decisão atual | O que falta responder
---|---|---
§4.2 Backend da API | `site/app/api/v1/` escolhido como hospedeiro transitório; a interface Next.js será descontinuada | Validar o deploy e decidir o hospedeiro da API antes do corte do site
§5.3 Login | Firebase Authentication por e-mail/senha, sem cadastro público; provedor, conta e convite inicial criados | Definir a senha, confirmar o e-mail e executar o smoke real
§17 Identificadores | `br.com.radarbeneficios.app` em Android e iOS | Fechado na Fase 3B
§17.2 Paginação | cursor **vs** página+número com versão do catálogo | escolher antes da busca de produtos paginada
§17.2 Filtros MVP | marca, categoria, loja, preço | confirmar se esses 4 já entram no primeiro MVP
§17 Nome público | **Radar de Benefícios** | fechado na Fase 3B
§17 Horário relatório diário | em aberto | decidir na Fase 6

Recomendação da Fase 1: **página + número + `atualizado_em`/`qualidade`** (sem cursor) no
primeiro MVP, mantendo filtros do §17.2. Simples, compatível com `?q=` atual e com teste
de volume igualmente fácil.

---

## 7. O que NÃO mudou e não muda

- `site/`, banco Neon e workflows continuam funcionando e sendo a fonte (Plano §3.1).
- O Flutter **não** acessa o Neon, **não** dispara o GitHub com token embutido, **não** toca
  Livelo/Inter direto (Plano §3.2).
- Nenhuma regra dos robôs é reimplementada no Flutter — a API reusa as funções do `site/lib`.
- Nenhuma tabela nova é criada por este documento.

---

## 8. Fechamento da Fase 1

Entregue neste inventário:

- [x] Todas as rotas e Server Actions do `site/` mapeadas e classificadas
- [x] Restrições de acesso documentadas (público vs sessão)
- [x] Modelos de dados reutilizáveis listados
- [x] Contrato JSON de paginação, ordenação, card de produto, histórico e erros
- [x] Lacunas detectadas: busca de produtos sem paginação e sem filtros (**corrigir no servidor**)
- [x] Decisões de backend, login, identificadores, paginação e filtros confirmadas
  nas Fases 3A/3B; os gates operacionais permanecem em `docs/PENDENCIAS.md`.

---

## 9. Avanço real — Fases 2 a 4.1

> Estado registrado depois do commit `732de42` (base do Flutter + API v1 na `main`).
> Este contrato guiou o que se fez; abaixo fica o que está implementado e o que falta.

### 9.1 Fase 2 — bootstrap (entregada)

- [x] Projeto Flutter criado em `app-robo/` (org provisional)
- [x] Tokens e tema aprovados; formatação pt-BR sem `double`
- [x] CI `.github/workflows/app-robo.yml` (analyze, formta, test, build web)

### 9.2 Fase 3 — API v1 (entregada)

- [x] Endpoints `status`, `livelo/painel`, `inter/cashback`, `inter/produtos`, `inter/produtos/lojas`, `inter/produtos/historico`
- [x] **Busca de produtos paginada no servidor** (corrige `LIMIT 500`) com filtros
- [x] Cliente Flutter: `ClienteApi`, `Pagina<T>`, modelos, `ApiV1.buscarProdutos`
- [x] Firebase por e-mail/senha, convite fechado, papéis, rate limit e auditoria
- [x] Identificadores Android/iOS `br.com.radarbeneficios.app`
- [x] Gates verdes: tsc, vitest, build do site

### 9.3 Fase 4.1 — shell web, estados, integração (entregada)

- [x] Construção da API real injetável para test
- [x] Widgets de estado (carregar, vazio, falha)
- [x] Barra lateral com 5 destinos, `IndexedStack` preserva estado
- [x] Página Início consulta o `/status` real
- [x] 34 testes Flutter verdes + build web

### 9.4 Pendiente (falta)

| Pendiente | Fase |
|---|---|
| Painel Livelo | 4.2 |
| Painel Inter (cashback) | 4.3 |
| Produtos + histórico | 4.4 |
| Mutaciones admin | 5 |
| Push e reportes | 6 |
| Barra inferior móvil | plataformas |

### 9.5 Gates respondidos (Sección 6)

- Backend: `site/app/api/v1/`
- Paginação: página + `atualizado_em`/`qualidade` (sem cursor)
- Filtros: marca/categoria/loja/precio
- Login: Firebase e-mail/senha conectado e validado em produção
- Nome público: "Radar de Benefícios"
