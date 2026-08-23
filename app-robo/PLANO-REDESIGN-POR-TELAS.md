# Plano de redesign por telas — Radar de Benefícios

**Status:** Etapas 0 e 1 aprovadas no Android conectado; Etapa 2 não iniciada

**Data-base:** 23 de agosto de 2026

**Escopo:** aplicativo Flutter em `app-robo/`, atendendo Web, Android e iOS

Este documento organiza a troca completa do design do Radar de Benefícios em
etapas pequenas e verificáveis. Ele não autoriza alterar todas as telas de uma
vez: cada etapa visual deve ser aprovada antes de sua implementação, e a etapa
seguinte só começa depois da validação da anterior.

Os protótipos que orientam este plano são:

- [`../design-app/prototipo-web.html`](../design-app/prototipo-web.html);
- [`../design-app/prototipo-mobile.html`](../design-app/prototipo-mobile.html);
- [`../design-app/PLANO-DE-ACAO.md`](../design-app/PLANO-DE-ACAO.md);
- [`../design-app/assets/logo-radar.svg`](../design-app/assets/logo-radar.svg);
- [`../design-app/assets/logo-radar-sobre-escuro.svg`](../design-app/assets/logo-radar-sobre-escuro.svg).

O PNG conceitual original foi preservado em
[`../design-app/assets/logo-radar-conceito.png`](../design-app/assets/logo-radar-conceito.png)
como referência do processo, mas não é usado nos novos assets do aplicativo.

## 1. Diagnóstico anterior à implementação

O aplicativo não será refeito do zero. O Flutter já possui autenticação,
painéis Livelo, Inter e Produtos, além da administração. O objetivo deste plano
é reorganizar e redesenhar essa base sem duplicar regras, banco ou robôs.

Pontos confirmados na auditoria que antecedeu a implementação:

- o design novo existia apenas nos protótipos de `design-app/` e ainda não havia
  sido aplicado ao Flutter;
- o logo de radar era conceitual e ainda não constituía o pacote final de
  ícones;
- a inicialização esperava o Firebase antes de abrir o Flutter; a animação
  proposta exigia um bootstrap visual dentro do app;
- o login já funciona e deve ser redesenhado sem mudar o contrato Firebase;
- a proposta troca os destinos principais atuais por **Início, Lojas, Produtos,
  Alertas e Mais**;
- o novo Início apresenta métricas que ainda não são entregues por um contrato
  único da API, portanto nenhum número do protótipo pode ser levado como dado
  real para o aplicativo;
- o catálogo Livelo selecionável mostrado no protótipo é funcionalidade nova,
  não apenas mudança visual; o backend atual entrega principalmente as lojas já
  cadastradas;
- Alertas continua pertencendo à Fase 6 e não deve fingir possuir eventos,
  notificações ou histórico que ainda não existem;
- há divergências de estado e totais entre `app-robo/PLANO.md`, os READMEs,
  `docs/PENDENCIAS.md` e `docs/TESTES.md`; a documentação afetada deve ser
  sincronizada quando a implementação começar, usando código, commits e testes
  executados como evidência.

## 2. Regra de trabalho para cada tela

Cada tela seguirá este ciclo:

1. revisar a proposta nos protótipos Web e Mobile;
2. obter a aprovação visual do responsável;
3. atualizar PRD, contratos e documentação quando houver mudança de regra ou
   dado;
4. implementar somente a tela aprovada e a menor infraestrutura diretamente
   necessária;
5. executar testes, análise e builds relevantes quando a tela estiver pronta;
6. realizar o aceite visual e funcional;
7. começar a próxima tela somente após o fechamento da anterior.

“Trocar tudo” permanece como objetivo geral, mas cada aprovação libera apenas
uma etapa.

## 3. Ordem recomendada

### Etapa 0 — decisões visuais

Antes do primeiro código:

- aprovar ou pedir ajustes no símbolo de radar;
- confirmar o nome curto **Radar** para o ícone instalado;
- aprovar a abertura e o login dos dois protótipos;
- deixar a decisão final da navegação mobile para a Etapa 3.

**Saída:** direção visual da primeira fatia aprovada, sem alteração no Flutter.

#### Registro da Etapa 0 — auditoria inicial

**Estado:** aprovado pelo responsável em 23 de agosto de 2026.

| Decisão | Evidência atual | Recomendação | Estado |
|---|---|---|---|
| Nome completo | Android, iOS e Flutter já usam **Radar de Benefícios** | Manter sem renomear pacote, repositório ou identificadores técnicos | Aprovado |
| Nome curto | O Web Manifest ainda mostra `app_robo`; o plano propõe **Radar** | Usar **Radar** sob o ícone instalado | Aprovado |
| Conceito do símbolo | O PNG de 1.254 × 1.254 representa radar, feixe e oportunidade, sem copiar Livelo ou Inter | Manter o conceito e produzir fonte vetorial limpa | Aprovado |
| Variante para fundo escuro | O arco azul-marinho perde contraste sobre o fundo azul-escuro da abertura | Produzir variante clara para splash escuro e manter variante escura para superfícies claras | Aprovado |
| Frase principal | Login usa “Seu próximo benefício não passa despercebido.” | Usar como frase principal da marca | Aprovado |
| Texto de apoio | O plano diz “reunidos em um só radar”, a splash diz “no seu alcance” e o login diz “em um só lugar” | Unificar em **“Pontos, cashback e preços reunidos em um só radar.”** | Aprovado |
| Estrutura da abertura | Protótipos mostram fundo escuro, símbolo central, pulsos e estado de inicialização | Manter a composição, com ciclo mínimo perceptível e movimento reduzido | Aprovado |
| Estrutura do login | Web usa apresentação + formulário; Mobile prioriza o formulário e conserva a marca | Manter os dois layouts e o contrato Firebase | Aprovado |

#### Ajustes aplicados aos protótipos após a aprovação

A aprovação resultou na menor atualização coerente dos dois protótipos:

1. usar o mesmo texto de apoio na abertura e no login;
2. representar a variante clara do símbolo no fundo escuro;
3. manter o botão real como **Entrar** — “Entrar no protótipo” continua apenas
   enquanto os arquivos forem demonstrações;
4. substituir o ícone de busca usado para mostrar a senha por um ícone de olho
   com rótulo acessível;
5. conservar o aviso de projeto independente no login;
6. não alterar a navegação mobile nesta rodada.

#### Aprovação necessária para encerrar a Etapa 0

- [x] Nome completo **Radar de Benefícios** e nome curto **Radar** aprovados.
- [x] Conceito do símbolo aprovado, com variante clara para fundo escuro.
- [x] Frase principal aprovada.
- [x] Texto de apoio único aprovado.
- [x] Composição da abertura aprovada.
- [x] Layout Web e Mobile do login aprovados.

A Etapa 0 foi encerrada com os seis itens aprovados. A Etapa 1 começa pela
sincronização dos protótipos e pela abertura, sem redesenhar o login real.

### Etapa 1 — abertura e animação

Primeira implementação do redesign:

- launch screen nativa estática, sem tela branca;
- bootstrap Flutter com animação contínua do radar enquanto a validação estiver
  em andamento;
- validação de Firebase, App Check, sessão, convite e configuração da API;
- ciclo visual mínimo de 1,5 segundo para a animação ser percebida; se a
  validação demorar mais, não existe espera adicional;
- inicialização demorada recebe uma mensagem honesta;
- falha interrompe a espera e apresenta **Tentar novamente**;
- movimento reduzido desliga ou simplifica a animação;
- nenhum acesso direto a API externa, banco ou robô é acrescentado.

**Aceite:** o movimento começa no primeiro toque, reinicia a cada ciclo enquanto
o app valida o acesso e a jornada não fica presa sem mensagem ou ação.

#### Registro da Etapa 1 — implementação local

**Estado:** código e gates locais concluídos em 23 de agosto de 2026; abertura
instalada e aprovada no Samsung SM-M135M conectado. O login real não foi
redesenhado nesta etapa.

- Android, iOS e Web receberam fundo azul-marinho, símbolo próprio e ícones da
  marca; o Web Manifest agora usa **Radar de Benefícios** e o nome curto
  **Radar**;
- o Web exibe uma camada estática antes do primeiro frame e a remove somente
  quando o Flutter sinaliza que desenhou a abertura;
- o Android inicia o movimento já na camada nativa; no Flutter, o feixe e os
  pulsos reiniciam continuamente enquanto a validação estiver pendente;
- a abertura cumpre o ciclo visual mínimo aprovado de 1,5 segundo; uma validação
  mais demorada não recebe espera adicional;
- após quatro segundos, a abertura explica honestamente que a validação segura
  está demorando;
- erro de configuração ou exceção recebe mensagem neutra e **Tentar novamente**,
  sem expor detalhes técnicos;
- a animação vetorial possui variante para fundo escuro, golden próprio e é
  desativada quando o sistema pede movimento reduzido;
- a sessão, o gate de convite e o cliente autenticado existentes continuam no
  mesmo `PortaoAutenticacao`.

Validações executadas:

- `dart format --output=none --set-exit-if-changed lib test`;
- `flutter analyze` sem apontamentos;
- `flutter test --coverage`: **121 testes aprovados**; os arquivos novos
  `logo_radar.dart` e `pagina_abertura.dart` ficaram com 100% das linhas
  cobertas;
- build Web aprovado antes dos ajustes visuais finais do Android e não repetido,
  conforme a orientação de validar esta rodada no aparelho conectado;
- APK debug instalado no Samsung SM-M135M, incluindo o loop nativo e Flutter;
- recursos iOS e `LaunchScreen.storyboard` conferidos estruturalmente; o build
  iOS não foi executado porque este ambiente Linux não possui Xcode.

O aceite visual e o smoke físico do Android foram concluídos. Web e iOS devem
receber aceite visual quando essas plataformas voltarem ao escopo. A Etapa 2
não foi iniciada.

### Etapa 2 — login e validação de acesso

- layout amplo em duas áreas no Web;
- layout compacto no celular;
- logo, frase principal e explicação curta do produto;
- campos E-mail e Senha com rótulos sempre visíveis;
- mostrar e ocultar senha;
- recuperação de senha sem revelar se o e-mail existe;
- carregamento dentro do botão Entrar;
- mensagens de erro acessíveis e sem apagar os campos;
- preservação integral do Firebase e do gate de convite.

**Aceite:** entrada, recuperação, acesso negado, retry e saída continuam
funcionando com o novo visual.

### Etapa 3 — moldura e navegação

- Web com barra lateral;
- Mobile conforme o protótipo: cabeçalho compacto e gaveta lateral;
- destinos fixos: Início, Lojas, Produtos, Alertas e Mais;
- preservação do estado das telas, filtros, páginas e posição útil;
- sem misturar os domínios Livelo, Inter Sites parceiros e Inter Compre direto.

**Recomendação:** seguir inicialmente a gaveta do protótipo e validar no
aparelho. Ela deixa a tela mais limpa, mas acrescenta um toque para trocar de
área; a barra inferior atual é mais rápida para navegação frequente.

**Aceite:** os cinco destinos são alcançáveis, a navegação funciona por teclado
e leitor de tela e trocar de área não descarta o estado já carregado.

### Etapa 4 — Início

- resumo do dia;
- indicação prioritária de falha, atraso ou coleta em andamento;
- bloco “O que merece atenção”;
- atividade recente distinguindo pedido aceito, execução e conclusão;
- atalhos para as jornadas mais frequentes.

Antes do código, será necessário definir o menor contrato de API que forneça os
totais reais. Nenhum número ilustrativo dos protótipos será colocado em
produção.

Os atalhos editáveis são uma melhoria opcional ainda não autorizada. A
alternativa simples recomendada é começar com quatro atalhos fixos e discutir
persistência e ordenação pessoal em uma etapa posterior.

### Etapa 5 — Lojas e hub do Shopping Inter

- tela Lojas com entradas separadas para Livelo e Shopping Inter;
- Inter dividido em Cashback, Produtos, gerenciamento e atualizações;
- nenhuma conversão ou ranking misto entre pontos, cashback e dinheiro;
- pedidos de atualização separados por domínio;
- retorno visível ao hub do Shopping Inter em todas as jornadas internas.

### Etapa 6 — Produtos e histórico

- aplicar o design novo sobre a busca já existente;
- manter 20 produtos por página e no máximo 50 por resposta da API;
- manter todos os resultados alcançáveis sem cortes, perdas ou duplicações;
- preservar filtros e histórico de 30 dias;
- dar a mesma força visual ao preço atual e ao valor após cashback;
- distinguir catálogo completo, degradado, atrasado, vazio e com falha;
- continuar consultando somente o Postgres pela API.

### Etapa 7 — Cashback Inter e acompanhamento

- busca com debounce de 350 ms;
- dez lojas por carregamento nessa jornada;
- total e quantidade exibida sempre visíveis;
- ação Acompanhar refletida imediatamente;
- remoção com confirmação contendo o nome da loja;
- atualização imediata de cartão e contadores;
- preservação de busca, página e posição após mutação;
- pedido de atualização aceito nunca apresentado como coleta concluída.

### Etapa 8 — Livelo

Primeiro será feito o redesign sobre os dados já existentes:

- busca e ordenação das lojas cadastradas;
- pontuação atual, normal, valor de disparo, Clube, campanha e alerta;
- condições externas sempre renderizadas como texto seguro;
- estados de coleta e ausência preservados.

A possibilidade de pesquisar e acompanhar qualquer parceiro coletado ficará em
uma etapa funcional separada. Ela exige atualização de PRD, persistência,
contrato de API e testes próprios, portanto não deve ser misturada com o reskin
inicial.

### Etapa 9 — Mais e Administração

- perfil, aparência, ajuda e saída;
- administração Livelo, Sites parceiros e Compre direto;
- preferências e disparos controlados;
- preservação de busca, filtros e paginação após mutações;
- Zona de perigo por último, mantendo prévia, frase exata, autorização no
  servidor, transação e rollback;
- nenhuma limpeza de produção durante o aceite visual.

### Etapa 10 — Alertas

Enquanto a Fase 6 não tiver contratos e regras aprovados, a tela permanecerá
como estado futuro honesto. Não será criada uma central visual que simule push,
histórico ou eventos inexistentes.

Quando a Fase 6 for autorizada, Alertas ganhará um plano próprio antes de
qualquer implementação de outbox, FCM ou relatórios.

## 4. Validação de cada etapa

Cada tela implementada deve passar, conforme o risco da mudança, por:

- testes unitários de formatação, estado e comportamento;
- testes de widgets e componentes;
- goldens das telas e componentes visuais críticos;
- testes de carregamento, sucesso, vazio, atraso, parcial, degradado, falha,
  retry e acesso negado;
- acessibilidade, foco, teclado, leitor de tela, texto ampliado e movimento
  reduzido;
- `dart format --output=none --set-exit-if-changed lib test`;
- `flutter analyze`;
- `flutter test` com a cobertura crítica definida no plano principal;
- build Flutter Web;
- build Android previsto para a etapa;
- build ou validação da configuração iOS quando houver runner compatível;
- Pytest, Ruff, TypeScript, Vitest e build do site quando a alteração alcançar
  código ou contrato compartilhado.

Os testes não acessam Livelo, Inter, GitHub Actions, Neon de produção, FCM ou
e-mail real.

## 5. Regras que o redesign não pode quebrar

- Flutter continua sendo apenas cliente da API.
- Nenhum segredo entra no bundle Web, APK ou IPA.
- Dinheiro, cashback e pontuação continuam como texto decimal seguro nos
  contratos; cálculos financeiros nunca usam `double`.
- Livelo, Inter Sites parceiros e Inter Compre direto permanecem domínios,
  processos, tabelas e workflows separados.
- Busca no aplicativo nunca consulta o Inter nem inicia coleta.
- Todos os resultados continuam alcançáveis por paginação.
- Dados externos são tratados como texto hostil e nunca executados como HTML.
- Falha, coleta parcial, dado atrasado, ausência e valor zero continuam estados
  diferentes.
- Ações administrativas são autorizadas, validadas, auditadas e protegidas
  contra repetição no servidor.
- O site legado permanece vivo até decisão explícita de corte.

## 6. Próximo passo

A **Etapa 1 — abertura e animação** recebeu aceite visual e físico no Android
conectado. Web e iOS permanecem como validações futuras de plataforma. Quando o
trabalho for retomado e houver autorização explícita, o próximo desenvolvimento
é a **Etapa 2 — login e validação de acesso**, começando pela última conferência
dos protótipos antes do código. Nenhuma tela da Etapa 2 foi alterada no Flutter
nesta rodada.
