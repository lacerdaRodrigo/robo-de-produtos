# Plano de execução — `re-design` mobile only

**Objetivo:** levar o Flutter mobile ao protótipo aprovado gastando contexto apenas no que afeta o celular.  
**Fonte visual:** [`prototipo-mobile.html`](prototipo-mobile.html)  
**Contrato:** [`UI_SPEC.md`](UI_SPEC.md)  
**Web:** fora do escopo desta branch.

## Gate 0 — ambiente

```bash
git switch re-design
git pull origin re-design
cd app
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
```

Não rode testes/goldens Web neste gate.

## Fase 1 — fundação visual mobile

- conferir tokens Flutter contra HTML/UI_SPEC;
- manter claro/escuro e persistência;
- reutilizar `app/lib/app/componentes/`;
- consolidar espaçamento, raios e sombras conforme forem necessários;
- rodar apenas testes de tema/tokens/componentes tocados.

**Aceite:** base visual reutilizável e sem números mágicos desnecessários.

## Fase 2 — moldura mobile

- reproduzir top bar e gaveta;
- quatro áreas: Início, Livelo, Banco Inter e Buscar produtos;
- alertas, conta, administração, tema e saída ficam como utilidades;
- preservar autorização e estado das áreas.

**Goldens:** moldura clara, escura e gaveta aberta — somente mobile.

## Fase 3 — Início

- reproduzir cabeçalho, hero, métricas e módulos;
- usar `/api/resumo` e dados reais;
- preservar atualização/retry e último retrato válido;
- validar 390×844, 320 px e texto ampliado.

**Goldens:** Início mobile claro/escuro.

## Fase 4 — Livelo

- reproduzir abas, busca, filtros e cartões;
- manter pontos, campanha, validade, histórico e acompanhamento ligados à API real;
- preservar busca, página e posição ao acompanhar/remover.

**Goldens:** estados principais mobile claro/escuro e estados especiais relevantes.

## Fase 5 — Banco Inter

- reproduzir a área Inter do HTML;
- não misturar Sites parceiros e Compre direto;
- preservar seleção, paginação, busca e feedback imediato;
- diferenciar pedido de coleta aceito de coleta concluída.

**Goldens:** mobile claro/escuro e estados relevantes.

## Fase 6 — Buscar produtos

- reproduzir busca, filtros e ProductCard;
- destacar `Após cashback` conforme HTML;
- preservar debounce, paginação, histórico, links e posição útil;
- catálogo completo nunca vai para o Flutter.

**Goldens:** resultados claro/escuro, vazio e erro relevante.

## Fase 7 — utilidades mobile

- alinhar alertas e conta/sistema;
- manter administração protegida;
- manter zona de perigo separada;
- não inventar histórico de alertas sem contrato.

## Fase 8 — fechamento mobile

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Depois:

- build Android previsto pelo projeto;
- abrir no Samsung/Android de teste;
- conferir retrato e paisagem;
- conferir claro/escuro e persistência após reinício;
- conferir 320 px/texto ampliado;
- conferir as quatro jornadas principais;
- preparar PR/merge somente depois dos gates.

**Não abrir, comparar, testar ou atualizar Web durante o fechamento deste redesign.** Se a suíte completa tiver testes Web que falhem por motivo não relacionado ao mobile, registrar separadamente em vez de transformar isso em tarefa desta branch.

## Economia de contexto

O Codex deve:

- trabalhar **uma fase por vez**;
- abrir somente arquivos ligados à fase atual;
- consultar somente o PRD específico do domínio quando necessário;
- não reler histórico, `CLAUDE.md`, protótipo Web ou documentação ampla sem uma razão concreta;
- usar testes direcionados durante desenvolvimento;
- usar a suíte completa apenas no fechamento de etapa maior;
- não repetir análise/teste que já passou se nenhum arquivo relacionado mudou.

## Golden

Nunca use `--update-goldens` para esconder divergência. Primeiro compare com o HTML. Regenere apenas quando a referência aprovada realmente tiver mudado.

## Prompt para o Codex

> Trabalhe somente no mobile da branch `re-design`. Não trabalhe no Web e não gaste contexto lendo protótipo Web, código Web, golden Web ou documentação Web. Leia `AGENTS.md`, `design-app/UI_SPEC.md`, `design-app/prototipo-mobile.html` e `design-app/PLANO-EXECUCAO-REDESIGN.md`. Abra apenas os arquivos Flutter/testes necessários para a fase atual e consulte o PRD específico apenas se precisar confirmar uma regra ou contrato. Execute uma fase por vez, começando pela Fase 1. Em cada fase faça implementação, formatação, `flutter analyze`, testes direcionados, goldens mobile e comparação visual com o HTML. Não invente UI e não me peça screenshots para diferenças que podem ser descobertas pelo HTML ou pelos testes. Ao final informe arquivos alterados, comandos executados, resultado dos gates e divergências restantes.
