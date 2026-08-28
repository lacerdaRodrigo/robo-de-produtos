# Plano de migração — novo design mobile

**Data-base:** 28 de agosto de 2026  
**Status:** Etapa 0 documentada; Etapa 1 autorizada e em implementação local,
com gates executáveis pendentes  
**Referência visual:** [`prototipo-mobile.html`](prototipo-mobile.html)  
**Escopo:** Android e iOS em largura compacta; o Web permanece visualmente como
está

## 1. Objetivo

Trocar, de forma incremental, a experiência mobile atual pela direção visual do
protótipo aprovado para planejamento, usando as cores e a identidade existentes
do Radar de Benefícios.

A navegação principal do celular passa a comunicar apenas quatro áreas:

1. **Início** — visão geral baseada em dados reais disponíveis;
2. **Livelo** — tudo que já existe do domínio Livelo;
3. **Banco Inter** — cashback, lojas e seleções do domínio Inter;
4. **Buscar produtos** — resultados das lojas selecionadas no Banco Inter.

Alertas, conta e administração continuam acessíveis, mas deixam de competir com
as quatro áreas principais. O produto deve estar preparado para novas lojas e
bancos sem criar um novo item de navegação para cada integração.

## 2. Decisões fechadas para este plano

| Tema | Decisão |
|---|---|
| Plataforma | O primeiro ciclo altera somente a experiência compacta/mobile |
| Web | Mantém navegação, layout e comportamento atuais |
| Navegação mobile | Cabeçalho compacto e gaveta com quatro áreas principais |
| Aparência | Temas claro e escuro, com escolha persistida no aparelho |
| Dados | O primeiro ciclo usa exclusivamente contratos de API já existentes |
| Integrações | Livelo, Cashback Inter e Produtos continuam isolados internamente |
| Utilidades | Alertas e conta/administração ficam fora da navegação principal |
| Prototipação | Toda diferença visível é validada no protótipo mobile antes do Flutter |

O protótipo contém números e eventos ilustrativos. Eles servem para avaliar
hierarquia e composição, não são requisitos de API e não podem aparecer no app
real como dados simulados.

## 3. Fora do primeiro ciclo

Os itens abaixo dependem de contrato novo, decisão de produto ou trabalho de
backend. Eles não bloqueiam a troca visual inicial:

- redesenho do Flutter Web;
- catálogo público completo e selecionável de lojas Livelo;
- central histórica de notificações e alertas lidos/não lidos;
- cálculo agregado de “melhor Livelo”, “melhor cashback” ou “melhor preço”;
- personalização da ordem dos atalhos;
- migrações de banco, novas coletas ou alteração de agendamentos;
- mistura ou conversão entre pontos Livelo, cashback e preços.

Se algum desses itens for aprovado depois, primeiro deve ganhar contrato, estados
e protótipo próprios.

## 4. Estado atual e destino

| Experiência atual no Flutter | Destino no novo mobile | Tratamento no Web |
|---|---|---|
| Início | **Início** | Sem mudança |
| Lojas, com hub Livelo/Inter | Divide-se em **Livelo** e **Banco Inter** | Hub atual permanece |
| Produtos | **Buscar produtos** | Sem mudança |
| Alertas, hoje sem jornada completa | Utilidade em folha/modal | Destino atual permanece |
| Mais/Administração | Utilidade de conta e sistema | Destino atual permanece |

A separação é de apresentação. Modelos, clientes HTTP e regras de cada domínio
continuam compartilhados e não devem ser duplicados para atender o layout.

## 5. Estratégia técnica

### 5.1 Navegação adaptativa sem redesenhar o Web

Hoje `MolduraRadar` usa o mesmo enum de cinco destinos e o mesmo
`IndexedStack` nos layouts compacto e amplo. A implementação deve separar o
modelo de navegação por apresentação:

- no compacto, quatro destinos: Início, Livelo, Banco Inter e Buscar produtos;
- no amplo, preservar os cinco destinos e o hub existentes;
- escolher a apresentação por plataforma e largura: somente Android/iOS em
  largura compacta recebem a moldura nova; o Flutter Web estreito também mantém
  a experiência atual;
- compartilhar as páginas e os controladores de domínio entre os dois layouts;
- manter vivas busca, filtros, paginação, rotas internas e posição útil ao trocar
  de área;
- manter Alertas e Administração alcançáveis no compacto por folhas, diálogos ou
  rotas auxiliares, com retorno explícito à área de origem;
- exibir Administração somente quando o perfil tiver autorização.

Arquivos centrais esperados quando a execução for aprovada:

- `app/lib/app/navegacao/destinos.dart`;
- `app/lib/app/navegacao/moldura.dart`;
- `app/test/app/navegacao/moldura_test.dart`;
- goldens mobile e Web da moldura.

### 5.2 Tema claro e escuro

`TemaRadar.claro()` e `TemaRadar.escuro()` já existem, porém a raiz do app está
fixada em `ThemeMode.light`. O ciclo deve:

- introduzir um controlador pequeno de aparência;
- carregar a escolha local antes de montar a experiência autenticada, sem travar
  a abertura;
- usar o tema do sistema na primeira execução e persistir mudanças posteriores;
- expor a troca no cabeçalho e na gaveta, como no protótipo;
- revisar cores fixas em widgets para que usem os tokens do tema;
- respeitar contraste, foco, leitor de tela e redução de movimento.

A persistência é local e não sensível. A dependência escolhida deve ser definida
na implementação e isolada atrás de uma interface testável. Neste primeiro
ciclo, o modo escolhido é aplicado apenas no app nativo compacto; o Web continua
claro e sem o novo controle de aparência.

### 5.3 Dados e segurança

- Flutter continua sendo apenas cliente da API autenticada;
- nenhuma tela consulta banco, Livelo ou Inter diretamente;
- valores monetários, percentuais e pontuação preservam os textos/decimais
  recebidos, sem conversão insegura para `double`;
- links de produto continuam passando pela validação existente;
- ações administrativas mantêm autorização por perfil, confirmação e feedback;
- carregamento, vazio, busca sem resultado, dado atrasado, falha e retry continuam
  sendo estados distintos;
- atualização deve preservar o último retrato válido em vez de apagar a tela.

## 6. Plano incremental

Cada etapa tem aceite próprio. Não é necessário esperar toda a migração para
revisar o resultado, e uma etapa rejeitada não deve contaminar as seguintes.

### Etapa 0 — contrato e linha de base documental

**Entrega**

- registrar este plano e sua relação com o redesign anterior;
- congelar o protótipo mobile atual como referência da primeira rodada;
- mapear cada elemento ilustrativo para dado real, adaptação honesta ou item
  adiado;
- registrar que o Web não faz parte da mudança visual.

**Gate de aceite**

- nenhuma referência obrigatória exige endpoint inexistente;
- as quatro áreas e as utilidades estão nomeadas sem ambiguidade;
- o plano não autoriza código, publicação ou mutação de dados.

### Etapa 1 — fundação visual e aparência

**Entrega**

- consolidar tokens de cor, superfície, tipografia, espaçamento, raio e sombra;
- ativar `ThemeMode` controlado e persistência local;
- criar componentes básicos reutilizáveis do protótipo: cabeçalho, cartão,
  indicador de estado, campo de busca, abas e folha de utilidade;
- remover cores fixas apenas nos componentes alcançados pelo mobile novo.

**Gate de aceite**

- claro e escuro funcionam sem reiniciar a sessão;
- a escolha reaparece após fechar e abrir o app;
- nenhuma tela tocada perde contraste ou semântica;
- o golden amplo do Web permanece inalterado.

### Etapa 2 — moldura mobile com quatro áreas

**Entrega**

- implantar o cabeçalho compacto e a gaveta do protótipo;
- criar os quatro destinos mobile;
- retirar Alertas e Mais da lista principal somente no compacto;
- oferecer acesso auxiliar a alertas, conta, administração e saída;
- preservar o estado das quatro áreas ao alternar entre elas.

**Gate de aceite**

- a gaveta mostra exatamente Início, Livelo, Banco Inter e Buscar produtos;
- nenhuma utilidade fica inacessível;
- perfis sem papel administrativo não veem ações protegidas;
- largura ampla continua com a experiência atual.

### Etapa 3 — Início

**Entrega**

- aplicar o novo cabeçalho, saudação neutra e cartões de resumo;
- alimentar a tela somente com `GET /api/resumo` e perfil já disponível;
- substituir métricas ilustrativas sem contrato por contagens, estados e horários
  reais;
- ligar os atalhos às três áreas de domínio;
- manter retry com o último resumo válido visível.

**Adaptação obrigatória do protótipo**

Enquanto a API não informar as melhores ofertas, cartões como “12x”, “10%” e
“218 ofertas” não aparecem como números reais. A composição pode ser mantida
com estado da coleta, lojas acompanhadas, produtos ativos e última atualização.

**Gate de aceite**

- nenhum nome pessoal ou número é inventado;
- cada domínio falha de forma isolada;
- os atalhos abrem o destino correto em um toque.

### Etapa 4 — Livelo

**Entrega**

- transformar Livelo em área mobile direta, sem passar pelo hub de Lojas;
- reutilizar painel, busca, ordenação, paginação e cartões já existentes;
- reunir, para administradores, lojas configuradas, regras e preferências já
  suportadas pela API;
- preservar confirmação, busca, página e resposta visual nas mutações;
- apresentar horários e estado da coleta sem sugerir consulta ao vivo à Livelo.

**Limite do ciclo**

“Catálogo” significa o painel coletado e as lojas administrativas que a API já
expõe. Descobrir e acompanhar qualquer loja de um catálogo público completo
fica adiado até existir contrato próprio.

**Gate de aceite**

- todas as funções Livelo atuais ficam alcançáveis dentro da área;
- paginação não duplica nem perde itens;
- valores de pontos e regras permanecem textualmente fiéis à API.

### Etapa 5 — Banco Inter

**Entrega**

- criar entrada mobile direta para Banco Inter;
- organizar Sites parceiros/Cashback e Compre direto sem misturar contratos;
- reutilizar painel de cashback, catálogo de lojas parceiras e favoritas;
- reutilizar seleção administrativa das lojas do Compre direto;
- explicar que Buscar produtos usa somente lojas selecionadas quando essa for a
  regra retornada pela API.

**Gate de aceite**

- cashback e produtos são distinguíveis antes de qualquer ação;
- seleção/favorito reage imediatamente e preserva busca e página;
- pedido aceito e coleta concluída não usam a mesma mensagem;
- percentuais são exibidos exatamente como publicados.

### Etapa 6 — Buscar produtos

**Entrega**

- aplicar o novo visual à busca existente;
- preservar debounce, cancelamento lógico de respostas antigas e paginação;
- manter histórico de 30 dias e validação dos links externos;
- mostrar claramente carregamento inicial, busca vazia, nenhuma coleta, fonte
  atrasada, erro recuperável e fim da paginação;
- manter filtros somente quando sustentados pelos dados reais.

**Gate de aceite**

- todos os resultados continuam alcançáveis;
- consultas antigas não substituem uma busca mais recente;
- voltar do histórico preserva termo, filtros, página e posição útil;
- nenhum produto é associado à Livelo por inferência visual.

### Etapa 7 — utilidades

**Entrega**

- criar folha de alertas com o que for honestamente derivável do estado atual;
- criar folha de conta e sistema com perfil, aparência, administração e saída;
- reutilizar a página administrativa atual até haver protótipo aprovado para
  reorganizá-la;
- manter zona de perigo separada, confirmada e restrita.

**Limite do ciclo**

Sem um endpoint de notificações, a folha de alertas não simula uma caixa de
entrada histórica. Ela pode mostrar estados atuais, vazio explicativo e atalhos
para os domínios. Lidos/não lidos, contador e histórico ficam para contrato novo.

**Gate de aceite**

- alertas e conta não aparecem como um quinto tópico principal;
- sair, administrar e trocar tema continuam fáceis de encontrar;
- operações perigosas não ficam a um toque acidental da gaveta.

### Etapa 8 — validação e entrega

Esta etapa só acontece junto da implementação autorizada. Ela inclui:

- testes unitários de tema, mapeamento de destinos e preservação de estado;
- testes de widget das quatro áreas e das utilidades;
- goldens claro/escuro em celular e golden de regressão do Web;
- `flutter analyze`, formatação e cobertura crítica mínima já adotada pelo
  projeto;
- builds previstos pelo projeto;
- smoke no Samsung em retrato e paisagem, incluindo reinício para conferir tema;
- verificação manual de leitor de tela, teclado, foco e aumento de texto.

Nenhum teste do aplicativo faz parte da elaboração deste documento.

## 7. Ordem de commits recomendada

1. documentação e contrato visual;
2. tokens, tema e persistência;
3. moldura e navegação compacta;
4. Início;
5. Livelo;
6. Banco Inter;
7. Buscar produtos;
8. utilidades;
9. ajustes de acessibilidade e evidências finais.

Cada commit de interface deve incluir seus testes e atualizar o protótipo caso o
aceite provoque alguma mudança visual. Mudanças de API, se forem aprovadas no
futuro, devem ficar separadas dos reskins.

## 8. Riscos e contenções

| Risco | Contenção |
|---|---|
| Alterar o Web ao separar a navegação | Manter comportamento amplo e exigir golden sem mudança |
| Tratar ilustração como dado real | Criar matriz de origem dos dados antes de cada tela |
| Duplicar regras entre layouts | Compartilhar páginas/controladores e separar apenas a apresentação |
| Perder estado ao trocar de área | Preservar pilhas/controladores e testar busca, página e scroll |
| Expor administração a perfil comum | Renderizar por autorização e manter bloqueio na API |
| Novo banco/loja aumentar o menu | Crescer dentro da área de integração, não na navegação principal |
| Tema escuro ficar parcial | Proibir cores fixas nos componentes tocados e testar ambos os temas |
| Confundir pedido com coleta concluída | Manter estados e mensagens diferentes em toda mutação |

## 9. Definição de pronto do primeiro ciclo

O ciclo estará pronto quando:

1. o celular tiver somente as quatro áreas principais aprovadas;
2. Livelo, Inter e Produtos mantiverem todas as capacidades atuais aplicáveis ao
   perfil conectado;
3. claro/escuro funcionar e persistir;
4. nenhuma tela mostrar dado fictício como real;
5. estados, paginação e posição útil forem preservados;
6. Alertas e Administração continuarem acessíveis como utilidades;
7. o Web não tiver mudança visual nem regressão funcional;
8. todos os gates técnicos e o smoke físico da Etapa 8 passarem;
9. PRDs e protótipo refletirem qualquer ajuste aprovado durante a execução.

## 10. Próximo aceite

Em 28 de agosto de 2026, o responsável autorizou seguir este plano. A primeira
fatia é a **Etapa 1 — fundação visual e aparência**; a Etapa 2 só começa depois
da revisão desta entrega e de seus gates.

A autorização não inclui publicação, `push`, migração, disparo administrativo
ou alteração real de coleta.
