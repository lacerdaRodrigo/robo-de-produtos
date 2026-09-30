# Pendências

Lista viva somente do que continua aberto. Histórico concluído permanece no Git e nos PRDs; não deve voltar a governar o ciclo atual.

O contrato operacional padrão do ciclo mobile V15 é o
[`AGENTS.md`](../AGENTS.md): Flutter Android/iOS, `design-app/mobile-v15/index.html`
como fonte visual e unitários/widgets afetados. Para este plano, foi autorizada
uma exceção estreita: runner Appium local, somente no Samsung, descrito em
[`tools/mobile-device-acceptance/README.md`](../tools/mobile-device-acceptance/README.md).
O contrato de backend necessário ao V15 está implementado, a migration 029 foi
aplicada e confirmada pelo responsável, e o APK histórico `27503` foi retestado
contra a API publicada. A rodada local `1.73.1+2026092702` passou 13 cenários
de navegação. A build `1.73.1+2026092801` foi instalada em 2026-09-28 e preservou
a sessão autenticada. O acesso mobile à Administração, a seleção da Casas Bahia,
a coleta e a busca real de produtos foram conferidos no Samsung; o aceite físico
completo continua aberto. Evidências e cenários restantes estão no
[`PRD de aceite mobile`](prd/PRD-ACEITE-MOBILE-V15.md). A
disponibilidade contínua do executor Android permanece uma pendência separada
na seção Pichau abaixo.

## Ciclo mobile atual

- [x] Definir e implementar o contrato paginado de lista consolidada do `Meu
  radar`, o bloco pessoal `radar` de `/api/resumo` e a integração Flutter. A
  migration 029 foi aplicada e confirmada; a distribuição privada ainda
  depende da publicação/autorização externa.
- [ ] Produzir um evento real de alerta e confirmar a entrega FCM; a coleta corrigida `34761933582` passou com 1.180 itens, mas não houve mudança de preço e, portanto, não houve evento pendente. A permissão de push é opcional e o histórico deve continuar acessível quando recusada.
- [ ] Fazer o aceite físico completo de cada revisão no aparelho-alvo. Para esta branch, o alvo é o Samsung SM-M135M (M13). No Samsung, `1.73.1+2026092702` passou os 13 cenários automatizados locais listados no PRD; a build `1.73.1+2026092801` preservou a sessão e confirmou Administração e Produtos reais. No Moto, esta branch local foi instalada anteriormente com `adb install -r`, manteve a sessão e recebeu conferência manual parcial de Home, Explorar, Inter, Produtos, Livelo, Pichau, Meu radar, Alertas e rotas secundárias de conta. Buscas e filtros de catálogo foram aplicados e restaurados por consultas de leitura, sem gravações. As capturas estão fora do Git e o detalhe consta no [`PRD de aceite mobile`](prd/PRD-ACEITE-MOBILE-V15.md). Ainda faltam comparação visual formal completa, estados offline/parcial/erro, sessão expirada, conta comum, paginação, históricos, teste de leitura coletiva quando houver alertas e verificação física em tema escuro. O histórico Samsung registra diferença entre acompanhamentos; confirmar a origem antes de aceitar continuidade dos dados. As evidências anteriores não aceitam esta revisão; não declarar a V15 aceita até concluir o aceite no aparelho-alvo.
- [ ] Completar no M13 a revisão visual e funcional do Perfil V15: Acompanhamentos, Aparência, Notificações, Ajuda, Relatar problema, Meus relatos e Privacidade. Esta branch alinha o formulário às cinco categorias e à validação V15, usa o ID real do POST no comprovante e encaminha dúvidas de privacidade ao formulário; revisar a build final em claro/escuro e os retornos visível/Android. O relato não foi enviado e a lista não deve ser validada contra o serviço publicado até a nova rota de leitura ser liberada.
- [ ] Publicar a API desta branch para habilitar `GET /api/relatos-problema` e os parâmetros do catálogo Livelo (`somente_pontuacao_comum_ampliada` e `ordenar=validade`). O contrato Livelo foi resolvido: comparar pontuação atual comum com `pontos_base`, excluir ausentes e filtrar antes da paginação. Até a publicação, não declarar esses comportamentos verificados no APK contra a API real; nenhuma publicação foi feita nesta tarefa.
- [ ] Gerar e instalar o APK final desta revisão no Samsung SM-M135M (M13), preservando a sessão. Nesta retomada, o responsável retirou o Moto G6 do alvo. O analisador Dart informou `No issues found!`, mas o comando encerrou ao tentar gravar telemetria global somente leitura; os testes Flutter foram bloqueados ao criar socket local. Uma tentativa anterior parou no Gradle 9.1.0 por IP wildcard e a mais recente parou antes do Gradle porque o Flutter tentou atualizar `engine.stamp`/`engine.realm` em SDK somente leitura. O ADB não iniciou (`Operation not permitted`). Não houve instalação nem captura nova; D-044 pertence a um APK anterior e não serve para conferir esta revisão.
- [x] Aplicar `migracoes/035_categorias_relato_mobile_v15.sql` para habilitar as cinco categorias V15. O responsável informou que as migrations foram executadas; esta sessão não consultou diretamente o banco. A alteração é aditiva e preserva os códigos legados.
- [ ] Publicar a API que aceita as cinco categorias V15 e oferece a leitura autenticada de Meus relatos. Até essa publicação, não validar o fluxo no APK contra o serviço real.
- [ ] Integrar o filtro por origem de `GET /api/alertas` e o resolvedor
  `GET /api/alertas/{id}/item` ao endpoint usado pelo APK de conferência.
  Esta branch local contém os contratos e testes; não houve publicação nem
  alteração de banco. O filtro e a abertura do detalhe não estão validados no
  aparelho enquanto o serviço acessível pelo M13 não tiver essas rotas.
- [ ] Investigar a demora observada no Moto: a Home levou cerca de 18 s após a
  primeira abertura do APK; as opções do filtro de Compre direto levaram cerca
  de 22 s na primeira observação e aproximadamente 8–12 s em duas reaberturas.
  As rotas terminaram de carregar, mas não houve cronometragem controlada nem
  evidência para atribuir a demora ao app, à API ou à rede.
- [ ] Classificar as lojas atuais de cashback Inter pelo endpoint administrativo após confirmar o conjunto e aprovar o mapeamento de categorias. O responsável confirmou que `migracoes/030_categorias_cashback_inter.sql` foi aplicada em 2026-09-26; os endpoints mantêm o fallback `Outros`. A coleta registrada nesta lista publicou 378 lojas, então a anotação histórica de que o destino estava vazio precisa ser descartada; esta sessão não consultou diretamente o banco nem alterou classificações.
- [ ] Completar a conferência física da Central de Alertas no M13. A evidência anterior desta branch é do Moto G6 e cobre título, estado vazio, filtro em folha com Origem/Tipo e troca para Explorar; esses cenários precisam ser repetidos no M13, além de leitura individual, detalhe, fallback de item removido, erro/retry, retorno preservando filtros/página/posição, leitura coletiva e paginação com alertas reais. Esta sessão adicionou o resolvedor local, sem publicar a API nem criar dados de teste. O ADB não iniciou na sandbox restrita (`could not install *smartsocket* listener: Operation not permitted`), então não houve instalação ou captura nova no M13.
- [x] Conferir manualmente no Samsung a nova composição da Home compacta: rail Livelo, Banco Inter e Pichau, sem a seção `Atividade recente` nem cartão de alerta; claro/escuro e bloqueio/retomada foram observados. `radar.destaque` permanece no contrato para a Central, enquanto a Home usa contadores e mantém estado honesto quando não há dados.
- [x] Aplicar e verificar `migracoes/029_indices_mobile_v15.sql` em conexão
  direta/unpooled no ambiente de teste. O responsável confirmou as duas
  instruções `CREATE`; o APK correspondente foi instalado e retestado no
  Samsung.
- [x] Validar que o catálogo Pichau publicado responde no APK real após a mudança para acompanhamento pessoal. Em 2026-09-29, a branch instalada no Moto abriu o catálogo com 1.223 produtos, cartões e folha de filtros; nenhuma atualização de backend foi feita nesta sessão.
- [ ] Conferir manualmente no Samsung a paginação de Produtos, Livelo, Sites parceiros e Compre direto nos limites de 9, 10 e 11 cards; o repositório cobre a regra por widget, mas não substitui o aceite físico.
- [ ] Completar no Samsung a navegação `Banco Inter → Sites parceiros` e `Banco Inter → Compre direto → Produtos`. O runner confirmou o hub, as duas telas próprias e o retorno Android; em 2026-09-28 o fluxo Compre direto também foi percorrido no APK autenticado e abriu ofertas reais. Permanecem o atalho da Home, histórico e acesso contínuo aos links.
- [ ] Concluir o aceite físico do Compre direto V15 no Samsung: cabeçalho Banco Inter, busca, abas `Todos`/`No radar`, filtros, paginação e cards agrupados por loja. Em 2026-09-28, a busca `motorola` retornou 66 ofertas da Casas Bahia e exibiu cartão com preço, cashback e detalhes; o histórico, os limites de paginação e a comparação formal com o HTML V15 continuam pendentes.
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
  Nenhum catálogo/histórico foi migrado; há somente o convite admin inicial, sem
  UID Firebase vinculado.
- [x] Enviar PR com CI e fazer merge squash: [#42](https://github.com/lacerdaRodrigo/robo-de-produtos/pull/42). Os jobs de qualidade e API passaram; o código já está na `main`.
- [x] Ativar e validar por conexão direta e pooler os logins `radar_api`,
  `radar_actions_robo`, `radar_actions_pichau` e `radar_samsung`. Foi confirmado
  que a API não acessa filas e que o Samsung não acessa tabelas pessoais. Os
  secrets de dispatch foram atualizados; o `DATABASE_URL` antigo do GitHub
  permaneceu intacto para rollback. Os disparos só foram iniciados depois da
  instalação e validação do Samsung.
- [x] Concluir o corte da API: a Vercel publicou `1.73.1` em Production com
  `radar_api`; `/api/status` ficou saudável, a outbox executou com sucesso e o
  aplicativo autenticado exibiu 255 lojas Livelo, 378 lojas em Sites parceiros
  do Inter e 1.223 produtos Pichau a partir do Neon novo. Manter o
  banco/credencial antigos por sete dias para rollback; não reutilizar a chave
  owner nem expor credenciais.
- [x] Instalar checkout, dependências, `radar_samsung`, boot e watchdog 7301 no
  Samsung. O diagnóstico confirmou worker/wake lock, watchdog novo, duas filas,
  ADB Wi-Fi e Appium ocioso. A ausência inicial de
  `tzdata` foi detectada antes das coletas e corrigida como dependência do pacote.
- [x] Validar uma coleta manual de cada fonte no Neon novo. Livelo publicou 255
  parceiros; Inter publicou 378 lojas de cashback e sincronizou 111 lojas do
  Compre direto; Pichau publicou 1.223 produtos em sete páginas, zero duplicados
  e uma tentativa. Os três pedidos terminaram como sucesso; o gate agendado de
  72 horas continua aberto abaixo.
- [x] Aceitar a outbox uma vez por hora, assumindo até cerca de uma hora adicional
  para entrega de push em troca de menos chamadas à API/Neon.

- [ ] Conferir manualmente no Samsung a composição visual Pichau V15: cabeçalho
  `Pichau`/`Catálogo`, retorno único, busca com avanço, abas `Todos`/`No radar`,
  botão `Filtros`, folha `Filtros · Pichau` com ordem/disponibilidade/faixa de
  preço — inclusive campo e ações alcançáveis acima do teclado —, hierarquia do
  card e abertura de `Detalhes`. Os widgets
  cobrem claro, escuro e larguras de 320/390/430 px; a build `2026092602` abriu
  o catálogo e confirmou abas/filtro, mas não cobre folha de filtros, teclado,
  detalhes nem a comparação física completa com o protótipo.
- [ ] Publicar a versão da API que contém o filtro server-side de faixa de preço
  da Pichau e validar novamente no APK. A validação física de 21/09/2026 no
  Samsung confirmou que o cliente envia `preco_min=3000` (junto de
  `ordenar=nome`), mas o endpoint publicado ainda retornou produtos abaixo de
  R$ 3.000; os 4 testes direcionados do endpoint local passaram, mas não houve
  deploy. Não criar fallback local no Flutter; o gate WAF abaixo continua
  bloqueando a publicação.
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
- [ ] Observar nove execuções Pichau agendadas consecutivas em 72 horas, com o
  aparelho dedicado, carregando, no Wi-Fi e tela bloqueada, sem abrir o Termux.
  Na arquitetura proposta, o worker Samsung também agenda Livelo às `:10` e
  Inter às `:30` da hora seguinte. A
  janela Pichau recomeça após implantação; qualquer nova falha a reinicia. Em
  27/09/2026, o estado local confirmou sucesso nas agendas Livelo e Inter, mas
  quatro slots Pichau desde o reboot de 26/09 falharam com `ADB Wi-Fi` ausente.
  A conexão foi recuperada e o status voltou a ficar saudável. A solicitação
  manual `3` (workflow `36360364615`) terminou com sucesso: sete páginas,
  1.223 itens únicos e uma tentativa. Após retirar o USB, a solicitação manual
  `4` (workflow `36362065611`) também terminou com sucesso na primeira
  tentativa, com sete páginas e 1.223 itens únicos, enquanto a tela permaneceu
  bloqueada. Iniciar nova sequência de nove slots agendados; as execuções
  manuais não contam para o gate. Os pedidos manuais Livelo `5` e Inter `6`
  (workflows `36362885182` e `36362887421`) terminaram com sucesso: 255
  parceiros Livelo com qualidade completa e 378 lojas Inter válidas. Naquele
  pedido, Compre direto teve zero lojas planejadas porque nenhuma loja direta
  ativa estava selecionada. A causa foi corrigida em 2026-09-28: Casas Bahia
  foi selecionada no catálogo administrativo mobile e a execução `9` concluiu
  com 1 loja, 58 páginas, 1.927 produtos únicos e qualidade completa. O registro
  e a confirmação de que nenhum horário da agenda mudou estão em
  [`PRD-EXECUCAO-COLETORES.md`](prd/PRD-EXECUCAO-COLETORES.md).
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
- [ ] App Check e Google Play permanecem adiados por decisão do responsável: manter `ATIVAR_APP_CHECK=false`, não ativar `EXIGIR_APP_CHECK=true` e não descrever o APK privado como distribuição Play. Preparar Play Console/App Check em uma etapa futura, com teste real em instalação Play antes de enforcement.
- [ ] Concluir a publicação em `Production` do cliente OAuth usado pela distribuição privada do APK; enquanto estiver em `Testing`, o refresh token do Drive pode exigir renovação após o prazo do Google.
- [ ] Corrigir a credencial OAuth da distribuição privada: o CI `35471530166`
  falhou com `invalid_grant` (`Token has been expired or revoked`). Renovar o
  `GOOGLE_DRIVE_REFRESH_TOKEN` ou concluir a publicação do cliente OAuth em
  `Production` antes de repetir o aceite externo da distribuição.
- [ ] Fazer o aceite externo da distribuição privada do APK: instalar a build no Samsung, confirmar acesso com `EMAIL_DESTINO`, negar acesso a uma conta não autorizada, observar mais de 10 builds para validar a retenção e confirmar um push na `main`. A implementação e a primeira execução estão documentadas em [`PRD-DISTRIBUICAO-ANDROID.md`](prd/PRD-DISTRIBUICAO-ANDROID.md).

## Próxima fase — produto, operação e publicação

- [x] Aplicar `migracoes/033_limpeza_admin_segura.sql` e `migracoes/034_role_backup_readonly.sql` no Neon correto; aplicação confirmada pelo responsável em 2026-09-26. Isso instala as funções de limpeza e a role de grupo de backup, mas não comprova backup restaurável nem aceite das funções destrutivas.
- [ ] Configurar o backup conforme [`PRD-BACKUP-NEON.md`](prd/PRD-BACKUP-NEON.md): conferir os grants da role `radar_backup`, criar login próprio associado a ela, gerar chave age e guardar a privada offline, renovar OAuth, cadastrar secrets e fazer bootstrap da pasta privada no Drive.
- [ ] Executar o primeiro backup manual, conferir ACL e restaurar em banco/branch descartável. **Não executar as funções de limpeza da migration 033 antes desse restore e do aceite destrutivo descartável.** A automação versionada ainda não prova acesso às contas nem recuperação.
- [ ] **Gate obrigatório antes de publicar a API desta branch:** a autenticação deixou de gravar no Neon o limite por IP para reduzir carga no banco; o limite por usuário autenticado continua no código, mas não substitui proteção por IP. Configurar no Vercel WAF uma regra para `/api/*`, chave por IP, janela fixa de 60 segundos e limite de 240 requisições por minuto. Manter em `Log` por 24 horas, revisar tráfego legítimo e só então habilitar 429. Inclui `/api/status`. Não publicar esta alteração antes de confirmar a regra ativa no painel e registrar evidência.
- [ ] Validar no Samsung os timeouts e a atualização/reinício controlado do worker implementados nesta branch. O código não está instalado no aparelho; a atualização continua in-place, sem releases atômicos ou rollback automático.
- [ ] Acompanhar a compatibilidade Gradle do plugin `firebase_app_check`: o build debug atual passou, mas Flutter avisou que versões futuras deixarão de aceitar plugins que ainda aplicam Kotlin Gradle Plugin diretamente. Atualizar quando o plugin upstream oferecer suporte ao Kotlin integrado ou antes da próxima atualização Flutter incompatível.
- [ ] Decidir e validar separadamente Crashlytics e ambientes Firebase adicionais; a configuração de autenticação, App Check e FCM do projeto `radarbeneficios` já foi usada pela API/Android desta entrega.
- [ ] Definir um sistema centralizado de logs para app, API e robôs, com correlação por execução, níveis de severidade, retenção e sem registrar tokens, dados pessoais ou payloads sensíveis.
- [ ] Completar o runbook operacional dos robôs Livelo, Inter Sites parceiros e Inter Compre direto: entradas, variáveis de ambiente, comandos, workflows, horários, tabelas escritas, códigos de saída, retries, reexecução manual e diagnóstico de falhas.
- [ ] Concluir, em ciclo futuro e fora da composição compacta V15 entregue nesta
  branch, a extração dos trechos restantes do layout amplo para widgets em
  pastas `widgets/`, preservando a separação por domínio e sem quebrar imports.
  A jornada compacta V15 já usa a fundação visual compartilhada e os tokens do
  design, e não deve reabrir a antiga gaveta como referência visual.
- [ ] Preparar a publicação na Google Play: nome, ícone, screenshots, classificação etária, política de privacidade, ficha de segurança de dados, versão e pacote de produção.
- [ ] Provisionar a assinatura release Android: criar a chave estável `radar-release`, guardar cópia offline criptografada, cadastrar os quatro secrets `ANDROID_KEYSTORE_*`/`ANDROID_KEY_*` e habilitar `ANDROID_RELEASE_ENABLED` só depois de comparar a impressão digital. A distribuição release está implementada, mas permanece desligada; a primeira instalação exige remover o APK debug e autenticar novamente.
- [ ] Criar deploy automático via GitHub Actions para API e aplicativo, com ambientes de validação e produção, aprovação antes da publicação e possibilidade de rollback.
- [ ] Criar monitoramento pós-publicação para erros, indisponibilidade da API, falhas dos robôs, dados atrasados e regressões de autenticação/App Check.
- [ ] Criar documentação OpenAPI/Swagger da API, cobrindo rotas públicas, autenticadas e administrativas, autenticação, paginação, schemas de resposta, códigos de erro e exemplos; validar o contrato no CI.
- [ ] Fazer aceite manual final em aparelho Android real, incluindo login, notificações quando aplicável, links externos, permissões, modo escuro, telas de erro e atualização sobre uma versão instalada.

## Sugestões para priorização futura

- [ ] Criar ambiente de homologação separado de produção, com Firebase, banco, API e secrets próprios.
- [ ] Formalizar checklist de backup/restauração e migrations antes de alterações no banco, após o primeiro restore descartável comprovar o procedimento.
- [ ] Garantir compatibilidade entre versões antigas do aplicativo e da API durante o período de atualização.
- [ ] Configurar distribuição interna na Google Play antes de liberar a versão pública.
- [ ] Google Play/App Check: criar e validar a configuração Play Integrity, testar em instalação pela Play Store e só depois avaliar enforcement. Enquanto isso, manter App Check desativado e registrar a distribuição atual como privada.
- [ ] Revisar com responsável jurídico o fluxo LGPD da Central: consentimento, exclusão de conta, política de privacidade e dados efetivamente coletados.
- [ ] Documentar e testar rollback da API, banco, robôs e versão publicada do aplicativo.

## Legado preservado ou incerto

- [ ] Planejar, em migration futura separada, eventual remoção das tabelas legadas `oferta_direta_inter_atual` e `disparo_manual*`. Não há remoção de schema neste ciclo.
- [ ] Reavaliar o painel Livelo legado somente quando o layout não compacto e a compatibilidade da rota `/api/livelo/painel` deixarem de ser necessários.

## Testes e plataformas adiados

- Integração genérica, E2E em CI, smoke em CI, performance e regressão visual automatizada continuam fora do gate. Exceção autorizada neste plano: runner Appium local somente no Samsung SM-M135M; 13/13 cenários de navegação passaram e a regra completa está no PRD de aceite.
- O alvo Flutter Web foi removido. API, workflows de backend e o protótipo HTML continuam existindo como superfícies separadas; não há build ou teste Web do aplicativo.
- O provisionamento do schema e o corte autorizado para o novo Neon foram
  concluídos em 2026-09-26. O responsável confirmou que as migrations 033 e 034
  foram aplicadas corretamente; esta sessão não verificou o banco diretamente.
  Na rodada de aceite mobile, nenhuma migration, credencial ou secret foi
  alterado; não houve deploy nem coleta manual pelo runner. O Samsung recebeu o
  APK debug universal `1.73.1+2026092602` com assinatura correspondente,
  preservando dados; o aceite Appium foi somente leitura/navegação. A
  recuperação operacional Pichau em 27/09 disparou uma coleta manual em
  Production, registrada acima. Evidências privadas estão no diretório indicado
  pelo PRD de aceite.
