# `design-app/` — Protótipos visuais (Web e Mobile)

Protótipos HTML usados para **validar a experiência visual** das novas telas do Flutter antes de escrever código. No redesign mobile, o HTML aprovado não é apenas inspiração: ele é a **fonte visual de verdade** e deve ser aplicado junto do contrato verificável em [`UI_SPEC.md`](UI_SPEC.md).

PRDs e contratos de API continuam mandando em regra de negócio, dados e segurança. O protótipo manda em estrutura, hierarquia, espaçamento, cores, estados e navegação da experiência aprovada.

## Arquivos

| Arquivo | Para quê |
|---|---|
| [`prototipo-web.html`](prototipo-web.html) | Visual do app na largura de Web (tela larga / lateral) |
| [`prototipo-mobile.html`](prototipo-mobile.html) | Fonte visual de verdade do redesign mobile: gaveta com quatro áreas principais e temas claro/escuro |
| [`UI_SPEC.md`](UI_SPEC.md) | Contrato para transformar o HTML em implementação verificável, incluindo tokens, componentes, viewports e golden tests |
| [`PLANO-MIGRACAO-MOBILE.md`](PLANO-MIGRACAO-MOBILE.md) | Roteiro incremental para levar o novo protótipo ao Flutter sem redesenhar o Web |
| [`PLANO-DE-ACAO.md`](PLANO-DE-ACAO.md) | Registro e direção do ciclo anterior de redesign |
| `assets/` | Fontes vetoriais da marca (`logo-radar.svg` etc.) |

## Como usar no redesign mobile

1. leia `prototipo-mobile.html` e `UI_SPEC.md` por completo;
2. localize a tela, estado e componentes equivalentes no Flutter;
3. preserve contratos e dados reais existentes — números do HTML são ilustrativos;
4. implemente usando tokens/componentes reutilizáveis, sem improvisar uma tela Material genérica;
5. rode formatação, análise e testes relevantes;
6. renderize no viewport de referência e rode os goldens aplicáveis;
7. compare a saída com o HTML, corrija diferenças e repita até estabilizar;
8. só atualize um golden depois de confirmar que a mudança visual foi aprovada no HTML/`UI_SPEC.md`.

Não é necessário pedir screenshots ao responsável para descobrir diferenças que o HTML, a renderização local ou os goldens já conseguem revelar.

Os protótipos **não** são código real nem substituem requisitos. Eles ilustram dados para decisão visual e não provam que um endpoint ou regra existe.

O protótipo mobile é a referência do ciclo compacto. O Web permanece protegido contra regressão e só muda mediante decisão explícita.
