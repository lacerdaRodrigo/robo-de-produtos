# PRD — Central de Alertas, suporte e privacidade

Status: implementado no contrato e no código; as migrations `023`, `025`, `026`,
`027`, `028` e `029` foram aplicadas manualmente. A migration `036` está
versionada e ainda depende de aplicação operacional antes da publicação desta
mudança. A aplicação da `028` foi confirmada
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
- `notificacao_entrega_alerta` (migration `036`), com estado e tentativas por
  par evento/aparelho, usando as chaves internas sem duplicar o token FCM;
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
- `GET/POST /api/relatos-problema`;
- `GET /api/alertas/{id}/item`;
- `GET /api/alertas/acompanhamentos`;
- `PATCH /api/alertas/acompanhamentos`;
- `PATCH /api/livelo/catalogo/{id_externo}/acompanhamento-pessoal`;
- `PATCH /api/inter/cashback/{id}/acompanhamento`;
- `PATCH /api/inter/produtos/{loja}/{id_externo}/acompanhamento`.
- `PATCH /api/pichau/catalogo/{id_externo}/acompanhamento-pessoal`.

`GET /api/alertas` aceita `pagina`, `por_pagina`, `tipo`, `origem`,
`somente_nao_lidos` e `coleta`. `origem` é opcional e aceita somente os
códigos `inter_cashback`, `inter_produto`, `livelo` e `pichau`; “Todas as
origens” omite o parâmetro. Origem, tipo, leitura e coleta se combinam na
consulta, na contagem e na paginação server-side. O cliente não filtra apenas
os itens da página carregada.

`GET /api/alertas/{id}/item` valida o alerta dentro da conta autenticada e
resolve uma única entidade pelo ID interno, retornando seu DTO de catálogo
existente. Alerta de outra conta, ausente ou associado a entidade removida tem
resposta indistinguível `404`. A rota permanece sem cache.

`GET /api/relatos-problema` exige autenticação sensível, consulta somente os
relatos da conta autenticada e pagina até 50 itens por página. A leitura respeita
a retenção de 180 dias e retorna apenas protocolo, categoria, mensagem e data de
criação. Resposta sem itens é distinta de falha de leitura; o cliente não converte
erro da API em lista vazia. A rota está nesta branch e requer publicação do
serviço API antes da leitura real no aparelho.

As rotas de usuário e administrativas usam Firebase Auth, respeitam App Check
quando o enforcement está ligado, isolam por `usuario_app_id`, paginam e
retornam `x-request-id`. A rota interna do cron usa exclusivamente o Bearer
`OUTBOX_CRON_SECRET`, sem identidade de usuário. Depois de validar App Check
(quando exigido), Firebase Auth, convite e papel, `autenticarRequisicao` aplica
limites persistentes por usuário e operação: até 120 leituras por minuto e 10
operações sensíveis por cinco minutos. Tentativas sem identidade verificada não
escrevem no Neon; negações com identidade verificada e operações sensíveis são
auditadas usando hashes, sem armazenar IP bruto. A proteção volumétrica antes da
autenticação depende do provedor de borda e permanece uma validação operacional
externa. O rollout de referência no Vercel é uma regra para `/api/*`, agrupada
por IP, janela fixa de 60 segundos e limite de 240 requisições por minuto: modo
Log por 24 horas, revisão do tráfego e depois resposta 429. `/api/status` também
entra na regra; a rota interna da outbox roda uma vez por hora. A configuração
continua pendente no painel e não deve ser descrita como ativa antes da
verificação. O `proxy.ts` aplica HTTPS e a allowlist CORS somente a `/api/*`;
origens não autorizadas são recusadas antes dos route handlers. Mensagens/logs
não incluem tokens, URLs de banco ou dados pessoais. A
outbox recupera linhas presas em `enviando` há pelo menos 15 minutos, respeita
preferências e desativa tokens FCM inválidos. O corpo é gerado na API para cada
evento: preço de produto inclui loja, produto e valor; cashback inclui produto
ou loja e percentual; Livelo explicita pontos por real; Pichau identifica o
preço Pix. Os nomes são normalizados e limitados a 48 caracteres. Valores
`NUMERIC` permanecem strings e são formatados em pt-BR. Cada evento elegível
gera uma mensagem por aparelho ativo, preservando o título e as chaves `rota`,
`coleta` e `origem` usados para abrir a Central. O worker tenta até 25 pares
evento/aparelho por execução; o restante fica na outbox para ciclos posteriores.

A migration `036` registra cada entrega por evento/aparelho. Em um retry, apenas
entregas pendentes ou falhas voltam a ser enviadas; uma aceitação FCM já gravada
não é repetida quando outro aparelho falha. Como o FCM e o banco não compartilham
uma transação, uma queda entre o aceite do FCM e a gravação local ainda pode
causar duplicidade. A fila antiga não guardava resultado por aparelho: durante o
cutover, linhas legadas `pendente`, `falha` ou `enviando` são encerradas sem
replay; os eventos permanecem no histórico da Central.

O workflow acorda a API uma vez por hora; o envio real continua no Firebase
Cloud Messaging através do Firebase Admin SDK. Não há limite diário artificial
de notificações.

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

Na tela Flutter `Meu radar`, a composição segue a rota `watching` da V15 e
respeita a área segura superior do Android: cabeçalho `No seu radar` com sino
para abrir alertas, total pessoal em uma linha,
busca com avanço e filtros horizontais `Todos`, `Sites parceiros`, `Compre
direto`, `Livelo` e `Pichau`, nesta ordem. O total permanece independente da
busca e do filtro ativos; o endpoint consultado continua paginado e recebe
`ordenar=recentes`, sem seletor de ordenação na tela. Os cartões exibem apenas
origem, nome, estado, valor textual e URL devolvidos pela API; o botão
`Acompanhando` mantém a remoção reversível, e o link externo só aparece quando
há URL válida. Não há cartão separado para a Central: o sino é o acesso aos
alertas. Valores, datas, condições e categorias ausentes no payload não são
inventados pelo cliente.

`GET /api/resumo` sempre recebe o ID da identidade autenticada, inclusive para
quem tem papel `admin`; o bloco `livelo`, `cashback_inter` e o recorte de `radar`
representam acompanhamentos pessoais. A seleção global legada não vira o
acompanhamento de administrador no aplicativo. O endpoint acrescenta o bloco
pessoal `radar`, com total, recorte por
origem, alertas não lidos e o destaque mais recente. O destaque usa o mesmo
contrato textual de valores e URL segura; `atividade_recente` permanece apenas
para clientes antigos. A migration `029_indices_mobile_v15.sql` é aditiva e
foi aplicada pelo responsável fora de transação, em conexão direta.

O bloco `radar.destaque` continua disponível para a Central e para integrações,
mas a Home compacta não o renderiza como cartão de alerta. O acesso aos eventos
permanece no sino do cabeçalho e na Central de Alertas.

A Home Flutter consulta o resumo na abertura, por atualização explícita e quando
o app retorna do segundo plano se o último sucesso tiver mais de cinco minutos.
Enquanto os dados ainda estão frescos, voltar ao app não gera consulta. A Home
não faz polling a cada 30 segundos; o prazo local é apenas cache em memória e
não altera a agenda nem a validade das coletas persistidas.

Na Home compacta, o trilho `Explore as origens` rola de ponta a ponta com
respiro interno de 20 dp. Cada atalho ocupa 43% da largura disponível, com
mínimo de 132 dp, e cresce pela escala de texto sem truncar a descrição.

`usuario_app.ultimo_acesso_em` só é atualizado no primeiro vínculo, quando o
e-mail verificado muda ou após 24 horas. Auditoria técnica é retida por 30 dias;
baldes de limite sem uso são removidos após 24 horas pelo cron interno horário.
As tabelas legadas de tentativas de login permanecem no schema por ora, mas não
são o mecanismo ativo de autenticação/rate limit.

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
`Filtrar mudanças` combina Origem (`Todas as origens`, `Sites parceiros`,
`Compre direto`, `Livelo`, `Pichau`) e Tipo de mudança (`Todos`, `Preço`,
`Cashback`, `Pontos`); esses filtros permanecem independentes das abas
`Todos`/`Não lidos`. O mapeamento é `Sites parceiros` → `inter_cashback`,
`Compre direto` → `inter_produto`, `Livelo` → `livelo` e `Pichau` → `pichau`.

`Marcar todos como lidos` percorre as páginas do recorte atual com `por_pagina`
limitado a 50 e envia lotes de no máximo 100 IDs para o `PATCH /api/alertas`.
O recorte inclui abas de leitura, origem, tipo e coleta. Falhas restauram os
itens e a contagem que estavam visíveis antes da tentativa.
`Ver item` marca o alerta como lido e solicita `GET /api/alertas/{id}/item`.
A rota autentica a conta, confere o vínculo entre o alerta e `usuario_app_id` e
resolve somente a entidade apontada por `entidade_id`, retornando um dos quatro
DTOs de catálogo já existentes. Não baixa um catálogo completo. A tela de
detalhe é empilhada sobre a Central; voltar pelo cabeçalho ou pelo sistema
retorna à lista com filtros, página e posição preservados. Alerta ou entidade
removidos recebem o mesmo `404` e usam o fallback para a área de origem. Falha
de rede ou resposta 5xx mantém a Central aberta e oferece nova tentativa; não é
tratada como item ausente. Quando a leitura já foi confirmada, a nova tentativa
repete somente a resolução do item e não envia outro `PATCH` de leitura.

O DTO Pichau atual não fornece CPU, GPU, RAM ou armazenamento mostrados como
exemplos no detalhe ilustrativo do HTML. A tela usa apenas os campos reais
disponíveis no contrato Pichau (SKU, marca/categoria, preço, disponibilidade,
parcelamento e etiquetas); dados ausentes não são preenchidos com os exemplos do
protótipo. Em Compre direto e Pichau, disponibilidade/estoque ausente é exibido
como `Disponibilidade não informada`, nunca como `Disponível`; estoque zero
continua sendo `Esgotado`.

A rota compacta mantém a barra inferior V15 visível e seleciona o destino de
origem da Central (por exemplo, Início quando aberta pelo sino da Home ou Perfil
quando aberta pelas preferências da conta). Tocar qualquer um dos quatro destinos
fecha a Central e seleciona a área correspondente na moldura existente, sem
duplicar a rota; o botão/gesto Android mantém o destino de origem. O Perfil segue
os grupos clicáveis do protótipo: Acompanhamentos, Aparência e Notificações na
conta; Ajuda, Relatar problema, Meus relatos e Privacidade no suporte; e saída
da sessão após confirmação. A identificação usa os dados reais da sessão; o
nome ilustrativo do HTML não é copiado para a conta. A contagem de
Acompanhamentos vem de `GET /api/resumo` e apresenta indisponibilidade sem
substituir a falha por zero. A descrição de Notificações reflete `push_global`
de `GET /api/alertas/preferencias`; ela informa o estado da preferência sem
afirmar que a permissão de notificações do aparelho está concedida. A Central é
aberta pelo sino da Home ou pelas preferências de Notificações. Administração
continua restrita ao papel autorizado. Livelo,
Banco Inter e Pichau são subáreas de Explorar. O botão/gesto de voltar do Android
em Explorar retorna para Início. Produtos Inter exibe a ação pessoal
`Acompanhar`, sem alterar a seleção global de lojas.

No Flutter, Perfil segue o cabeçalho V15 e agrupa os atalhos de conta e suporte
em superfícies planas, mostrando apenas a identificação recebida da sessão. A
tela Aparência apresenta seguir o sistema, claro e escuro, marca a opção ativa
com borda e superfície de acento e mantém o controle de redução de movimento
ligado à preferência local existente. O layout amplo permanece claro e as
barras do sistema acompanham o tema efetivo. Ajuda usa perguntas
expansíveis com respostas baseadas nos contratos atuais; Privacidade descreve
retenção e direitos com os fatos disponíveis no produto, sem reproduzir o texto
demonstrativo do protótipo nem apresentar uma conta pessoal como canal oficial.
Ajuda e Privacidade oferecem acesso ao formulário existente; Meus relatos exibe
os registros reais devolvidos pela API, formata suas datas em pt-BR, permite
copiar o protocolo, paginar e iniciar um novo relato. O avatar demonstrativo é
decorativo; o item acessível do Perfil anuncia o cumprimento e a identificação
real sem expor as iniciais do avatar. O formulário segue as cinco categorias V15 (`catalog`,
`access`, `notification`, `privacy`, `other`) e aceita descrições de 10 a 2.000
caracteres. O POST retorna o ID real do protocolo; após sucesso, o app abre Meus
relatos com o comprovante retornado pela API enquanto atualiza a lista. A API
preserva os quatro códigos legados já salvos, e a migration 035 amplia o CHECK
do banco para novos registros V15 sem reescrever dados existentes. As telas
secundárias preservam o retorno visível e usam a pilha existente: o back Android
fecha primeiro a rota aberta; o shell só muda para Início quando nenhuma rota
secundária está acima dele.
No compacto, Aparência,
Notificações, Ajuda, Privacidade, Meus relatos e Relatar problema mantêm a barra
inferior V15. Trocar de destino nessa barra encerra todas as rotas
secundárias abertas a partir da conta antes de selecionar a aba, inclusive
quando o formulário foi aberto por Ajuda ou Privacidade.
Esses testes de widget não substituem a conferência manual no Samsung SM-M135M
(M13).

Quando a Central é aberta como rota secundária, o botão `Voltar` do cabeçalho e
o botão/gesto de voltar do Android fazem o mesmo `pop` para a tela anterior,
preservando o estado da moldura e sem criar uma nova instância da Central.

A rota `Notificações` apresenta as quatro preferências reais recebidas por
`GET /api/alertas/preferencias`; cada alternância envia um `PATCH` serializado,
atualiza a opção de forma otimista e restaura o valor anterior com mensagem de
erro se a gravação falhar. `Rever permissão do aparelho` abre uma folha V15;
`Agora não` fecha a folha e `Permitir` solicita a permissão real do sistema.
Recusar mantém a Central e o histórico disponíveis.

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

Conforme confirmação operacional do responsável, as migrations da Central
indicadas no status acima foram aplicadas manualmente e o Firebase
`radarbeneficios` está configurado para a API/Android. A verificação de produção
em 2026-09-13 confirmou a `028` em modo somente leitura, incluindo
`SECURITY DEFINER`, `search_path` fechado e execução para `pichau_publisher`. A
coleta `34761933582` passou com qualidade
completa, sem `pichau-banco`, mas não houve mudança de preço para gerar evento.
O merge, deploy, APK e secret do cron foram confirmados; ainda falta produzir um
evento real, observar sua entrega FCM e instalar/conferir a APK nos devices para
o aceite manual completo.

Para esta mudança, a migration `036` precisa ser aplicada por operação autorizada
antes de publicar o código da API. Suspenda o processamento da outbox durante a
aplicação para evitar concorrência com a fila legada; valide a tabela e os grants
de `robo_api`, depois publique a API e observe uma mudança natural. Este ciclo
não aplica a migration nem publica a API.

Este PRD incorpora os contratos implementados. O checkpoint operacional de
migration, publicação e reteste físico está no
[`PRD-ACEITE-MOBILE-V15.md`](PRD-ACEITE-MOBILE-V15.md); a lista viva de
bloqueios e próximas ações está em [`../PENDENCIAS.md`](../PENDENCIAS.md).
