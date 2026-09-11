# PRD — Central de Alertas, suporte e privacidade

Status: implementado no contrato e no código; a migration foi aplicada
manualmente e o projeto Firebase `radarbeneficios`/Vercel já está configurado.
Ainda dependem de operação o segredo compartilhado do cron e o aceite físico
do Android.

## Objetivo

Oferecer no aplicativo Flutter V11 uma Central autenticada para mudanças válidas
em itens acompanhados, com histórico de 90 dias, filtros, leitura individual ou
em massa, preferências de push, Ajuda, Reportar problema e Privacidade. O cliente
continua consumindo somente a API; Livelo, Cashback Inter e Produtos Inter
mantêm snapshots e contratos separados.

## Contrato de dados

A migration `migracoes/023_alertas_suporte_privacidade.sql` cria:

- `acompanhamento_usuario`, camada pessoal por usuário e origem;
- `evento_alerta`, com valores `NUMERIC`, origem, tipo, coleta e leitura;
- `preferencia_alerta`, com flags globais e por tipo;
- `token_fcm_app`, com tokens ativos por usuário;
- `notificacao_outbox_alerta`, idempotente por usuário/origem/coleta;
- `relato_problema_app`, com retenção de 180 dias.

As funções de geração são chamadas somente depois de uma publicação completa e
válida. O primeiro snapshot não gera evento; ausência, valor inválido, falha ou
coleta parcial não vira zero nem alerta. Comparações são deduplicadas por coleta.
Alertas expiram após 90 dias e relatos após 180 dias.

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

As leituras de Livelo e Sites parceiros do Inter usam acompanhamento pessoal
por padrão; `escopo=global` só é aceito para administradores e mantém a seleção
legada separada da Central.

## Flutter V11

`PaginaAlertas` substitui a folha placeholder e preserva filtro, página e coleta
recebida por deep link de push. A tela cobre loading, vazio, erro, parcial,
offline, lidos/não lidos, paginação e preferências. O menu Conta oferece
Central, Ajuda, Reportar problema e Privacidade. Produtos Inter exibe a ação
pessoal `Acompanhar`, sem alterar a seleção global de lojas.

Após o primeiro login, FCM solicita permissão. Recusar ou indisponibilidade do
Firebase não bloqueia a Central nem o histórico. Logout remove o token atual.

## Critérios de aceite

1. `dart format`, `flutter analyze` e testes unitários/widgets afetados passam.
2. `npm run checar`, testes Vitest direcionados e workflow da outbox passam; testes Python dos
   adaptadores de coleta passam.
3. O protótipo V11 e a tela Flutter mantêm estados e hierarquia nas larguras
   320, 360, 390 e 430 px, em claro e escuro, sem overflow.
4. Migration 023 está aplicada no banco alvo por operação autorizada.
5. APK debug é instalada e as jornadas de login, Central, filtros, leitura,
   preferências, Ajuda, relato, privacidade, links externos e ausência de dados
   são conferidas no Moto G6 Play; o aceite Samsung permanece separado.

## Pendências externas

Conforme confirmação operacional do responsável, a migration 023 foi aplicada
manualmente depois das migrations anteriores e o Firebase `radarbeneficios` está
configurado para a API/Android. Este checkout não executou a SQL nem produziu
evidência independente do banco. Antes do merge na `main`, é necessário
cadastrar `OUTBOX_CRON_SECRET` com o mesmo valor na Vercel em `Production` e em
GitHub Actions; o valor não é enviado pelo chat. Depois, ainda é necessário
executar o workflow, confirmar FCM real, distribuir a APK privada e concluir o
teste manual nos devices.

Este PRD incorpora o plano de implementação; o arquivo de plano histórico foi
removido para não voltar a orientar trabalho já entregue.
