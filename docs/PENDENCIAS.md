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
- [ ] Configurar/deployar API e workflow; o repositório não prova publicação externa.
- [x] Fazer a primeira coleta real no Samsung: as execuções 6 e 8 provaram o caminho histórico de 33 páginas; as execuções 22 e 23 aprovaram o caminho rápido com 12 páginas, `1169/1169` itens únicos, zero duplicados e 1.169 medições; a 23 terminou em 225 segundos. A tentativa concorrente 7 falhou com código `acesso` sem substituir snapshot.
- [x] Reexecutar o workflow após o diagnóstico de bloqueio e confirmar no log se o GitHub recebeu Cloudflare/Turnstile, manutenção ou outro HTML sem catálogo. As execuções `34006575148` (`headless2`) e `34006802532` (`xvfb`) receberam `Site em Manutenção - Pru Pru`, sem payload de catálogo ou marcador de desafio, e não publicaram dados.
- [x] Comparar uma execução manual com `modo_navegador=xvfb` contra o `headless2`; ambas retornaram a mesma página de manutenção, portanto o agendamento continua em `headless2` e o executor Android fica como alternativa em avaliação.
- [x] Registrar o levantamento do executor Android: Samsung SM-M135M, Android 14, aproximadamente 3,8 GB de RAM, Chrome instalado e ABI `armeabi-v7a/armeabi` 32-bit; a compatibilidade 32-bit passou a ser o primeiro gate explícito.
- [x] Versionar o adaptador Android com CDP direto/local, fallback de Appium/UiAutomator2 para configuração/recuperação, modo `PICHAU_MODO_NAVEGADOR=android`, diagnóstico sem banco, runner Termux com lock/wake-lock/logs e agendador aproximado de seis horas. O descritor do `flock` não é herdado pelo ADB/tmux persistente.
- [x] Instalar Termux, Termux:Boot, Termux:API, Python, Appium/UiAutomator2 e Chrome no Samsung e aprovar o diagnóstico SSR/Appium e a coleta completa histórica: `total=1169`, 36 itens na primeira página, 33 páginas e 1.169 itens publicados. O caminho DOM/CDP atual usa 12 páginas e reconcilia SKU por URL. O driver puro `psycopg` foi instalado no ARM32 contra o `libpq` local.
- [x] Configurar o `termux-job-scheduler` real com período de 21.600.000 ms, rede não tarifada, armazenamento disponível e sem `--charging`; o job persistente 7301 foi conferido como ativo. Não há alerta automático de bateria.
- [ ] Confirmar o receiver do Termux:Boot após reinicialização com a ROM Samsung; o pacote foi habilitado e o runner inicia Appium por conta própria quando um job real existir, mas o receiver não foi observado automaticamente nesta prova. Após o reboot de validação, o Wi‑Fi voltou desconectado e a depuração sem fio ficou desligada, impedindo uma nova prova autônoma.
- [ ] Criar e testar fora do repositório a role Postgres exclusiva do robô Pichau, com acesso somente às três tabelas/sequências Pichau e conexão SSL; nenhuma senha deve entrar no Git ou no log.
- [x] Executar no aparelho o diagnóstico e as coletas de prova; as execuções 6 e 8 fecharam 1.169/1.169 com zero duplicados antes da otimização. Livelo e Inter continuam fora da prova.
- [x] Fechar o caminho rápido Android com 1.169 itens únicos e zero duplicados: a execução 22 publicou `sucesso`/`completa` com 12 páginas, `itens_lidos=1169`, `itens_unicos=1169`, `duplicados=0` e 1.169 medições. A validação da última página renderizada e a reconciliação em lote por URL/SKU ficaram versionadas.
- [ ] Fazer mais uma execução consecutiva do caminho rápido, validar o receiver do Termux:Boot após reinicialização e conferir API/Flutter.
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
- [ ] Exibir no card de Cashback Inter a descrição completa da regra publicada pela loja, incluindo produtos, categorias, vendedores, percentuais e demais condições retornadas em `redirectWarning`/`descricao_principal`.
- [ ] Validar estados da descrição do Inter: texto longo, múltiplas condições, ausência de descrição, quebra de linha e conteúdo atualizado entre coletas.
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
