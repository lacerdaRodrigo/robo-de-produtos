# Instruções para o Codex — design mobile V11

## Escopo do design mobile

Este ciclo existe para **implementar somente o aplicativo mobile Flutter** conforme o design V11 aprovado, com o menor gasto de contexto possível.

### Fora do escopo

Durante este ciclo, **não trabalhar no Web**:

- não investigar protótipos ou documentação visual fora da V11;
- não redesenhar Flutter Web;
- não executar golden Web por rotina;
- não investigar CSS/site/Next.js/Vercel;
- não atualizar documentação Web;
- não gastar contexto tentando manter paridade visual com desktop.

Código compartilhado pode continuar existindo, mas só deve ser inspecionado quando for necessário para compilar ou para não quebrar a jornada mobile tocada. Não faça refatoração preventiva do Web.

Para tarefas do design mobile V11, esta regra de escopo substitui instruções históricas que mandem atualizar ou comparar Web e Mobile juntos.

## Leitura obrigatória mínima

Antes de alterar uma tela mobile, leia apenas:

1. `design-app/prototipo-mobile-redesign-novo-11.html` — fonte visual de verdade e referência clicável;
2. `design-app/SISTEMA-DESIGN-MOBILE-V11.md` — contrato de cores, componentes, estados, montagem e gates;
3. arquivos Flutter e testes unitários/widgets diretamente relacionados à fase atual;
4. PRD específico do domínio somente quando precisar confirmar regra, dado ou contrato de API.

**Não leia documentação grande sem necessidade.** Não leia `CLAUDE.md`, todos os PRDs, histórico do projeto ou arquivos Web por padrão. Abra somente o necessário para resolver a fase atual.

## Regra visual inegociável

`design-app/prototipo-mobile-redesign-novo-11.html` é a fonte visual de verdade do design mobile.

Não invente UI. Não substitua o protótipo por uma interpretação Material genérica. Reproduza estrutura, hierarquia, espaçamento, cores, estados, navegação e destaque visual definidos no HTML.

Se algo não estiver definido no HTML nem no `SISTEMA-DESIGN-MOBILE-V11.md`, não improvise: registre a lacuna e peça decisão.

Dados ilustrativos do HTML não viram dados reais. Backend, regras e contratos continuam vindo da API/PRDs existentes.

## Ciclo obrigatório

Para cada fase:

**implementar → formatar → analisar → rodar somente unitários/widgets necessários → renderizar/comparar com HTML quando necessário → corrigir → repetir até estabilizar**.

Uma tela não está pronta só porque compila.

Não peça screenshots ao responsável para diferenças que possam ser descobertas pelo HTML ou pela renderização local.

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

## Testes deste ciclo

O objetivo é manter **o mínimo de testes necessário** durante o redesign.

Os únicos tipos de teste autorizados neste ciclo são:

- testes unitários diretamente afetados;
- testes de widgets diretamente afetados.

Não criar, atualizar ou executar como parte deste plano:

- golden tests;
- testes de integração;
- E2E;
- smoke automatizado;
- performance;
- regressão visual automatizada;
- testes Web.

Não apague testes existentes dessas categorias. Eles ficam preservados para um ciclo posterior.

`dart format` e `flutter analyze` continuam obrigatórios porque são validações estáticas, não tipos de teste.

Durante o desenvolvimento, rode somente os arquivos unitários/widgets relacionados ao que mudou. Não execute `flutter test` sem filtro por rotina se isso puxar testes fora do escopo.

## Definição de pronto

Uma fase está concluída quando:

1. a jornada mobile real continua funcionando;
2. a tela segue o estado correspondente do HTML;
3. não há overflow nas larguras cobertas pelos widgets alterados;
4. claro/escuro funcionam quando aplicáveis;
5. unitários/widgets relevantes passam;
6. nenhum dado fictício foi promovido a real;
7. o Codex informa arquivos alterados, comandos executados e divergências restantes.
