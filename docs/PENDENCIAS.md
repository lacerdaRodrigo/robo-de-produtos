# Pendências

Lista viva somente do que continua aberto. Histórico concluído permanece no Git e nos PRDs; não deve voltar a governar o ciclo atual.

O contrato operacional padrão da branch `re-design` é o [`AGENTS.md`](../AGENTS.md):
Flutter mobile, protótipo mobile como fonte visual, unitários/widgets afetados e
Web/integration/E2E fora do gate. A implementação backend Pichau desta tarefa
foi autorizada explicitamente; suas pendências agora são operacionais externas.

## Ciclo mobile atual

- [ ] Concluir a Central de Alertas somente após fechar seu contrato de dados e histórico; o estado atual continua parcial/placeholder.
- [ ] Fazer conferências manuais no Samsung quando uma entrega mobile exigir aceite físico. Isso não vira smoke automatizado neste ciclo.
- [ ] Conferir manualmente no Samsung a paginação de Produtos, Livelo, Sites parceiros e Compre direto nos limites de 9, 10 e 11 cards; o repositório cobre a regra por widget, mas não substitui o aceite físico.
- [ ] Conferir manualmente no Samsung a combinação, remoção individual e limpeza dos recortes contextuais de Produtos; em especial, confirmar que `Outros / novas categorias` continua exclusivo e que a resposta troca os cards sem perder a busca em curso.
- [ ] Fazer aceite manual da jornada Pichau no Samsung: entrada por Serviços, retorno, paginação, busca, histórico, estados de catálogo e abertura de link externo.

## Pichau — operação externa e evolução

- [x] Versionar o pacote independente `robo_pichau`, fixtures sanitizadas, migration própria (`pichau_execucao`, `pichau_produto`, `pichau_medicao`), retenção de medições por 30 dias e testes unitários diretamente afetados.
- [x] Versionar as rotas autenticadas `/api/pichau/catalogo` e `/api/pichau/catalogo/{id_externo}/historico`, além do bloco Pichau em `/api/resumo`.
- [x] Versionar workflow isolado da Pichau nos horários aprovados, com concorrência própria e `DATABASE_URL` em secret.
- [x] Executar a prova de viabilidade autorizada em UC/CDP, limitada às páginas públicas de catálogo, com no máximo 300 páginas por job, intervalo de 2 a 5 segundos, parada após três falhas consecutivas e cron com pelo menos 6 horas entre execuções. Em duas execuções controladas, a categoria retornou o payload `products.items`, SKU `PCM-Pichau-Gamer-67332` e `total_count=1169`, sem a página de manutenção.
- [x] Integrar o parser do payload Next.js e o adaptador SeleniumBase UC/CDP ao caminho padrão do workflow, mantendo o HTTP como fallback controlado e sem persistir imagens.
- [x] Registrar o termo de autorização informado para este escopo: domínio `pichau.com.br`, catálogo público, UC/CDP, resolução de CAPTCHA sob os limites definidos, GitHub Actions, dados de catálogo sem PII e retenção bruta máxima de 90 dias.
- [x] Aplicar `migracoes/021_pichau_pc_gamer.sql` em ambiente autorizado; a confirmação do responsável e a leitura somente do banco encontraram as três tabelas Pichau.
- [x] Publicar e validar externamente o workflow Pichau e o caminho API; a execução real `34081623450` aguardou o Android, terminou com sucesso e o catálogo voltou a ficar disponível.
- [x] Fazer a primeira coleta real no Samsung: as execuções 6 e 8 provaram o caminho histórico de 33 páginas; as execuções 22, 23 e 24 aprovaram o caminho rápido com 12 páginas, `1169/1169` itens únicos, zero duplicados e 1.169 medições; as duas últimas terminaram em 225 e 227 segundos. A tentativa concorrente 7 falhou com código `acesso` sem substituir snapshot.
- [x] Reexecutar o workflow após o diagnóstico de bloqueio e confirmar no log se o GitHub recebeu Cloudflare/Turnstile, manutenção ou outro HTML sem catálogo. As execuções `34006575148` (`headless2`) e `34006802532` (`xvfb`) receberam `Site em Manutenção - Pru Pru`, sem payload de catálogo ou marcador de desafio, e não publicaram dados.
- [x] Comparar uma execução manual com `modo_navegador=xvfb` contra o `headless2`; ambas retornaram a mesma página de manutenção, portanto o agendamento continua em `headless2` e o executor Android fica como alternativa em avaliação.
- [x] Registrar o levantamento do executor Android: Samsung SM-M135M, Android 14, aproximadamente 3,8 GB de RAM, Chrome instalado e ABI `armeabi-v7a/armeabi` 32-bit; a compatibilidade 32-bit passou a ser o primeiro gate explícito.
- [x] Versionar o adaptador Android com CDP direto/local, fallback de Appium/UiAutomator2 para configuração/recuperação, modo `PICHAU_MODO_NAVEGADOR=android`, diagnóstico sem banco, runner Termux com lock/wake-lock/logs, worker de fila e watchdog sem coleta independente. O descritor do `flock` não é herdado pelo ADB/tmux persistente.
- [x] Instalar Termux, Termux:Boot, Termux:API, Python, Appium/UiAutomator2 e Chrome no Samsung e aprovar o diagnóstico SSR/Appium e a coleta completa histórica: `total=1169`, 36 itens na primeira página, 33 páginas e 1.169 itens publicados. O caminho DOM/CDP foi sondado com `pageSize=200` (200 cards na primeira página, 169 na sexta e total 1.169), reduzindo a coleta prevista para 6 páginas; a reconciliação continua por URL. O driver puro `psycopg` foi instalado no ARM32 contra o `libpq` local.
- [x] Sincronizar o worker/boot no Samsung, reaplicar o job 7301 como watchdog de 15 minutos e confirmar que ele não executa coleta sem solicitação pendente. O worker retornou `status=0` sem item pendente, e não há alerta automático de bateria.
- [x] Aplicar `migracoes/022_pichau_android_fila.sql` no banco operacional; a fila foi criada e o worker confirmou consulta sem item pendente.
- [x] Criar e testar as credenciais mínimas separadas do dispatcher GitHub e do publicador Android: as roles `pichau_dispatcher` e `pichau_publisher` foram criadas com SSL obrigatório e grants restritos; `PICHAU_DISPATCH_DATABASE_URL` foi configurado no GitHub e o arquivo privado do Termux recebeu somente a credencial do publicador com modo `600`. A execução real `34136108063` passou pelo secret separado, fila, worker, coleta e publicação.
- [x] Versionar e validar o workflow Pichau como produtor da fila Android, com cron alinhado a 09h/14h/20h de Brasília, disparo manual, espera do resultado e falha explícita quando o Android não responde. As execuções reais `34081623450` e `34136108063` passaram pelo GitHub, fila, worker, coleta e publicação.
- [x] Confirmar que o Termux:Boot inicia o worker sem abrir o Termux: o aplicativo
  Termux:Boot foi aberto uma vez, o arquivo efetivo foi corrigido para o
  interpretador absoluto do Termux e, no reboot de 2026-09-07, o receiver
  executou `pichau-android-boot.sh`; após o primeiro desbloqueio, o worker,
  Appium e o job 7301 ficaram ativos sem comando manual no Termux.
- [ ] Fechar o boot totalmente autônomo antes do primeiro desbloqueio: o teste
  mostrou o Android mantendo `com.termux.boot.BootReceiver` pendente na tela de
  bloqueio (`directBootAware=false`) e nenhum worker/Appium iniciou enquanto ela
  estava bloqueada. É preciso aceitar esse desbloqueio após reinício ou decidir
  explicitamente sobre a remoção da tela de bloqueio; não alterar a segurança
  do aparelho automaticamente. O transporte do host continua USB para
  gerenciamento, mas o worker dentro do Samsung usa ADB TCP local em
  `127.0.0.1:5555`, pois o processo Android não consegue usar o serial USB do
  próprio host. Wireless Debugging permanece opcional e desligado.
- [x] Diagnosticar e corrigir as falhas das execuções automáticas
  `34158686905` e `34174437207`: a troca para o serial USB deixou o worker sem
  um endpoint ADB acessível dentro do Android e o runner terminou com
  `runner-2`/código `navegador`. O Samsung voltou ao endpoint local
  `127.0.0.1:5555`, o runner passou a rejeitar serial USB com código explícito
  e a execução `34182214027` confirmou fila, coleta e publicação completas.
- [ ] Preparar e validar o Wireless Debugging pareado como transporte
  alternativo, sem remover o cabo USB; ele continua desligado e não bloqueia a
  operação atual.
- [x] Executar no aparelho o diagnóstico e as coletas de prova; as execuções 6 e 8 fecharam 1.169/1.169 com zero duplicados antes da otimização. Livelo e Inter continuam fora da prova.
- [x] Fechar o caminho rápido Android com 1.169 itens únicos e zero duplicados: as execuções 22, 23 e 24 publicaram `sucesso`/`completa` com 12 páginas, `itens_lidos=1169`, `itens_unicos=1169`, `duplicados=0` e 1.169 medições. A validação da última página renderizada e a reconciliação em lote por URL/SKU ficaram versionadas.
- [x] Fazer três execuções consecutivas do caminho rápido: 22, 23 e 24 fecharam `sucesso`/`completa`, `1169/1169` únicos, zero duplicados e 1.169 medições.
- [ ] Validar a redução de tempo da implementação em três coletas reais consecutivas de até 120 segundos: medir `dom`, `fetch` e `rede` no arquivo privado do Termux, corrigir e tentar novamente até atingir o objetivo, sempre com coleta completa e respeitando pelo menos seis horas entre execuções. A execução `34136108063` publicou 1.169/1.169 com zero duplicados em 214,3s de runner (205,9s de coleta); a tentativa `name-asc` fechou em 255,2s e foi desabilitada. A execução `34144116813` também fechou completa, em 221,9s de runner e 214,2s de coleta. A execução `34148112344` ficou abaixo da meta, em 87,5s de runner e 79,6s de coleta, mas as duas execuções seguintes falharam após a troca para USB; a série de três coletas aceitas deverá ser reiniciada depois da correção.
- [ ] Validar a redução de tempo da implementação em três coletas reais consecutivas de até 120 segundos: medir `dom`, `fetch` e `rede` no arquivo privado do Termux, corrigir e tentar novamente até atingir o objetivo, sempre com coleta completa e respeitando pelo menos seis horas entre execuções. A execução `34136108063` publicou 1.169/1.169 com zero duplicados em 214,3s de runner (205,9s de coleta); a tentativa `name-asc` fechou em 255,2s e foi desabilitada. A execução `34144116813` também fechou completa, em 221,9s de runner e 214,2s de coleta. A execução `34148112344` ficou abaixo da meta, em 87,5s de runner e 79,6s de coleta. Após a correção do transporte, `34182214027` publicou `1169/1169`, zero duplicados, em aproximadamente 73,5s de coleta; ela é a primeira rodada da nova série e ainda faltam duas, com intervalo mínimo de seis horas.
- [ ] Decidir posteriormente se e quando a Pichau entra na busca global de Produtos; a v1 mobile mantém essa busca inalterada.

## Ações operacionais externas

- [ ] Confirmar operacionalmente a aplicação das migrations `016_preserva_historico_livelo.sql` e `017_qualidade_livelo.sql`. Elas são tratadas externamente; este repositório não registra confirmação de aplicação.
- [ ] Validar a migration `020_categorias_inter_fonte_oficial.sql` em ambiente descartável e decidir sua aplicação somente com autorização explícita. Ela remove a taxonomia Radar obsoleta depois de confirmar que não há seleção legada de categorias.
- [ ] Revisar periodicamente amostras reais dos recortes hierárquicos de navegação do catálogo Inter (incluindo os novos recortes de cozinhas, quarto/camas, beleza, saúde, limpeza/climatização e festas) e ampliar apenas folhas finais quando houver evidência. Os escopos atuais e “Outros / novas categorias” já são dinâmicos para qualquer quantidade de lojas ativas e selecionadas.
- [ ] Publicar a API com os novos identificadores de escopo antes de distribuir o APK correspondente; app e API fora de versão retornam erro de validação e mantêm os cards anteriores como estado de falha.
- [ ] Fechar o rollout externo do App Check antes de exigir enforcement. Não declarar Web/iOS observados nem enforcement ativo sem confirmação.
- [ ] Confirmar a revogação/rotação de qualquer credencial Gmail antiga e remover secrets externos obsoletos, se ainda existirem. O código e os workflows atuais não possuem envio SMTP/e-mail ativo.

## Próxima fase — produto, operação e publicação

- [ ] Integrar e configurar o Firebase usado pelo aplicativo, incluindo autenticação, App Check, Crashlytics e ambientes separados quando aplicável.
- [ ] Definir um sistema centralizado de logs para app, API e robôs, com correlação por execução, níveis de severidade, retenção e sem registrar tokens, dados pessoais ou payloads sensíveis.
- [ ] Completar o runbook operacional dos robôs Livelo, Inter Sites parceiros e Inter Compre direto: entradas, variáveis de ambiente, comandos, workflows, horários, tabelas escritas, códigos de saída, retries, reexecução manual e diagnóstico de falhas.
- [ ] Reorganizar as telas Flutter e extrair componentes reutilizáveis para pastas `widgets/`, preservando a separação por domínio e sem quebrar os imports das jornadas existentes.
- [x] Exibir no card de Cashback Inter a descrição completa da regra publicada pela loja, incluindo produtos, categorias, vendedores, percentuais e demais condições retornadas em `redirectWarning`/`descricao_principal`; o card compacto abre a folha V11 “Ver condições” sem truncar o texto.
- [x] Cobrir no Flutter os estados da descrição do Inter: texto longo, múltiplas condições, ausência de descrição e quebra de linha. A validação manual no Samsung ainda depende do aceite no device.
- [x] Validar manualmente no Samsung a folha de condições do Cashback Inter com conta autenticada, incluindo conteúdo real retornado pela API, estado neutro sem descrição e descrição longa com quebra de linha.
- [ ] Preparar a publicação na Google Play: nome, ícone, screenshots, classificação etária, política de privacidade, ficha de segurança de dados, versão e pacote de produção.
- [ ] Configurar assinatura do Android e guardar keystore, senhas e credenciais somente nos secrets protegidos do ambiente de release.
- [ ] Criar deploy automático via GitHub Actions para API e aplicativo, com ambientes de validação e produção, aprovação antes da publicação e possibilidade de rollback.
- [ ] Definir o fluxo de versionamento, changelog, build de release e distribuição interna antes de liberar uma versão pública.
- [ ] Criar monitoramento pós-publicação para erros, indisponibilidade da API, falhas dos robôs, dados atrasados e regressões de autenticação/App Check.
- [ ] Criar documentação OpenAPI/Swagger da API, cobrindo rotas públicas, autenticadas e administrativas, autenticação, paginação, schemas de resposta, códigos de erro e exemplos; validar o contrato no CI.
- [ ] Fazer aceite manual final em aparelho Android real, incluindo login, notificações quando aplicável, links externos, permissões, modo escuro, telas de erro e atualização sobre uma versão instalada.

## Sugestões para priorização futura

- [ ] Criar ambiente de homologação separado de produção, com Firebase, banco, API e secrets próprios.
- [ ] Definir rotina de backup, restauração testada e checklist de migrations antes de alterações no banco.
- [ ] Garantir compatibilidade entre versões antigas do aplicativo e da API durante o período de atualização.
- [ ] Configurar distribuição interna na Google Play antes de liberar a versão pública.
- [ ] Implementar notificações para mudanças de preço, cashback e pontuação das lojas acompanhadas.
- [ ] Criar uma área de ajuda e “Reportar problema”, enviando versão do app e identificadores técnicos sem dados sensíveis.
- [ ] Revisar o fluxo LGPD: consentimento, exclusão de conta, política de privacidade e dados efetivamente coletados.
- [ ] Documentar e testar rollback da API, banco, robôs e versão publicada do aplicativo.

## Legado preservado ou incerto

- [ ] Decidir em ciclo próprio o destino de `ranking_inter.py` e `app/lib/inter_preview.dart`.
- [ ] Planejar, em migration futura separada, eventual remoção das tabelas legadas `oferta_direta_inter_atual` e `disparo_manual*`. Não há remoção de schema neste ciclo.
- [ ] Reavaliar o painel Livelo legado somente quando o layout não compacto e a compatibilidade da rota `/api/livelo/painel` deixarem de ser necessários.

## Testes e plataformas adiados

- Integration, E2E, smoke automatizado, performance e regressão visual não fazem parte do gate deste ciclo.
- O suporte Web permanece no repositório, mas não é alvo visual nem gate obrigatório da branch mobile.
- Nenhum item acima autoriza deploy, coleta real, alteração de secrets, aplicação de migration ou mudança em produção.
