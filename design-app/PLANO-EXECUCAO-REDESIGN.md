# Plano de execução — `re-design` mobile only

**Objetivo:** levar o Flutter mobile ao protótipo aprovado gastando contexto apenas no que afeta o celular.  
**Fonte visual:** [`prototipo-mobile.html`](prototipo-mobile.html)  
**Contrato:** [`UI_SPEC.md`](UI_SPEC.md)  
**Web:** fora do escopo desta branch.  
**Testes neste ciclo:** somente **unitários e widgets**. Golden, integração, E2E, smoke automatizado e outros tipos ficam para outro ciclo.

## Gate 0 — ambiente

```bash
git switch re-design
git pull origin re-design
cd app
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
```

`dart format` e `flutter analyze` são validações estáticas, não tipos de teste, e continuam obrigatórios.

## Fase 1 — fundação visual mobile

- conferir tokens Flutter contra HTML/UI_SPEC;
- manter claro/escuro e persistência;
- reutilizar `app/lib/app/componentes/`;
- consolidar espaçamento, raios e sombras conforme forem necessários;
- criar/ajustar somente testes unitários e de widgets diretamente afetados.

**Aceite:** base visual reutilizável, sem números mágicos desnecessários, com unitários/widgets da fatia passando.

## Fase 2 — moldura mobile

- reproduzir top bar e gaveta;
- quatro áreas: Início, Livelo, Banco Inter e Buscar produtos;
- alertas, conta, administração, tema e saída ficam como utilidades;
- preservar autorização e estado das áreas;
- validar comportamento com testes de widget mínimos da navegação e das ações tocadas.

## Fase 3 — Início

- reproduzir cabeçalho, hero, métricas e módulos;
- usar `/api/resumo` e dados reais;
- preservar atualização/retry e último retrato válido;
- validar 390×844, 320 px e texto ampliado por testes de widget quando necessário para evitar overflow/regressão.

## Fase 4 — Livelo

- reproduzir abas, busca, filtros e cartões;
- manter pontos, campanha, validade, histórico e acompanhamento ligados à API real;
- preservar busca, página e posição ao acompanhar/remover;
- cobrir somente regras/mapeamentos com unitários e interações principais com widgets.

## Fase 5 — Banco Inter

- reproduzir a área Inter do HTML;
- não misturar Sites parceiros e Compre direto;
- preservar seleção, paginação, busca e feedback imediato;
- diferenciar pedido de coleta aceito de coleta concluída;
- cobrir somente lógica unitária e comportamento de widget diretamente alterados.

## Fase 6 — Buscar produtos

- reproduzir busca, filtros e ProductCard;
- destacar `Após cashback` conforme HTML;
- preservar debounce, paginação, histórico, links e posição útil;
- catálogo completo nunca vai para o Flutter;
- testar somente unidades de lógica e widgets essenciais da busca/listagem.

## Fase 7 — utilidades mobile

- alinhar alertas e conta/sistema;
- manter administração protegida;
- manter zona de perigo separada;
- não inventar histórico de alertas sem contrato;
- adicionar apenas unitários/widgets quando houver comportamento novo ou alterado.

## Fase 8 — fechamento mobile

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test <arquivos-unitarios-e-widgets-relevantes>
```

Depois:

- build Android previsto pelo projeto, se necessário para a entrega;
- abrir no Samsung/Android de teste somente para conferência manual da interface, sem transformar isso em suíte de teste neste ciclo;
- conferir claro/escuro e as quatro jornadas principais de forma manual quando necessário;
- preparar PR/merge somente depois dos gates.

**Não executar neste ciclo:** golden tests, testes de integração, E2E, testes Web, smoke automatizado, testes de performance ou qualquer outra categoria além de unitários e widgets.

## Economia de contexto

O Codex deve:

- trabalhar **uma fase por vez**;
- abrir somente arquivos ligados à fase atual;
- consultar somente o PRD específico do domínio quando necessário;
- não reler histórico, `CLAUDE.md`, protótipo Web ou documentação ampla sem uma razão concreta;
- rodar somente unitários/widgets diretamente relacionados à alteração;
- não executar a suíte Flutter inteira por rotina se ela trouxer categorias fora do escopo;
- não repetir análise/teste que já passou se nenhum arquivo relacionado mudou.

## Testes adiados para outro ciclo

Ficam explicitamente para depois:

- golden tests;
- integração;
- E2E;
- smoke automatizado/dispositivo;
- performance;
- regressão visual automatizada;
- testes Web.

A ausência desses testes nesta branch é uma decisão de escopo para acelerar o redesign, não autorização para apagar testes existentes. **Não delete testes existentes dessas categorias; apenas não crie, atualize nem execute como parte deste plano.**

## Prompt para o Codex

> Trabalhe somente no mobile da branch `re-design`. Não trabalhe no Web. Leia `AGENTS.md`, `design-app/UI_SPEC.md`, `design-app/prototipo-mobile.html` e `design-app/PLANO-EXECUCAO-REDESIGN.md`. Abra apenas os arquivos Flutter e testes necessários para a fase atual e consulte o PRD específico somente se precisar confirmar uma regra ou contrato. Execute uma fase por vez, começando pela Fase 1. Neste ciclo os únicos tipos de teste autorizados são testes unitários e testes de widgets. Não crie, atualize ou execute golden, integração, E2E, smoke automatizado, performance ou testes Web. `dart format` e `flutter analyze` continuam obrigatórios por serem validações estáticas. Implemente, formate, analise, rode apenas os unitários/widgets relevantes, renderize o app quando necessário para comparar manualmente com o HTML e corrija as diferenças. Não invente UI. Ao final informe arquivos alterados, comandos executados, unitários/widgets rodados e divergências restantes.
