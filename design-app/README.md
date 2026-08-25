# `design-app/` — Protótipos visuais (Web e Mobile)

Protótipos HTML usados para **validar a experiência visual** das novas telas do
Flutter **antes** de escrever código. Seguem a regra de produto: toda
funcionalidade visível, tela ou jornada passa primeiro pelos dois protótipos e
só depois é implementada.

## Arquivos

| Arquivo | Para quê |
|---|---|
| [`prototipo-web.html`](prototipo-web.html) | Visual do app na largura de Web (tela larga / lateral) |
| [`prototipo-mobile.html`](prototipo-mobile.html) | Visual do app no celular (barra inferior) |
| [`PLANO-DE-ACAO.md`](PLANO-DE-ACAO.md) | Direção e roteiro do redesign |
| `assets/` | Fontes vetoriais da marca (logo-radar.svg etc.) |

## Como usar

1. Abra o protótipo correspondente à plataforma;
2. valide o fluxo e a experiência com o responsável;
3. após a aprovação visual, atualize os contratos/PRDs afetados;
4. só então implemente no Flutter (`../app/`), mantendo os protótipos
   sincronizados se a implementação mudar.

Os protótipos **não** são código real nem substituem requisitos. Eles ilustram
com dados claramente fictícios para decisão visual.
