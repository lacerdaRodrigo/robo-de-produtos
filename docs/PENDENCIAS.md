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
- [ ] Reexecutar o levantamento técnico com acesso operacional permitido; a fonte respondeu 403/manutenção nesta execução, então endpoint/HTML/JSON, paginação real, `robots.txt`, limites e termos ainda não foram aceitos operacionalmente.
- [x] Aplicar `migracoes/021_pichau_pc_gamer.sql` em ambiente autorizado; a confirmação do responsável e a leitura somente do banco encontraram as três tabelas Pichau.
- [ ] Configurar/deployar API e workflow; o repositório não prova publicação externa.
- [ ] Fazer a primeira coleta real e validar que falha/parcial preserva o último snapshot sem afetar Livelo ou Inter.
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
