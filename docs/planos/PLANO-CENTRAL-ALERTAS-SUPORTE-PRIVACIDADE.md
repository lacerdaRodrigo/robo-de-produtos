# Plano — Central de Alertas, suporte, privacidade e validação V11

**Status:** planejado; ainda não implementado.

**Escopo:** Flutter mobile Android, API e banco necessários para esta frente.
A Web e o fluxo Pichau ficam fora deste plano para não interferir no trabalho
paralelo do outro agente.

## Resumo

Implementar uma Central de Alertas acessível por Conta/perfil, com histórico de
90 dias, eventos individuais, filtros, paginação e push resumido por coleta.
Também serão criadas as áreas de Ajuda, Reportar problema e Privacidade, além
da reorganização dos componentes Flutter reutilizáveis e da validação visual
com o protótipo mobile V11 no Samsung.

## 1. Central de Alertas

### 1.1 Regras funcionais

- Monitorar somente itens acompanhados pelo usuário.
- Livelo: alteração de pontuação em parceiros acompanhados.
- Inter Cashback: alteração de cashback em lojas acompanhadas.
- Produtos Inter: alteração de preço ou cashback em produtos explicitamente
  acompanhados.
- Qualquer alteração válida gera evento, tanto aumento quanto redução.
- O primeiro snapshot não gera alerta.
- Valores ausentes, inválidos, coleta falha ou dado parcial não viram zero nem
  geram evento.
- Eventos duplicados da mesma coleta devem ser eliminados por chave idempotente.
- Eventos permanecem por 90 dias.
- Cada evento terá origem, tipo, entidade, valor anterior, valor atual, direção,
  data, estado lido/não lido e identificador da coleta.

As flags administrativas globais atuais de Livelo e Inter não serão tratadas
como preferências pessoais. Será criada uma camada de acompanhamento por
usuário. Produtos precisarão de acompanhamento explícito antes de gerar
notificações.

### 1.2 Contrato da API

- `GET /api/alertas`
  - paginação;
  - filtro por `preco`, `cashback` e `pontuacao`;
  - filtro `somente_nao_lidos`;
  - filtro por coleta ao abrir pelo push.
- `PATCH /api/alertas/{id}/leitura`
  - marca um alerta como lido ou não lido.
- `PATCH /api/alertas/leitura`
  - marca os alertas visíveis como lidos.
- `GET /api/alertas/preferencias`.
- `PATCH /api/alertas/preferencias`
  - controle global;
  - preço;
  - cashback;
  - pontuação.
- `POST /api/notificacoes/dispositivos`
  - registra token FCM, plataforma e versão do app.
- `DELETE /api/notificacoes/dispositivos`
  - remove token inválido, revogado ou desconectado.
- `PATCH /api/inter/produtos/{loja}/{id_externo}/acompanhamento`
  - liga ou desliga o acompanhamento individual do produto.

A resposta paginada seguirá o envelope já usado pela API: `itens`, `pagina`,
`por_pagina`, `total_itens` e `tem_proxima`, acrescido da quantidade de não
lidos.

### 1.3 Persistência e geração

- Criar tabela de eventos de alerta com vínculo ao usuário, origem, entidade,
  coleta, valores anteriores/atuais e leitura.
- Criar tabela de acompanhamentos de produtos por usuário.
- Criar tabela ou outbox de envio para garantir que um digest não seja enviado
  duas vezes.
- Comparar snapshots somente durante a publicação bem-sucedida da coleta.
- Manter valores monetários como `NUMERIC` no banco e texto/decimal controlado
  na API; não usar `double` para regra financeira.
- Expurgar eventos com mais de 90 dias.

### 1.4 Push

- Usar Firebase Cloud Messaging.
- Pedir a permissão depois do primeiro login.
- Permitir desligar todos os pushes ou apenas preço, cashback e pontuação.
- Manter o histórico da Central mesmo com push desativado.
- Enviar um push resumido por usuário e coleta, com contagens por categoria.
- Ao tocar no push, abrir a Central filtrada para a coleta correspondente.
- Reutilizar o `firebase-admin` existente no backend.
- Não registrar tokens ou dados pessoais em logs.

## 2. Atualização do protótipo V11

Antes das telas Flutter, atualizar:

- `design-app/prototipo-mobile-redesign-novo-11.html`;
- `design-app/SISTEMA-DESIGN-MOBILE-V11.md`.

Adicionar ao contrato visual:

- Central de Alertas;
- filtros por tipo e não lidos;
- paginação;
- eventos lidos e não lidos;
- preferências de push;
- estados carregando, vazio, erro, parcial e sem conexão;
- Ajuda;
- Reportar problema;
- Privacidade;
- acesso dessas áreas por Conta/perfil;
- ausência de exclusão de conta;
- estados claro e escuro;
- larguras de referência de 320, 360, 390 e 430 px.

Os dados ilustrativos do HTML continuam sendo apenas fixtures visuais.

## 3. Reorganização Flutter

Reorganizar os componentes reutilizáveis existentes sem alterar as regras de
Livelo, Inter ou Produtos:

- separar fundação visual, controles, estados, folhas e feedback;
- preservar compatibilidade dos imports atuais durante a migração;
- extrair padrões repetidos de cartão, cabeçalho, busca, abas, paginação,
  estado vazio, folha e confirmação;
- manter componentes específicos de cada domínio dentro de suas features;
- evitar uma abstração genérica que esconda regras de negócio.

Implementar também:

- modelos, API, controlador e tela da Central;
- preferências de notificação;
- registro e ciclo de vida do token FCM;
- acompanhamento explícito de produtos;
- entrada pela Conta/perfil;
- abertura filtrada a partir do push;
- preservação de busca, filtros, página e posição útil.

## 4. Ajuda e Reportar problema

### 4.1 Ajuda

Criar área informativa com:

- perguntas frequentes;
- explicação dos estados de coleta;
- funcionamento da Central;
- funcionamento de paginação e filtros;
- contato de suporte;
- link para privacidade.

### 4.2 Reportar problema

Criar `POST /api/relatos-problema` com autenticação, limite de requisições e
resposta confirmando o registro. O relato terá:

- categoria;
- mensagem;
- tela atual;
- versão do app preenchida automaticamente;
- sistema/dispositivo quando disponível;
- data e identificador da requisição gerados pelo servidor.

Não enviar tokens, senhas, dados bancários ou catálogo completo. A retenção
técnica dos relatos será de 180 dias, salvo necessidade operacional registrada.

## 5. LGPD e privacidade

Criar tela informativa e revisar a documentação com:

- dados usados pelo Firebase;
- e-mail e identificador técnico;
- preferências e acompanhamentos;
- eventos de alerta;
- token de notificação;
- relatos de problema;
- finalidade de cada dado;
- retenção;
- segurança;
- terceiros utilizados;
- contato do responsável;
- direitos do titular.

Não criar botão nem endpoint de exclusão automática de conta nesta frente. A
política deverá registrar essa decisão sem afirmar que direitos legais deixam
de existir. Solicitações formais deverão usar o contato de privacidade
documentado, atualmente `lacerdaa.rodrigo@gmail.com`.

## 6. Validação visual e manual no Samsung

Usar preferencialmente o Samsung conectado ao Wi-Fi, sem registrar em
documentação o serial USB ou o endpoint privado de Wireless Debugging.

Comparar componente por componente com o HTML V11:

- autenticação;
- shell, app bar e perfil;
- dock inferior;
- início e cartões de resumo;
- serviços;
- Livelo, catálogo, abas, alertas e histórico;
- Inter Cashback;
- Inter Compre Direto;
- Produtos;
- filtros contextuais;
- categorias acompanhadas;
- “Sem categoria” e novas categorias;
- histórico de produto;
- administração;
- folhas, confirmações, toasts e estados;
- Central de Alertas;
- Ajuda;
- Reportar problema;
- Privacidade.

Validar manualmente:

- login e primeiro pedido de permissão push;
- push com app aberto, fechado e em segundo plano;
- abertura da Central filtrada;
- paginação avançando, voltando e retornando à primeira página;
- mudança de filtro resetando a página;
- busca preservada após filtro e retorno;
- filtros contextuais de Produtos, Livelo e Inter;
- dados vazios, atrasados, parciais e falhas;
- claro/escuro;
- larguras cobertas pelos widgets;
- ausência de overflow;
- áreas de toque e semântica.

Usar uma conta de teste no API atual. Limitar as mutações a acompanhamento
controlado, leitura de alertas e preferências autorizadas.

## 7. Testes

### 7.1 Backend

Adicionar testes para:

- comparação entre snapshots;
- primeiro snapshot;
- aumento e redução;
- valores ausentes;
- deduplicação;
- retenção de 90 dias;
- isolamento por usuário;
- paginação e filtros;
- leitura individual e em massa;
- preferências;
- token FCM;
- relato de problema;
- autenticação, autorização e limite de requisições.

### 7.2 Flutter

Executar somente testes unitários e de widgets relacionados a:

- modelos e parsers da Central;
- controlador de paginação e filtros;
- estados da Central;
- preferências;
- Ajuda;
- formulário de problema;
- Privacidade;
- Conta/perfil;
- acompanhamento de produto;
- Produtos, Livelo e Inter afetados.

Executar também `dart format`, `flutter analyze` e `git diff --check`.

Não criar testes E2E, integração, Web, performance ou regressão visual
automatizada neste ciclo.

## 8. Documentação e implantação

Atualizar:

- PRD da Central, suporte e privacidade;
- PRDs de Livelo, Inter e Produtos quando os contratos mudarem;
- `docs/testes/TESTES.md`;
- `docs/PENDENCIAS.md`;
- `docs/README.md`;
- `backend/api/README.md`;
- documentação das variáveis e credenciais FCM.

Manter pendentes somente itens que dependam de configuração externa do
Firebase/FCM, deploy da API, conta de teste, validação manual no Samsung ou
revisão jurídica da política.

Sequência de implantação:

1. migração compatível do banco;
2. API e testes;
3. atualização do protótipo V11;
4. Flutter e FCM;
5. validação no Samsung;
6. correção das divergências visuais;
7. documentação;
8. build da APK pelo fluxo existente.

## Critérios de aceite

- A Central deixa de ser placeholder.
- Eventos reais são lidos da API e persistidos por usuário.
- Paginação e filtros funcionam no Samsung.
- O push resumido chega e abre a Central filtrada.
- Preferências globais e por categoria funcionam.
- Produtos podem ser acompanhados explicitamente.
- Ajuda e Reportar problema funcionam pela API.
- Privacidade está disponível no app.
- Não existe exclusão automática de conta.
- As telas existentes permanecem compatíveis com a V11.
- Nenhum dado fictício é usado como dado real.
- Flutter, API, testes e documentação permanecem consistentes.
