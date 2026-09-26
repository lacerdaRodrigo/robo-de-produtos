# Pendências

Lista viva somente do que continua aberto. Histórico concluído permanece no Git e nos PRDs; não deve voltar a governar o ciclo atual.

O contrato operacional padrão do ciclo mobile V15 é o
[`AGENTS.md`](../AGENTS.md): Flutter Android/iOS, `design-app/mobile-v15/index.html`
como fonte visual, unitários/widgets afetados e integração/E2E fora do gate. O contrato de backend necessário ao V15 está implementado, a migration
029 foi aplicada e confirmada pelo responsável, e o APK build `27503` foi
retestado localmente contra a API publicada. A distribuição privada e o aceite
físico completo continuam abertos; evidências e cenários restantes estão no
[`PRD de aceite mobile`](prd/PRD-ACEITE-MOBILE-V15.md). A
disponibilidade contínua do executor Android permanece uma pendência separada
na seção Pichau abaixo.

## Ciclo mobile atual

- [x] Definir e implementar o contrato paginado de lista consolidada do `Meu
  radar`, o bloco pessoal `radar` de `/api/resumo` e a integração Flutter. A
  migration 029 foi aplicada e confirmada; a distribuição privada ainda
  depende da publicação/autorização externa.
- [ ] Produzir um evento real de alerta e confirmar a entrega FCM; a coleta corrigida `34761933582` passou com 1.180 itens, mas não houve mudança de preço e, portanto, não houve evento pendente. A permissão de push é opcional e o histórico deve continuar acessível quando recusada.
- [ ] Fazer o aceite físico completo no Moto G6 Play e no Samsung quando uma entrega mobile exigir. No Samsung, o APK build `27503` foi instalado e o relatório atual registra `29` cenários verdes, `11` amarelos, `2` pendentes e nenhum vermelho; o estado offline inicial agora apresenta falha/retry recuperável. Ainda faltam sessão expirada controlada, usuário comum, paginação completa, alguns estados e comparação visual formal, incluindo os cabeçalhos responsivos, áreas seguras, retorno Android, a composição corrigida do hub Banco Inter, a tela responsiva de Sites parceiros, a conferência física da folha de filtros de Sites parceiros com os selects alinhados e as opções do protótipo, ausência de busca no hub de Explorar, composição dos cartões do catálogo Livelo (hierarquia, Clube no histórico, condições e confirmação externa) e folha de histórico. No Moto G6 Play, permanecem as lacunas já registradas. Isso não vira smoke automatizado neste ciclo.
- [ ] Aplicar `migracoes/030_categorias_cashback_inter.sql` no projeto Neon que atende a API Production e classificar as lojas atuais pelo endpoint administrativo. A migration já foi aplicada no novo destino vazio em 2026-09-26; lá ainda não há lojas para classificar. Enquanto não houver mapeamento aprovado, a API mantém as lojas em `Outros`; os códigos, validação, fallback e filtro já estão cobertos localmente.
- [ ] Revalidar fisicamente a Central de Alertas após a composição V15 atual: botão `Voltar`, título `Mudou. Você viu.`, abas planas, filtro em folha, feed sem cartões, barra inferior e `Marcar todos como lidos` em mais de uma página. O widget e o controlador cobrem a estrutura, o toque de retorno e o contrato paginado; o back Android e a comparação visual ainda precisam de conferência no Samsung/Moto G6 Play.
- [x] Conferir manualmente no Samsung a nova composição da Home compacta: rail Livelo, Banco Inter e Pichau, sem a seção `Atividade recente` nem cartão de alerta; claro/escuro e bloqueio/retomada foram observados. `radar.destaque` permanece no contrato para a Central, enquanto a Home usa contadores e mantém estado honesto quando não há dados.
- [x] Aplicar e verificar `migracoes/029_indices_mobile_v15.sql` em conexão
  direta/unpooled no ambiente de teste. O responsável confirmou as duas
  instruções `CREATE`; o APK correspondente foi instalado e retestado no
  Samsung.
- [ ] Publicar e validar a correção de compatibilidade da leitura do catálogo Pichau após a mudança para acompanhamento pessoal; enquanto o fallback não for observado no ambiente publicado, não declarar o catálogo recuperado no APK real.
- [ ] Conferir manualmente no Samsung a paginação de Produtos, Livelo, Sites parceiros e Compre direto nos limites de 9, 10 e 11 cards; o repositório cobre a regra por widget, mas não substitui o aceite físico.
- [ ] Conferir manualmente no Samsung a navegação `Banco Inter → Sites parceiros` e `Banco Inter → Compre direto → Produtos`: abertura dos dois cards em telas próprias, abas `Todas`, `Selecionadas` e `Produtos`, atalho da Home, retorno às lojas e acesso contínuo ao histórico/links.
- [ ] Conferir manualmente no Samsung o Compre direto nas abas `Todas` e `Selecionadas`, confirmando a composição compacta do protótipo: cabeçalho Banco Inter, busca, abas `Todos`/`No radar`, filtros e cards agrupados por loja; o teste de widget cobre a estrutura, mas o aceite visual físico continua pendente.
- [x] Conferir manualmente no Samsung o novo acesso pelo perfil: aparência, Central de Alertas, suporte, privacidade e Administração exibindo somente a Zona de perigo, sem a antiga gaveta. O usuário autorizado abriu todos os destinos e o relatório registra o que ainda depende de outra conta/fixture.
- [x] Aplicar e verificar as migrations `025`, `026` e `027`: a leitura do banco
  confirmou 10 acompanhamentos Livelo, 16 Pichau, 37 Produtos Inter, dois
  eventos Inter recuperados com push suprimido e nenhuma outbox pendente.
- [x] Aplicar e verificar a migration `028_permissoes_alertas_pichau.sql`: a
  leitura de produção confirmou as funções de alerta como `SECURITY DEFINER`,
  `search_path` fechado e execução autorizada para `pichau_publisher`. A coleta
  `34761933582` passou com a fila 70 e a execução 58 em qualidade completa:
  1.180 itens lidos/únicos, zero duplicados e sem `pichau-banco`. As execuções
  anteriores `34759635491` e `34760049617` ficam como histórico da falha
  corrigida; o backfill histórico não envia push atrasado.

## Pichau — evolução ainda aberta

- [x] Preparar o novo projeto Neon vazio: aplicar as migrations `001`–`026` e
  `028`–`032`, criar roles/grants por consumidor e verificar schema, funções e índices.
  A migration `027` foi pulada porque só transporta seleções/eventos legados.
  Nenhum dado foi migrado; usuários, catálogos e históricos estão vazios.
- [ ] Criar PR desta branch, aguardar a CI verde e fazer merge squash conforme
  aprovado; não iniciar os coletores pelo código ainda não publicado na `main`.
- [ ] Ativar e validar os logins `radar_api`, `radar_actions_robo`,
  `radar_actions_pichau` e `radar_samsung` com senhas geradas fora do
  repositório; provar que a API não acessa filas e que o Samsung não acessa as
  tabelas pessoais.
- [ ] Após a validação de acesso, fazer o corte para o destino vazio:
  substituir `DATABASE_URL` da Vercel Production, atualizar
  `ROBO_DISPATCH_DATABASE_URL` e `PICHAU_DISPATCH_DATABASE_URL` no GitHub e
  `DATABASE_URL` no arquivo privado do Termux. Manter o `DATABASE_URL` antigo
  do GitHub como rollback por sete dias; não reutilizar a chave owner nem enviar
  credenciais pelo chat. Catálogos/históricos serão reconstruídos por novas
  coletas; seleções e dados pessoais não serão copiados.
- [ ] Instalar o checkout e dependências no Samsung sem remover os links de boot
  antigos antes de verificar os novos caminhos; apontar Termux:Boot para
  `scripts/celular/boot.sh`, validar `scripts/celular/status.sh`, agendas locais
  e disparos manuais. O worker busca `origin/main` e valida o SHA dos workflows;
  este branch precisa chegar à `main` antes de operar pelo fluxo normal. O
  workflow verde confirma apenas que o pedido entrou na fila, não que o coletor
  publicou os dados.
- [ ] Após a implantação, verificar ao menos uma coleta de cada fonte. Manter o
  gate já definido de nove execuções Pichau agendadas consecutivas em 72 horas,
  tela bloqueada e sem abrir Termux; qualquer falha reinicia a janela. Isso não
  prova disponibilidade após reboot nem substitui validar Livelo/Inter.
- [ ] Aceitar conscientemente a mudança da outbox para uma execução por hora:
  reduz chamadas agendadas à API/Neon, mas pode acrescentar quase uma hora de
  atraso à entrega de push. Se essa latência não for aceitável, decidir outro
  intervalo antes de publicar o workflow.

- [ ] Conferir manualmente no Samsung a composição visual Pichau V15: cabeçalho
  `Pichau`/`Catálogo`, retorno único, busca com avanço, abas `Todos`/`No radar`,
  botão `Filtros`, folha `Filtros · Pichau` com ordem/disponibilidade/faixa de
  preço — inclusive campo e ações alcançáveis acima do teclado —, hierarquia do
  card e abertura de `Detalhes`. Os widgets
  cobrem claro, escuro e larguras de 320/390/430 px, mas não substituem a
  comparação física com o protótipo.
- [ ] Publicar a versão da API que contém o filtro server-side de faixa de preço
  da Pichau e validar novamente no APK. A validação física de 21/09/2026 no
  Samsung confirmou que o cliente envia `preco_min=3000` (junto de
  `ordenar=nome`), mas o endpoint publicado ainda retornou produtos abaixo de
  R$ 3.000; não criar fallback local no Flutter.
- A validação branch-first da `024` foi concluída em 2026-09-10 numa branch
  temporária derivada de `production`, sem aplicar a `023`: coluna e constraints
  válidas, 47 linhas existentes compatíveis com `{}` e grants preservados para
  `pichau_dispatcher` (`SELECT/INSERT`) e `pichau_publisher` (`SELECT/UPDATE`). A
  branch temporária foi descartada sem alterar `production`. Depois da
  confirmação, o responsável aplicou a migration em `production`; a
  verificação somente de leitura confirmou coluna, constraints, 47 linhas com
  `{}` e os mesmos grants.
- [ ] Recuperar e analisar, em outro momento e apenas se ainda for útil, os
  metadados seguros do log local da falha de 10/09. Essa investigação foi
  adiada pelo responsável e não bloqueia a migration nem a implementação local.
- [ ] Executar uma coleta manual real com a tela bloqueada e somente Wi-Fi:
  exigir no máximo duas sessões, recuperação visível quando usada, catálogo e
  contagens completos, nenhuma publicação parcial, fila/sumário detalhados no
  Actions e Chrome/Appium ociosos ao final. A `34547539783` comprovou tudo isso
  com transporte interno Wi-Fi, mas o cabo de dados permaneceu conectado para a
  inspeção ADB e por isso não encerra este aceite.
- [ ] Observar nove execuções Pichau agendadas consecutivas em 72 horas, com o
  aparelho dedicado, carregando, no Wi-Fi e tela bloqueada, sem abrir o Termux.
  Na arquitetura proposta, o worker Samsung também agenda Livelo às `:10` e
  Inter às `:30` da hora seguinte; validar essas publicações separadamente. A
  janela Pichau recomeça após implantação; qualquer nova falha a reinicia.
- [ ] Decidir depois do gate se a exigência de recuperação manual após reboot é
  aceitável: ligar e desbloquear uma vez, ativar “Depuração por Wi‑Fi”, executar
  `adb tcpip 5555` por USB autorizado, conferir o status e retirar o cabo. A
  operação normal bloqueada e sem cabo não depende do USB enquanto o aparelho
  não reiniciar.
- [ ] Se a recuperação manual não for aceitável, avaliar controlador Linux
  residencial sempre ligado. O Android sem root não deve ser tratado como capaz
  de reativar sozinho a Depuração por Wi‑Fi desativada pela ROM.

## Ações operacionais externas

- [ ] Revisar periodicamente amostras reais dos recortes hierárquicos de navegação do catálogo Inter (incluindo os novos recortes de cozinhas, quarto/camas, beleza, saúde, limpeza/climatização e festas) e ampliar apenas folhas finais quando houver evidência. Os escopos atuais e “Outros / novas categorias” já são dinâmicos para qualquer quantidade de lojas ativas e selecionadas.
- [ ] Publicar a API com os novos identificadores de escopo antes de distribuir o APK correspondente; app e API fora de versão retornam erro de validação e mantêm os cards anteriores como estado de falha.
- [ ] Fechar o rollout externo do App Check antes de exigir enforcement. Não declarar uma plataforma nativa observada nem enforcement ativo sem confirmação.
- [ ] Concluir a publicação em `Production` do cliente OAuth usado pela distribuição privada do APK; enquanto estiver em `Testing`, o refresh token do Drive pode exigir renovação após o prazo do Google.
- [ ] Corrigir a credencial OAuth da distribuição privada: o CI `35471530166`
  falhou com `invalid_grant` (`Token has been expired or revoked`). Renovar o
  `GOOGLE_DRIVE_REFRESH_TOKEN` ou concluir a publicação do cliente OAuth em
  `Production` antes de repetir o aceite externo da distribuição.
- [ ] Fazer o aceite externo da distribuição privada do APK: instalar a build no Samsung, confirmar acesso com `EMAIL_DESTINO`, negar acesso a uma conta não autorizada, observar mais de 10 builds para validar a retenção e confirmar um push na `main`. A implementação e a primeira execução estão documentadas em [`PRD-DISTRIBUICAO-ANDROID.md`](prd/PRD-DISTRIBUICAO-ANDROID.md).

## Próxima fase — produto, operação e publicação

- [ ] Decidir e validar separadamente Crashlytics e ambientes Firebase adicionais; a configuração de autenticação, App Check e FCM do projeto `radarbeneficios` já foi usada pela API/Android desta entrega.
- [ ] Definir um sistema centralizado de logs para app, API e robôs, com correlação por execução, níveis de severidade, retenção e sem registrar tokens, dados pessoais ou payloads sensíveis.
- [ ] Completar o runbook operacional dos robôs Livelo, Inter Sites parceiros e Inter Compre direto: entradas, variáveis de ambiente, comandos, workflows, horários, tabelas escritas, códigos de saída, retries, reexecução manual e diagnóstico de falhas.
- [ ] Concluir, em ciclo futuro e fora da composição compacta V15 entregue nesta
  branch, a extração dos trechos restantes do layout amplo para widgets em
  pastas `widgets/`, preservando a separação por domínio e sem quebrar imports.
  A jornada compacta V15 já usa a fundação visual compartilhada e os tokens do
  design, e não deve reabrir a antiga gaveta como referência visual.
- [ ] Preparar a publicação na Google Play: nome, ícone, screenshots, classificação etária, política de privacidade, ficha de segurança de dados, versão e pacote de produção.
- [ ] Configurar assinatura do Android e guardar keystore, senhas e credenciais somente nos secrets protegidos do ambiente de release.
- [ ] Criar deploy automático via GitHub Actions para API e aplicativo, com ambientes de validação e produção, aprovação antes da publicação e possibilidade de rollback.
- [ ] Criar monitoramento pós-publicação para erros, indisponibilidade da API, falhas dos robôs, dados atrasados e regressões de autenticação/App Check.
- [ ] Criar documentação OpenAPI/Swagger da API, cobrindo rotas públicas, autenticadas e administrativas, autenticação, paginação, schemas de resposta, códigos de erro e exemplos; validar o contrato no CI.
- [ ] Fazer aceite manual final em aparelho Android real, incluindo login, notificações quando aplicável, links externos, permissões, modo escuro, telas de erro e atualização sobre uma versão instalada.

## Sugestões para priorização futura

- [ ] Criar ambiente de homologação separado de produção, com Firebase, banco, API e secrets próprios.
- [ ] Definir rotina de backup, restauração testada e checklist de migrations antes de alterações no banco.
- [ ] Garantir compatibilidade entre versões antigas do aplicativo e da API durante o período de atualização.
- [ ] Configurar distribuição interna na Google Play antes de liberar a versão pública.
- [ ] Revisar com responsável jurídico o fluxo LGPD da Central: consentimento, exclusão de conta, política de privacidade e dados efetivamente coletados.
- [ ] Documentar e testar rollback da API, banco, robôs e versão publicada do aplicativo.

## Legado preservado ou incerto

- [ ] Decidir em ciclo próprio o destino de `ranking_inter.py`; o preview Flutter não faz mais parte do repositório.
- [ ] Planejar, em migration futura separada, eventual remoção das tabelas legadas `oferta_direta_inter_atual` e `disparo_manual*`. Não há remoção de schema neste ciclo.
- [ ] Reavaliar o painel Livelo legado somente quando o layout não compacto e a compatibilidade da rota `/api/livelo/painel` deixarem de ser necessários.

## Testes e plataformas adiados

- Integration, E2E, smoke automatizado, performance e regressão visual não fazem parte do gate deste ciclo.
- O alvo Flutter Web foi removido. API, workflows de backend e o protótipo HTML continuam existindo como superfícies separadas; não há build ou teste Web do aplicativo.
- O provisionamento do schema no novo Neon foi autorizado e concluído em
  2026-09-26. Os itens ainda abertos não autorizam deploy, coleta real, alteração
  de secrets, corte da API/Actions/Termux ou outras mudanças em produção.
