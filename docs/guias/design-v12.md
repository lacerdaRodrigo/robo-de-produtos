# Prompt mestre — produto mobile V12 Delta

**Status:** vigente para o protótipo Delta e sua implementação Flutter

**Escopo visual:** protótipo em `design-app/prototipos/mobile-v12/` e cliente
Flutter em `app/`; regras de negócio continuam nos PRDs.

**Última atualização:** 2026-09-16

> Este documento substitui qualquer orientação visual anterior nesta rodada. É
> um prompt executável: leia tudo antes de iniciar e cumpra os gates na ordem.

## 1. Missão

Mantenha um **produto mobile completo**, com protótipo HTML/CSS/JavaScript 100%
clicável e cliente Flutter responsivo, representando todas as jornadas
documentadas do Radar de Benefícios — da abertura e login até Ajuda, Privacidade
e Administração.

O resultado deve parecer um produto novo, com identidade, cores, tipografia,
layout, navegação e linguagem de interação inéditos neste projeto. Não faça uma
reforma da V11, da tentativa V12 rejeitada ou de qualquer protótipo anterior.

O protótipo é o contrato visual e comportamental do Flutter. Toda mudança
observável deve ser refletida nos dois espelhos no mesmo ciclo.

Os componentes — chamados também de widgets neste documento — devem ser
realmente reutilizáveis, orientados por tokens, dados e estado. Não copie e cole
o mesmo HTML entre telas.

## 2. Limite de trabalho

O protótipo oficial fica em `design-app/prototipos/mobile-v12/` e o cliente
Flutter em `app/`. Consulte os PRDs e guias em `docs/` para regras, estados e
contratos. O Web permanece fora do redesign.

Regras obrigatórias:

- não usar protótipos, screenshots ou golden files antigos como referência
  visual;
- não promover dados ilustrativos do HTML a dados de produção;
- manter Flutter como cliente da API autenticada;
- alterar backend/API somente quando necessário à jornada V12 e documentar o
  impacto observável;
- preservar autorização, paginação, estados honestos e valores financeiros;
- manter documentação e testes unitários/widgets afetados sincronizados;
- não criar testes Web, integração, E2E, golden, snapshot ou performance neste
  ciclo.

## 3. Leitura obrigatória, linha por linha

Antes de escrever código, leia integralmente, sem se limitar a títulos ou
buscas:

1. todos os arquivos em `prd/`;
2. `testes/TESTES.md`;
3. `README.md`;
4. `guias/GUIA-SKILLS-DESIGN-MOBILE-V12.md`;
5. `planos/PLANO-SKILLS-DESIGN-MOBILE-V12.md`;
6. este documento;
7. os `SKILL.md` das skills usadas nesta fase.

O plano do executor Android Pichau pode ser lido para compreender estados e
limitações, mas não deve influenciar a aparência do aplicativo.

Ao terminar a leitura, produza primeiro uma matriz interna com:

- domínio;
- jornada;
- tela ou overlay;
- ação disponível;
- estados obrigatórios;
- regra que não pode ser inventada;
- documento de origem.

Não comece pelo visual antes dessa matriz. Não trate exemplos de telas como uma
lista fechada: procure toda superfície de usuário mencionada nos PRDs e testes.

### 3.1 Hierarquia para resolver conflitos

Quando documentos de épocas diferentes divergirem, use:

1. contrato mais recente e explicitamente vigente;
2. PRD específico do domínio;
3. critérios atuais do mobile V12 no catálogo de testes;
4. documento histórico somente para entender regra ou fluxo;
5. nunca um artefato visual antigo para desempatar estética.

Decisões já resolvidas pela documentação:

- no mobile compacto, a barra inferior tem somente **Resumo** e **Serviços**;
- Produtos fica em Banco Inter → Compre direto → Produtos;
- Pichau é subárea de Serviços, não item da barra inferior;
- a Home compacta não tem “Atividade recente”;
- Livelo, Inter — Sites parceiros, Inter — Compre direto e Pichau são separados;
- acompanhamento pessoal não é seleção administrativa global;
- ausência, zero, atraso, parcial e falha são estados diferentes;
- catálogos mobile usam paginação visível, não rolagem infinita;
- dados ilustrativos nunca se tornam contratos reais.

Se ainda houver lacuna real de produto, registre-a no relatório de validação.
Só peça decisão se ela mudar regra, autorização ou jornada; para escolhas
visuais reversíveis, tome uma decisão documentada e prossiga.

## 4. Quarentena visual

Não use como referência estética, wireframe, paleta ou sistema de componentes:

- qualquer protótipo V11;
- qualquer tentativa V12 anterior;
- o conceito “Console de sintonia”;
- `.impeccable/design.json`;
- `.impeccable/review/`;
- `.impeccable/surfaces/`;
- imagens ou capturas de implementações anteriores;
- arquivos visuais apontados pelo README fora de `docs`;
- memórias de outros projetos.

Esses materiais são históricos e funcionam apenas como **anti-referência**.
Não os abra para buscar ideias, não extraia cores e não reaproveite composição.

Preserve exclusivamente o produto real:

- funcionalidades e regras de negócio;
- dados e relações;
- ações, jornadas e retornos;
- hierarquia de autorização;
- APIs documentadas como contrato conceitual;
- paginação;
- estados e distinções semânticas;
- restrições de segurança e acessibilidade.

## 5. Skills obrigatórias e limites

Use as skills locais em `docs/.agents/skills/` nesta ordem.

### 5.1 Concepção

1. **`frontend-design`** — liderar conceito, tipografia, composição, tokens e
   crítica.
2. **`design-anti-slop` em Mode A** — fechar brief específico antes do código.
3. **`gpt-taste`** — ampliar a variedade entre os três conceitos.
4. **`mobile-design`** — garantir fluxo, retorno, estados, ergonomia e
   comportamento de aplicativo.

### 5.2 Protótipo e crítica

1. **`frontend-design`** — manter a intenção visual na implementação.
2. **`mobile-design`** — validar fluxos, estados, densidade e interação.
3. **`design-anti-slop` em Mode B** — auditar as camadas conceitual,
   estrutural e visual.
4. **Impeccable** — usar só inspeção/revisão; não carregar o design histórico
   salvo em `.impeccable/design.json`.

### 5.3 Skills Flutter usadas na implementação

- `redesign-existing-projects`: a missão não é reformar interface existente;
- `imagegen-frontend-mobile`: não substitui protótipo clicável;
- `flutter-build-responsive-layout`, `flutter-add-widget-preview`,
  `flutter-fix-layout-issues` e `flutter-add-widget-test` entram na
  implementação do cliente e permanecem limitadas ao escopo autorizado.

### 5.4 Limite do `gpt-taste`

Aproveite apenas variação e personalidade. Não importe:

- AIDA;
- hero de landing page;
- GSAP obrigatório;
- scroll cinematográfico;
- bento grid;
- espaçamento gigante de site;
- hover como interação principal;
- aleatoriedade que ignore ergonomia ou o produto.

Este é um aplicativo mobile recorrente, não uma landing page.

## 6. Brief criativo antes do código

Escreva um brief positivo e específico com:

1. **Tipografia:** voz, papéis e tratamento dos números.
2. **Cor:** cor de marca nomeada, papéis semânticos e claro/escuro.
3. **Estrutura:** o que a composição comunica e qual padrão evita.
4. **Claim:** frase concreta sobre encontrar e acompanhar mudanças reais de
   benefício, sem slogan aspiracional.
5. **Asset:** unidade real que provará o conceito, como mudança de cashback,
   pontuação Livelo ou preço Pix acompanhado.

Não responda “surpreenda-me”. Não use só proibições. Toda exclusão deve ser
substituída por uma direção positiva.

## 7. Três conceitos realmente diferentes

Antes do HTML, crie três direções completas. Elas devem parecer propostas de
três equipes, e não a mesma tela com três paletas.

Cada conceito define:

- nome inédito;
- ideia central e relação não literal com o Radar;
- personalidade, claim e asset concreto;
- paleta de 4 a 6 cores nomeadas com hex;
- claro e escuro;
- tipografia e tratamento de preço, cashback, pontos e percentuais;
- composição, densidade, navegação e retorno;
- listas, lojas, benefícios, produtos e alertas;
- iconografia, forma, borda, raio, elevação e divisores;
- motion e elemento memorável;
- riscos de acessibilidade e implementação;
- sinais de template evitados e a decisão positiva adotada.

As propostas devem divergir em pelo menos cinco eixos: estrutura, tipografia,
cor, densidade, forma e movimento.

Compare por originalidade, adequação, legibilidade, compreensão do benefício,
uso com uma mão, crescimento, claro/escuro, acessibilidade, implementação
Flutter e risco de parecer fintech, marketplace, SaaS, Material ou UI de IA.

Escolha uma e explique. Incorpore no máximo um aspecto de outra proposta, sem
criar um Frankenstein visual.

## 8. Identidade inédita

A direção escolhida deve nascer das ações reais: detectar mudança, acompanhar,
comparar, entender origem, avaliar frescor e agir no momento certo. Não repita
um círculo de radar em todas as telas.

Não use por hábito:

- azul financeiro, roxo startup ou degradê índigo;
- creme editorial com terracota;
- plum;
- açafrão/grafite do conceito rejeitado;
- glassmorphism, glow ou blobs;
- card arredondado para cada conteúdo;
- pills para todo rótulo;
- ícone em quadrado arredondado em todas as linhas;
- três cards iguais, bento, sidebar SaaS ou dashboard;
- marketplace genérico;
- Material 3 apenas recolorido;
- emoji como ícone;
- headline vazia.

Esses recursos só podem aparecer isoladamente com justificativa funcional.
Gaste ousadia em um ou dois gestos reconhecíveis; mantenha o restante
disciplinado, legível e silencioso.

## 9. Navegação obrigatória

Crie roteador JavaScript e histórico navegável. Use rotas hash ou equivalente
que funcione com servidor local simples.

```text
Abertura
└── Entrar
    ├── Recuperar acesso
    ├── Acesso negado
    └── Permissão de notificações no contexto correto
        └── Aplicativo autenticado
            ├── Resumo
            ├── Serviços
            │   ├── Livelo
            │   ├── Banco Inter
            │   │   ├── Sites parceiros — Cashback
            │   │   └── Compre direto
            │   │       ├── Todas
            │   │       ├── Selecionadas
            │   │       └── Produtos
            │   └── Pichau
            └── Perfil
                ├── Central de Alertas
                ├── Aparência
                ├── Ajuda
                ├── Reportar problema
                ├── Privacidade
                ├── Administração — somente admin
                └── Sair
```

No compacto, **Resumo** e **Serviços** são os únicos destinos inferiores.
Perfil fica no cabeçalho. Não crie Produtos, Alertas, Pichau ou Inter como
destinos globais.

Voltar respeita a hierarquia: Produtos volta a Compre direto; Cashback volta ao
hub Inter; Livelo e Pichau voltam a Serviços antes de sair.

## 10. Inventário obrigatório de telas e superfícies

“Todas as telas” inclui jornadas, overlays, folhas, diálogos e confirmações.

### 10.1 Abertura, autenticação e acesso

Implemente:

1. abertura normal;
2. inicialização demorada com mensagem honesta;
3. falha de inicialização e retry;
4. login com e-mail e senha;
5. validação;
6. mostrar/ocultar senha;
7. envio pendente sem duplo toque nem perda dos campos;
8. falha preservando conteúdo;
9. recuperação com resposta neutra, sem enumerar contas;
10. acesso negado sem convite/permissão e ação Sair;
11. contextualização de notificações após primeiro login;
12. permissão recusada/indisponível sem bloquear o app.

Não crie cadastro aberto, login social ou onboarding comercial.

### 10.2 Moldura autenticada

Implemente:

- cabeçalho com contexto, retorno e Perfil;
- barra inferior Resumo/Serviços;
- safe areas;
- navegação por toque, teclado e histórico;
- preservação de estado entre áreas;
- rota ativa sem depender só de cor;
- tema Sistema, Claro e Escuro.

### 10.3 Resumo

Inclua:

- visão geral separada de Livelo, Banco Inter e Pichau;
- estado/frescor de cada domínio;
- contagens reais ou `—`;
- melhor oportunidade acompanhada só quando o contrato fornecer;
- atalhos reais para Livelo, Cashback, Produtos e Pichau;
- “Buscar produtos” abrindo Inter → Compre direto → Produtos;
- atualização preservando o último retrato;
- retry isolado por fonte.

Não inclua “Atividade recente” e não contamine serviços saudáveis com a falha
de outro.

### 10.4 Serviços

Crie hub acionável para Livelo, Banco Inter e Pichau. Cada entrada explica o
serviço, estado e próxima ação sem inventar métricas. Banco Inter abre seu hub
com **Sites parceiros — Cashback** e **Compre direto — Produtos**.

### 10.5 Livelo

Cubra:

- resumo do catálogo e última atualização;
- abas Lojas, Acompanhadas e Alertas;
- busca, categoria, ordenação e paginação de 10 itens;
- loja com pontos atuais/base, Clube, campanha, validade, limiar, atualização e
  origem quando houver;
- diferença entre “Até N pontos” e “N pontos”;
- benefício geral, exclusivo Clube e Clube com valor maior;
- acompanhar/desacompanhar com sino e ação textual no mesmo estado;
- aba Alertas claramente identificada como indicador administrativo da última
  coleta, e não como a Central pessoal nem como garantia de push;
- condições/termos completos;
- histórico em folha somente leitura;
- ação externa segura para a página da Livelo;
- para administrador, solicitação idempotente de atualização com aceite,
  pendência e cooldown, sem afirmar que a coleta já terminou;
- retorno preservando posição, busca, filtros e página.

Não mostre logo, imagem de parceiro ou pontuação inventada.

### 10.6 Banco Inter — hub

Separe:

1. **Sites parceiros — Cashback:** compra iniciada no Inter e vantagem da loja.
2. **Compre direto — Produtos:** catálogo de lojas e produtos do Shopping Inter.

Cada modalidade preserva estado, atualização, retorno e vocabulário.

### 10.7 Inter — Sites parceiros / Cashback

Cubra:

- abas Todas/Acompanhadas;
- busca, ordenação e paginação de 10 itens;
- loja com oferta principal, prefixo “Até”, “Cliente Inter”, promoção,
  atualização e acompanhamento;
- ausência honesta de condições;
- oferta de não correntista separada;
- folha rolável com condições completas;
- ação externa “Ir para o Inter”;
- acompanhamento otimista, pendência e rollback;
- preservação de busca, ordenação, aba e página.

Não use imagem/logo. Cashback zero, oferta textual sem percentual e ausência
continuam distintos.

### 10.8 Inter — Compre direto / lojas

Cubra as abas Todas, Selecionadas e Produtos. Nas duas primeiras:

- busca e lista diretamente;
- paginação de 10 itens;
- não recriar “Categorias acompanhadas” nem “Configurar”;
- distinguir seleção global administrativa de acompanhamento pessoal;
- mostrar ação global só para função autorizada, sem confundi-la com sino.

### 10.9 Inter — Produtos

Cubra:

- estado inicial antes de busca válida;
- campo compartilhado;
- atalhos Celulares, Informática, Casa, Beleza e Pet;
- termo mínimo e debounce simulado;
- resumo com atualização, total e lojas selecionadas quando disponível;
- resultados paginados, 10 por página;
- loja, categoria e marca quando fornecidas;
- preço atual, após cashback, cashback e disponibilidade;
- preço anterior, desconto, etiqueta e parcelamento só quando existentes;
- Acompanhar com rollback;
- Histórico e oferta externa;
- histórico de 30 dias com medições, mínimo, máximo, paginação, retry e
  ausência honesta;
- “Menor preço atual” só para o primeiro item da ordenação correspondente.

Filtros:

- folha com lojas selecionadas e preço mínimo/máximo;
- apenas filtros conhecidos;
- manter termo e recorte ao aplicar;
- manter cartões anteriores durante atualização.

Áreas/categorias:

- CTA de largura total;
- hierarquia área → subárea → recorte final;
- voltar sem aplicar;
- múltiplos recortes em chips removíveis;
- adicionar/limpar áreas;
- nomes humanos, nunca slugs;
- “Outros / novas categorias” exclusivo;
- erro de escopo preservando resultados anteriores.

Não invente imagens. A documentação diz que imagens não são persistidas nem
necessárias; transforme a restrição em solução editorial forte.

### 10.10 Pichau

Cubra:

- subárea em Serviços;
- abas Todas/Acompanhadas;
- busca simulada por nome, marca e SKU;
- disponibilidade todas/disponíveis/esgotadas;
- ordenação por nome, preço Pix e desconto;
- paginação;
- item com nome, marca, origem, categoria, Pix, preço original, desconto,
  cartão, parcelamento, etiquetas e disponibilidade quando fornecidos;
- disponível, esgotado e fora do catálogo;
- acompanhar com pendência e rollback;
- histórico Pix/cartão em folha;
- “Ver na Pichau” só com URL ilustrativa válida;
- retorno preservando estado.

Não use imagem. Ausência de preço não vira `R$ 0,00`; ausência do catálogo não
vira esgotado.

### 10.11 Central de Alertas

Cubra:

- histórico de 90 dias;
- origens Livelo, Inter Cashback, Inter Produtos e Pichau;
- mudanças de pontos, cashback, preço/cashback e preço Pix;
- filtros por origem, tipo e leitura;
- leitura individual e em massa;
- paginação;
- push global e por tipo;
- permissão recusada sem bloquear histórico;
- deep link preservando evento/coleta alvo;
- retorno ao item de origem quando documentado.

Primeiro snapshot, dado ausente/inválido, falha ou parcial não viram eventos.

### 10.12 Perfil e aparência

Perfil oferece Central, Aparência, Ajuda, Reportar problema, Privacidade,
Administração apenas para admin e Sair.

Aparência permite Sistema, Claro e Escuro, aplica imediatamente e persiste
durante a sessão. Implemente confirmação de saída; logout remove sessão
simulada e volta ao login.

### 10.13 Ajuda

Crie tela útil com:

- como os dados são obtidos e atualizados;
- diferença entre os quatro domínios;
- significado de acompanhado, alerta, atraso, parcial e ausência;
- busca, filtros, paginação e histórico;
- notificações e permissão;
- caminhos para Reportar problema e Privacidade;
- respostas expansíveis acessíveis;
- retorno ao Perfil.

Não invente telefone, e-mail, SLA ou chat humano.

### 10.14 Reportar problema

Cubra categoria, mensagem, versão/contexto sem segredo, validação, envio
pendente, sucesso, falha com retry, preservação do texto e aviso para não
incluir senha/dado sensível. Informe retenção de 180 dias. Não envie à API real.

### 10.15 Privacidade

Explique:

- acompanhamento pessoal e isolamento por conta;
- alertas por 90 dias e relatos por 180;
- token de notificação e remoção no logout;
- preferência pessoal versus seleção administrativa;
- app sem acesso direto às fontes externas ou banco;
- caminhos para Ajuda e relato.

Não invente aconselhamento jurídico, contato ou prática.

### 10.16 Administração mobile

Mostre somente a **Zona de perigo**:

- “Apagar dados da Livelo”;
- “Resetar dados do Inter”.

Cada confirmação contém domínio, contagens ilustrativas, consequências, ausência
de backup, frase exata, validação vazia/incorreta/correta, Cancelar, execução,
sucesso retornando com faixa, falha genérica, acesso negado e 404 para domínio
desconhecido.

Não exclua nada de verdade e não inclua Pichau sem contrato.

### 10.17 Laboratório do protótipo

Crie rota de QA fora da navegação do produto, como `#/laboratorio`, para
acionar:

- todas as rotas;
- papéis usuário/admin;
- todos os estados;
- temas;
- permissão push;
- conteúdo curto, longo e ausente;
- larguras de referência.

Ela é ferramenta de revisão, não funcionalidade do usuário.

## 11. Matriz transversal de estados

Toda tela de dados demonstra, quando aplicável:

- inicial;
- loading sem retrato;
- refresh com retrato preservado;
- sucesso com dados;
- zero real;
- campo ausente;
- catálogo vazio;
- busca vazia;
- nunca sincronizado;
- atrasado;
- parcial/degradado;
- última tentativa falhou com retrato;
- falha sem retrato;
- offline;
- indisponível;
- paginação;
- falha adicional preservando conteúdo;
- ação pendente/otimista/rollback/sucesso;
- desabilitado;
- sessão expirada com retorno neutro ao login;
- limite temporário de requisição com orientação de nova tentativa;
- acesso negado.

Modele centralmente e deixe o laboratório selecionar variantes. Todas devem
renderizar e continuar clicáveis.

Regras:

- `0` é valor real; ausência usa texto neutro ou `—`;
- atraso não é falha;
- parcial não é completo;
- fora do catálogo não é esgotado;
- sem condições não é sem oferta;
- primeiro snapshot não é mudança;
- erro de uma origem não zera as outras;
- atualização não apaga conteúdo válido.

## 12. Clique em tudo — zero controles mortos

Todo elemento interativo funciona: navegação, voltar, abas, busca, limpar,
chips, filtros, ordenação, paginação, acordeões, acompanhamento, leitura,
condições, histórico, seletor, aparência, senha, recuperação, permissão,
links externos simulados, cancelar, confirmar, retry e logout.

Ações externas não abrem URL real durante revisão. Mostre diálogo seguro com
destino ilustrativo e Cancelar/Simular abertura.

Use pendência, `aria-live`, confirmação e rollback. Não dependa de `alert()`.
Preserve busca, aba, filtros, ordenação, página e posição útil ao voltar.

## 13. Componentes/widgets 100% reaproveitáveis

Reuso não é um “MegaCard” com dezenas de condicionais. Separe:

1. primitivos visuais;
2. componentes de interação;
3. composições de domínio;
4. telas que coordenam componentes e estado.

### 13.1 Primitivos mínimos

`AppShell`, `ScreenHeader`, `BottomNavigation`, `BackButton`,
`IconButton`, `Button`, `TextField`, `PasswordField`, `SearchField`,
`Tabs`, `Chip`, `StatusText`, `StatusMarker`, `Divider`, `Banner`,
`Skeleton`, `EmptyState`, `ErrorState`, `Pagination`, `BottomSheet`,
`Dialog`, `Toast`, `Accordion` e `ThemeSelector`.

### 13.2 Composições

`ServiceSummary`, `FreshnessStatus`, `FollowControl`, `BenefitValue`,
`MoneyValue`, `SourceIdentity`, `LiveloStoreItem`, `CashbackStoreItem`,
`InterProductItem`, `PichauProductItem`, `AlertItem`, `FilterSheet`,
`ConditionsSheet`, `HistorySheet`, `CategoryScopePicker`,
`ExternalLinkDialog` e `DestructiveConfirmation`.

Cada domínio pode ter layout próprio. Reuse comportamento e primitivos sem
forçar Livelo, cashback e produtos a parecer o mesmo objeto.

### 13.3 Regras técnicas

- registro central de rotas e store único;
- dados ilustrativos centralizados;
- um componente por padrão compartilhado;
- renderização modular, sem blocos copiados;
- infraestrutura comum para folhas e diálogos;
- tokens CSS para decisões repetidas;
- sem cor, spacing, raio, sombra, duração ou tipo hardcoded fora dos tokens;
- componentes aceitam conteúdo longo, ausência, loading, erro, disabled e tema.

## 14. Estrutura de arquivos

O protótipo oficial está em `design-app`:

```text
design-app/prototipos/mobile-v12/
├── index.html
├── README.md
├── css/
│   ├── tokens.css
│   ├── base.css
│   ├── components.css
│   └── screens.css
├── js/
│   ├── app.js
│   ├── router.js
│   ├── state.js
│   ├── data.js
│   ├── components/
│   └── screens/
└── assets/
    ├── icons.svg
    └── fonts/  # somente fonte licenciada e local
```

Os documentos de contrato relacionados ficam em `docs/guias/`:

```text
docs/guias/SISTEMA-DESIGN-MOBILE-V12-NOVO.md
docs/guias/MATRIZ-TELAS-MOBILE-V12.md
docs/guias/RELATORIO-VALIDACAO-PROTOTIPO-MOBILE-V12.md
```

`index.html` é a entrada, sem CSS/JS monolítico. Use módulos ES nativos e
documente um servidor local simples. Não use React, Vue, Angular, Tailwind,
Bootstrap ou jQuery. Não dependa de CDN.

Ao alterar esses artefatos, atualize também `docs/README.md` para manter os
links do protótipo, sistema visual, matriz e relatório sem transformar
referências históricas externas em fontes estéticas.

## 15. Tokens e sistema visual

Registre:

- cores primitivas e semânticas em claro/escuro;
- escala tipográfica e fonte numérica;
- spacing, largura e gutters;
- raio por papel, bordas, divisores e elevação;
- motion e reduced motion;
- ícones e alvos de toque;
- breakpoints e densidade;
- regras para ausências e números.

Preço, cashback, pontos e percentuais têm leitura rápida e figuras tabulares,
sem parecer painel financeiro. Origem nunca domina a marca e nunca depende só
de cor.

## 16. Conteúdo e dados ilustrativos

Use exemplos coerentes e marcados como protótipo. Não copie dados sensíveis,
capturas ou payloads reais.

- valores financeiros/pontos continuam strings;
- não calcule regra financeira com `Number`;
- não invente disponibilidade, preço, cashback, ponto ou prazo;
- sem lorem ipsum, logos externos, imagens de produtos ou fotos de estoque;
- texto hostil aparece como texto, nunca HTML;
- URLs são ilustrativas;
- nenhum segredo, token, e-mail real ou URL de banco;
- nenhuma chamada à API: respostas vêm do store local.

## 17. Responsividade

Valide:

- 320 × 640;
- 360 × 800;
- 390 × 844;
- 412 × 915;
- 430 × 932;
- paisagem mobile;
- tablet;
- viewport até 1440 px.

O alvo é mobile. Em tela ampla, adapte como aplicativo, sem virar dashboard,
sidebar SaaS ou landing page.

Use layout intrínseco, safe areas e breakpoints baseados no conteúdo. Não trate
artboard como largura fixa. Não aceite rolagem horizontal acidental. Conteúdo
longo e texto a 200% não podem ocultar ações essenciais.

## 18. Acessibilidade

Exija:

- HTML semântico e `lang="pt-BR"`;
- ordem/foco visível e operação integral por teclado;
- nomes acessíveis para ícones;
- `aria-current`, `aria-selected`, `aria-expanded`, `aria-pressed` e
  `aria-invalid` quando aplicáveis;
- `aria-live` para mudanças;
- focus trap e devolução de foco em overlays;
- Escape para overlays não destrutivos;
- contraste AA e estado além da cor;
- alvos mínimos de 48 × 48 CSS px;
- `prefers-reduced-motion` e `prefers-color-scheme`;
- uso a 200% de zoom/texto;
- erro associado ao campo.

Folhas têm título, fechar, rolagem segura e retorno de foco. Toast nunca é a
única comunicação de erro importante.

## 19. Motion

Defina movimento curto e funcional para navegação, folhas, acompanhamento,
leitura, atualização, tema, confirmação, rollback e loading.

Use preferencialmente 150–300 ms. Toda entrada tem saída compatível. Sem
parallax, animação decorativa de listas ou hover obrigatório. Com redução de
movimento, preserve só mudanças necessárias.

## 20. Ciclo obrigatório

1. ler tudo;
2. mapear produto e conflitos;
3. produzir brief;
4. criar/comparar três conceitos;
5. escolher direção;
6. definir tokens e componentes;
7. montar rotas e store;
8. implementar fluxos/overlays;
9. validar cliques e estado;
10. renderizar larguras;
11. auditar acessibilidade;
12. rodar anti-slop Mode B;
13. encontrar cinco motivos para não aprovar;
14. revisar como Designer, Engenharia e Produto;
15. corrigir ao menos uma rodada real;
16. repetir até estabilizar.

Na crítica, corrija primeiro conceito, depois estrutura e por último visual.
Não salve estrutura genérica trocando cor, raio ou fonte.

## 21. Gates

### 21.1 Cobertura

- todas as rotas e overlays existem;
- estão ligadas ao fluxo ou laboratório;
- matriz aponta PRD/teste de origem;
- nenhuma tela ficou apenas “futura”;
- nenhuma função foi inventada.

### 21.2 Interação

- zero botões mortos e links vazios;
- voltar e browser back/forward funcionam;
- overlays abrem, rolam, fecham e devolvem foco;
- busca/filtro/aba/ordem/página mudam conteúdo;
- duplo envio é bloqueado;
- rollback restaura estado;
- contexto útil é preservado.

### 21.3 Visual

- parece app novo sem depender do logo;
- não parece V11, V12 rejeitada, Console de sintonia, fintech, marketplace,
  SaaS ou Material genérico;
- há gesto memorável específico do Radar;
- benefício é instantâneo;
- origens são distintas sem fragmentar marca;
- claro/escuro foram projetados;
- ausência de imagens parece intencional.

### 21.4 Responsividade e acessibilidade

- sem overflow nas larguras;
- ações alcançáveis em 320 px;
- texto a 200% funciona;
- teclado opera tudo e foco é visível;
- contraste AA;
- estado não depende de cor;
- reduced motion funciona;
- console sem erro/warning relevante.

### 21.5 Arquitetura

- tokens centralizados;
- componentes sem duplicação;
- dados/estado separados da apresentação;
- sem mega-componente;
- sem dependência externa em runtime;
- README explica abertura e revisão.

## 22. Entregáveis

Entregue:

1. três conceitos e comparação;
2. conceito escolhido e justificativa;
3. sistema visual;
4. protótipo HTML/CSS/JS;
5. matriz de telas, overlays, rotas e estados;
6. inventário de widgets e reuso;
7. validação por largura, tema, teclado e estado;
8. auditoria anti-slop antes/depois;
9. lacunas documentais;
10. arquivos criados/alterados.

Informe também quantidades de rotas, overlays, componentes, estados do
laboratório, controles simulados e divergências restantes.

## 23. Definição de pronto

Só está pronto quando:

- é possível ir da abertura até Ajuda usando apenas cliques;
- todas as outras telas estão no fluxo real ou laboratório;
- todo controle visível funciona;
- estados são honestos;
- claro/escuro funcionam;
- layout vai de 320 a 1440 px sem virar site genérico;
- componentes são reutilizados de verdade;
- nenhum dado fictício parece real;
- nenhuma imagem externa foi inventada;
- nenhuma estética anterior foi incorporada;
- houve crítica e refinamento real;
- o protótipo oficial permanece em `design-app/prototipos/mobile-v12/`;
- a implementação Flutter compacta foi realizada em `app/`; backend e
  contratos permaneceram inalterados nesta etapa.

Se o resultado for amostra de telas, coleção de cards ou versão repintada do
passado, considere a tarefa **não concluída**.

O teste final: sem o nome, a interface precisa ter lógica própria; com as
jornadas, precisa continuar sendo exatamente o Radar documentado aqui.
