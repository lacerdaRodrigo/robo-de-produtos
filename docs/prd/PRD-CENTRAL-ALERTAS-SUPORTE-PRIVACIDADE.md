# PRD — Central de Alertas, suporte e privacidade

Status: implementado no contrato e no código; as migrations `023`, `025`, `026`,
`027`, `028` e `029` foram aplicadas manualmente. A aplicação da `028` foi confirmada
por leitura de produção: as funções estão como `SECURITY DEFINER`, com
`search_path` fechado, e o `pichau_publisher` pode executá-las. Ainda dependem
de operação um evento real que gere push, a entrega FCM e o aceite físico do
Android.

## Objetivo

Oferecer no aplicativo Flutter mobile V15 uma Central autenticada para mudanças válidas
em itens acompanhados, com histórico de 90 dias, filtros, leitura individual ou
em massa, preferências de push, Ajuda, Reportar problema e Privacidade. O cliente
continua consumindo somente a API; Livelo, Cashback Inter, Produtos Inter e
Pichau mantêm snapshots e contratos separados.

## Contrato de dados

A migration `migracoes/023_alertas_suporte_privacidade.sql` cria:

- `acompanhamento_usuario`, camada pessoal por usuário e origem;
- `evento_alerta`, com valores `NUMERIC`, origem, tipo, coleta e leitura;
- `preferencia_alerta`, com flags globais e por tipo;
- `token_fcm_app`, com tokens ativos por usuário;
- `notificacao_outbox_alerta`, idempotente por usuário/origem/coleta;
- `relato_problema_app`, com retenção de 180 dias.

A migration `migracoes/026_alertas_pichau_pessoal.sql` inclui `pichau` como
origem válida, gera alertas Pichau por preço Pix, respeita o momento em que o
usuário começou a acompanhar e permite suprimir push em backfills. A migration
`027_backfill_alertas_sem_push.sql` transforma, de forma protegida, as 10
seleções Livelo e os 16 produtos Pichau atuais da única conta ativa em relações
pessoais e recupera somente a janela Inter posterior ao último evento conhecido.
A migration `028_permissoes_alertas_pichau.sql` protege o gerador Pichau e o
trigger da outbox como `SECURITY DEFINER`, mantendo o publicador sem acesso direto
às tabelas pessoais.

As funções de geração são chamadas somente depois de uma publicação completa e
válida. O primeiro snapshot pessoal não gera evento; ausência, valor inválido,
falha ou coleta parcial não vira zero nem alerta. Comparações são deduplicadas
por coleta. Para Produtos Inter, a qualidade da coleta é lida na execução da
loja (`rodada_loja`), que é a tabela que persiste essa coluna; a rodada
coordenadora é finalizada primeiro e só então dispara os alertas das lojas
válidas. Eventos de backfill ficam na Central, mas não criam outbox nem push.
Alertas expiram após 90 dias e relatos após 180 dias.

### Comportamento por origem

| Origem acompanhada no app | Mudança que gera evento | Coleta mínima válida |
|---|---|---|
| Livelo | Mudança em `pontos_atuais` entre snapshots completos do parceiro | Execução Livelo publicada com sucesso e acompanhamento pessoal ativo |
| Inter — Sites parceiros | Mudança em `cashback_principal_valor` da loja | Execução da loja válida e completa, com acompanhamento pessoal ativo |
| Inter — Compre direto | Mudança em `preco_atual` ou `cashback_percentual` do produto | Execução da loja válida e completa, com acompanhamento pessoal ativo |
| Pichau | Mudança em `preco_pix` do produto | Execução Pichau completa e acompanhamento pessoal ativo |

Em todas as quatro origens, aumento e redução são mudanças válidas, mas o
primeiro snapshot depois de começar a acompanhar serve apenas como baseline.
Ausência de dado, valor inválido, falha ou coleta parcial não gera evento.
O evento pode aparecer no histórico da Central mesmo quando o usuário recusou
push; a notificação depende adicionalmente de preferência habilitada, token FCM
válido e processamento da outbox. A régua `multiplicador`/`piso` da Livelo e
as seleções administrativas globais são indicadores ou configurações legadas;
não substituem o acompanhamento pessoal desta tabela.

## API

Rotas autenticadas em `backend/api/app/api`:

- `GET /api/perfil`;
- `GET/PATCH /api/alertas` e `PATCH /api/alertas/{id}/leitura`;
- `GET/PATCH /api/alertas/preferencias`;
- `POST/DELETE /api/notificacoes/dispositivos`;
- `POST /api/notificacoes/outbox` (admin, acionamento manual);
- `POST /api/cron/notificacoes/outbox` (GitHub Actions, `Authorization: Bearer OUTBOX_CRON_SECRET`);
- `POST /api/relatos-problema`;
- `GET /api/alertas/acompanhamentos`;
- `PATCH /api/alertas/acompanhamentos`;
- `PATCH /api/livelo/catalogo/{id_externo}/acompanhamento-pessoal`;
- `PATCH /api/inter/cashback/{id}/acompanhamento`;
- `PATCH /api/inter/produtos/{loja}/{id_externo}/acompanhamento`.
- `PATCH /api/pichau/catalogo/{id_externo}/acompanhamento-pessoal`.

As rotas de usuário e administrativas usam Firebase Auth, respeitam App Check
quando o enforcement está ligado, isolam por `usuario_app_id`, paginam e
retornam `x-request-id`. A rota interna do cron usa exclusivamente o Bearer
`OUTBOX_CRON_SECRET`, sem identidade de usuário. `autenticarRequisicao` aplica
limites por IP e operação, e mensagens/logs não incluem tokens, URLs de banco ou
dados pessoais. A outbox faz retry, recupera linhas presas em `enviando` há pelo
menos 15 minutos, não duplica envios e desativa tokens FCM inválidos. O workflow
acorda a API a cada 15 minutos; o envio real continua no Firebase Cloud
Messaging através do Firebase Admin SDK. Não há limite diário artificial de
notificações.

`GET /api/perfil` fecha o gate de entrada do Flutter: não recebe identidade em
query ou corpo e retorna exclusivamente o `id`, o `email` e o `papel` da sessão
autenticada. `403` impede a abertura da moldura para conta sem convite/papel
válido; rede, App Check e outros erros permanecem distintos de sessão expirada
no cliente.

As leituras de Livelo, Sites parceiros do Inter e Pichau usam acompanhamento pessoal
por padrão; `escopo=global` só é aceito para administradores e mantém a seleção
legada separada da Central.

### Lista consolidada do Meu radar

`GET /api/alertas/acompanhamentos` é autenticado e nunca recebe o usuário no
query string. Aceita `q`, `origem`, `ordenar`, `pagina` e `por_pagina` (máximo
50), consulta somente os retratos persistidos e retorna item, estado, valor
textual, URL validada, paginação e contagem das quatro origens. Livelo, Inter
Sites parceiros, Inter Compre direto e Pichau continuam em joins e contratos
separados. Ausência de retrato não é convertida em zero ou item fictício.

`GET /api/resumo` acrescenta o bloco pessoal `radar`, com total, recorte por
origem, alertas não lidos e o destaque mais recente. O destaque usa o mesmo
contrato textual de valores e URL segura; `atividade_recente` permanece apenas
para clientes antigos. A migration `029_indices_mobile_v15.sql` é aditiva e
foi aplicada pelo responsável fora de transação, em conexão direta.

O bloco `radar.destaque` continua disponível para a Central e para integrações,
mas a Home compacta não o renderiza como cartão de alerta. O acesso aos eventos
permanece no sino do cabeçalho e na Central de Alertas.

Nos cards de Livelo, cashback Inter, produtos Inter e Pichau, o sino é apenas
um atalho visual para a ação de acompanhamento do usuário e compartilha o mesmo
estado de salvamento/rollback do botão textual. Nenhum desses controles deve ser
interpretado como preferência de push por si só; as seleções administrativas
globais continuam separadas e protegidas por autorização.

### Fixture guardada para QA

O roteiro de dados controlados para validar lista, paginação, leitura, vazio,
ausência de destaque e alternância de autorização fica em
`backend/api/scripts/qa-mobile-v15.mjs`. Ele só pode ser executado com
`QA_ENVIRONMENT=test`, `QA_RUN_ID`, `QA_ACCOUNT_ID`, conexão Postgres direta e
`QA_CONFIRM=I_UNDERSTAND_QA_FIXTURE` para preparação/restauração. O backup deve
ficar fora do repositório, com modo `0600`; a ferramenta falha antes de escrever
quando ambiente, conexão, confirmação ou caminho não são válidos.

O roteiro guarda o estado original, cria apenas relações e alertas identificados
por `QA_RUN_ID`, não dispara push, restaura exatamente as linhas alteradas e
remove somente os dados do ciclo. Não registrar credenciais, tokens, URLs
privadas ou backups no Git. Revogação de token Firebase para o cenário de sessão
expirada é uma ação manual explícita da conta de teste, nunca uma mutação SQL.

O checkpoint da migration `029_indices_mobile_v15.sql` foi confirmado pelo
responsável em conexão direta/unpooled, com checksum
`ec0394b66618b9606373a3a34dcdb97f183813e059f53d87abf41ff78d179a89`. A
evidência completa do aceite físico, incluindo os 42 cenários e suas provas,
está no [`PRD-ACEITE-MOBILE-V15.md`](PRD-ACEITE-MOBILE-V15.md); os bloqueios
ainda abertos ficam somente em [`../PENDENCIAS.md`](../PENDENCIAS.md).

## Flutter mobile V15

`PaginaAlertas` substitui a folha placeholder e preserva filtro, página e coleta
recebida por deep link de push. A tela cobre loading, vazio, erro, parcial,
offline, lidos/não lidos, paginação e preferências. No mobile compacto, a
Central segue a composição do protótipo V15: cabeçalho `Mudou. Você viu.` com
botão acessível `Voltar` e acesso às preferências, descrição curta, abas planas `Todos`/`Não lidos`,
linha `Últimos 90 dias` com a ação `Filtrar`, ação `Marcar todos como lidos` e
um feed de mudanças sem cartões elevados. Cada mudança mostra origem e horário,
título orientado pela direção da alteração, entidade, comparação textual dos
valores, `Ver item` e o estado de leitura. O filtro de tipo abre uma folha; ele
continua usando o contrato paginado da API, sem baixar catálogo completo.

`Marcar todos como lidos` percorre as páginas do recorte atual com `por_pagina`
limitado a 50 e envia lotes de no máximo 100 IDs para o `PATCH /api/alertas`.
Falhas restauram os itens e a contagem que estavam visíveis antes da tentativa.
`Ver item` mantém a ação contextual do protótipo e usa o callback da moldura
quando disponível para voltar à origem correspondente (Livelo, Inter ou Pichau);
sem esse callback, informa a origem sem inventar uma rota de detalhe que a API de
alertas não fornece.

A rota compacta mantém a barra inferior V15 visível, com Início selecionado como
no protótipo; tocar outro destino fecha a Central e devolve o contexto à moldura
principal. O perfil substitui a antiga gaveta: oferece Central, Ajuda, Reportar
problema, Privacidade, aparência, Administração e saída. Livelo, Banco Inter e
Pichau são subáreas de Explorar. O botão/gesto de voltar do Android em Explorar
retorna para Início. Produtos Inter exibe a ação pessoal `Acompanhar`, sem
alterar a seleção global de lojas.

Quando a Central é aberta como rota secundária, o botão `Voltar` do cabeçalho e
o botão/gesto de voltar do Android fazem o mesmo `pop` para a tela anterior,
preservando o estado da moldura e sem criar uma nova instância da Central.

Após o primeiro login, FCM solicita permissão. Recusar ou indisponibilidade do
Firebase não bloqueia a Central nem o histórico. Logout remove o token atual.

## Critérios de aceite

1. `dart format`, `flutter analyze` e testes unitários/widgets afetados passam.
2. `npm run checar`, testes Vitest direcionados e workflow da outbox passam; testes Python dos
   adaptadores de coleta passam.
3. O protótipo V15 e a tela Flutter mantêm estados e hierarquia nas larguras
   320, 360, 390 e 430 px, em claro e escuro, sem overflow.
4. Migrations 023, 025, 026, 027 e 028 estão aplicadas no banco alvo por
   operação autorizada, com a validação de contagens, isolamento da conta e
   permissões mínimas do publicador Pichau.
5. A migration 029 está aplicada e verificada no banco alvo.
6. APK debug é instalada e as jornadas de login, Central, filtros, leitura,
   preferências, Ajuda, relato, privacidade, links externos e ausência de dados
   são conferidas no Moto G6 Play; o aceite Samsung permanece separado.

## Pendências externas

Conforme confirmação operacional do responsável, as migrations 023 e seguintes
foram aplicadas manualmente e o Firebase `radarbeneficios` está configurado para
a API/Android. A verificação de produção em 2026-09-13 confirmou a `028` em
modo somente leitura, incluindo `SECURITY DEFINER`, `search_path` fechado e
execução para `pichau_publisher`. A coleta `34761933582` passou com qualidade
completa, sem `pichau-banco`, mas não houve mudança de preço para gerar evento.
O merge, deploy, APK e secret do cron foram confirmados; ainda falta produzir um
evento real, observar sua entrega FCM e instalar/conferir a APK nos devices para
o aceite manual completo.

Este PRD incorpora os contratos implementados. O checkpoint operacional de
migration, publicação e reteste físico está no
[`PRD-ACEITE-MOBILE-V15.md`](PRD-ACEITE-MOBILE-V15.md); a lista viva de
bloqueios e próximas ações está em [`../PENDENCIAS.md`](../PENDENCIAS.md).
