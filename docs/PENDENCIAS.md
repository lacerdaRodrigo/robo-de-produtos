# Pendências abertas

Esta lista contém apenas trabalho ainda sem conclusão ou evidência suficiente.
Aceites parciais e resultados físicos ficam nos PRDs de domínio e no
[`PRD de aceite mobile`](prd/PRD-ACEITE-MOBILE-V15.md). O escopo e os gates do
ciclo Flutter estão em [`AGENTS.md`](../AGENTS.md); este arquivo não substitui
essas regras.

## Aceite mobile V15

- [ ] Produzir um evento real de mudança de preço e confirmar a entrega FCM, o
  conteúdo da notificação e a abertura da Central. Não criar fixtures nem
  alterar dados de produção para provocar o evento. A permissão de push continua
  opcional e o histórico deve permanecer acessível quando recusada.
- [ ] Completar o aceite físico no Samsung SM-M135M (M13), aparelho-alvo desta
  revisão. Ainda faltam sessão expirada controlada, conta sem papel
  administrativo, estados de erro/atraso/parcial, leitura de tela, cobertura de
  rotas com texto ampliado e comparação formal de todas as telas com o HTML V15.
  A rodada parcial anterior no Moto G6 Play é histórica e não substitui o aceite
  no M13. O registro detalhado está no
  [`PRD de aceite mobile`](prd/PRD-ACEITE-MOBILE-V15.md).
- [ ] Revisar e aprovar o mapeamento de categorias das lojas atuais de cashback
  Inter; depois, classificar o conjunto confirmado pelo fluxo administrativo.
  A confirmação da migration não aprova categorias em nome do responsável.
- [ ] Validar fisicamente a Central de Alertas V15 com alertas não lidos em mais
  de uma página: abas e filtros, leitura individual e coletiva, paginação,
  retorno Android e estado vazio. Na última rodada a conta não tinha alertas
  não lidos.
- [ ] Completar o aceite físico dos Sites parceiros Inter: busca, efeito dos
  filtros, ordenação e paginação. A abertura do link real e o retorno do Chrome
  já foram revalidados; os casos restantes estão no PRD de aceite.
- [ ] Conferir no Samsung a paginação física de Produtos, Livelo, Sites
  parceiros e Compre direto quando cada lista tiver 9, 10 e 11 cards. Os
  widgets cobrem os limites, mas o aparelho ainda não foi validado com essas
  cardinalidades reais.
- [ ] Finalizar o aceite físico de Compre direto: aplicar e conferir busca e
  filtros, aba `No radar`, agrupamento com mais de uma loja e estados vazio,
  parcial/erro. A rodada de 28/09 confirmou catálogo real, filtros acessíveis,
  página 2, detalhe e histórico; o restante está no
  [`PRD de aceite mobile`](prd/PRD-ACEITE-MOBILE-V15.md).
- [ ] Validar fisicamente a disponibilidade Pichau `Fora do catálogo` e seus
  estados vazio, parcial e erro. Na rodada atual, `Todos`, `Disponíveis`,
  `Esgotados`, busca, faixa de preço, detalhe e histórico foram conferidos; o
  estado `Fora do catálogo` não foi forçado. Ver também o
  [`PRD Pichau`](prd/PRD-PICHAU.md).
- [ ] Confirmar em ambiente controlado que a API publicada contém e preserva o
  fallback de leitura do catálogo Pichau para falhas específicas de relação,
  coluna ou permissão de acompanhamento pessoal. O Samsung carregou 1.223
  produtos pelo caminho normal, mas esta rodada não provocou essas falhas; não
  fazer fault injection em Production.
- [ ] Reconciliar o estado de `Meu radar`: a conta mostrou um acompanhamento
  Riachuelo em `Sem dados`, enquanto a evidência anterior registrava 74 e outra
  rodada retornou zero. Confirmar conta/corte de dados antes de aceitar a
  continuidade dos acompanhamentos; não preencher valores ausentes.

## Revisão mobile V15 desta branch

- [ ] Gerar e instalar o APK final desta revisão no Samsung SM-M135M (M13), preservando a sessão. O artefato existente não contém as alterações atuais; os bloqueios de build e ADB estão detalhados em D-045 no [`PRD de aceite mobile`](prd/PRD-ACEITE-MOBILE-V15.md). A evidência D-044 é uma rodada parcial anterior no Moto G6 Play e não valida esta revisão no aparelho-alvo.
- [ ] Publicar a API desta branch para habilitar `GET /api/relatos-problema`, as cinco categorias V15, os parâmetros do catálogo Livelo (`somente_pontuacao_comum_ampliada` e `ordenar=validade`) e as rotas de filtro/detalhe da Central de Alertas. Até a publicação, não validar esses fluxos no APK contra o serviço real. A migration `035_categorias_relato_mobile_v15.sql` foi informada como executada pelo responsável; esta sessão não consultou o banco.

## Executor Android e Pichau

- [ ] Passar nove execuções Pichau agendadas consecutivas em 72 horas com o
  Samsung carregando, no Wi-Fi, tela bloqueada e sem abrir o Termux. As
  execuções manuais não contam. Uma falha reinicia a janela; após o reboot de
  26/09 houve quatro falhas porque a ROM desativou a Depuração por Wi-Fi. O
  [`PRD de execução dos coletores`](prd/PRD-EXECUCAO-COLETORES.md) registra os
  slots e evidências mais recentes.
- [ ] Depois do gate, decidir se é aceitável recuperar manualmente o ADB por
  Wi-Fi após reboot: ligar e desbloquear o Samsung, ativar a opção do
  desenvolvedor, executar `adb tcpip 5555` por USB autorizado, conferir o
  executor e retirar o cabo. A ROM atual não promete recuperação autônoma após
  reboot.
- [ ] Se a recuperação manual não for aceitável, avaliar separadamente um
  controlador Linux residencial sempre ligado; não presumir que o Android sem
  root possa religar a Depuração por Wi-Fi.
- [ ] Validar no Samsung os timeouts e a atualização/reinício controlado do
  worker descritos no PRD de execução. A atualização ainda é in-place, sem
  release atômico nem rollback automático.

## API, dados e publicação externa

- [ ] Revisar amostras reais dos recortes hierárquicos de navegação do catálogo
  Inter e ampliar somente folhas finais com evidência. Os escopos incluem
  cozinhas, quarto/camas, beleza, saúde, limpeza/climatização e festas; os
  recortes `Outros / novas categorias` permanecem dinâmicos.
- [ ] Publicar a API com os novos identificadores de escopo antes de distribuir
  o APK correspondente. App e API em versões incompatíveis devem manter os
  cards anteriores como estado de falha.
- [ ] Corrigir o OAuth da distribuição privada: o CI `35471530166` falhou com
  `invalid_grant` porque o refresh token expirou ou foi revogado. Renovar
  `GOOGLE_DRIVE_REFRESH_TOKEN` ou concluir a publicação do cliente OAuth em
  `Production` antes de repetir o aceite externo.
- [ ] Fazer o aceite externo da distribuição privada: instalar pelo fluxo
  autorizado, confirmar acesso da conta permitida e bloqueio para uma conta não
  autorizada, observar mais de 10 builds para validar retenção e confirmar um
  push em `main`. Ver [`PRD de distribuição Android`](prd/PRD-DISTRIBUICAO-ANDROID.md).
- [ ] Configurar o gate WAF no Vercel antes da próxima publicação da API que
  dependa dele: regra para `/api/*`, chave por IP, janela fixa de 60 segundos e
  limite de 240 requisições/minuto. Manter em `Log` por 24 horas, revisar o
  tráfego legítimo e só então habilitar `429`, incluindo `/api/status`. Registrar
  a regra ativa; não publicar alteração bloqueada por este gate.
- [ ] Configurar o backup Neon conforme o
  [`PRD de backup`](prd/PRD-BACKUP-NEON.md): validar grants, criar login próprio
  para `radar_backup`, gerar chave age e guardar a privada offline, renovar
  OAuth, cadastrar secrets e preparar a pasta privada no Drive.
- [ ] Executar o primeiro backup, conferir ACL e restaurar em banco ou branch
  descartável. Não executar funções de limpeza da migration 033 antes do restore
  e do aceite destrutivo descartável.

## Produto, operação e distribuição futura

- [ ] Decidir e validar App Check/Google Play, incluindo Play Integrity em uma
  instalação real pela Play Store. Até essa validação, manter
  `ATIVAR_APP_CHECK=false`, não ativar `EXIGIR_APP_CHECK=true` e descrever o APK
  atual como distribuição privada.
- [ ] Acompanhar a compatibilidade Gradle do plugin `firebase_app_check`; o
  build debug passou, mas o Flutter avisou que versões futuras deixarão de
  aceitar plugins que aplicam Kotlin Gradle Plugin diretamente. Atualizar
  quando o plugin upstream suportar Kotlin integrado ou antes da atualização
  Flutter incompatível.
- [ ] Decidir e validar separadamente Crashlytics e ambientes Firebase
  adicionais.
- [ ] Definir logs centralizados para app, API e robôs, com correlação por
  execução, severidade, retenção e sem tokens, dados pessoais ou payloads
  sensíveis.
- [ ] Completar um runbook operacional para Livelo, Inter Sites parceiros e
  Inter Compre direto: entradas, variáveis, comandos, workflows, horários,
  tabelas escritas, códigos de saída, retries, reexecução manual e diagnóstico.
- [ ] Em ciclo futuro, extrair os trechos restantes do layout amplo em widgets
  por domínio sem reabrir a composição antiga como referência da jornada V15.
- [ ] Preparar a publicação na Google Play: nome, ícone, capturas, classificação
  etária, política de privacidade, ficha de segurança de dados, versão e pacote
  de produção.
- [ ] Provisionar a assinatura Android release: criar a chave estável
  `radar-release`, guardar cópia offline criptografada, cadastrar os quatro
  secrets `ANDROID_KEYSTORE_*`/`ANDROID_KEY_*` e habilitar
  `ANDROID_RELEASE_ENABLED` só após comparar a impressão digital. A primeira
  instalação release exige remover o APK debug e autenticar novamente.
- [ ] Criar deploy automático via GitHub Actions para API e aplicativo, com
  ambientes de validação e produção, aprovação antes da publicação e rollback.
- [ ] Criar monitoramento pós-publicação para erros, indisponibilidade da API,
  falhas dos robôs, dados atrasados e regressões de autenticação/App Check.
- [ ] Criar documentação OpenAPI/Swagger das rotas públicas, autenticadas e
  administrativas, com autenticação, paginação, schemas, erros e exemplos;
  validar o contrato no CI.
- [ ] Completar aceite manual final em Android real, incluindo login,
  notificações quando aplicável, links externos, permissões, tema escuro, telas
  de erro e atualização sobre uma versão instalada.
- [ ] Avaliar um ambiente de homologação separado de produção, com Firebase,
  banco, API e secrets próprios.
- [ ] Formalizar checklist de backup/restauração e migrations depois que o
  primeiro restore descartável comprovar o procedimento.
- [ ] Garantir compatibilidade entre versões antigas do aplicativo e da API
  durante o período de atualização.
- [ ] Configurar distribuição interna da Google Play antes de eventual liberação
  pública.
- [ ] Revisar com responsável jurídico o fluxo LGPD da Central: consentimento,
  exclusão de conta, política e dados efetivamente coletados.
- [ ] Documentar e testar rollback da API, banco, robôs e versão publicada do
  aplicativo.

## Legado ainda usado ou sem decisão de remoção

- [ ] Planejar em migration futura separada eventual remoção das tabelas legadas
  `oferta_direta_inter_atual` e `disparo_manual*`; nenhuma remoção de schema foi
  autorizada neste ciclo.
- [ ] Reavaliar o painel Livelo legado somente quando o layout não compacto e a
  compatibilidade da rota `/api/livelo/painel` deixarem de ser necessários.
