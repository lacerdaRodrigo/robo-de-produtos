# Plano de ação — nova experiência do Radar de Benefícios

**Status:** direção inicial, abertura, Login, Moldura e Início aprovados; os
Módulos 0 a 3 estão implementados localmente no Flutter. As telas seguintes
continuam propostas e não estão autorizadas automaticamente.

**Data-base da auditoria:** 23 de agosto de 2026

**Protótipo Web:** [`prototipo-web.html`](prototipo-web.html)

**Protótipo Mobile:** [`prototipo-mobile.html`](prototipo-mobile.html)

**Logo vetorial aprovado:** [`assets/logo-radar.svg`](assets/logo-radar.svg) e
[`assets/logo-radar-sobre-escuro.svg`](assets/logo-radar-sobre-escuro.svg)

## 0. Regra permanente de evolução visual

Toda nova funcionalidade visível, tela, jornada ou mudança relevante de
navegação deve seguir esta ordem:

1. confirmar o requisito e separar dado real de hipótese;
2. atualizar `prototipo-web.html` e `prototipo-mobile.html`;
3. validar o fluxo visual com o responsável;
4. atualizar PRD e contratos afetados;
5. implementar no Flutter/API com testes;
6. manter os protótipos sincronizados com qualquer ajuste aprovado durante a
   implementação.

Os protótipos são a primeira etapa obrigatória, mas continuam sendo simulações:
não provam que API, banco, coleta ou regra já estejam implementados. Correções
internas sem efeito visual não exigem tela nova; mudanças percebidas pelo usuário
exigem atualização dos dois protótipos.

## 1. Resultado da análise

O produto já possui uma base técnica forte, mas sua interface cresceu por
entregas sucessivas. As funções existem; o problema principal é encontrá-las e
entender como Livelo, Sites parceiros do Inter e Compre direto se relacionam.

### Evidências encontradas antes da Fase D1

- O nome público aprovado já é **Radar de Benefícios**. Android, iOS e o título
  do Flutter usam esse nome; não vale fazer uma renomeação técnica do
  repositório ou do pacote.
- O ícone instalado ainda é o ícone padrão do Flutter. O Web Manifest também
  conserva `app_robo`, a descrição padrão e o azul padrão do Flutter.
- A abertura nativa ainda é a tela padrão do projeto e não comunica a marca.
- O login já possui e-mail, senha, mostrar/ocultar senha e recuperação, mas é um
  cartão genérico sem uma proposta de valor clara.
- A tela **Início** mostra apenas que a API está conectada. Ela ainda não ajuda a
  decidir o que merece atenção.
- A navegação atual tem Início, Livelo, Inter, Alertas e Mais. Produtos ficam
  escondidos atrás de um ícone na tela Inter; lojas ficam dentro de quatro abas
  em Mais → Administração.
- **Alertas** ainda é um lugar-ocupante.
- A administração é funcional, mas mistura configuração Livelo, favoritas dos
  Sites parceiros, seleção do Compre direto e Zona de perigo em uma tela densa.
- A busca administrativa já usa debounce de 350 ms, paginação e descarte de
  resposta antiga. A ação de acompanhar já muda a linha local imediatamente.
- O feedback de mutações usa principalmente `SnackBar`. Ele confirma a ação,
  mas não existe hoje um estado compartilhado que obrigue todas as telas
  relacionadas a se revalidarem no mesmo instante.

### Evidências do histórico Git

Foram inspecionados os **221 commits alcançáveis da `main`** e as referências
locais relevantes. O histórico deixa cinco lições que o redesign não pode
regredir:

1. acompanhar ou remover uma loja deve preservar busca, página e posição;
2. a tela não pode ficar branca durante atualização;
3. a escolha precisa aparecer imediatamente, sem esperar uma nova coleta;
4. todos os resultados continuam alcançáveis por paginação;
5. “pedido de coleta aceito” é diferente de “coleta concluída”.

Os commits recentes também comprovam que autenticação, painéis de leitura e
administração já estão implementados no Flutter. Portanto, o próximo trabalho é
uma reorganização de experiência, não a criação de um aplicativo do zero.


## 2. Nome e posicionamento recomendados

### Nome

- **Marca completa dentro do produto e nas lojas:** Radar de Benefícios.
- **Nome curto sob o ícone instalado:** Radar.
- **Identificadores técnicos:** permanecem `br.com.radarbeneficios.app` e
  `app_robo` onde já forem internos. O redesign não autoriza renomeá-los.

“Radar” é curto e fácil de localizar no celular. “Radar de Benefícios” explica
o produto em login, cabeçalho, metadados e publicação.

### Frase principal

> **Seu próximo benefício não passa despercebido.**

Texto de apoio:

> Pontos, cashback e preços reunidos em um só radar.

### Logo conceitual

O conceito troca o antigo “R$ vira ponto” e o ícone padrão do Flutter por um
símbolo próprio: um radar encontra uma oportunidade. Ele evita cifrão, moeda,
carrinho e marcas da Livelo ou do Inter.

O PNG inicial foi uma exploração para aprovação e permanece guardado como
histórico. A direção aprovada foi redesenhada em SVG, ganhou variante clara e
os recortes exigidos por Android, iOS e Web, inclusive versão `maskable`, na
Fase D1.

## 3. Arquitetura de navegação

### Recomendação

A barra principal deve ser **fixa**. O que será editável são os atalhos da tela
Início, não a estrutura do aplicativo.

| Destino fixo | Responsabilidade |
|---|---|
| Início | resumo do dia, pendências e atalhos pessoais |
| Lojas | fontes atuais e futuras; entrada para Livelo e Inter |
| Produtos | busca frequente no catálogo já persistido |
| Alertas | eventos e preferências quando a Fase 6 existir |
| Mais | perfil, administração, ajuda, aparência e saída |

Motivo: se a barra inteira fosse editável, um destino importante poderia sumir
e cada nova integração aumentaria a confusão. Com um hub de Lojas, novas fontes
entram como cartões sem criar mais uma aba principal.

### Adaptação por dispositivo

- **Web:** barra lateral nas janelas amplas; o protótipo Web preserva a barra
  inferior da proposta original quando a janela fica estreita.
- **Mobile:** cabeçalho compacto e botão de menu hambúrguer no lado esquerdo. O
  botão abre uma gaveta lateral com os mesmos cinco destinos fixos.
- A mudança é apenas de apresentação: nomes, destinos e hierarquia continuam
  iguais entre Web, Android e iOS.

### Atalhos editáveis do Início

- até quatro atalhos visíveis;
- exemplos: Cashback Inter, Ofertas Livelo, Buscar produto e Atualizações;
- ação **Personalizar** para escolher e ordenar;
- Início e Lojas nunca podem ser removidos da navegação principal;
- a preferência deve ser pessoal quando o modelo de preferências de usuário
  estiver disponível; até lá, pode ser local e não sensível.

Esta personalização é recomendada, mas deve ser aprovada antes de entrar no
Flutter. O protótipo mostra apenas a experiência visual; não persiste a ordem.

### Hierarquia das lojas

```text
Lojas
├── Livelo
│   ├── Buscar no catálogo coletado
│   ├── Lojas acompanhadas
│   ├── Regras de alerta
│   └── Solicitar atualização
└── Shopping Inter
    ├── Cashback — Sites parceiros
    ├── Produtos — Compre direto
    ├── Gerenciar lojas acompanhadas
    └── Solicitar atualização por domínio
```

Não existe conversão automática entre pontos e cashback. O hub reúne caminhos,
mas preserva os domínios e contratos separados.

## 4. Fluxos propostos

### 4.1 Abertura

A abertura terá duas camadas coordenadas:

1. **Launch screen nativa:** fundo azul-marinho e símbolo animado desde o toque,
   exibidos enquanto o motor Flutter inicia.
2. **Bootstrap Flutter:** animação contínua do feixe do radar enquanto Firebase,
   sessão, convite, App Check e configuração da API são validados.

Regras:

- ciclo visual mínimo de 1,5 segundo quando a inicialização for rápida;
- se a validação demorar mais que o ciclo mínimo, não adicionar outra espera;
- depois de alguns segundos, trocar o texto por uma explicação honesta;
- enquanto a validação estiver pendente, a animação reinicia a cada ciclo;
- falha interrompe a espera e oferece **Tentar novamente**;
- respeitar a preferência de movimento reduzido;
- usar animação vetorial/CSS/Flutter, não um GIF pesado.

O protótipo simula essa abertura. A Fase D1 já implementou as camadas nativas e
Flutter em Android, iOS e Web. O Android conectado recebeu aceite visual e
smoke físico; Web e iOS permanecem pendentes.

### 4.2 Login

- logo e nome no topo;
- título “Seu próximo benefício não passa despercebido.”;
- texto curto explicando pontos, cashback e preços;
- campos E-mail e Senha com rótulos sempre visíveis;
- mostrar/ocultar senha;
- botão principal **Entrar**;
- recuperação **Esqueci minha senha** preservada;
- mensagens sem enumerar se um e-mail existe;
- carregamento dentro do botão, sem bloquear toda a página desnecessariamente.

### 4.3 Início

- saudação curta e data da última sincronização geral;
- faixa prioritária quando houver falha, atraso ou coleta em andamento;
- resumo com métricas reais e recortes claros;
- quatro atalhos pessoais;
- bloco “O que merece atenção” com promoções, cashback e produtos monitorados;
- atividade recente, distinguindo pedido aceito, execução e conclusão.

Nenhum número será inventado pela interface. O endpoint do futuro dashboard
precisa fornecer os totais; até existir, a tela mostra apenas dados que os
contratos atuais já entregam.

### 4.4 Lojas

O primeiro nível mostra uma tarjeta por fonte:

- Livelo: pontos e alertas;
- Shopping Inter: Cashback e Produtos;
- espaço planejado para novas fontes, sem botão vazio fingindo função pronta.

Cada tarjeta explica o que a fonte responde e abre uma tela própria de ações.

### 4.5 Shopping Inter

Ao abrir Inter, a pessoa escolhe entre:

- **Cashback:** Sites parceiros, busca e acompanhamento;
- **Produtos:** Compre direto, busca no catálogo local e histórico;
- **Gerenciar lojas:** visão administrativa das duas modalidades;
- **Atualizar dados:** ações separadas, sem um disparo genérico ambíguo.

### 4.6 Cashback e acompanhamento

- campo de busca fixo no topo;
- a pesquisa consulta somente o Postgres pela API, nunca o Inter;
- debounce de 350 ms preservado para digitação fluida sem chamadas inúteis;
- dez cartões por página no fluxo de lojas, conforme pedido;
- total e página sempre visíveis;
- botão **Mostrar mais 10**, mantendo todos os resultados alcançáveis;
- cartão mostra nome, oferta textual, condição curta e estado de acompanhamento;
- **Acompanhar** muda imediatamente para **Acompanhando**;
- loja acompanhada recebe um botão de lixeira com nome acessível;
- a lixeira sempre abre a confirmação “Você quer mesmo excluir a loja X do
  acompanhamento?” antes de alterar o estado;
- depois da confirmação, cartão, filtro e contadores são atualizados na hora;
- confirmação visível na própria tela e anunciada a leitor de tela;
- busca, página e posição não são perdidas após a ação.

A API já aceita `por_pagina` entre 1 e 50. O Flutter atual usa o padrão 20; a
fatia de implementação deverá passar 10 somente para essa jornada e manter 20
como padrão da busca de produtos.

### 4.7 Catálogo e acompanhamento Livelo

A tela Livelo replica a jornada de descoberta do Inter sem misturar os dados:

- busca por loja ou categoria;
- filtros **Todas as lojas** e **Acompanhadas**;
- dez cartões por vez, com todos os resultados alcançáveis;
- cartão com pontuação atual, categoria, pontuação normal, valor de disparo,
  Clube Livelo quando existir, campanha, alerta e estado de acompanhamento;
- ações de acompanhar e excluir com a mesma confirmação do Inter.

O protótipo usa dados ilustrativos para demonstrar esse catálogo. Hoje, o painel
Livelo da API entrega as lojas já cadastradas e suas pontuações; ele não oferece
um catálogo persistido de todos os parceiros descobertos para seleção. Levar
esta proposta ao aplicativo real exigirá primeiro definir no PRD e implementar
o contrato e a persistência desse catálogo, preservando o histórico atual.

### 4.8 Atualização imediata do aplicativo

Após uma mutação bem-sucedida:

1. atualizar o cartão local imediatamente;
2. atualizar contadores e selo da tela atual;
3. invalidar as leituras relacionadas em um estado compartilhado;
4. reconsultar a API em segundo plano;
5. manter o último dado na tela se a reconsulta falhar e oferecer retry;
6. não dizer que a coleta terminou quando apenas o pedido foi aceito.

Isso atende ao pedido de “sempre atualizar o app” sem transformar o Flutter em
fonte da verdade. O servidor continua validando autorização, idempotência e
estado final.

## 5. Sistema visual

### Paleta

Os tokens aprovados continuam como base, com superfícies mais vivas e suaves:

| Papel | Cor | Uso |
|---|---|---|
| Marca | `#102A43` | cabeçalhos, texto forte e navegação |
| Ação | `#1769AA` | botões, seleção, links e foco |
| Apoio vivo | `#25B8D8` | ilustrações e detalhes de marca, nunca texto pequeno |
| Ganho | `#16803C` | cashback, economia e sucesso |
| Atenção | `#B7791F` | atraso e dado envelhecendo |
| Perigo | `#C53030` | erro e ação destrutiva |
| Fundo | `#F4F7FB` | descanso visual |
| Superfície | `#FFFFFF` | cartões e formulários |

As cores vivas ficam em áreas pequenas, ícones e ações. Grandes superfícies são
claras e neutras para não cansar os olhos.

### Componentes

- botões com pelo menos 48 px de altura;
- cantos entre 14 e 20 px, sem excesso de sombras;
- um botão principal por bloco;
- rótulo junto de todo ícone importante;
- preço atual e “após cashback” com a mesma força visual;
- status com ícone + texto + cor;
- foco visível, contraste WCAG AA e suporte a aumento de texto;
- nenhum texto externo é interpretado como HTML.

## 6. Plano de implementação incremental

### Fase D0 — decisão visual

- [x] aprovar nome curto “Radar”;
- [x] aprovar símbolo, paleta de apoio, abertura e estrutura do login;
- [x] decidir a navegação mobile na etapa própria: gaveta;
- [ ] decidir se e quando entram atalhos editáveis.

### Fase D1 — fundação da marca e abertura

- [x] produzir logo vetorial e ícones de todas as plataformas;
- [x] corrigir Web Manifest, metadados e favicon;
- [x] criar launch screens nativas e bootstrap animado;
- [x] adicionar testes de inicialização, falha e movimento reduzido;
- [x] obter o aceite visual e executar o smoke físico no Android conectado;
- [ ] obter o aceite visual em Web e iOS quando voltarem ao escopo.

### Fase D2 — login e moldura

- [x] redesenhar o login sem mudar o contrato Firebase;
- [x] aplicar os tokens e componentes necessários ao login;
- [x] obter o aceite visual do login no Android conectado;
- [x] decidir e aprovar a moldura/navegação mobile com gaveta;
- [x] trocar a navegação para Início/Lojas/Produtos/Alertas/Mais;
- [x] preservar `IndexedStack`, responsividade e semântica;
- [x] obter o aceite visual final da implementação no Samsung.

### Fase D3 — Início e hub de Lojas

- definir o menor contrato de API necessário para o resumo real;
- criar dashboard e estados honestos;
- criar hub de fontes e páginas Livelo/Inter;
- manter produtos e domínios separados internamente.

### Fase D4 — acompanhamento e sincronização visual

- mover a gestão de lojas para o fluxo da própria fonte;
- definir e implementar o catálogo selecionável da Livelo antes de ligar essa
  tela a dados reais;
- usar dez cartões por página nessa jornada;
- adicionar confirmação de exclusão em tela e invalidação compartilhada;
- cobrir busca, paginação, mutação e preservação de estado.

### Fase D5 — validação multiplataforma

- testes unitários, widgets, goldens e jornadas críticas;
- `flutter analyze`, formato e cobertura crítica mínima de 90%;
- builds Web, Android e iOS previstos na fase;
- smoke em aparelhos e tamanhos diferentes;
- preservar Pytest, Ruff, TypeScript, Vitest e site legado.

## 7. Critérios de aceite do redesign

1. O app instalado aparece como Radar e usa um ícone próprio aprovado.
2. A abertura nunca mostra tela branca e nunca esconde uma falha indefinidamente.
3. Login mantém entrada, recuperação e mensagens seguras.
4. Início responde “o que merece minha atenção agora?”.
5. Lojas leva a Livelo e Inter em no máximo dois toques.
6. Inter distingue Cashback de Produtos antes de mostrar ações.
7. Buscar filtra enquanto a pessoa digita, sem consultar a fonte externa.
8. A jornada de lojas mostra dez cartões e permite alcançar todos os demais.
9. Acompanhar confirma sucesso, atualiza o cartão e preserva busca/página.
10. Excluir exige confirmação com o nome da loja e atualiza a tela imediatamente.
11. Livelo oferece busca, acompanhamento e cartões com os dados atuais do domínio.
12. Toda jornada interna do Inter oferece retorno visível ao Shopping Inter.
13. Mudança relevante invalida e atualiza as telas relacionadas.
14. Estado, erro, atraso, ausência, parcial e zero continuam diferentes.
15. Contraste, teclado, leitor de tela, texto ampliado e movimento reduzido passam.

## 8. Fora desta entrega

- nenhuma tela Flutter foi alterada;
- nenhum contrato de API, banco, migração ou workflow foi alterado;
- nenhum ícone foi instalado no Android/iOS/Web;
- nenhuma coleta, publicação, limpeza ou notificação real foi executada;
- atalhos editáveis e o logo final ainda dependem da aprovação visual.
