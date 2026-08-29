# Plano de execução — branch `re-design`

**Objetivo:** levar o Flutter mobile ao protótipo aprovado sem depender de correções manuais por screenshot.  
**Fonte visual:** [`prototipo-mobile.html`](prototipo-mobile.html)  
**Contrato visual:** [`UI_SPEC.md`](UI_SPEC.md)  
**Backend:** preservar contratos e comportamento atuais; redesign não autoriza mudança de backend por conta própria.

## Gate 0 — preparar o ambiente

1. trocar para a branch `re-design` e atualizar a cópia local;
2. entrar em `app/`;
3. executar `flutter pub get`;
4. executar `dart format --output=none --set-exit-if-changed lib test`;
5. executar `flutter analyze`;
6. executar `flutter test` para confirmar a linha de base da branch.

Se qualquer gate falhar antes de mudança de tela, corrigir primeiro ou registrar claramente a falha preexistente.

## Fase 1 — fundação visual

- conferir `app/lib/app/tema/tokens.dart` contra `UI_SPEC.md` e o HTML;
- manter tema claro/escuro e persistência já existentes;
- revisar componentes de `app/lib/app/componentes/` antes de criar novos;
- consolidar espaçamento, raios e sombras conforme cada componente do HTML for migrado;
- manter testes de tokens e tema passando.

**Aceite:** nenhum valor visual estrutural importante fica duplicado sem necessidade e os componentes novos usam tokens semânticos.

## Fase 2 — moldura e navegação mobile

- reproduzir top bar e gaveta do HTML;
- manter exatamente quatro áreas principais: Início, Livelo, Banco Inter e Buscar produtos;
- manter tema, alertas, conta, administração e saída como utilidades;
- preservar autorização administrativa;
- preservar a experiência Web/layout amplo.

**Goldens:** moldura mobile clara, escura, gaveta aberta e regressão Web.

## Fase 3 — Início

- migrar a composição do HTML: cabeçalho, hero, métricas e módulos;
- usar somente dados reais de `/api/resumo`;
- preservar atualização/retry e último retrato válido;
- validar 390×844, 320 px e texto ampliado.

**Goldens:** Início claro/escuro e Web de regressão.

## Fase 4 — Livelo

- reproduzir abas, busca, filtros e cartões do protótipo;
- manter pontos, campanha, validade, histórico e acompanhamento ligados aos contratos reais;
- preservar busca, página e posição ao acompanhar/remover;
- não transformar navegação em consulta direta à Livelo.

**Goldens:** catálogo/estado principal claro e escuro; estados vazios/erro quando mudarem a composição.

## Fase 5 — Banco Inter

- reproduzir a área Inter do protótipo sem misturar Sites parceiros e Compre direto;
- manter Cashback/Acompanhadas conforme o plano funcional;
- preservar seleção, paginação e feedback imediato;
- diferenciar pedido aceito de coleta concluída.

**Goldens:** área principal clara/escura e estados relevantes.

## Fase 6 — Buscar produtos

- reproduzir busca, filtros e cartões de produto;
- destacar `Após cashback` conforme o HTML;
- manter preço atual e preço líquido lado a lado quando houver espaço previsto;
- preservar debounce, paginação, histórico, validação de links e posição útil;
- nunca carregar catálogo inteiro no Flutter.

**Goldens:** resultados claro/escuro, vazio e erro relevante.

## Fase 7 — utilidades

- alinhar folhas de alertas e conta/sistema ao HTML;
- manter administração protegida e zona de perigo separada;
- não inventar caixa de entrada histórica sem endpoint correspondente.

## Fase 8 — validação final

Na raiz de `app/`:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Depois:

- rodar os builds previstos pelo projeto;
- abrir o app no Android/Samsung de teste;
- conferir retrato e paisagem;
- conferir claro/escuro e persistência após reinício;
- conferir largura estreita/texto ampliado;
- conferir que Web/layout amplo não mudou visualmente;
- só então preparar PR/merge.

## Regra para atualização de golden

`flutter test --update-goldens` não é ferramenta para apagar divergência. Antes de regenerar:

1. abrir o estado correspondente no HTML;
2. confirmar que a implementação pretendida segue essa referência;
3. executar o teste normalmente e analisar a divergência;
4. corrigir o Flutter se o HTML estiver certo;
5. regenerar somente quando o HTML/`UI_SPEC.md` tiverem mudado de propósito ou quando o golden antigo comprovadamente representar a versão anterior aprovada.

## Prompt curto para iniciar no Codex

> Trabalhe na branch `re-design`. Leia `AGENTS.md`, `CLAUDE.md`, `design-app/UI_SPEC.md`, `design-app/prototipo-mobile.html` inteiro e `design-app/PLANO-EXECUCAO-REDESIGN.md`. O HTML é a fonte visual de verdade do redesign mobile e os PRDs/API são a fonte de regras e dados. Não invente UI. Execute uma fase por vez, começando pela Fase 1, e em cada fase faça implementação, formatação, análise, testes, goldens e comparação visual antes de declarar concluído. Preserve backend e Web/layout amplo salvo autorização explícita. Não me peça screenshots para diferenças que podem ser determinadas pelo HTML ou pelos testes locais. Ao final de cada fase, informe arquivos alterados, comandos executados, resultado dos gates e divergências restantes.
