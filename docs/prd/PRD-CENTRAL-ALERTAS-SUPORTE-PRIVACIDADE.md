# PRD — Central de Alertas, suporte e privacidade

Status: implementado no contrato e no código; as migrations `023`, `025`, `026`,
`027` e `028` foram aplicadas manualmente. A aplicação da `028` foi confirmada
por leitura de produção: as funções estão como `SECURITY DEFINER`, com
`search_path` fechado, e o `pichau_publisher` pode executá-las. Ainda dependem
de operação um evento real que gere push, a entrega FCM e o aceite físico do
Android.

## Objetivo

Oferecer no aplicativo Flutter mobile V12 Delta uma Central autenticada para mudanças válidas
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

- `GET/PATCH /api/alertas` e `PATCH /api/alertas/{id}/leitura`;
- `GET/PATCH /api/alertas/preferencias`;
- `POST/DELETE /api/notificacoes/dispositivos`;
- `POST /api/notificacoes/outbox` (admin, acionamento manual);
- `POST /api/cron/notificacoes/outbox` (GitHub Actions, `Authorization: Bearer OUTBOX_CRON_SECRET`);
- `POST /api/relatos-problema`;
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

As leituras de Livelo, Sites parceiros do Inter e Pichau usam acompanhamento pessoal
por padrão; `escopo=global` só é aceito para administradores e mantém a seleção
legada separada da Central.

Nos cards de Livelo, cashback Inter, produtos Inter e Pichau, o sino é apenas
um atalho visual para a ação de acompanhamento do usuário e compartilha o mesmo
estado de salvamento/rollback do botão textual. Nenhum desses controles deve ser
interpretado como preferência de push por si só; as seleções administrativas
globais continuam separadas e protegidas por autorização.

## Flutter mobile V12 Delta

`PaginaAlertas` substitui a folha placeholder e preserva filtro, página e coleta
recebida por deep link de push. A tela cobre loading, vazio, erro, parcial,
offline, lidos/não lidos, paginação e preferências. No mobile compacto, o
perfil substitui a antiga gaveta: oferece Central, Ajuda, Reportar problema,
Privacidade, aparência, Administração e saída. Resumo e Serviços continuam
exclusivos da barra inferior. Produtos Inter exibe a ação pessoal `Acompanhar`,
sem alterar a seleção global de lojas.

Após o primeiro login, FCM solicita permissão. Recusar ou indisponibilidade do
Firebase não bloqueia a Central nem o histórico. Logout remove o token atual.

## Critérios de aceite

1. `dart format`, `flutter analyze` e testes unitários/widgets afetados passam.
2. `npm run checar`, testes Vitest direcionados e workflow da outbox passam; testes Python dos
   adaptadores de coleta passam.
3. O protótipo Delta e a tela Flutter mantêm estados e hierarquia nas larguras
   320, 360, 390 e 430 px, em claro e escuro, sem overflow.
4. Migrations 023, 025, 026, 027 e 028 estão aplicadas no banco alvo por
   operação autorizada, com a validação de contagens, isolamento da conta e
   permissões mínimas do publicador Pichau.
5. APK debug é instalada e as jornadas de login, Central, filtros, leitura,
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

Este PRD incorpora o plano de implementação; o arquivo de plano histórico foi
removido para não voltar a orientar trabalho já entregue.
