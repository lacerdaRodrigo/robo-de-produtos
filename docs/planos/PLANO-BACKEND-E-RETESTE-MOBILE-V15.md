# Plano de implementação do backend e reteste Mobile V15

## Objetivo

Fechar as lacunas de backend necessárias ao Mobile V15 e retestar o aplicativo
completo no Samsung SM-M135M, buscando o resultado final de 42 testes verdes,
sem alterar o Web e sem alterar o executor Android da Pichau.

Estado inicial: branch `codex/design-mobile-v15-definitivo`, commit `909dd88`.
Branch de execução: `codex/backend-mobile-v15-fechamento`.

## Execução local registrada — 2026-09-19

- ✅ Rota consolidada, resumo pessoal, modelos Flutter, Meu radar, Home,
  movimento reduzido e sessão expirada implementados.
- ✅ Backend: `npm run checar`, `npm run lint`, `npm run build` e Vitest
  direcionado (`15` testes aprovados).
- ✅ Flutter: `dart format`, `flutter analyze` e testes unitários/widgets
  diretamente afetados (`56` aprovados).
- ✅ `flutter build apk --debug` gerou
  `app/build/app/outputs/flutter-apk/app-debug.apk`.
- ✅ Fixture guardada criada em
  `backend/api/scripts/qa-mobile-v15.mjs`; só escreve com ambiente `test`,
  conexão direta, `QA_RUN_ID`, `QA_ACCOUNT_ID`, backup fora do repositório e
  confirmação literal. O preflight sem variáveis foi bloqueado, como esperado.
- 🟡 Migration ainda não aplicada. Checksum de
  `migracoes/029_indices_mobile_v15.sql`:
  `ec0394b66618b9606373a3a34dcdb97f183813e059f53d87abf41ff78d179a89`.
- ⬜ Publicação, APK e os 42 cenários físicos continuam para depois da
  confirmação operacional. Nenhum cenário físico novo foi marcado como verde.

## Registro e ciclo do plano

1. O plano deve ser salvo nesta pasta antes de qualquer alteração de código,
   indexado em `docs/README.md` e commitado separadamente.
2. A implementação pode alterar somente backend/API necessário ao Mobile V15,
   Flutter, migrations, testes unitários/widgets diretamente afetados e a
   documentação dos domínios envolvidos.
3. A migration não será aplicada pelo Codex nesta primeira etapa. Após a
   implementação, o responsável receberá o arquivo, checksum e comando para
   aplicar a migration em conexão direta. O trabalho ficará pausado até a
   confirmação da aplicação.
4. Depois da confirmação, o Codex publica a API no ambiente atual, compila o
   APK, instala no Samsung e executa o roteiro manual dos 42 testes.
5. Durante a execução, este arquivo funciona como checklist. No fechamento,
   seus contratos serão incorporados aos PRDs e o conteúdo será convertido em
   relatório final, sem deixar instrução obsoleta ativa.

Não registrar credenciais, tokens, URLs privadas ou backups no Git. Preservar o
conteúdo não rastreado de `docs/prints/`.

## Contratos de backend

### `GET /api/alertas/acompanhamentos`

Adicionar leitura autenticada e paginada dos acompanhamentos pessoais. Manter o
`PATCH` existente sem alteração de compatibilidade.

Query parameters:

- `q`: busca por nome ou identificador externo;
- `origem`: `todas`, `livelo`, `inter_cashback`, `inter_produto` ou `pichau`;
- `ordenar`: `recentes` ou `nome`;
- `pagina`: padrão 1;
- `por_pagina`: padrão 20, máximo 50.

Resposta mínima:

```json
{
  "itens": [
    {
      "id": "123",
      "origem": "livelo",
      "tipo_entidade": "parceiro",
      "entidade_id": "456",
      "entidade_externa": "chave-publica",
      "nome": "Nome exibível",
      "estado": "atualizado",
      "valor_atual": "8.00",
      "valor_texto": "8 pontos por real",
      "unidade": "pontos_por_real",
      "url_externa": "https://exemplo.invalid/item",
      "criado_em": "2026-01-01T00:00:00Z",
      "atualizado_em": "2026-01-01T00:00:00Z"
    }
  ],
  "paginacao": {
    "pagina": 1,
    "por_pagina": 20,
    "total": 25,
    "total_paginas": 2
  },
  "totais_por_origem": {
    "livelo": 0,
    "inter_cashback": 0,
    "inter_produto": 0,
    "pichau": 0
  }
}
```

Regras:

- nunca receber `usuario_app_id` do cliente;
- consultar somente banco/API, sem fonte externa durante a busca;
- manter Livelo, Inter Sites parceiros, Inter Compre direto e Pichau em regras
  e joins separados;
- usar `LEFT JOIN` para preservar acompanhamentos cuja fonte esteja
  indisponível;
- manter valores financeiros e de pontuação como texto decimal exato;
- validar e retornar apenas URLs `http` ou `https`;
- validar origem, ordenação e paginação com resposta 400 consistente;
- retornar sempre as quatro origens em `totais_por_origem`, mesmo quando zero.

### Extensão de `GET /api/resumo`

Adicionar bloco retrocompatível `radar`:

```json
{
  "radar": {
    "estado": "atualizado",
    "total_acompanhamentos": 0,
    "por_origem": {
      "livelo": 0,
      "inter_cashback": 0,
      "inter_produto": 0,
      "pichau": 0
    },
    "alertas_nao_lidos": 0,
    "destaque": null
  }
}
```

Quando houver alerta não lido, `destaque` será o mais recente e carregará
origem, tipo, entidade, nome, valor anterior, valor atual, unidade, direção,
data e URL validada.

- ausência real: contagem `0` e `destaque: null`;
- falha: `null` nos campos indisponíveis e estado `parcial` ou
  `indisponivel`, nunca zero fabricado;
- estados aceitos: `atualizado`, `parcial`, `atrasado` e `indisponivel`;
- manter `atividade_recente` temporariamente para clientes antigos;
- o Mobile V15 usará `radar`, não dados ilustrativos nem a atividade antiga.

### Migration 029

Criar migration aditiva, idempotente e compatível contendo apenas:

- índice de listagem em `acompanhamento_usuario` por usuário, atualização e id;
- índice parcial de alertas não lidos por usuário, criação e id;
- `CREATE INDEX CONCURRENTLY IF NOT EXISTS` em conexão direta/unpooled;
- nenhuma remoção de tabela, coluna ou dado.

Entregar checksum e consultas de verificação. Não aplicar antes da confirmação
explícita do responsável.

## Flutter

### Home e Meu Radar

- usar o primeiro alerta não lido real como destaque da Home;
- mostrar carregando, ausência, parcialidade, atraso, falha e retry de forma
  distinta;
- incluir as quatro origens nas contagens;
- transformar Meu Radar em lista real com busca, filtro, ordenação, paginação,
  vazio, erro, remoção otimista, desfazer e rollback;
- preservar busca, página, posição útil e estado da jornada;
- abrir cada origem na subárea correta e somente abrir URLs validadas pela API;
- reutilizar os widgets V15 existentes e não deixar referências do design
  anterior no código.

### Movimento reduzido

- adicionar preferência persistida “Reduzir movimento” na tela Aparência;
- combinar preferência do usuário com `MediaQuery.disableAnimations`;
- fazer animações e transições respeitarem o resultado efetivo;
- manter tema claro, escuro e sistema independentes da preferência.

### Sessão expirada

- centralizar 401 de autenticação como sessão expirada;
- não confundir 401 de App Check, 403 ou falha de rede com sessão expirada;
- exibir reautenticação sobre a moldura atual preservando rota, filtros e
  paginação;
- repetir leituras idempotentes no máximo uma vez após login;
- nunca repetir mutações automaticamente.

Todas as mudanças Flutter devem usar tokens existentes, layout adaptativo,
insets direcionais, semântica, alvos de toque de 48dp e suporte a texto em
200%. O teste comentado de Shopping Inter compacto em
`app/test/app/navegacao/moldura_test.dart` deve permanecer intocado.

## QA controlado

A ferramenta guardada foi criada em
`backend/api/scripts/qa-mobile-v15.mjs`. Executar somente após o checkpoint:

```bash
QA_ENVIRONMENT=test QA_RUN_ID=... QA_ACCOUNT_ID=... \
node scripts/qa-mobile-v15.mjs --preflight
QA_ENVIRONMENT=test QA_RUN_ID=... QA_ACCOUNT_ID=... \
QA_CONFIRM=I_UNDERSTAND_QA_FIXTURE node scripts/qa-mobile-v15.mjs --prepare
QA_ENVIRONMENT=test QA_RUN_ID=... QA_ACCOUNT_ID=... \
QA_CONFIRM=I_UNDERSTAND_QA_FIXTURE node scripts/qa-mobile-v15.mjs --restore
```

O `DATABASE_URL` deve ser direta/unpooled e o `QA_BACKUP_PATH`, quando usado,
deve ficar fora do repositório. A ferramenta não registra e-mail, token ou
senha e falha antes de qualquer escrita quando uma trava não é satisfeita.
Para D-039, a revogação do token Firebase continua sendo ação explícita do
executor autenticado; não deve ser simulada por uma mutação no banco.

Ela deverá:

- salvar fora do repositório, com modo `0600`, papel, acompanhamentos,
  referências de alertas, estados de leitura e preferências originais;
- selecionar entidades reais existentes nos quatro domínios;
- criar acompanhamentos necessários sem alterar catálogos;
- inserir pelo menos 25 alertas com `coleta_id` exclusivo do ciclo;
- marcar as linhas de outbox das fixtures como enviadas na mesma transação,
  sem disparar push;
- preparar lista cheia, paginação, vazio, leitura e ausência de destaque;
- alternar temporariamente administrador/usuário comum;
- restaurar exatamente os dados originais e remover somente o `QA_RUN_ID`;
- interromper antes da escrita se backup, ambiente ou confirmação não forem
  válidos.

Para D-039, revogar tokens da conta de teste com Firebase Admin sem alterar a
senha. Ao final, restaurar banco, preferências, rede, rotação, escala de fonte,
animações e estado local do app; bloquear o Samsung.

## Sequência

### Implementação local

1. Salvar e commitar o plano.
2. Implementar API, modelos Dart, repositórios, controladores, widgets,
   migration, ferramenta de QA e documentação.
3. Executar apenas validações diretamente afetadas:
   `npm run checar`, `npm run lint`, Vitest direcionado, `npm run build`,
   `dart format`, `flutter analyze` e testes Flutter unitários/widgets
   relacionados.
4. Corrigir todos os erros antes do checkpoint da migration.

### Checkpoint da migration

Entregar migration, checksum, comando, consultas de verificação, commits e
resultado dos gates. Pausar até o responsável confirmar que aplicou a migration
no ambiente atual.

### Publicação

Após a confirmação:

1. verificar os índices e contratos reais;
2. registrar o deployment Vercel anterior;
3. publicar a API no ambiente atual;
4. validar status, autenticação, 400, 401, paginação e respostas reais;
5. fazer rollback do deployment anterior se houver regressão crítica;
6. compilar, instalar e abrir o APK apontando para a API publicada.

Se a sessão de publicação não estiver autenticada, pausar apenas para login
externo; não improvisar credenciais nem trocar de provedor.

## Matriz de reteste

Reexecutar os 19 testes que já estavam verdes:

`D-001–D-005`, `D-007–D-009`, `D-012–D-014`, `D-026`, `D-030–D-031`,
`D-033–D-034`, `D-036` e `D-041–D-042`.

Fechar os 23 restantes:

- `D-006`: recuperação real, validação e feedback;
- `D-010–D-011`: Home com resumo, destaque, ausência, parcial, erro, offline e retry;
- `D-015–D-017`: Inter parceiros, busca, filtros, ordenação, paginação,
  acompanhar, rollback, condições e URL;
- `D-018–D-019`: Inter direto, abas, lojas, categorias, filtros, acompanhamento
  e histórico;
- `D-020–D-022`: Livelo, catálogo, filtros, condições, campanhas, validade,
  acompanhamento, paginação e histórico;
- `D-023–D-025`: Pichau, disponibilidade, preço Pix/cartão, detalhe,
  histórico, acompanhamento, paginação e estados parciais;
- `D-027`: Meu Radar cheio/vazio, explorar, alertas, atualização e remoção;
- `D-028–D-029`: lista de alertas, vazio, filtros, paginação e leitura
  individual/coletiva;
- `D-032`: movimento reduzido e persistência;
- `D-035`: acesso administrativo e ausência para usuário comum;
- `D-037–D-038`: retrato, paisagem, teclado, texto em 200% e toque;
- `D-039`: offline, atraso, falha, retry e sessão expirada;
- `D-040`: comparação manual final com o protótipo V15 em claro e escuro.

## Regra de correção

Cada falha terá no máximo três tentativas. Cada tentativa inclui reprodução,
correção, `dart format`, `flutter analyze`, unitário/widget afetado, novo APK
quando necessário, instalação e repetição no aparelho.

Se os testes diretamente afetados passarem, a correção técnica será aceita;
quando for seguro, o cenário físico será repetido. Migration, deploy ou
autenticação externa bloqueados não consomem tentativa. Após três tentativas
sem solução, registrar ❌ com causa e não declarar o projeto concluído.

## Documentação e aceite

Atualizar os PRDs de alertas, resumo/Home, autenticação e preferências,
`docs/testes/TESTES.md`, `docs/PENDENCIAS.md`, `docs/README.md`, README de
migrations e índices documentais.

Durante o reteste, atualizar
`docs/planos/RELATORIO-TESTE-DEVICE-MOBILE-V15.md` com ID, check, tentativa e
evidência:

- ✅ aprovado;
- ❌ falhou após três tentativas;
- 🟡 bloqueado por dependência externa;
- ⬜ ainda não executado.

O aceite final exige 42 testes ✅, nenhum dado fictício promovido a real,
unitários/widgets e análise estática aprovados, API publicada, APK instalado,
documentação consistente e restauração confirmada do banco e do aparelho.
