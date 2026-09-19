# Prompt mestre — migração definitiva do Flutter mobile para a V15

Copie todo o bloco abaixo e envie a um agente de código aberto na raiz deste
repositório. O objetivo é executar a migração, não produzir outro plano.

---

Você está na raiz do projeto `/home/rodrigo/Estudos/robo`.

Sua missão é **substituir integralmente a experiência visual mobile Flutter
atual pela V15**, implementando a referência aprovada de ponta a ponta no app
real. Não encerre o trabalho depois de auditar, explicar ou planejar: implemente,
valide, corrija e prossiga fase por fase enquanto houver trabalho seguro e
necessário dentro deste escopo.

## Resultado esperado

Ao terminar, o aplicativo Flutter mobile deve usar a identidade, temas,
navegação, componentes, imagens, ícones, animações, estados e jornadas da V15.
O sistema visual anterior deve deixar de aparecer no mobile e seus componentes,
aliases e assets sem consumidores devem ser removidos depois que a substituição
estiver comprovada.

Esta é uma troca completa da camada de experiência mobile, **não** uma
reescrita do produto. Preserve a API, os controladores, os modelos, a
autenticação, a autorização, os contratos de domínio e as regras financeiras
que já funcionam.

## Fonte visual de verdade

Leia integralmente antes de alterar o Flutter:

1. `AGENTS.md`;
2. `design-app/mobile-v15/index.html`;
3. `design-app/mobile-v15/identidade.html`;
4. `design-app/mobile-v15/README.md`;
5. `design-app/mobile-v15/css/tokens.css`;
6. `design-app/mobile-v15/assets/PROMPTS.md`;
7. `design-app/mobile-v15/review/VALIDACAO.md`;
8. `docs/guias/design-v15.md`;
9. os arquivos Flutter e testes diretamente relacionados à fase em execução;
10. o PRD do domínio somente quando for necessário confirmar comportamento,
    dado, contrato de API ou autorização.

Não consulte nenhum protótipo, guia, prompt, screenshot ou sistema visual
predecessor. O código Flutter atual pode e deve ser lido para preservar
integrações e localizar consumidores, mas **não é referência estética**.

O HTML é uma especificação interativa, não código de produção. Não use WebView,
não embarque HTML/CSS/JavaScript no app e não transporte fixtures ilustrativas
para o Flutter. Traduza a composição para widgets Flutter nativos e conecte-os
aos dados reais já fornecidos pelos controladores e pela API.

## Skills obrigatórias

Use, nesta ordem e apenas quando aplicáveis, as skills instaladas:

1. `$codebase-conventions` para descobrir convenções, componentes e assets;
2. `$mobile-design` para arquitetura das jornadas, hierarquia e polimento;
3. `$design-tokens` para centralizar qualquer valor visual em `AppTokens`;
4. `$responsive-adaptive` para constraints, celulares compactos e telas amplas;
5. `$a11y-and-rtl` para semântica, escala de texto, foco, contraste e RTL;
6. `$flutter-add-widget-preview` ao criar ou mudar componentes visuais centrais;
7. `$flutter-add-widget-test` para interações e estados diretamente alterados;
8. `$flutter-fix-layout-issues` se qualquer renderização apresentar overflow ou
   constraints inválidas.

Leia o `SKILL.md` completo de cada skill usada. As skills ajudam a implementar
a V15; não autorizam inventar outra direção visual.

## Preflight obrigatório

Antes de escrever widgets:

- verifique `git status --short` e preserve mudanças do responsável;
- confirme Flutter/Dart pelo `app/pubspec.yaml`;
- leia `app/lib/app/tema/tokens.dart`, `tema.dart` e `aparencia.dart`;
- leia `app/lib/app/componentes/`, `app/lib/app/identidade/`,
  `app/lib/app/inicializacao/`, `app/lib/app/autenticacao/` e
  `app/lib/app/navegacao/` por papel, não apenas por nome imaginado;
- pesquise componentes existentes por sufixos `Button`, `Card`, `Field`,
  `Tile`, `Sheet`, `Dialog` e equivalentes em português;
- identifique quais páginas e controladores reais atendem cada jornada;
- registre uma matriz curta “rota V15 → tela/controlador/API existente → ação”;
- declare em até dez linhas o stack, tokens, componentes reutilizados, lacunas,
  fases e testes; em seguida, comece a implementação.

Não crie um segundo design system paralelo. Evolua `ThemeData`, `ColorScheme`,
`AppTokens` e os componentes compartilhados existentes. Reutilize widgets
Material 3 quando forem semanticamente corretos. Um componente existente que
faz a mesma função deve ser adaptado ou substituído conscientemente, não
duplicado com outro nome.

## Regras funcionais que não podem regredir

- Flutter continua cliente exclusivo da API; nunca acessa Neon, Livelo, Inter
  ou Pichau diretamente.
- Livelo, Inter Sites parceiros, Inter Compre direto e Pichau são quatro
  experiências distintas, mesmo sob uma única identidade visual.
- Livelo apresenta lojas e pontos; não transforme Livelo em busca de produtos.
- Banco Inter abre uma escolha explícita entre Sites parceiros e Compre direto.
- Busca de produtos consulta API/banco paginados; digitar não inicia coleta na
  fonte externa e o cliente não recebe o catálogo inteiro.
- Paginação continua obrigatória e deve preservar busca, filtros, ordenação,
  página e posição útil nos retornos já suportados.
- Dinheiro, cashback e pontuação não são recalculados com `double` para regra
  financeira. Exiba os valores e qualificadores fornecidos pelo domínio.
- Preço cobrado, cashback, estimativa após cashback, preço Pix, preço no cartão,
  pontos comuns, base e Clube são conceitos separados.
- Zero, ausência, falha, parcialidade, atraso, esgotado e fora do catálogo são
  estados diferentes e nunca devem ser fundidos por conveniência visual.
- Acompanhar é pessoal, assíncrono e independente da permissão de push. Preserve
  pendência, bloqueio de duplo envio, sucesso, rollback e desfazer quando houver.
- Condições completas, histórico e destino externo devem pertencer ao item que
  abriu a ação e preservar o contexto da lista.
- Administração permanece protegida pela autorização real. Controles de
  revisão do protótipo nunca entram no app de produção.
- Dados ilustrativos e credenciais da demonstração não entram no app real.
- Não altere backend, migrations, workflows, produção ou publicação sem uma
  necessidade comprovada da jornada e autorização explícita.

## Sistema visual V15

Implemente Material 3 personalizado, com uma identidade única para todos os
domínios:

- fundo claro papel `#F6F4F0`, superfície `#FFFDF9` e texto `#282629`;
- fundo escuro grafite `#222225`, superfície `#2B2B2E` e texto `#F6F0E9`;
- laranja brasa `#B6421E` no claro e damasco `#FFAC86` no escuro como ação;
- verde apenas para resultado favorável; vermelho para erro/perigo;
- nenhuma cor própria do domínio deve disputar com a identidade do app;
- Manrope como voz tipográfica, declarada corretamente no `pubspec.yaml` e
  carregada a partir do asset fornecido, com a licença preservada;
- preços, pontos, percentuais e datas com figuras tabulares quando aplicável;
- escala de espaços 4, 8, 12, 16, 20, 24, 32, 40 e 48;
- raios por função: controles, ofertas e folhas; não arredonde tudo;
- borda e contraste tonal antes de sombras pesadas;
- um foco principal por tela e densidade maior nos catálogos;
- temas Sistema, Claro e Escuro persistidos;
- nenhum gradiente roxo, glow decorativo, glassmorphism estrutural, bento grid
  gratuito ou aparência genérica de dashboard.

Todos os valores de cor, espaço, raio, sombra, duração e estilo textual usados
por widgets novos ou migrados devem resolver por `ThemeData`, `ColorScheme`,
`TextTheme` ou `AppTokens`. Não deixe hex, `EdgeInsets`, `BorderRadius`,
`Duration` e `TextStyle` visuais espalhados pelas telas.

## Marca, ícone, imagens e abertura

Use exclusivamente os assets em `design-app/mobile-v15/assets/` como origem:

- símbolo: etiqueta de compra com três sinais de descoberta;
- wordmark `radar.`;
- ícone quadrado iOS e camadas de ícone adaptativo Android;
- ícone monocromático de notificação;
- ilustração de descoberta na jornada de acesso;
- ilustração de acompanhamento em estados vazios/permissão adequados;
- SVGs de abertura e confirmação como referência de movimento.

Copie para `app/assets/` somente os arquivos realmente consumidos, usando nomes
coerentes com o projeto, e declare cada diretório/fonte no `pubspec.yaml`.
Configure também os recursos nativos Android/iOS necessários; não basta mostrar
o ícone dentro do Flutter. Evite dupla máscara no iOS e respeite a safe zone do
ícone adaptativo Android.

Implemente a abertura nativamente em Flutter: etiqueta entra, sinal expande,
wordmark aparece e a jornada segue para autenticação/sessão. A animação não
representa rede, não bloqueia inicialização real e deve ter uma alternativa
curta por opacidade quando o sistema pedir movimento reduzido. Faça splash
nativa clara/escura combinar com o primeiro frame para evitar flash.

Não adicione fotos ou placeholders de produtos: a API atual não fornece imagens
de catálogo. As ilustrações servem à identidade e aos estados, não fingem ser
dados reais.

## Navegação definitiva

O mobile deve ter quatro destinos estáveis:

1. `Início`;
2. `Explorar`;
3. `Meu radar`;
4. `Perfil`.

Reestruture `moldura.dart`, destinos e pilhas sem quebrar autenticação nem deep
links existentes. Cada aba preserva seu histórico e estado útil. Voltar retorna
ao contexto correto. Bottom sheets e diálogos devolvem foco ao controle que os
abriu. O destino ativo usa ícone, rótulo e estado sem depender somente de cor.

Alertas ficam acessíveis pelo Início e pelo Meu radar. Administração fica no
Perfil somente para usuário autorizado. Banco Inter, Livelo e Pichau são
acessados por Explorar; não crie uma barra inferior diferente por domínio.

## Jornadas obrigatórias

Implemente a cobertura completa abaixo com dados reais e todos os estados que o
contrato/API permitem.

### Abertura e autenticação

- launcher, splash e abertura animada;
- login, mostrar/ocultar senha, validação, pending e bloqueio de duplo envio;
- erro preservando campos;
- recuperação de acesso sem revelar existência da conta;
- sessão expirada e retomada segura do destino pretendido;
- saída desassociando notificações conforme o contrato existente.

### Início

- primeiro evento válido não lido como destaque, quando houver;
- demais mudanças relevantes em composição compacta;
- quantidade não lida e acesso à Central;
- atalhos para as origens e quantidade real de acompanhamentos;
- atualização sem apagar o último retrato válido;
- estado “tudo lido” sem inventar promoção.

### Explorar e Banco Inter

- cards/linhas claros para Banco Inter, Livelo e Pichau;
- Banco Inter abre a escolha entre `Sites parceiros` e `Compre direto`;
- descrições curtas e sem misturar os dois catálogos.

### Sites parceiros do Inter

- catálogo paginado de lojas;
- busca, `Todos`/`No radar`, filtros e ordenação suportados;
- cashback principal com qualificador `Até` quando fornecido;
- cashback secundário separado;
- atualização, ausência/inatividade e condições completas;
- acompanhar/deixar de acompanhar com pending, sucesso e rollback;
- destino externo seguro.

### Compre direto do Inter

- busca por termos significativos e variantes conforme o contrato;
- agrupamento por loja e paginação da API;
- filtros de loja, categoria e faixa quando suportados;
- identidade composta do item, preço de compra, preço anterior quando válido,
  cashback e estimativa após cashback claramente separados;
- detalhe e histórico do produto correto;
- disponibilidade/ausência e destino seguro.

### Livelo

- catálogo paginado de lojas, não produtos;
- busca, categorias, `Lojas`/`No radar`, ordenação e filtros reais;
- pontos atuais, base, Clube, tipo de campanha e validade sem misturar regras;
- marcação clara de campanha comum versus exclusiva/extra do Clube;
- condições, histórico, acompanhamento e destino seguro;
- nenhuma campanha artificial criada pelo cliente.

### Pichau

- catálogo paginado de PCs gravados no banco e recebido pela API;
- busca por nome, processador, SKU e campos realmente suportados;
- filtros enxutos em bottom sheet, com disponibilidade e ordenação;
- preço Pix, cartão, desconto, parcelamento e especificações sem recomputar;
- disponível, esgotado, fora do catálogo e preço ausente distintos;
- detalhe, histórico, acompanhar e abrir destino quando permitido.

### Meu radar e Central

- lista pessoal conjunta com busca e filtro por origem;
- remoção com desfazer e lista vazia útil;
- Central com retenção, paginação, origem/tipo e lido/não lido;
- leitura individual/coletiva e abertura do item correto;
- acompanhamento não cria evento retroativo falso;
- permissão de push continua opcional e separada da Central.

### Perfil, preferências, suporte e privacidade

- aparência Sistema/Claro/Escuro;
- preferência de reduzir movimento;
- preferências de alertas e fluxo de permissão contextual;
- ajuda baseada no produto real;
- privacidade e limites de dados corretos;
- formulário de suporte com validação, pending, erro preservando texto,
  sucesso/protocolo e lista de relatos quando o backend oferecer;
- logout com confirmação.

### Administração

- área invisível ou inacessível sem autorização;
- operações Livelo e Inter separadas;
- impacto real antes da confirmação e frase exata quando exigida;
- pending, sucesso, falha e cancelamento;
- nenhuma permissão concedida apenas porque uma rota foi aberta no cliente.

## Componentes compartilhados

Consolide uma biblioteca pequena, específica e sem `MegaCard`:

- cabeçalho de tela e seção;
- logo/wordmark e ícones da identidade;
- campo de busca;
- seletor `Todos`/`No radar`;
- botão de filtros com contagem;
- card de loja e card de produto, sem fingir que são o mesmo componente;
- bloco de benefício e bloco de preço;
- indicador de frescor/estado;
- botão de acompanhamento com pending;
- paginação;
- bottom sheet de filtros, condições e histórico;
- estados carregando, atualizando, vazio, sem resultado, offline, atrasado,
  parcial, erro com dados, erro sem dados e sessão expirada;
- confirmação destrutiva e feedback por `SnackBar`/semântica.

Antes de criar cada widget, pesquise se a função já existe. Estenda o existente
quando a anatomia for a mesma. Separe componentes quando os domínios possuem
significados diferentes; não esconda regras atrás de muitos booleanos.

## Responsividade, acessibilidade e desempenho

- use `SafeArea`, `LayoutBuilder`, slivers/listas preguiçosas e propriedades
  direcionais; a largura do protótipo é referência, nunca constante do app;
- cubra celulares de 320 a 430 dp, aparelho alto/baixo e pelo menos um tablet;
- suporte texto a 200% sem overflow, truncamento de condição ou ação inacessível;
- alvos de toque de no mínimo 48 dp;
- `Semantics`, labels, valores, toggled/selected/busy e anúncios de resultado;
- ordem de foco lógica, teclado e restauração de foco em modal;
- contraste e estado não comunicados apenas por cor;
- RTL espelha apenas elementos direcionais;
- respeite `MediaQuery.disableAnimations`/preferência equivalente;
- use listas lazy e assets dimensionados; não mantenha blur, shader ou animação
  decorativa contínua que prejudique 60 fps.

## Ordem de execução

Trabalhe em fatias verticais estáveis. Em cada fase faça:

**implementar → `dart format` → `flutter analyze` → testes unitários/widgets
diretamente relacionados → renderizar/comparar com a referência → corrigir →
atualizar documentação**.

Fases:

1. auditoria curta, matriz de rotas e fundação V15;
2. assets, fonte, ícones nativos, splash, logo e abertura;
3. tema/tokens/componentes e moldura com quatro destinos;
4. autenticação, Início e Explorar/Inter;
5. Sites parceiros e Compre direto;
6. Livelo e Pichau;
7. Meu radar e Central;
8. Perfil, preferências, suporte, privacidade e administração;
9. remoção do sistema visual sem consumidores;
10. crítica visual completa, correções finais, documentação e entrega.

Uma fase não precisa esperar aprovação se a referência e os contratos já
resolverem a decisão. Pergunte somente quando uma lacuna real puder mudar
materialmente o produto. Não peça screenshots que possam ser obtidos pela
renderização local.

## Testes permitidos e obrigatórios

Siga o escopo do `AGENTS.md`: neste ciclo use somente testes unitários e de
widgets diretamente relacionados, além de `dart format` e `flutter analyze`.
Não crie nem rode integração, E2E, smoke, performance, Web ou regressão visual
automatizada.

Inclua ou ajuste testes de widget para, no mínimo:

- temas claro/escuro e preferência Sistema;
- abertura com movimento normal e reduzido;
- moldura com quatro destinos e restauração de aba;
- login pending/erro sem perder campos;
- estados loading/empty/error/offline de cada anatomia compartilhada;
- filtros/paginação sem acumular ou trocar o item;
- condições e histórico do item correto;
- acompanhar pending/sucesso/rollback/desfazer;
- Central lida/não lida;
- administração negada sem autorização;
- larguras compactas e texto ampliado sem overflow.

Não altere uma interface correta apenas para satisfazer teste antigo. Atualize o
teste quando a expectativa visual foi legitimamente substituída, preservando a
regra funcional. Mantenha a pendência isolada documentada em `AGENTS.md` sem
descomentar ou adaptar aquele teste antes da decisão manual registrada.

## Limpeza definitiva

Depois que todos os consumidores mobile estiverem migrados e os gates passarem:

- remova tokens, temas, aliases, widgets, imagens e caminhos visuais obsoletos
  que não tenham consumidores necessários;
- mantenha código compartilhado Web somente quando removê-lo quebraria o Web;
- não faça redesign, refatoração preventiva ou teste Web;
- confirme por busca que o mobile não referencia nenhum sistema visual
  predecessor;
- confirme que todos os assets do `pubspec.yaml` existem e são usados;
- não apague lógica de domínio apenas por estar no mesmo arquivo de um widget;
- não delete a referência `design-app/mobile-v15/`.

## Documentação no mesmo ciclo

Atualize, conforme o impacto real:

- `app/README.md`;
- `docs/guias/design-v15.md` se uma adaptação nativa válida melhorar a referência;
- `docs/testes/TESTES.md` para novos/alterados casos;
- PRDs apenas quando comportamento, contrato, dado ou aceite mudar;
- `docs/PENDENCIAS.md`, distinguindo o que o repositório prova do que exige
  aparelho, ambiente, backend ou decisão humana;
- `docs/README.md` e o README raiz quando caminhos/estado mudarem.

Não mantenha documentação ensinando o sistema visual removido como se ainda
fosse vigente.

## Gates finais

Só declare concluído quando houver evidência de que:

1. todas as jornadas mobile acima usam a V15;
2. nenhuma fixture do protótipo virou dado real;
3. integrações, paginação, regras financeiras e autorização continuam intactas;
4. claro, escuro e Sistema funcionam;
5. 320/390/430 dp, texto 200%, RTL e movimento reduzido não apresentam overflow;
6. não há ações mortas, sheets vazios, navegação sem saída ou duplo envio;
7. `dart format --output=none --set-exit-if-changed` passa nos arquivos tocados;
8. `flutter analyze` termina sem erro ou warning;
9. todos os unitários/widgets diretamente afetados passam;
10. documentação, testes e pendências estão consistentes;
11. uma crítica forçada encontrou cinco riscos, passou pelas perspectivas de
    Design, Engenharia e Produto e gerou pelo menos uma rodada de correção;
12. o relatório final diferencia implementação comprovada de validação externa.

## Entrega final

Informe de forma objetiva:

- resultado visual e funcional;
- fases concluídas;
- principais arquivos alterados;
- componentes reutilizados, estendidos, criados e removidos;
- assets/ícones/animações efetivamente integrados;
- comandos executados e resultado;
- matriz de dispositivos/temas/estados revisada;
- melhorias justificadas sobre a referência;
- divergências ou validações externas restantes.

Não diga “100% pronto” se ainda houver gate manual, ambiente externo, push real,
ícone/splash não conferido em aparelho ou comportamento que o repositório não
consiga provar. Ao mesmo tempo, não pare antes de concluir tudo que pode ser
implementado e verificado localmente dentro deste escopo.

---
