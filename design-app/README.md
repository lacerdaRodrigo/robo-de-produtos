# `design-app/` — Protótipos visuais (Web e Mobile)

Protótipos HTML usados para **validar a experiência visual** das novas telas do
Flutter **antes** de escrever código. Seguem a regra de produto: toda
funcionalidade visível, tela ou jornada passa primeiro pelo protótipo da
plataforma afetada e só depois é implementada. Mudanças compartilhadas devem ser
validadas nos dois protótipos.

## Arquivos

| Arquivo | Para quê |
|---|---|
| [`prototipo-web.html`](prototipo-web.html) | Visual do app na largura de Web (tela larga / lateral) |
| [`prototipo-mobile.html`](prototipo-mobile.html) | Nova direção mobile: gaveta com quatro áreas principais e temas claro/escuro |
| [`PLANO-MIGRACAO-MOBILE.md`](PLANO-MIGRACAO-MOBILE.md) | Roteiro incremental para levar o novo protótipo ao Flutter sem redesenhar o Web |
| [`PLANO-DE-ACAO.md`](PLANO-DE-ACAO.md) | Registro e direção do ciclo anterior de redesign |
| `assets/` | Fontes vetoriais da marca (logo-radar.svg etc.) |

## Como usar

1. Abra o protótipo correspondente à plataforma;
2. valide o fluxo e a experiência com o responsável;
3. após a aprovação visual, atualize os contratos/PRDs afetados;
4. só então implemente no Flutter (`../app/`), mantendo os protótipos
   sincronizados se a implementação mudar.

Os protótipos **não** são código real nem substituem requisitos. Eles ilustram
com dados claramente fictícios para decisão visual.

O protótipo mobile de 28 de agosto de 2026 é a referência do novo ciclo apenas
para celular. Ele não autoriza mudança visual no Web nem implementação no
Flutter por si só.
