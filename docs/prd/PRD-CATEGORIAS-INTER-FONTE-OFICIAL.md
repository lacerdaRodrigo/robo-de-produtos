# PRD — Categorias do Shopping Inter como fonte oficial

**Status vigente em 2026-09-04:** regra implementada no robô, API e Flutter.
A migration `020_categorias_inter_fonte_oficial.sql` permanece pendente de
validação em ambiente descartável e de autorização explícita antes de aplicação.

Este PRD detalha o contrato de categorias externas do Shopping Inter. Ele
prevalece sobre qualquer descrição anterior de taxonomia interna de categorias
de produtos.

## 1. Objetivo

Simplificar o domínio de categorias de produtos do Shopping Inter para que a categoria enviada pelo próprio Inter seja a única referência funcional usada pelo Radar.

A partir desta decisão:

```text
JSON do Shopping Inter
    ↓
item.categoryName ou sku.categoryName
    ↓
ProdutoDiretoInter.categoria
    ↓
produto_direto_inter.categoria
    ↓
API
    ↓
App
```

O Radar não reclassifica o produto nem altera sua categoria externa. Uma camada
editorial, versionada e exclusivamente de **navegação** pode reunir categorias
externas já observadas para abrir uma busca contextual; ela não substitui a
origem, não é persistida no produto e não decide sua existência no catálogo.

## 2. Evidência que motivou a mudança

A fonte principal desta decisão é:

- `docs/VALIDACAO-CATEGORIAS-JSON-INTER-2026-09-04.md`

Na execução manual observada em produção:

- workflow: `shopping-inter`;
- GitHub Actions run: `#98`;
- run ID: `33881332856`;
- branch: `main`;
- commit executado: `d48d0135b6973f71968fc478ae71bac0a36f458a`;
- versão do robô: `1.53.1`;
- execução no banco: `ID 13`;
- lojas planejadas: `6`;
- lojas com sucesso: `6`;
- lojas com falha: `0`;
- produtos únicos/publicados: `9.565`;
- produtos com `produto_direto_inter.categoria` preenchida: `9.565`;
- produtos sem categoria: `0`;
- cobertura observada: `100%`;
- categorias externas distintas: `510`.

O extrator que rodou nessa execução usa diretamente:

```python
categoria=_texto_opcional(
    item.get("categoryName") or sku.get("categoryName"),
    MAX_TEXTO,
)
```

Logo, a categoria já é um dado da fonte externa e não precisa ser descoberta pelo Radar.

## 3. Decisão funcional definitiva deste plano

### 3.1 Fonte de verdade

A categoria oficial de um produto do Shopping Inter é:

```text
produto_direto_inter.categoria
```

Esse campo representa a categoria externa recebida do Inter.

### 3.2 Regra de exibição

```text
Se a categoria do Inter existe
→ usar exatamente a categoria recebida do Inter

Se a categoria do Inter não existe
→ colocar o produto no agrupamento "Sem categoria"
```

### 3.3 Regra de preservação da origem

`Sem categoria` é um fallback funcional de leitura/exibição.

**Não gravar a string `Sem categoria` em `produto_direto_inter.categoria` apenas para preencher ausência.**

O campo deve continuar fiel ao que veio da origem:

```text
Inter enviou categoria → persistir categoria recebida
Inter não enviou categoria → manter NULL/ausente na origem
API/App → apresentar esse produto dentro de "Sem categoria"
```

Isso garante que, se uma coleta futura passar a fornecer categoria para o produto, ele saia automaticamente de `Sem categoria` e passe a aparecer na categoria real enviada pelo Inter.

### 3.4 Todo produto deve pertencer a um agrupamento visível

Nenhum produto ativo pode desaparecer da experiência por falta de categoria.

Todo produto deve aparecer em exatamente um dos casos funcionais:

1. categoria externa recebida do Inter;
2. `Sem categoria` quando a origem não informar categoria.

## 4. O que não será mais responsabilidade do Radar

O Radar não deve mais:

- criar uma taxonomia própria para classificar produtos do Shopping Inter;
- inferir categoria pelo nome do produto;
- inferir categoria pela marca;
- inferir categoria por descrição;
- traduzir automaticamente a categoria recebida;
- corrigir o nome escolhido pelo Inter;
- unir categorias consideradas sinônimas;
- transformar `Celulares`, `Smartphones` e `Android` em uma categoria própria comum;
- criar categoria pai/filha por interpretação interna;
- exigir `categoria_radar_id` para um produto ser exibido;
- excluir produtos que não tenham mapeamento interno;
- manter taxonomia Radar ou mapeamento que regrave, esconda ou altere a
  categoria externa do produto.

Se o Inter enviar `Notebooks gamer`, o Radar usa `Notebooks gamer`.

Se o Inter enviar `Android`, o Radar usa `Android`.

Se o Inter enviar `2 Portas`, o Radar usa `2 Portas`.

A responsabilidade pela taxonomia passa a permanecer na fonte externa.

## 5. Comportamento esperado quando o Inter mudar uma categoria

O Radar acompanha a fonte.

Exemplo:

```text
Coleta A
produto X → categoria = "Celulares"

Coleta B
produto X → categoria = "Smartphones"
```

Após a publicação da coleta B, o produto deve passar a aparecer em `Smartphones`.

O Radar não deve manter o produto artificialmente em `Celulares` por uma regra própria antiga.

## 6. Comportamento esperado para categoria nova

Se amanhã o Inter criar uma categoria nunca vista pelo Radar:

```text
categoryName = "Nova Categoria do Inter"
```

nenhuma migration, enum, cadastro manual ou alteração de código deve ser necessária apenas para a categoria existir.

Depois da coleta e publicação, a categoria deve poder aparecer automaticamente na listagem de categorias, desde que existam produtos ativos associados a ela dentro do escopo consultado.

## 7. Comportamento esperado para produto sem categoria

Se o JSON não trouxer `item.categoryName` nem `sku.categoryName`:

```text
produto_direto_inter.categoria = NULL
```

Na leitura funcional:

```text
categoria exibida = "Sem categoria"
```

O produto:

- continua ativo;
- continua pesquisável;
- continua paginado normalmente;
- continua aparecendo na loja correta;
- continua com preço, cashback e histórico normais;
- aparece no agrupamento/filtro `Sem categoria`;
- não recebe classificação inventada pelo Radar.

## 8. Identidade das categorias externas

A implementação deve preservar o valor recebido pelo extrator como nome funcional da categoria.

O extrator já faz apenas a higienização mínima de texto necessária para persistência segura, como remoção de caracteres de controle e `trim`.

Não adicionar normalização semântica como:

- `lowercase` para transformar identidades diferentes em iguais;
- tradução;
- remoção de acentos para unificação;
- sinônimos;
- stemming;
- IA/classificador;
- tabela manual de equivalência.

Para filtro por uma categoria selecionada na interface, preferir correspondência
exata do valor persistido, e não busca parcial por `ILIKE`, para evitar que uma
categoria selecione acidentalmente outra categoria de nome parecido. Um escopo
de navegação aprovado pode ser resolvido pela API como uma lista declarada de
valores externos exatos; ele é uma união de correspondências exatas, não uma
inferência pelo nome de produto, marca ou categoria.

`Sem categoria` deve ser tratado como identificador funcional reservado do fallback, sem conflitar com a categoria externa original.

## 9. Estado atual que precisa ser simplificado

A implementação anterior criou uma camada de taxonomia Radar que hoje participa do fluxo de produtos.

Foram identificados, entre outros, os seguintes pontos:

### Banco/migrations

- `migracoes/018_categorias_produtos_inter.sql`;
- `migracoes/019_classificacao_exata_categorias_produtos_inter.sql`;
- tabela `categoria_radar`;
- tabela `categoria_radar_acompanhada`;
- tabela `categoria_externa_loja_inter`;
- tabela `mapeamento_categoria_loja_inter`;
- campos de classificação em `produto_direto_inter`, incluindo:
  - `categoria_externa_loja_inter_id`;
  - `categoria_radar_id`;
  - `estado_classificacao`;
  - `motivo_classificacao`;
  - `mapeamento_categoria_loja_inter_id`;
  - `versao_mapeamento`;
  - `classificado_em`.

### Robô

- `backend/robo/src/robo_livelo/adaptadores_produtos_inter.py` contém sincronização/mapeamento/classificação de categorias externas para Radar.

### API

- `backend/api/lib/banco-categorias-produtos-inter.ts` usa `categoria_radar` e `categoria_radar_acompanhada`;
- `backend/api/lib/banco-produtos-inter.ts` inclui `categoria_radar_slug`, `categoria_radar_nome`, `categoria_radar` como filtro e restringe resultados por `p.categoria_radar_id` quando há preferência configurada;
- `backend/api/app/api/inter/produtos/route.ts` aceita `categoria_radar`;
- `backend/api/app/api/inter/produtos/categorias/route.ts` atualmente lê/salva categorias Radar.

### App Flutter

- `app/lib/core/api/api.dart` ainda envia `categoria_radar` na busca de produtos;
- modelos e telas de Produtos/Compre direto possuem comportamento construído em torno da taxonomia Radar e devem ser revisados antes de alteração.

### Testes

Existem testes específicos da taxonomia Radar, incluindo:

- `backend/api/lib/banco-categorias-produtos-inter.teste.ts`;
- `backend/api/lib/banco-produtos-inter.teste.ts`;
- `backend/api/testes/categorias-produtos-inter-api.teste.ts`;
- `backend/api/testes/produtos-categorias-api.teste.ts`;
- `backend/api/testes/migracao-categorias-produtos-inter.teste.ts`;
- `backend/api/testes/migracao-classificacao-exata-categorias-produtos-inter.teste.ts`.

Esses testes devem ser ajustados/removidos somente na medida em que o comportamento correspondente deixar de existir.

## 10. Regra para migrations já aplicadas

As migrations `018` e `019` já fazem parte do histórico do projeto.

**Não apagar ou reescrever migrations já aplicadas em produção para fingir que nunca existiram.**

A remoção de estruturas obsoletas deve ocorrer por uma nova migration forward-only, depois que:

1. o robô não depender mais delas;
2. a API não depender mais delas;
3. o app não depender mais delas;
4. os dados que eventualmente precisem ser preservados forem avaliados;
5. a nova implementação estiver validada;
6. houver autorização explícita para alterar o banco de produção.

A limpeza física do schema deve ser a última etapa, não a primeira.

## 11. Estratégia de implementação proposta

### Fase 0 — revisão e congelamento da decisão

- [x] Confirmar que a categoria oficial será a categoria recebida do Inter.
- [x] Confirmar que o Radar não manterá taxonomia própria de produtos do Shopping Inter.
- [x] Confirmar que produtos sem categoria irão para `Sem categoria`.
- [x] Confirmar que nenhum produto deve desaparecer por ausência de categoria.
- [x] Confirmar que `Sem categoria` não substitui o valor original no campo de origem.
- [ ] Revisar este documento.
- [ ] Autorizar explicitamente o início da implementação.

**Gate:** nenhum código, migration ou produção deve ser alterado antes da aprovação deste plano.

### Fase 1 — caracterizar o comportamento atual

Antes de remover qualquer coisa:

- [ ] mapear todos os usos de `categoria_radar` no backend e app;
- [ ] mapear todos os usos de `categoria_radar_id` nas queries;
- [ ] identificar quais telas atualmente dependem de categoria acompanhada;
- [ ] identificar quais preferências de usuário já podem estar gravadas em `categoria_radar_acompanhada`;
- [ ] consultar quantidade real de registros nessas tabelas antes de definir estratégia de migração;
- [ ] caracterizar com testes o fluxo atual que precisa continuar funcionando: busca, paginação, loja, histórico, cashback e filtros não relacionados a categoria.

**Gate:** nenhum dado de usuário deve ser descartado por suposição.

### Fase 2 — simplificar o robô

Objetivo: o robô deve apenas preservar a categoria externa já recebida.

Manter:

```text
item.categoryName
    ↓ fallback
sku.categoryName
    ↓
ProdutoDiretoInter.categoria
    ↓
produto_direto_inter.categoria
```

Remover da execução normal, depois de validar dependências:

- [ ] sincronização de categoria externa para taxonomia Radar;
- [ ] mapeamento automático externo → Radar;
- [ ] atualização de `categoria_radar_id`;
- [ ] estados de classificação cuja única finalidade seja a taxonomia Radar;
- [ ] qualquer bloqueio que dependa de classificação.

Garantir:

- [ ] categoria externa continua sendo atualizada a cada coleta;
- [ ] categoria ausente continua válida como ausência de dado;
- [ ] produto sem categoria não é descartado pelo extrator/coletor;
- [ ] nenhuma inferência é adicionada como substituição.

### Fase 3 — substituir a fonte das categorias na API

Objetivo: a API deve derivar as categorias diretamente dos produtos ativos.

Regra conceitual:

```sql
categoria_funcional =
  CASE
    WHEN p.categoria IS NULL OR BTRIM(p.categoria) = ''
      THEN 'Sem categoria'
    ELSE p.categoria
  END
```

A implementação não precisa necessariamente materializar esse `CASE` em coluna física; pode ser derivado na consulta/contrato.

A listagem de categorias deve:

- [ ] vir das categorias externas efetivamente presentes no catálogo consultável;
- [ ] usar valores reais do Inter;
- [ ] eliminar apenas duplicidade exata necessária para a listagem;
- [ ] incluir `Sem categoria` somente quando houver ao menos um produto naquele estado dentro do escopo;
- [ ] não depender de cadastro em `categoria_radar`;
- [ ] não depender de mapeamento;
- [ ] não exigir categoria pai;
- [ ] não criar hierarquia própria;
- [ ] aceitar categoria nova automaticamente após nova coleta.

### Fase 4 — corrigir o filtro de produtos

O filtro funcional de categoria deve usar a categoria externa.

Para uma categoria real:

```text
categoria selecionada = valor exato recebido do Inter
→ filtrar p.categoria pelo valor exato
```

Para `Sem categoria`:

```text
→ filtrar p.categoria IS NULL ou vazia após trim
```

Remover da busca de produtos, depois de compatibilidade/transição:

- [ ] `categoria_radar` como parâmetro funcional;
- [ ] CTEs de descendentes de `categoria_radar`;
- [ ] filtro por `p.categoria_radar_id`;
- [ ] restrição que faça produto desaparecer porque o usuário não possui mapeamento Radar.

Preservar integralmente:

- [ ] paginação;
- [ ] filtro de loja;
- [ ] filtro de marca;
- [ ] preço mínimo/máximo;
- [ ] busca textual;
- [ ] dados monetários em NUMERIC/Decimal;
- [ ] histórico independente por produto/loja;
- [ ] estados de falha/parcial/atraso existentes.

### Fase 5 — decidir e migrar a preferência de categorias, se a funcionalidade continuar

Existe hoje lógica de `categorias acompanhadas` baseada em `categoria_radar_acompanhada`.

Como a taxonomia Radar deixará de ser a fonte, essa funcionalidade não pode continuar gravando IDs da taxonomia própria.

Antes de implementar:

- [ ] verificar se existem preferências reais de usuários gravadas;
- [ ] definir como a seleção passará a identificar a categoria externa sem inventar uma taxonomia;
- [ ] usar o valor real da categoria do Inter como referência funcional;
- [ ] tratar `Sem categoria` como opção funcional apenas se ela existir no catálogo;
- [ ] não converter preferências antigas silenciosamente quando não houver equivalência comprovada;
- [ ] registrar estratégia de transição antes de remover dados antigos.

Se a funcionalidade de acompanhar categorias deixar de fazer sentido com a nova decisão, sua remoção deve ser uma decisão explícita separada — não assumir neste plano.

### Fase 6 — adaptar o app Flutter

Objetivo: o Flutter deve consumir as categorias retornadas pela API, sem manter catálogo próprio.

- [ ] remover dependência de `categoria_radar` no cliente;
- [ ] remover modelo/hierarquia Radar que deixar de existir no contrato;
- [ ] listar categorias reais retornadas pela API;
- [ ] exibir os nomes exatamente como recebidos pelo contrato;
- [ ] exibir `Sem categoria` como categoria normal de fallback quando retornada;
- [ ] ao selecionar uma categoria, enviar a identidade/valor definido pelo contrato real;
- [ ] não hardcodar as 510 categorias observadas;
- [ ] não criar enum de categorias;
- [ ] não traduzir categorias no cliente;
- [ ] categoria nova deve aparecer sem atualização do app;
- [ ] preservar paginação, busca e posição útil conforme regras atuais do projeto.

### Fase 7 — testes

Atualizar somente testes afetados pela mudança.

#### Robô

- [ ] produto com `item.categoryName` preserva a categoria;
- [ ] fallback para `sku.categoryName` continua funcionando;
- [ ] ausência de ambos mantém categoria nula sem descartar produto;
- [ ] nenhuma classificação Radar é exigida para publicação.

#### API

- [ ] lista categorias distintas reais do catálogo;
- [ ] categoria nova aparece sem cadastro manual;
- [ ] filtro por categoria externa usa correspondência correta;
- [ ] `Sem categoria` retorna apenas produtos sem categoria externa;
- [ ] produtos sem categoria continuam no total geral;
- [ ] nenhum produto é excluído por ausência de `categoria_radar_id`;
- [ ] paginação continua correta com filtro de categoria.

#### Flutter

Seguir `AGENTS.md`: somente unitários/widgets diretamente afetados.

- [ ] parsing da nova resposta real de categorias;
- [ ] renderização de categoria externa;
- [ ] renderização de `Sem categoria`;
- [ ] seleção/filtro usa o contrato real;
- [ ] categoria desconhecida/nova não quebra a UI;
- [ ] nomes longos continuam sem overflow;
- [ ] claro/escuro continuam funcionando onde aplicável.

Não criar golden, integração, E2E, smoke, performance ou teste Web para esta mudança.

### Fase 8 — migração/limpeza de banco

Somente depois de robô, API e app não dependerem mais da taxonomia Radar:

- [ ] levantar dados existentes nas estruturas antigas;
- [ ] confirmar que nenhuma funcionalidade restante depende delas;
- [ ] criar nova migration de limpeza forward-only;
- [ ] remover índices/FKs antes das colunas/tabelas conforme dependências reais;
- [ ] remover campos de classificação obsoletos de `produto_direto_inter` se comprovadamente sem uso;
- [ ] remover tabelas Radar/mapeamento apenas se não houver outra funcionalidade válida dependendo delas;
- [ ] manter `produto_direto_inter.categoria` como dado de origem;
- [ ] validar migration em branch de banco antes de produção;
- [ ] aplicar em produção somente com autorização explícita.

## 12. Ordem segura de rollout

A ordem recomendada é:

```text
1. Aprovar plano
2. Caracterizar dependências e dados existentes
3. Preparar API para usar categoria externa
4. Adaptar app para o novo contrato
5. Simplificar/remover dependência da classificação no robô
6. Validar ponta a ponta com coleta real
7. Confirmar que nenhum consumidor usa categoria Radar
8. Criar migration de limpeza
9. Validar migration fora de produção
10. Autorizar aplicação em produção
11. Reexecutar robô
12. Validar catálogo e categorias reais
```

Durante uma transição, é aceitável manter colunas/tabelas antigas temporariamente sem uso. É preferível uma etapa transitória redundante a remover schema cedo e quebrar produção.

## 13. Critérios de aceitação funcional

A implementação só estará correta quando todos os itens abaixo forem verdadeiros:

- [ ] a categoria exibida de um produto vem do campo externo do Inter;
- [ ] nenhum classificador interno decide a categoria do produto;
- [ ] nenhum mapeamento Radar é necessário para o produto aparecer;
- [ ] todo produto ativo aparece em uma categoria real ou em `Sem categoria`;
- [ ] produtos sem categoria não somem do catálogo;
- [ ] `Sem categoria` não sobrescreve o dado bruto de origem;
- [ ] categoria nova do Inter aparece sem alteração de código;
- [ ] mudança de categoria feita pelo Inter é refletida após nova coleta;
- [ ] não existe lista hardcoded de categorias no backend ou Flutter;
- [ ] não existe tradução/agrupamento automático de categorias;
- [ ] o filtro seleciona a categoria externa correta;
- [ ] paginação continua obrigatória;
- [ ] busca continua vindo do banco/API, nunca diretamente do Inter enquanto o usuário digita;
- [ ] preço/cashback/histórico não sofrem regressão;
- [ ] nenhum dado de usuário é apagado sem estratégia explícita de migração;
- [ ] testes afetados passam;
- [ ] validação com uma nova execução real do robô confirma o comportamento.

## 14. Critérios específicos para `Sem categoria`

- [ ] existe como agrupamento funcional quando necessário;
- [ ] contém todos os produtos ativos sem categoria externa no escopo consultado;
- [ ] não contém produtos que possuam categoria externa válida;
- [ ] não precisa existir na listagem quando o total de produtos sem categoria for zero;
- [ ] não é persistido artificialmente sobre o campo de origem;
- [ ] um produto sai automaticamente do grupo quando uma coleta futura fornecer categoria;
- [ ] um produto pode entrar no grupo se a fonte deixar de fornecer categoria numa coleta futura, conforme regra de atualização do catálogo.

## 15. Não objetivos

Este plano não autoriza:

- redesenhar telas;
- criar nova tela;
- inventar novo fluxo;
- inventar endpoint sem antes revisar o contrato existente;
- criar categoria manual;
- traduzir categorias;
- criar taxonomia hierárquica própria;
- usar IA para classificar produtos;
- alterar Livelo;
- alterar Inter Sites Parceiros;
- mexer no Web por consequência desta decisão;
- remover migration histórica já aplicada;
- executar mudança destrutiva no banco sem aprovação.

## 16. Documentos que precisam ser reconciliados após aprovação

A decisão deste plano entra em conflito com partes da documentação criada para a taxonomia Radar.

Após aprovação e durante a implementação, revisar somente os trechos afetados em:

- `docs/planos/PLANO-MODIFICACAO-PRODUTOS.md`;
- `docs/planos/PLANO-ACAO-TEMPORARIO-PRODUTOS-CATEGORIAS-V11.md`;
- documentação/PRD que declare `categoria_radar` como fonte funcional dos produtos;
- protótipo experimental de categorias, apenas se ele representar hierarquia própria Radar que não existirá mais.

Não apagar o histórico da decisão anterior. Marcar claramente o que foi substituído pela nova evidência e pela decisão de 04/09/2026.

## 17. Resumo executivo

Antes:

```text
Categoria do Inter
    ↓
Categoria externa registrada
    ↓
Mapeamento
    ↓
Categoria Radar
    ↓
Classificação do produto
    ↓
API/App
```

Depois:

```text
Categoria do Inter
    ↓
produto_direto_inter.categoria
    ↓
API/App
```

Fallback:

```text
categoria Inter existe
→ usar categoria Inter

categoria Inter não existe
→ exibir/agrupar em "Sem categoria"
```

A mudança reduz responsabilidade interna, evita erros de classificação, elimina necessidade de manter uma taxonomia paralela e mantém o Radar fiel à informação entregue pela fonte do catálogo.

---

**Próximo passo:** revisão deste plano pelo responsável. Nenhuma implementação deve começar até aprovação explícita.
