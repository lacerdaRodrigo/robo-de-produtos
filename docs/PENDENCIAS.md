# Pendências

Lista viva somente do que continua aberto. Histórico concluído permanece no Git e nos PRDs; não deve voltar a governar o ciclo atual.

O contrato operacional padrão da branch `re-design` é o [`AGENTS.md`](../AGENTS.md):
Flutter mobile, protótipo mobile como fonte visual, unitários/widgets afetados e
Web/integration/E2E fora do gate. A implementação backend Pichau desta tarefa
foi autorizada explicitamente. Coletor e transporte Wi-Fi foram validados, mas
a disponibilidade contínua do executor Android continua aberta. A execução
`34519730452`, em 2026-09-10, falhou como `pichau-acesso`; uma coleta anterior
passou no mesmo commit também com o Chrome aberto, portanto o estado residual é
um risco removido pelo novo ciclo limpo, não uma causa isolada comprovada. Essa
falha reiniciou o gate operacional.

## Ciclo mobile atual

- [ ] Aplicar e validar `migracoes/023_alertas_suporte_privacidade.sql` no banco alvo: não há `DATABASE_URL`, credencial Neon nem `psql` disponíveis neste checkout, portanto a execução não foi simulada nem declarada como feita. Registrar tabelas, índices, constraints e consultas de verificação após a aplicação autorizada.
- [ ] Configurar FCM no projeto Android/API e executar o cron da outbox; a permissão de push é opcional e o histórico deve continuar acessível quando recusada.
- [ ] Fazer conferências manuais no Moto G6 Play e no Samsung quando uma entrega mobile exigir aceite físico. A APK debug foi instalada no Moto e já confirmou abertura, navegação de Conta, Ajuda, Reportar problema, Privacidade, claro/escuro e estado de erro da Central; filtros, paginação, leitura, preferências e dados reais aguardam a migration/API 023. O aceite completo também cobre login/reautenticação, ausência, links externos e overflow. Isso não vira smoke automatizado neste ciclo.
- [ ] Conferir manualmente no Samsung a paginação de Produtos, Livelo, Sites parceiros e Compre direto nos limites de 9, 10 e 11 cards; o repositório cobre a regra por widget, mas não substitui o aceite físico.
- [ ] Conferir manualmente no Samsung a combinação, remoção individual e limpeza dos recortes contextuais de Produtos; em especial, confirmar que `Outros / novas categorias` continua exclusivo e que a resposta troca os cards sem perder a busca em curso.
- [ ] Publicar a evolução do contrato Pichau de acompanhamento antes de
  distribuir a APK desta branch: a camada Flutter já envia `aba`,
  `disponibilidade`, `ordenar`, `acompanhada` e o PATCH autenticado, mas a
  rota `/api/pichau/catalogo/{id_externo}/acompanhamento`, a contagem no
  resumo e a migration de persistência ficaram fora do ciclo mobile e ainda
  precisam de validação/aplicação externa.

## Pichau — evolução ainda aberta

- A validação branch-first da `024` foi concluída em 2026-09-10 numa branch
  temporária derivada de `production`, sem aplicar a `023`: coluna e constraints
  válidas, 47 linhas existentes compatíveis com `{}` e grants preservados para
  `pichau_dispatcher` (`SELECT/INSERT`) e `pichau_publisher` (`SELECT/UPDATE`). A
  branch temporária foi descartada sem alterar `production`. Depois da
  confirmação, o responsável aplicou a migration em `production`; a
  verificação somente de leitura confirmou coluna, constraints, 47 linhas com
  `{}` e os mesmos grants.
- [ ] Atualizar o checkout do Samsung por USB autorizado, conferir
  worker/watchdog/fila/ADB e retirar o cabo.
- [ ] Recuperar e analisar, em outro momento e apenas se ainda for útil, os
  metadados seguros do log local da falha de 10/09. Essa investigação foi
  adiada pelo responsável e não bloqueia a migration nem a implementação local.
- [ ] Executar uma coleta manual real com a tela bloqueada e somente Wi-Fi:
  exigir no máximo duas sessões, recuperação visível quando usada, catálogo e
  contagens completos, nenhuma publicação parcial, fila/sumário detalhados no
  Actions e Chrome/Appium ociosos ao final. Registrar a run no PRD.
- [ ] Observar nove execuções agendadas consecutivas em 72 horas, com o aparelho
  dedicado, carregando, no Wi-Fi e com a tela bloqueada, sem abrir o Termux
  entre as coletas. A janela recomeça após a validação manual desta correção;
  qualquer nova falha a reinicia novamente.
- [ ] Decidir depois do gate se a exigência de recuperação manual após reboot é
  aceitável: ligar e desbloquear uma vez, ativar “Depuração por Wi‑Fi”, executar
  `adb tcpip 5555` por USB autorizado, conferir o status e retirar o cabo. A
  operação normal bloqueada e sem cabo não depende do USB enquanto o aparelho
  não reiniciar.
- [ ] Se a recuperação manual não for aceitável, avaliar controlador Linux
  residencial sempre ligado. O Android sem root não deve ser tratado como capaz
  de reativar sozinho a Depuração por Wi‑Fi desativada pela ROM.
- [ ] Decidir posteriormente se e quando a Pichau entra na busca global de Produtos; a v1 mobile mantém essa busca inalterada.

## Ações operacionais externas

- [ ] Confirmar operacionalmente a aplicação das migrations `016_preserva_historico_livelo.sql` e `017_qualidade_livelo.sql`. Elas são tratadas externamente; este repositório não registra confirmação de aplicação.
- [ ] Validar a migration `020_categorias_inter_fonte_oficial.sql` em ambiente descartável e decidir sua aplicação somente com autorização explícita. Ela remove a taxonomia Radar obsoleta depois de confirmar que não há seleção legada de categorias.
- [ ] Revisar periodicamente amostras reais dos recortes hierárquicos de navegação do catálogo Inter (incluindo os novos recortes de cozinhas, quarto/camas, beleza, saúde, limpeza/climatização e festas) e ampliar apenas folhas finais quando houver evidência. Os escopos atuais e “Outros / novas categorias” já são dinâmicos para qualquer quantidade de lojas ativas e selecionadas.
- [ ] Publicar a API com os novos identificadores de escopo antes de distribuir o APK correspondente; app e API fora de versão retornam erro de validação e mantêm os cards anteriores como estado de falha.
- [ ] Fechar o rollout externo do App Check antes de exigir enforcement. Não declarar Web/iOS observados nem enforcement ativo sem confirmação.
- [ ] Concluir a publicação em `Production` do cliente OAuth usado pela distribuição privada do APK; enquanto estiver em `Testing`, o refresh token do Drive pode exigir renovação após o prazo do Google.
- [ ] Fazer o aceite externo da distribuição privada do APK: instalar a build no Samsung, confirmar acesso com `EMAIL_DESTINO`, negar acesso a uma conta não autorizada, observar mais de 10 builds para validar a retenção e confirmar um push na `main`. A implementação e a primeira execução estão documentadas em [`PRD-DISTRIBUICAO-ANDROID.md`](prd/PRD-DISTRIBUICAO-ANDROID.md).

## Próxima fase — produto, operação e publicação

- [ ] Integrar e configurar o Firebase usado pelo aplicativo, incluindo autenticação, App Check, FCM, Crashlytics e ambientes separados quando aplicável.
- [ ] Definir um sistema centralizado de logs para app, API e robôs, com correlação por execução, níveis de severidade, retenção e sem registrar tokens, dados pessoais ou payloads sensíveis.
- [ ] Completar o runbook operacional dos robôs Livelo, Inter Sites parceiros e Inter Compre direto: entradas, variáveis de ambiente, comandos, workflows, horários, tabelas escritas, códigos de saída, retries, reexecução manual e diagnóstico de falhas.
- [ ] Reorganizar as telas Flutter e extrair componentes reutilizáveis para pastas `widgets/`, preservando a separação por domínio e sem quebrar os imports das jornadas existentes.
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

- [ ] Decidir em ciclo próprio o destino de `ranking_inter.py` e `app/lib/inter_preview.dart`.
- [ ] Planejar, em migration futura separada, eventual remoção das tabelas legadas `oferta_direta_inter_atual` e `disparo_manual*`. Não há remoção de schema neste ciclo.
- [ ] Reavaliar o painel Livelo legado somente quando o layout não compacto e a compatibilidade da rota `/api/livelo/painel` deixarem de ser necessários.

## Testes e plataformas adiados

- Integration, E2E, smoke automatizado, performance e regressão visual não fazem parte do gate deste ciclo.
- O suporte Web permanece no repositório, mas não é alvo visual nem gate obrigatório da branch mobile.
- Nenhum item acima autoriza deploy, coleta real, alteração de secrets, aplicação de migration ou mudança em produção.
