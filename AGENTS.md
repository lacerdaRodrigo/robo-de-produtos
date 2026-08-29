# Instruções para o Codex — branch `re-design`

## Escopo desta branch

Esta branch existe para **redesenhar somente o aplicativo mobile Flutter**. O objetivo é reproduzir o protótipo aprovado com o menor gasto de contexto possível.

### Fora do escopo

Durante este ciclo, **não trabalhar no Web**:

- não abrir nem analisar `design-app/prototipo-web.html`;
- não redesenhar Flutter Web;
- não executar golden Web por rotina;
- não investigar CSS/site/Next.js/Vercel;
- não atualizar documentação Web;
- não gastar contexto tentando manter paridade visual com desktop.

Código compartilhado pode continuar existindo, mas só deve ser inspecionado quando for necessário para compilar ou para não quebrar a jornada mobile tocada. Não faça refatoração preventiva do Web.

Para tarefas desta branch, esta regra de escopo substitui qualquer instrução antiga em `CLAUDE.md` ou planos históricos que mande atualizar/comparar Web e Mobile juntos.

## Leitura obrigatória mínima

Antes de alterar uma tela mobile, leia apenas:

1. `design-app/prototipo-mobile.html` — fonte visual de verdade;
2. `design-app/UI_SPEC.md` — contrato visual e gates;
3. `design-app/PLANO-EXECUCAO-REDESIGN.md` — ordem de execução;
4. arquivos Flutter e testes diretamente relacionados à fase atual;
5. PRD específico do domínio somente quando precisar confirmar regra, dado ou contrato de API.

**Não leia documentação grande sem necessidade.** Não leia `CLAUDE.md`, todos os PRDs, histórico do projeto ou arquivos Web por padrão. Abra somente o necessário para resolver a fase atual.

## Regra visual inegociável

`design-app/prototipo-mobile.html` é a fonte visual de verdade do redesign.

Não invente UI. Não substitua o protótipo por uma interpretação Material genérica. Reproduza estrutura, hierarquia, espaçamento, cores, estados, navegação e destaque visual definidos no HTML.

Se algo não estiver definido no HTML nem no `UI_SPEC.md`, não improvise: registre a lacuna e peça decisão.

Dados ilustrativos do HTML não viram dados reais. Backend, regras e contratos continuam vindo da API/PRDs existentes.

## Ciclo obrigatório

Para cada fase:

**implementar → formatar → analisar → testar somente o necessário → golden mobile → renderizar/comparar com HTML → corrigir → repetir até estabilizar**.

Uma tela não está pronta só porque compila.

Não peça screenshots ao responsável para diferenças que o HTML, a renderização local ou os goldens mobile conseguem revelar.

Não use `--update-goldens` apenas para fazer um teste passar. Primeiro confirme qual lado está divergente da referência aprovada.

## Regras técnicas que não podem regredir

- Flutter continua cliente da API; não acessa Neon, Livelo ou Inter diretamente.
- Livelo, Inter Sites parceiros e Inter Compre direto continuam separados.
- Busca de produtos consulta banco/API, nunca a fonte externa enquanto o usuário digita.
- O Flutter não recebe catálogo completo; paginação continua obrigatória.
- Dinheiro, cashback e pontuação não são recalculados com `double` para regra financeira.
- Falha, parcial, atrasado, ausência de dado e zero continuam estados diferentes.
- Busca, página e posição útil devem ser preservadas nas ações já cobertas pelo produto.
- Administração continua protegida por autorização.
- Não alterar backend, migração, workflow, produção ou publicação sem autorização explícita.

## Testes desta branch

Prefira testes direcionados à fase atual para economizar tempo e contexto.

Obrigatórios quando aplicáveis:

- `dart format` nos arquivos tocados;
- `flutter analyze`;
- testes unitários/widget diretamente afetados;
- golden tests **mobile** da tela/estado alterado.

Não rode golden Web nem suíte Web como gate do redesign mobile. Rode a suíte Flutter completa apenas no fechamento de uma etapa maior ou antes de entrega/merge, quando fizer sentido.

## Definição de pronto

Uma fase está concluída quando:

1. a jornada mobile real continua funcionando;
2. a tela segue o estado correspondente do HTML;
3. não há overflow em 320 px nem no viewport de referência;
4. claro/escuro funcionam quando aplicáveis;
5. testes e goldens mobile relevantes passam;
6. nenhum dado fictício foi promovido a real;
7. o Codex informa arquivos alterados, comandos executados e divergências restantes.
