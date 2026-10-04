# Pendências abertas

Esta lista contém somente itens sem conclusão que dependem de aparelho, dados
naturais, decisão do responsável, credenciais ou configuração/ensaio externo.
Os detalhes e resultados parciais ficam nos PRDs de domínio e no
[`PRD de aceite mobile`](prd/PRD-ACEITE-MOBILE-V15.md). Os gates do ciclo
Flutter estão em [`AGENTS.md`](../AGENTS.md).

## Aceite mobile e dados reais

- [ ] Observar uma mudança natural de preço, confirmar a entrega FCM, o conteúdo
  da notificação e a abertura da Central pelo toque. Não criar fixture nem
  alterar dados de Production para provocar o evento. Push permanece opcional e
  o histórico deve continuar acessível após recusa.
- [ ] Aplicar/verificar a migration `036_rastreio_entrega_push.sql` no banco alvo
  por operação autorizada antes de publicar a API desta mudança. Suspender o
  processamento da outbox durante o corte; a migration encerra pendências antigas
  sem replay porque não há histórico individual de aceite FCM. Depois, conferir
  a tabela/grants de `robo_api` e observar uma mudança natural.
- [ ] Executar no Samsung SM-M135M (M13) os casos físicos ainda abertos: sessão
  expirada controlada, conta sem papel administrativo, atraso/erro/parcial,
  TalkBack, texto a 200% em todas as rotas e comparação formal de todas as telas
  e estados com o HTML V15. A build atual `1.74.1+2026100301` foi instalada,
  mas o runner corrigido também bloqueou antes do primeiro cenário porque não
  encontrou o rótulo acessível `Início`. A tela ficou aberta no app; a árvore de
  acessibilidade ainda precisa ser esclarecida. O PRD mantém a matriz e as
  evidências por cenário.
- [ ] Resolver manualmente o caso Shopping Inter compacto: decidir se `Acompanhar`
  continua visível na lista ou se o cartão pode sair da árvore ao deixar de
  acompanhar e reposicionar. O teste permanece comentado em
  `app/test/app/navegacao/moldura_test.dart`; não remover o comentário, adaptar
  a expectativa nem mudar a interface antes da decisão manual.
- [ ] Validar fisicamente a Central com mais de uma página de alertas não lidos,
  leitura individual e coletiva, paginação e estado vazio. A conta mostrou dois
  não lidos no build 103; a rodada foi somente leitura e nenhum alerta foi
  alterado. Não criar alertas artificiais em Production.
- [ ] Conferir no M13 as listas reais de Produtos, Livelo, Sites parceiros e
  Compre direto com 9, 10 e 11 cards; widgets cobrem os limites, mas faltam as
  cardinalidades reais no aparelho.
- [ ] Completar Compre direto com agrupamento de mais de uma loja e estados
  parcial/erro. A rodada física cobriu busca, vazio, filtro, `No radar`, limpar
  e página 2; havia somente Casas Bahia selecionada. Não alterar a seleção
  administrativa de Production sem a janela operacional correspondente.
- [ ] Validar no M13 os estados parcial/erro do Pichau. `Fora do catálogo`, seu
  estado vazio e a restauração de `Todos` já foram confirmados; estados parcial
  e erro não foram provocados. Confirmar também, em ambiente controlado, o
  fallback da API publicada para falhas específicas de relação, coluna e
  permissão pessoal. Não fazer fault injection em Production.
- [ ] Reconciliar `Meu radar` usando a mesma conta e o mesmo corte de dados. O
  M13 mostrou 27 acompanhamentos; registros anteriores mostram 74, zero e uma
  Riachuelo em `Sem dados`. Não preencher valores ausentes.
- [ ] Revisar amostras atuais das folhas hierárquicas do catálogo Inter e
  ampliar os recortes apenas com evidência real; submeter o mapeamento de
  categorias de cashback à aprovação do responsável e, só depois, classificar o
  conjunto aprovado pelo fluxo administrativo. Não inferir categorias por nome.

## Executor Android e publicação da API

- [ ] Passar nove execuções Pichau agendadas consecutivas em 72 horas com o
  Samsung carregando, no Wi-Fi e tela bloqueada, sem abrir o Termux. Execuções
  manuais não contam; qualquer falha reinicia a janela. Ver o PRD de execução
  dos coletores para slots e evidências.
- [ ] Validar no M13 os timeouts e a atualização/reinício controlado do worker.
  A atualização atual é in-place, sem troca atômica nem rollback automático.
- [ ] Decidir se a recuperação manual do ADB por Wi-Fi após reboot é aceitável.
  Se não for, decidir separadamente pelo controlador Linux residencial; esta
  ROM não permite prometer recuperação autônoma pelo Android sem root.
- [ ] Publicar a API com os identificadores de escopo necessários e a migration
  `036` aplicada antes de distribuir o APK correspondente; conferir a
  compatibilidade do serviço publicado. A implantação base em Production com
  `radar_api`, status/outbox saudáveis e leitura autenticada dos catálogos já foi
  confirmada no PRD de execução; isso não valida a revisão dependente da `036`.
  O fallback Pichau também depende de validação publicada em ambiente controlado.

## Contas, segurança e serviços externos

- [ ] Validar a credencial OAuth renovada da distribuição privada e concluir o
  aceite externo: instalar pelo fluxo
  autorizado, confirmar conta permitida e bloqueio de conta não autorizada,
  observar mais de 10 builds para retenção e confirmar um push em `main`. Ver o
  PRD de distribuição Android.
- [ ] Configurar o gate WAF no Vercel: `/api/*`, chave por IP, janela fixa de 60
  segundos e limite de 240 requisições por minuto; manter em `Log` por 24 horas,
  revisar tráfego legítimo e só depois habilitar `429`, incluindo `/api/status`.
  Registrar a regra ativa antes de publicação dependente dela.
- [ ] Configurar o backup Neon: login exclusivo para `radar_backup`, chave age
  privada guardada offline, secrets e pasta privada no Drive. Executar o primeiro
  backup, conferir ACL e restaurar em banco/branch descartável. Não executar as
  funções destrutivas da migration 033 antes desse restore e do aceite isolado.
- [ ] Decidir e validar App Check/Google Play, incluindo Play Integrity em uma
  instalação real pela Play Store. Até lá, manter App Check desativado e
  identificar o APK atual como distribuição privada.
- [ ] Atualizar e validar `firebase_app_check` quando o pacote puder ser obtido
  pelo fluxo normal de dependências. O lock atual usa 0.4.6; a versão 0.4.7 do
  upstream remove os pins locais de AGP/Kotlin, mas não foi possível baixar a
  dependência nesta sessão. Ver [changelog oficial](https://pub.dev/packages/firebase_app_check/changelog).
- [ ] Decidir separadamente Crashlytics e ambientes Firebase adicionais; depois
  provisionar projetos e credenciais próprios.
- [ ] Confirmar no Vercel se a API já publica por integração Git e configurar
  ambientes de validação/Production com aprovação, sem criar fluxo concorrente.
  O workflow Android privado já existe; deploy, WAF e secrets reais exigem
  configuração externa.
- [ ] Definir o destino, retenção, acessos e destinatários do monitoramento
  central de app/API/robôs. O
  [`PRD de operação`](prd/PRD-OPERACAO-RELEASE-OBSERVABILIDADE.md) documenta o
  esquema de logs seguros, a correlação disponível e os limites de
  `/api/status`; centralização e alertas dependem dessa escolha e configuração.
- [ ] Definir a janela de suporte e a versão mínima do aplicativo. O contrato
  documentado preserva rotas e campos para clientes antigos, mas a janela e a
  compatibilidade com deployments/APKs efetivamente publicados exigem decisão e
  evidência externa.
- [ ] Provisionar homologação separada (Firebase, banco, API e secrets) antes
  de validar integrações ou falhas controladas fora de Production.
- [ ] Fazer os ensaios de rollback em cada destino real: API no provedor, restore
  Neon descartável, recuperação do worker no M13 e reinstalação/retorno da APK
  debug distribuída. A assinatura pode variar entre execuções; desinstalar a
  versão anterior pode apagar os dados locais. O procedimento e os limites estão
  no
  [`PRD de operação`](prd/PRD-OPERACAO-RELEASE-OBSERVABILIDADE.md) e nos PRDs de
  domínio; os mecanismos externos e os ensaios ainda não foram aceitos.

## Google Play e privacidade

- [ ] Preparar a ficha de produção Google Play com conta responsável,
  classificação etária, política de privacidade, formulário de segurança de
  dados, capturas e pacote release; concluir a revisão jurídica do fluxo LGPD da
  Central (consentimento, exclusão de conta e dados efetivamente coletados).
- [ ] Criar e guardar offline, de forma criptografada, uma chave de assinatura
  estável para um futuro pacote release/Google Play; conferir sua impressão
  digital e documentar a assinatura. Isso é separado da distribuição privada
  de APK debug para testes, que não usa esses secrets. Uma primeira instalação
  release pode exigir remover o APK debug e autenticar novamente.
- [ ] Configurar distribuição interna da Google Play antes de qualquer
  liberação pública.
