# Plano de redesign por telas — Radar de Benefícios

**Status:** Modelo 0 e Módulos 1 a 4 implementados e aceitos; Módulo 5 — hub
do Shopping Inter implementado localmente após aprovação dos protótipos

**Data-base:** 23 de agosto de 2026

**Escopo:** aplicativo Flutter em `app-robo/`, atendendo Web, Android e iOS

Este documento organiza a troca completa do design do Radar de Benefícios em
etapas pequenas e verificáveis. Ele não autoriza alterar todas as telas de uma
vez: cada etapa visual deve ser aprovada antes de sua implementação, e a etapa
seguinte só começa depois da validação da anterior.

### Autorização operacional desta rodada

O responsável autorizou o Codex a criar arquivos, alterar o código local,
executar testes, gerar builds, instalar APKs de desenvolvimento e usar o
Samsung conectado para validar telas e comandos. Essa autorização vale para o
módulo visual que já tiver passado pelo gate de aprovação do protótipo.

Ela **não** autoriza:

- `git push`, criação/merge de PR, tag ou release;
- publicação na Vercel, Google Play, App Store ou outro ambiente externo;
- migração ou limpeza de produção;
- disparo real de workflow, e-mail, push ou relatório;
- mutação de dados reais durante um smoke puramente visual;
- remoção do `site/` ou de qualquer compatibilidade existente.

O trabalho fica no workspace até o responsável revisar e decidir o que deseja
enviar ao repositório remoto.

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

Neste plano, **Modelo 0** é o nome operacional da fundação já aprovada: ele
reúne a antiga Etapa 0 (decisões visuais) e a Etapa 1 (identidade, abertura e
animação). A sequência nova começa no Módulo 1 para não renumerar esse trabalho
concluído.

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

### Módulo 1 — login e validação de acesso

**Tipo:** redesign de comportamento já existente; não exige contrato novo.

**Estado:** implementação local concluída e aprovada pelo responsável em 23 de
agosto de 2026.

**Estado real de partida:** `PaginaEntrar` já oferece e-mail, senha,
mostrar/ocultar senha, envio pelo Firebase e recuperação neutra. O
`PortaoAutenticacao` já conserva sessão, perfil, convite e acesso negado. O
módulo troca a experiência visual sem mover essas decisões para a tela.

#### Escopo visual

- Web amplo em duas áreas: apresentação da marca e formulário;
- celular em uma coluna, priorizando o formulário sem perder a identidade;
- `LogoRadar`, frase principal, texto de apoio e aviso de projeto independente;
- campos E-mail e Senha com rótulos sempre visíveis, autofill e teclado correto;
- botão acessível para mostrar/ocultar senha;
- carregamento dentro de **Entrar**, mantendo a página e os campos visíveis;
- mensagens de validação, autenticação e recuperação em região viva;
- recuperação por **Esqueci minha senha**, sem confirmar se a conta existe;
- foco inicial, ordem de tabulação e envio pelo teclado;
- layout estável com teclado virtual aberto, rotação e texto ampliado.

#### Estados obrigatórios

1. inicial;
2. campos inválidos;
3. enviando credenciais;
4. credencial recusada com mensagem neutra;
5. falha de rede com nova tentativa;
6. recuperação solicitada;
7. perfil sem convite ou sem permissão;
8. sessão válida seguindo para a moldura.

#### Arquivos previstos

- `lib/app/autenticacao/pagina_entrar.dart`;
- componentes visuais compartilhados realmente necessários em
  `lib/app/componentes/`;
- `test/app/autenticacao/portao_test.dart` e novo teste específico do login;
- os dois protótipos, somente se o último aceite pedir ajuste.

#### Testes e aceite no Samsung

- widget tests para validação, loading, senha, recuperação e erro preservando
  os campos;
- golden do formulário compacto e do layout Web amplo;
- semântica do botão de senha e mensagens anunciadas;
- no Samsung: abrir com sessão encerrada, testar teclado, senha visível/oculta,
  orientação retrato/paisagem e botão Voltar;
- o smoke real pode ler autenticação e perfil, mas não cria usuário, convite ou
  dado de produção.

**Saída:** login redesenhado e aprovado, com o mesmo contrato Firebase e sem
regressão no gate de convite.

#### Registro do Módulo 1 — implementação local

O formulário foi redesenhado sem alterar `Autenticador`, Firebase,
`PortaoAutenticacao`, convite ou autorização da API:

- telas a partir de 920 px usam apresentação institucional + formulário;
- telas menores priorizam o formulário e preservam a assinatura compacta;
- os campos mantêm rótulos, autofill, ações de teclado e conteúdo durante
  loading ou erro;
- o e-mail é normalizado apenas nas bordas e a senha nunca é aparada;
- a recuperação usa resposta neutra mesmo quando o provedor devolve uma falha
  conhecida, sem confirmar a existência da conta;
- botão de senha, mensagens e estados possuem semântica acessível;
- foram adicionados goldens para 390 × 844 e 1440 × 900, além de teste em
  320 × 640 com texto a 150%.

Evidências do fechamento:

- formatação e `flutter analyze` aprovados;
- `flutter test --coverage`: **131 testes aprovados**;
- `pagina_entrar.dart`: **233/241 linhas, 96,68%** de cobertura; a cobertura
  global medida foi **89,76%**, portanto não é registrada como 90%;
- `flutter build web` e `flutter build apk --debug` aprovados;
- APK debug instalado no Samsung SM-M135M e login aberto em retrato, sem
  autenticação real ou mutação de dados;
- o responsável conferiu e aprovou o resultado no aparelho, dispensando a
  continuação do roteiro manual de teclado, rotação e botão Voltar;
- a reinstalação substituiu o APK anterior e limpou apenas a sessão/dados locais
  do aplicativo no aparelho; nenhum dado de servidor foi alterado.

O Módulo 1 está encerrado. Nenhuma alteração de código do Módulo 2 foi iniciada.

### Módulo 2 — moldura, navegação e hierarquia principal

**Tipo:** mudança visual e de navegação sobre infraestrutura existente.

**Estado:** implementação, gates e aceite manual no Samsung concluídos em 23 de
agosto de 2026.

**Estado real de partida:** `MolduraRadar` usa `IndexedStack`; celular usa barra
inferior, telas largas usam barra lateral; os destinos atuais são Início,
Livelo, Inter, Alertas e Mais. Produtos está dentro de Inter e Administração
ocupa o destino Mais.

#### Decisão visual fechada

O responsável aprovou em 23 de agosto de 2026 a opção já desenhada no protótipo:

- **Mobile e Web estreito:** cabeçalho compacto + gaveta lateral;
- **Web amplo:** lateral fixa com os mesmos cinco destinos;
- o toque adicional da gaveta foi aceito em troca de mais espaço e melhor
  acomodação do texto ampliado.

A barra inferior anterior foi removida somente depois dessa aprovação.

#### Escopo depois da decisão

- destinos fixos: **Início, Lojas, Produtos, Alertas e Mais**;
- Web amplo com lateral; Web estreito e Mobile coerentes com a decisão aprovada;
- cabeçalho com marca, título da área e acesso previsível à navegação;
- hierarquia interna com retorno visível, sem depender apenas do botão físico;
- preservação do `IndexedStack` ou solução equivalente que mantenha busca,
  filtros, páginas e posição útil;
- restauração correta após rotação e retorno de uma página de detalhe;
- item selecionado comunicado por texto, ícone, contraste e semântica;
- domínio atual preservado ao voltar de Histórico, Administração ou confirmação;
- nenhum destino externo, token ou workflow aceito pela navegação.

#### Arquivos previstos

- `lib/app/navegacao/destinos.dart`;
- `lib/app/navegacao/moldura.dart`;
- componentes de cabeçalho/gaveta quando aprovados;
- `test/app/navegacao/moldura_test.dart` e testes de preservação de estado.

#### Aceite

- cinco destinos alcançáveis em retrato, paisagem e texto ampliado;
- Web navegável por teclado, com foco visível;
- leitor de tela anuncia destino, seleção e botão de abrir/fechar menu;
- no Samsung, vinte trocas de área não descartam uma busca já carregada nem
  produzem tela branca;
- botão Voltar fecha primeiro a gaveta/página interna e não encerra o app de
  forma surpreendente.

**Saída:** fundação de navegação pronta para receber todas as telas seguintes.

#### Registro do Módulo 2 — implementação local

- os destinos agora são **Início, Lojas, Produtos, Alertas e Mais**;
- a gaveta compacta possui marca, abrir/fechar acessível, seleção por texto,
  ícone, contraste e semântica; a lateral Web usa a mesma ordem;
- o breakpoint comum é 920 px e o `IndexedStack` continua preservando o estado
  das cinco áreas ao alternar entre elas;
- **Lojas** ganhou somente a entrada transitória necessária para manter Livelo
  e Shopping Inter alcançáveis. Ela não consulta resumos nem inventa números; o
  redesign completo dos cartões continua no Módulo 4;
- **Produtos** abre diretamente a busca existente e preserva o texto digitado;
- **Alertas** continua exibindo o estado honesto de funcionalidade futura;
- **Mais** conserva a Administração atual durante a transição para o Módulo 9;
- rotas internas de Lojas possuem retorno explícito, e o botão Voltar retorna
  primeiro ao hub antes de sair do aplicativo.

Evidências do fechamento técnico:

- formatação e `flutter analyze` aprovados;
- `flutter test --coverage`: **137 testes aprovados**;
- cobertura global: **2529/2805 linhas, 90,16%**;
- `moldura.dart`: **116/118 linhas, 98,31%**;
- `lojas.dart`: **70/71 linhas, 98,59%**;
- goldens aprovados para gaveta Mobile e lateral Web;
- `flutter build web` e `flutter build apk --debug` aprovados;
- APK debug instalado com `adb install -r`, preservando dados locais, e aberto
  no Samsung SM-M135M; o responsável realizou o teste manual e aprovou;
- nenhum backend, contrato, workflow, dado real ou protótipo foi alterado.

O Módulo 3 não começa antes do aceite visual final desta moldura e da definição
do contrato real de resumo prevista no próprio módulo.

### Módulo 3 — Início e resumo real do dia

**Tipo:** tela nova de produto; exige contrato de API antes da implementação.

**Estado real de partida:** `PaginaInicio` mostra somente o status da API. Os
números, oportunidades e atividades do protótipo são ilustrativos. Hoje não há
um contrato único que entregue esse resumo.

#### Submódulo 3A — contrato do resumo

Antes de desenhar dados reais no Flutter:

1. inventariar quais totais e estados já podem ser obtidos sem consulta
   redundante;
2. definir um contrato agregado versionado na API, sem assinatura inventada
   neste plano;
3. separar Livelo, Cashback Inter e Produtos no payload;
4. devolver instante, recorte e qualidade de cada total;
5. distinguir última solicitação, execução em andamento, última tentativa e
   último sucesso;
6. manter pontos, cashback e dinheiro como texto decimal seguro;
7. cobrir autorização, falha parcial e compatibilidade com o site legado.

##### Contrato aprovado — `GET /api/v1/resumo`

O inventário de 23 de agosto de 2026 confirmou que o resumo pode ser calculado
por leitura do Postgres existente, sem migração e sem consultar Livelo ou Inter
durante a navegação. O endpoint será autenticado como as demais rotas privadas
e não substituirá os contratos atuais usados pelo site legado.

```json
{
  "gerado_em": "2026-08-23T12:00:00.000Z",
  "estado_geral": "atualizado | atencao | sem_dados | indisponivel",
  "livelo": {
    "estado": "atualizado | atrasado | sem_dados | indisponivel",
    "ultimo_sucesso_em": "data ISO ou null",
    "lojas_acompanhadas": 0,
    "alertas_ultima_coleta": 0
  },
  "cashback_inter": {
    "estado": "atualizado | atrasado | atualizando | falha_recente | sem_dados | indisponivel",
    "ultima_tentativa_em": "data ISO ou null",
    "ultima_tentativa_estado": "iniciada | sucesso | falha | null",
    "ultimo_sucesso_em": "data ISO ou null",
    "lojas_acompanhadas": 0,
    "lojas_encontradas_ultima_coleta": 0
  },
  "produtos": {
    "estado": "atualizado | atrasado | atualizando | parcial | falha_recente | degradado | sem_dados | indisponivel",
    "ultima_tentativa_em": "data ISO ou null",
    "ultima_tentativa_estado": "iniciada | sucesso | parcial | falha | null",
    "dados_mais_antigos_em": "data ISO ou null",
    "dados_mais_recentes_em": "data ISO ou null",
    "qualidade": "completa | degradada | null",
    "lojas_selecionadas": 0,
    "lojas_sem_coleta": 0,
    "produtos_ativos": 0
  }
}
```

Regras da proposta:

- cada domínio conserva seu próprio relógio e seu último retrato válido;
- uma tentativa recente com falha, parcial ou em andamento não apaga o último
  sucesso;
- Produtos expõe o intervalo entre a loja selecionada mais antiga e a mais
  recente, evitando esconder uma loja atrasada atrás de uma data agregada;
- falha de leitura de um domínio o marca como `indisponivel`, sem fabricar zero
  e sem impedir que os outros domínios reais sejam devolvidos;
- contagens são inteiros não negativos; qualquer valor futuro de pontos,
  cashback ou dinheiro continuará textual e nunca será calculado com `double`;
- o Flutter deriva a apresentação e as prioridades desses estados, mas nunca
  inicia coleta nem acessa as fontes ou o banco diretamente.

Os protótipos Web e Mobile foram atualizados com cartões sem números
ilustrativos, três relógios de domínio e quatro atalhos fixos. O responsável
aprovou o contrato e a experiência visual em 23 de agosto de 2026, liberando a
implementação local da API e do Flutter.

#### Submódulo 3B — tela Início

- saudação curta, data e último dado confiável;
- faixa prioritária para falha, atraso, parcial, degradado ou coleta em curso;
- cartões de resumo com recorte explícito, nunca um total ambíguo;
- bloco **O que merece atenção** sem ranking misto entre benefícios;
- atividade recente distinguindo pedido aceito, início, conclusão e falha;
- quatro atalhos **fixos** inicialmente, apontando apenas para jornadas reais;
- atualização por gesto/botão consulta a API, nunca Livelo ou Inter;
- falha da reconsulta mantém o último resumo e oferece retry.

Atalhos editáveis continuam uma melhoria opcional não autorizada. Para entrar,
precisam de decisão sobre persistência local ou por usuário, sincronização e
ordenação. Até lá, os quatro atalhos fixos são a alternativa simples.

#### Testes e aceite

- contrato com relógio explícito, números textuais e estados por domínio;
- widgets para carregamento, sucesso, zero real, vazio, atraso, parcial,
  degradado, falha e acesso negado;
- golden do celular e Web amplo;
- no Samsung, atalhos abrem as áreas certas e voltar conserva o Início;
- nenhuma métrica ilustrativa aparece num build conectado à API real.

**Saída:** Início responde honestamente “o que merece atenção agora?”.

#### Registro do Módulo 3 — implementação local

**Estado:** contrato, API, Flutter e gates locais concluídos em 23 de agosto de
2026. A rota foi observada publicada com proteção de autenticação (`401` sem
credencial) e o resumo foi aberto no Samsung em build debug sem App Check. O
App Check de depuração continua com observação própria pendente.

- `GET /api/v1/resumo` autentica com a operação `resumo.ler` e faz uma leitura
  isolada por domínio;
- falha de uma leitura devolve somente aquele domínio como `indisponivel` e
  nunca inclui a exceção ou a credencial do banco na resposta;
- a tela conserva o último resumo recebido se uma atualização falhar;
- métricas indisponíveis usam `—`; zero continua reservado a contagem real;
- a prioridade visual cobre atraso, atualização, falha, parcial, degradado,
  sem dados e indisponibilidade;
- os quatro atalhos abrem Lojas, Livelo, Produtos e Cashback Inter sem criar
  jornadas novas;
- Mobile/Web possuem goldens próprios e 320 × 640 com texto a 150% não causa
  overflow.

Validações locais:

- site: TypeScript, ESLint, **83 testes Vitest** e build Next.js aprovados; o
  build lista `/api/v1/resumo` como rota dinâmica;
- Flutter: formatação, análise, **147 testes** e builds Web/APK debug aprovados;
- cobertura Flutter global: **2872/3146 linhas, 91,29%**;
- `inicio.dart`: **306/306 linhas, 100%**;
- nenhum teste acessou Neon de produção, Livelo ou Inter.

### Módulo 4 — hub de Lojas

**Tipo:** nova organização visual usando jornadas existentes.

#### Escopo

- entrada própria para **Livelo**, explicando pontos, Clube e regras de alerta;
- entrada própria para **Shopping Inter**, explicando Cashback e Produtos;
- estado resumido por fonte somente quando houver dado real disponível;
- nenhum cartão vazio para integração futura ainda inexistente;
- Livelo e Inter alcançáveis em no máximo dois toques a partir da navegação;
- falha de uma fonte não contamina visualmente a outra;
- sem conversão de pontos, cashback e dinheiro.

**Dependência:** Módulo 2. Métricas agregadas dependem do Módulo 3A; sem elas,
os cartões exibem apenas descrição e acesso, não números fictícios.

**Aceite:** caminhos, títulos e retorno ficam claros no Samsung e no Web;
teclado/leitor de tela entendem cada cartão como ação única.

#### Registro do Módulo 4 — implementação local

**Estado:** protótipos Web/Mobile aprovados e implementação local concluída em
23 de agosto de 2026. O aceite visual no Samsung fica com o responsável.

- o hub consulta somente `GET /api/v1/resumo`, sem iniciar coleta nem acessar
  Livelo, Inter ou Postgres diretamente;
- Livelo mostra lojas acompanhadas, alertas somente quando há coleta válida e
  o instante do último sucesso;
- Shopping Inter mostra Cashback e Produtos em chips separados; uma falha ou
  estado parcial de uma modalidade não é apresentado como estado da outra;
- indisponibilidade da leitura mantém os dois acessos disponíveis e oferece
  nova tentativa do resumo, sem inventar números;
- cada cartão inteiro continua sendo uma única ação para sua jornada existente,
  e o retorno para o hub preserva a navegação interna.

Validações executadas:

- `dart format --output=none --set-exit-if-changed lib test`;
- `flutter analyze` sem apontamentos;
- `flutter test`: **148 testes aprovados**, incluindo CT-328;
- builds Web e APK debug aprovados; o APK não foi instalado nesta etapa.

### Módulo 5 — hub do Shopping Inter

**Tipo:** reorganização das duas integrações Inter já implementadas.

#### Escopo

- cartão **Cashback — Sites parceiros**;
- cartão **Produtos — Compre direto**;
- acesso protegido a gerenciamento das duas modalidades para administrador;
- ações de atualização separadas por domínio;
- carimbo e estado próprios para Cashback e Produtos;
- retorno visível para **Lojas** e para **Shopping Inter** nas jornadas internas;
- nenhum botão genérico que dispare um workflow ambíguo.

**Regra estrutural:** V3 e V4 continuam com modelos, processos, tabelas e
workflows próprios. O hub compartilha navegação, não regra de negócio.

**Aceite:** uma pessoa que não conhece os PRDs identifica a diferença entre
Sites parceiros e Compre direto antes de abrir a jornada.

#### Registro do Módulo 5 — implementação local

**Estado:** protótipos Web/Mobile aprovados e implementação local concluída em
23 de agosto de 2026. O aceite visual no Samsung fica com o responsável.

- `Lojas → Shopping Inter` abre um segundo hub, com cartões distintos para
  **Cashback — Sites parceiros** e **Produtos — Compre direto**;
- cada cartão consulta somente o resumo autenticado já existente e mantém
  estado e carimbo próprios, sem transformar falha, parcial ou ausência em zero;
- os pedidos administrativos aparecem apenas para administrador e chamam,
  respectivamente, os domínios `inter` e `produtos_inter`; não há ação genérica
  que possa disparar o workflow errado;
- Cashback e Produtos permanecem em suas páginas, controladores e contratos
  atuais. Seus retornos explícitos levam primeiro ao Shopping Inter e depois a
  Lojas;
- a Administração existente em **Mais** continua sendo o acesso protegido de
  gerenciamento enquanto a reorganização dela fica reservada para o Módulo 9.

Validações executadas:

- `dart format --output=none --set-exit-if-changed lib test`;
- `flutter analyze` sem apontamentos;
- `flutter test`: **150 testes aprovados**, incluindo CT-329;
- builds Web e APK debug aprovados; não houve smoke manual nesta etapa.

### Módulo 6 — Produtos e histórico de 30 dias

**Tipo:** redesign de jornada já implementada; contratos principais prontos.

#### Submódulo 6A — busca e filtros

- destino principal **Produtos**, também acessível pelo hub Inter;
- termo obrigatório de 2 a 100 caracteres;
- debounce de 350 ms e descarte de resposta antiga;
- filtros de loja, marca, categoria e preço validados no servidor;
- busca consulta somente o Postgres pela API;
- tela inicial não baixa nem renderiza o catálogo completo;
- 20 produtos por página e no máximo 50 por resposta;
- total, página, qualidade e horário do catálogo sempre visíveis;
- todos os resultados alcançáveis, sem lacuna, duplicação ou corte silencioso;
- falha numa página adicional mantém resultados anteriores e retry tenta a
  mesma página.

#### Submódulo 6B — cartão de produto

- nome completo, loja, marca/categoria quando disponíveis;
- preço cheio riscado somente quando diferente do atual;
- desconto absoluto/percentual sem inventar zero;
- preço atual e **Após cashback** com o mesmo peso visual;
- cashback, parcelamento, estoque e etiquetas da mesma medição;
- qualidade completa/degradada e horário por loja;
- botão externo somente para HTTPS reconstruído sob `shopping.inter.co`;
- conteúdo externo sempre como texto e nenhuma imagem remota.

#### Submódulo 6C — histórico

- identidade loja + ID externo preservada;
- preço atual, mínimo e máximo dos últimos 30 dias;
- medições paginadas, mais recentes primeiro;
- produto inativo mantém histórico e informa ausência atual;
- falha de página adicional mantém resumo e medições já exibidos;
- tabela acessível no Web e composição legível no celular;
- sem gráfico até existir proposta visual e aprovação próprias.

#### Testes e aceite

- regressões CT-285 a CT-293 preservadas;
- widgets/goldens para card completo, incompleto, degradado e atrasado;
- busca com 200 itens de fixture permite alcançar dez páginas de 20;
- no Samsung: teclado, filtros, rotação, rolagem, detalhe, retorno e link
  externo confirmado antes de abrir;
- smoke conectado é somente leitura e nunca inicia coleta.

**Saída:** busca e histórico recebem a nova identidade sem alterar as regras V4.

### Módulo 7 — Cashback Inter e acompanhamento

**Tipo:** redesign de leitura existente + aproximação das mutações já existentes
na Administração.

#### Escopo de leitura

- busca por nome/slug com debounce de 350 ms;
- ordenação por cashback e nome, mantendo valor zero/ausente no estado correto;
- dez lojas por carregamento nesta jornada;
- total, quantidade exibida e continuação sempre visíveis;
- oferta principal textual, valor auxiliar, etiqueta e condições completas;
- oferta de não-correntista identificada e recolhida por padrão;
- ausência de condição recebe a mensagem neutra aprovada;
- carimbo, falha recente, último sucesso, atraso e loja ausente separados;
- link genérico aprovado do Shopping Inter.

#### Escopo de acompanhamento

- **Acompanhar** atualiza o cartão e contadores imediatamente após sucesso do
  servidor;
- remoção exige confirmação com o nome exato da loja;
- duplo toque fica bloqueado;
- busca, página, filtro e posição útil são preservados;
- revalidação em segundo plano não apaga a lista quando falha;
- a tela não inicia coleta ao acompanhar ou remover;
- administrador pode solicitar atualização pela API protegida, com cooldown e
  idempotência já existentes;
- pedido aceito nunca é apresentado como coleta concluída.

#### Dependência técnica

O endpoint administrativo já existe, mas a tela pública usa atualmente
`por_pagina=20`. A implementação deve parametrizar 10 somente nesta jornada,
sem mudar o padrão de Produtos e sem ampliar o máximo 50 da API.

#### Testes e aceite

- preservar CT-277 a CT-284 e CT-294/CT-295;
- testar confirmação nominal, atualização imediata, erro mantendo estado e
  resposta antiga descartada;
- no Samsung, acompanhar/remover usa ambiente falso ou descartável durante o
  desenvolvimento. Qualquer mutação real exige autorização específica no
  momento do smoke.

**Saída:** Cashback e acompanhamento passam a formar uma jornada única e
coerente, sem misturar coleta com seleção.

### Módulo 8 — Livelo

**Tipo:** dividido entre redesign possível agora e evolução funcional bloqueada
por contrato.

#### Submódulo 8A — painel das lojas já cadastradas

- busca por nome/categoria e ordenação por pontos, alerta ou nome;
- paginação progressiva sem repetição;
- pontuação atual, normal, valor de disparo, Clube e campanha;
- distinção correta entre `CLUB` e `PROMOTION_CLUB`;
- validade, alerta, loja ausente e dado atrasado;
- condições externas expansíveis como texto seguro;
- botão de regra/ajuste somente para administrador;
- solicitação de atualização protegida, sem afirmar conclusão antecipada;
- nenhuma mudança em RN27, RN28 ou RN30.

Esse submódulo é um redesign do que a API já entrega e pode ser implementado
depois da aprovação visual.

#### Submódulo 8B — descobrir e acompanhar qualquer parceiro coletado

**Bloqueado como funcionalidade nova.** O protótipo demonstra “Todas as lojas”
com seleção, mas o backend atual expõe principalmente as lojas já cadastradas.
Antes do código será obrigatório:

1. aprovar a jornada nos dois protótipos;
2. definir no PRD o que é catálogo coletado e o que é favorita;
3. decidir persistência e identidade sem quebrar RN04;
4. definir contrato paginado e mutações da API;
5. preservar retratos/histórico e o TOML de reserva;
6. escrever testes de migração, seleção e correspondência exata.

O 8A não espera o 8B e não fingirá oferecer lojas que o contrato atual não
possui.

#### Testes e aceite

- preservar CT-263 a CT-276;
- golden dos cartões com e sem alerta, Clube e condições longas;
- no Samsung, busca, ordenação, paginação, rotação e retorno conservam estado;
- números continuam textuais e nenhuma descrição externa vira HTML.

**Saída:** primeiro o painel atual recebe o design novo; catálogo selecionável
entra somente depois do próprio gate funcional.

### Módulo 9 — Mais, perfil, ajuda, aparência e saída

**Tipo:** hub novo sobre capacidades de maturidades diferentes.

#### Submódulo 9A — hub Mais

- perfil resumido usando apenas nome/papel que o contrato já entrega;
- acesso à Administração somente para `admin`;
- acesso à Ajuda e ao aviso de não afiliação;
- ação **Sair** com feedback e retorno ao login;
- itens indisponíveis não aparecem como se funcionassem;
- sem mostrar UID, token, e-mail sensível ou detalhe interno desnecessário.

#### Submódulo 9B — Ajuda

- explicar Livelo, Sites parceiros e Compre direto em linguagem comum;
- explicar atualização, atraso, degradado, falha, cashback e após cashback;
- informar que o projeto é independente e que a condição deve ser confirmada
  na fonte antes da compra;
- conteúdo estático versionado, sem carregar página externa dentro do app.

#### Submódulo 9C — Aparência

O tema escuro completo e a persistência de aparência são melhorias opcionais
ainda não autorizadas. Antes de entrar será necessário decidir:

- claro, escuro e seguir sistema;
- armazenamento local ou preferência por usuário;
- comportamento equivalente no Flutter Web;
- contraste e goldens dos dois temas.

Até essa decisão, **Aparência** não será um botão sem efeito. A tela usa o tema
claro aprovado.

#### Aceite

- usuário comum não vê nem alcança Administração;
- admin alcança as áreas existentes sem perder a tela anterior;
- sair encerra a sessão local e não afeta outros dados;
- ajuda funciona offline depois do app carregado e é acessível.

### Módulo 10 — Administração por domínio

**Tipo:** reorganização visual de funções já implementadas e publicadas na API.

#### Submódulo 10A — hub administrativo

- cartões separados para Livelo, Sites parceiros, Compre direto, Atualizações e
  Zona de perigo;
- papel administrativo revalidado no servidor em toda leitura/mutação;
- última intenção não vira permissão permanente no cliente;
- retorno para Mais e entre subáreas sem perder estado.

#### Submódulo 10B — Livelo administrativa

- preferências globais em linguagem comum;
- cadastro somente com nome canônico e apelidos válidos;
- regra própria opcional por loja;
- busca, paginação e remoção com confirmação nominal;
- decimais textuais de ponta a ponta;
- cadastro/regra/apelidos atômicos no servidor.

#### Submódulo 10C — Sites parceiros

- catálogo paginado, busca e estado acompanhada/não acompanhada;
- mudança imediata do cartão depois do sucesso;
- remoção confirmada e estado preservado;
- nenhuma edição livre de nome, slug ou ID.

#### Submódulo 10D — Compre direto

- vendedores paginados, busca e seleção operacional;
- explicar que cada loja selecionada acrescenta coleta paginada;
- nenhuma quantidade máxima inventada na interface;
- remover interrompe novas coletas e exposição, sem prometer apagar histórico;
- seleção nunca recebe slug/URL arbitrária do cliente.

#### Submódulo 10E — Atualizações

- Livelo, Inter Sites parceiros e Produtos como ações separadas;
- cooldown, última solicitação e pré-condições vindos da API;
- `Idempotency-Key` gerada no cliente e autoridade mantida no servidor;
- botão bloqueado durante envio e resposta repetida tratada como mesma intenção;
- estados: disponível, enviando, aceito, cooldown, sem loja, acesso negado e
  falha;
- não consultar GitHub diretamente nem expor token/workflow.

#### Submódulo 10F — Zona de perigo

- entrada visualmente separada e por último;
- páginas distintas para Livelo e Inter;
- prévia de contagens, consequências, irreversibilidade e ausência de backup;
- frase exata `APAGAR LIVELO` ou `RESETAR INTER`;
- frase e domínio revalidados no servidor;
- transação, rollback, idempotência de domínio vazio e auditoria preservados;
- abrir a tela nunca executa limpeza;
- **nenhuma limpeza de produção durante implementação ou smoke**.

#### Testes e aceite

- preservar CT-294 a CT-298;
- testes de widget por submódulo, incluindo acesso negado e estado preservado;
- testes de API/site apenas quando o contrato compartilhado mudar;
- no Samsung, formulários, teclado, rotação, confirmação e botão Voltar;
- mutações usam fakes ou banco descartável protegido; disparo e limpeza reais
  ficam fora.

**Saída:** Administração deixa de ser uma tela densa e mantém todas as
proteções da Fase 5 e do PRD V5.

### Módulo 11 — Alertas

**Tipo:** estado futuro honesto agora; funcionalidade real depende da Fase 6.

#### Entrega permitida no redesign atual

- tela explicando que alertas automáticos ainda estão em preparação;
- acesso à informação sobre o que será necessário;
- nenhum badge, contador, evento, toggle ou histórico falso;
- rota/destino permanece estável para não redesenhar a navegação novamente.

#### Entrega futura, ainda não autorizada

Quando a Fase 6 for aprovada, deve existir um plano próprio cobrindo:

- regras de eventos por domínio;
- outbox persistente e consumidor com retry;
- idempotência e anti-spam;
- tokens/aparelhos, FCM e deep links autenticados;
- preferências, horário silencioso e conteúdo discreto;
- relatório diário/manual, remetente e horário;
- retenção e histórico de notificações;
- falha de canal sem reverter coleta válida;
- testes Android, iOS, Web e cliente real de e-mail.

**Saída atual:** estado vazio honesto. **Saída futura:** somente a definida no
plano próprio da Fase 6.

### Módulo 12 — fechamento multiplataforma do redesign

**Tipo:** consolidação; não acrescenta nova regra de produto.

#### Escopo

- varrer consistência entre Flutter e os dois protótipos;
- revisar todos os componentes/tokens antes de criar duplicação;
- executar acessibilidade com texto ampliado, contraste, foco, teclado, leitor
  de tela e movimento reduzido;
- conferir retrato e paisagem em celular, tablet e Web estreito/largo;
- validar deep links/retornos internos existentes;
- confirmar que Web, Android e iOS usam o mesmo projeto adaptativo;
- manter o site legado vivo e seus gates verdes;
- registrar limitações de iOS enquanto não houver macOS/Xcode/aparelho.

#### Aceite final

- todas as telas aprovadas estão coerentes com os protótipos;
- nenhum estado real foi substituído por número ilustrativo;
- nenhuma regra Livelo/V3/V4/V5 regrediu;
- todos os resultados paginados continuam alcançáveis;
- segredos não aparecem em bundle, log ou captura;
- gates locais e builds previstos passam;
- smoke físico Android é concluído; Web e iOS recebem o aceite previsto para a
  plataforma antes do corte;
- nenhuma publicação ou `push` acontece automaticamente.

**Saída:** redesign pronto localmente para revisão e decisão de envio.

## 4. Mapa consolidado e dependências

| Ordem | Módulo | Estado inicial | Backend novo | Gate antes do código |
|---:|---|---|---|---|
| 0 | Decisões visuais + abertura | Concluído no Android | Não | Web/iOS ficam como aceite de plataforma |
| 1 | Login | Redesenhado e aprovado no Samsung | Não | Concluído; Web/iOS entram no aceite de plataforma |
| 2 | Moldura e navegação | Implementado e aprovado no Samsung | Não | Concluído; Web/iOS entram no aceite de plataforma |
| 3 | Início | Somente status da API | **Sim, resumo agregado** | Fechar contrato e dados reais |
| 4 | Hub de Lojas | Não existe como hub | Não, salvo métricas | Aprovar cartões e hierarquia |
| 5 | Hub Shopping Inter | Existe parcialmente | Não | Aprovar caminhos e retornos |
| 6 | Produtos + histórico | Funcional | Não | Aprovar reskin de busca, cards e detalhe |
| 7 | Cashback + acompanhamento | Leitura e gestão existem separadas | Não | Aprovar mutações dentro da jornada |
| 8A | Livelo atual | Funcional | Não | Aprovar reskin do painel existente |
| 8B | Catálogo Livelo selecionável | Não existe | **Sim, PRD/API/banco** | Decisão funcional própria |
| 9 | Mais, perfil, ajuda e saída | Administração ocupa Mais | Parcial | Aparência continua opcional |
| 10 | Administração por domínio | Funcional em quatro abas | Não | Aprovar nova divisão por telas |
| 11 | Alertas | Lugar-ocupante | **Sim, Fase 6** | Plano próprio; agora só estado honesto |
| 12 | Fechamento multiplataforma | Não iniciado | Não | Todos os módulos aprovados encerrados |

### 4.1 Ondas de execução

Os módulos continuam aprovados e entregues um por vez, mas são agrupados para
deixar as dependências claras:

1. **Onda A — acesso:** Módulo 1;
2. **Onda B — estrutura:** Módulo 2;
3. **Onda C — descoberta:** Módulos 3, 4 e 5;
4. **Onda D — jornadas de consulta:** Módulos 6, 7 e 8A;
5. **Onda E — conta e gestão:** Módulos 9 e 10;
6. **Onda F — futuro honesto:** Módulo 11, sem ativar a Fase 6;
7. **Onda G — consolidação:** Módulo 12.

O 8B e a funcionalidade real do 11 não entram automaticamente nessa fila. São
projetos funcionais novos e retornam ao ciclo PRD → protótipos → aprovação →
contratos → implementação.

### 4.2 Critério para avançar automaticamente

Depois que o responsável aprovar visualmente um módulo, a automação pode
executar sem pedir confirmação intermediária:

1. registrar o módulo como `em andamento` neste plano;
2. implementar a menor fatia coerente;
3. escrever/ajustar testes em lote;
4. executar os gates proporcionais ao risco;
5. instalar no Samsung quando o módulo tiver comportamento móvel;
6. realizar o roteiro físico não destrutivo;
7. corrigir falhas e repetir somente o necessário;
8. atualizar documentação e evidências reais;
9. parar no aceite visual do módulo concluído antes de iniciar o próximo.

Escopo materialmente novo, contrato ausente, sugestão opcional ou ação externa
continua interrompendo a automação no gate correspondente.

## 5. Execução automática e aparelhos de teste

### 5.1 Alvos confirmados em 23 de agosto de 2026

| Alvo | Identificação | Uso no redesign |
|---|---|---|
| Android físico | Samsung SM-M135M, Android 14/API 34, serial `RX8W105DHSY` | Instalação, toque, teclado, rotação, Voltar e smoke visual |
| Web | Chrome disponível no workspace | Responsividade, teclado, foco e build Web |
| Linux desktop | Runner Flutter disponível | Apoio de diagnóstico, não substitui Web/mobile |
| iOS | Sem Xcode/macOS neste ambiente | Estrutura e recursos; build/smoke ficam pendentes |

Antes de cada instalação, a automação confirma novamente o serial. Ela nunca
usa um alvo genérico se houver mais de um Android conectado.

### 5.2 Sequência técnica por módulo

1. conferir `git status` e preservar mudanças do responsável;
2. confirmar `flutter devices` e `adb devices -l`;
3. editar código e testes em lote;
4. executar testes específicos durante correções;
5. fechar com formatação, análise e suíte Flutter relevante uma vez;
6. gerar o build previsto;
7. instalar explicitamente no `RX8W105DHSY`;
8. fazer smoke manual orientado pelo aceite do módulo;
9. capturas temporárias ficam fora do repositório, salvo aprovação para um
   golden ou documentação;
10. conferir `git diff --check`, resumo de mudanças e ausência de segredo;
11. não criar commit nem fazer `push` automaticamente.

### 5.3 Roteiro físico comum no Samsung

- abrir a tela a partir do ícone e pela navegação interna;
- testar retrato e paisagem;
- abrir/fechar teclado e voltar sem perder campos ou filtros;
- usar aumento de fonte disponível no aparelho quando o módulo tiver muito
  texto;
- validar toque único e bloqueio de toque repetido;
- navegar para detalhe e voltar preservando posição útil;
- simular falha com fakes/build de desenvolvimento quando necessário;
- conferir loading, vazio, atraso, parcial, degradado, falha e retry que se
  apliquem;
- observar logs somente para exceção técnica sanitizada, nunca para segredo;
- encerrar sem disparar workflow, notificação, limpeza ou mutação real não
  autorizada.

### 5.4 O que o smoke físico não substitui

O aparelho ajuda a descobrir problemas de layout, teclado, rotação, navegação
e integração de plataforma. Ele não substitui:

- testes unitários e de widget;
- paginação com centenas de itens em fixture;
- falhas, concorrência e respostas antigas controladas por teste;
- acessibilidade Web por teclado;
- build iOS em runner compatível;
- testes de contrato e segurança no servidor;
- aceite destrutivo em banco descartável.

## 6. Validação de cada etapa

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

## 7. Regras que o redesign não pode quebrar

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

## 8. Próximo passo

Os **Módulos 0 a 4** receberam aceite e o **Módulo 5 — hub do Shopping Inter**
está implementado localmente após a aprovação dos protótipos. O próximo passo é
o protótipo do Módulo 6; Web e iOS permanecem como validações futuras de
plataforma.

Nenhum commit, `push`, disparo, migração ou mutação real foi realizado nesta
etapa.
