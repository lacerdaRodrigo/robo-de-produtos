# `design-app/` — redesign mobile

Nesta branch, o trabalho visual está focado **somente no aplicativo mobile Flutter**.

A referência obrigatória é:

- [`prototipo-mobile.html`](prototipo-mobile.html) — fonte visual de verdade;
- [`UI_SPEC.md`](UI_SPEC.md) — contrato visual e gates;
- [`PLANO-EXECUCAO-REDESIGN.md`](PLANO-EXECUCAO-REDESIGN.md) — ordem de implementação;
- `assets/` — identidade visual usada pelo protótipo.

## Web fora do ciclo

`prototipo-web.html` e o restante da experiência Web continuam no repositório por histórico e manutenção do produto, mas **não fazem parte do redesign desta branch**.

Durante `re-design`:

- não redesenhar Web;
- não comparar com protótipo Web;
- não executar ou atualizar golden Web como rotina;
- não abrir arquivos Web para contexto sem necessidade concreta de compilação compartilhada;
- não sincronizar mudanças visuais mobile com desktop.

Isso é intencional para concentrar tempo e tokens no celular.

## Fluxo mobile

1. ler `prototipo-mobile.html` e `UI_SPEC.md`;
2. abrir somente o código/testes da fase atual;
3. implementar sem inventar UI;
4. formatar e analisar;
5. rodar somente unitários/widgets diretamente afetados;
6. renderizar no viewport de referência quando necessário;
7. comparar com o HTML e corrigir diferenças;
8. repetir até estabilizar.

Dados do protótipo são ilustrativos. Regras e dados reais continuam vindo dos contratos existentes.
