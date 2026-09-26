# `migracoes/` — Schema do Postgres (Neon)

Migrações SQL **aplicadas manualmente** no Postgres (Neon). Cada arquivo é
idempotente e numerado na ordem em que evoluiu o schema.
`backend/robo/scripts/livelo/carregar_catalogo.py`
cria o `001` e carrega o catálogo.

## Migrações

| Arquivo | Cria/altera | Domínio |
|---|---|---|
| `001_esquema.sql` | `loja`, `apelido`, `preferencia` | Livelo catálogo |
| `002_execucao.sql` | `execucao`, `pontuacao` (retrato) | Livelo site |
| `003_tentativa_login.sql` | `tentativa_login` | autenticação do site legado |
| `004_disparo_manual.sql` | `disparo_manual` (trava 5 min) | site → robô |
| `005_descricao_campanha.sql` | `pontuacao.descricao_campanha` | Livelo |
| `006_inter.sql` | `loja_inter`, `favorita_inter`, `cashback_inter`, `execucao_inter` | Inter V3 |
| `007_produtos_inter.sql` | lojas/execuções/produtos/medições do Compre direto | V4 |
| `008_contrato_real_produtos_inter.sql` | colunas de texto de preço/desconto | V4 |
| `009_coleta_degradada_produtos_inter.sql` | `qualidade`, `tentativas`, totais | V4 |
| `010_autenticacao_app.sql` | `usuario_app`, `auditoria_app` (Firebase) | app (API) |
| `011_disparos_api_idempotentes.sql` | `solicitacao_disparo_app` (cooldown API) | app (API) |
| `012_oferta_direta_inter_atual.sql` | `oferta_direta_inter_atual` (limpeza V5) | V4 |
| `013_catalogo_livelo.sql` | catálogo completo e vínculo opcional com `loja` | Livelo |
| `014_alerta_no_card.sql` | alerta calculado no retrato atual | Livelo |
| `015_historico_catalogo_livelo.sql` | identidade da medição por parceiro e índice do histórico completo | Livelo |
| `016_preserva_historico_livelo.sql` | separa acompanhamento da identidade histórica | Livelo |
| `017_qualidade_livelo.sql` | registra RN29 sem substituir o último snapshot completo | Livelo |
| `018_categorias_produtos_inter.sql` | taxonomia Radar e classificação auditável de categorias | Inter produtos (histórico) |
| `019_classificacao_exata_categorias_produtos_inter.sql` | semeia somente mapeamentos por igualdade exata | Inter produtos (histórico) |
| `020_categorias_inter_fonte_oficial.sql` | substitui a taxonomia Radar por categorias externas exatas do Inter | Inter produtos |
| `021_pichau_pc_gamer.sql` | catálogo/histórico persistido de PCs Gamer | Pichau |
| `022_pichau_android_fila.sql` | fila idempotente do executor Android | Pichau |
| `023_alertas_suporte_privacidade.sql` | acompanhamentos pessoais, eventos, preferências, tokens FCM, outbox e relatos | Central de Alertas/app |
| `024_pichau_android_diagnostico.sql` | diagnóstico JSONB seguro e limitado na fila Android | Pichau |
| `025_pichau_acompanhamento.sql` | seleção administrativa idempotente de produtos acompanhados | Pichau/API |
| `026_alertas_pichau_pessoal.sql` | origem Pichau na Central, push controlado e geração após coleta completa | Alertas/Pichau |
| `027_backfill_alertas_sem_push.sql` | ponte das seleções legadas para a conta pessoal e recuperação Inter | Operação/Alertas |
| `028_permissoes_alertas_pichau.sql` | função segura para o publicador Pichau gravar alertas sem grants pessoais amplos | Operação/Alertas |
| `029_indices_mobile_v15.sql` | índices para lista consolidada de acompanhamentos e destaque não lido | Mobile V15/Alertas |
| `030_categorias_cashback_inter.sql` | taxonomia editorial dos Sites parceiros | Inter Cashback |
| `031_fila_coletas_android.sql` | fila idempotente de pedidos manuais Livelo/Inter, leases e funções com grants separados | Executor Android |
| `032_permissoes_consumidores_neon.sql` | roles distintas para API, Actions e Samsung; isolamento das filas e dados pessoais | Segurança/Neon |

## Onde são usadas

- Robôs: `001`–`009`, `013`–`022`, `024`, `026`, `028` e `031` (coleta Livelo/Inter/produtos, histórico, categorias, Pichau, alertas e fila manual).
- API do app: `010`–`020`, `023`, `025` e `026` (autenticação, disparos, catálogos, acompanhamentos e Central de Alertas).
- Operação: `027` (ponte inicial das seleções legadas e recuperação sem push).
- Segurança dos consumidores: `032` (grants mínimos para API, Actions e Samsung).

## Destino Neon novo — 2026-09-26

O projeto de destino foi preparado como banco vazio, sem importar dados do
projeto anterior. Foram aplicadas `001`–`026` e `028`–`032`; a `027` foi
intencionalmente pulada porque é um backfill de seleções/eventos antigos e exige
uma conta ativa. A `029` foi executada em conexão direta, fora de transação,
como exige `CREATE INDEX CONCURRENTLY`.

A verificação encontrou 39 tabelas, as quatro funções da fila Android, os dois
índices V15 e os grants de execução esperados. As roles de grupo
`pichau_publisher`, `pichau_dispatcher`, `robo_dispatcher` e `robo_executor`
foram criadas como `NOLOGIN`. A migration `032` cria `robo_api` e
`robo_coletor`, associa `radar_api`, `radar_actions_robo`,
`radar_actions_pichau` e `radar_samsung` aos grupos corretos e concede somente
os acessos documentados. Os quatro logins foram ativados e validados por
conexões direta e pooled; as credenciais não ficam no repositório. O banco tem
somente o convite admin inicial, sem UID Firebase; execuções, pontuações e
catálogos continuam vazios. A API Production e o Samsung ainda não foram
cortados para este destino.

## Histórico do projeto Neon anterior

> **Importante:** aplicar migração em produção é ação explícita e separada — nunca
> feita automaticamente pela organização de pastas. As confirmações a seguir
> descrevem o projeto Neon anterior; não representam o estado do destino novo.
> A `028` corrige a permissão do publicador para alertas Pichau, e a verificação
> somente de leitura de 2026-09-13 confirmou a definição segura das funções e a
> execução autorizada pelo `pichau_publisher`.

`023` foi aplicada manualmente no banco alvo. Este checkout não executou a SQL
nem produziu evidência independente; a confirmação operacional permanece
externa ao repositório.

`024` depende somente de `022` e não aplica nem exige a `023`. Em 2026-09-10,
ela foi validada numa branch temporária derivada de `production`: coluna e
constraints válidas, 47 linhas antigas compatíveis com `{}` e grants existentes
de `pichau_dispatcher` (`SELECT/INSERT`) e `pichau_publisher`
(`SELECT/UPDATE`) preservados. A branch foi descartada sem alterar
`production`. Depois da confirmação do responsável, a migration foi aplicada
em `production`; a verificação somente de leitura confirmou os mesmos
resultados nas 47 linhas existentes.

`025` depende de `021` e adiciona a seleção administrativa legada
`pichau_produto.acompanhada`. `026` depende de `023` e `025`, libera a origem
Pichau na Central, controla o push e gera alertas somente após coleta completa.
`027` depende de `026`, exige uma única conta ativa e foi executada uma vez para
criar os acompanhamentos Livelo/Pichau e recuperar o recorte Inter sem outbox.
Em 2026-09-13, a verificação somente de leitura confirmou 10 acompanhamentos
Livelo, 16 Pichau, 37 Produtos Inter, dois eventos Inter recuperados com
`notificar_push = false` e nenhuma outbox pendente.

`028` depende de `026` e torna o gerador de alertas Pichau e o trigger da outbox
`SECURITY DEFINER`, com `search_path` fechado, para que `pichau_publisher` possa
gerar alertas sem receber acesso direto às tabelas pessoais da Central. A
execução manual `34759635491` confirmou que, sem essa migration, a coleta chega
à publicação e termina como `pichau-banco` por falta de privilégio nas tabelas
de alertas. Após a aplicação, a execução `34761933582` passou com a fila 70 e a
execução 58 em qualidade completa, com 1.180 itens lidos/únicos e zero
duplicados. Como não houve mudança de preço, não houve evento ou outbox novo;
isso mantém pendente apenas a prova de um evento real e de sua entrega FCM.

`029` depende de `023` e `026`, usa índices concorrentes aditivos para o Mobile
V15 e foi aplicada/verificada pelo responsável no ambiente informado.

`030` depende do schema do Inter. Ela foi aplicada no destino novo, que ainda não
tem lojas para classificar; no projeto anterior, a aplicação e classificação
continuam pendentes conforme `docs/PENDENCIAS.md`.

`031` adiciona uma fila separada para pedidos manuais Livelo e Inter; não move
nem apaga catálogos ou históricos. Ela foi aplicada no destino novo. Os grupos
`robo_dispatcher NOLOGIN` e `robo_executor NOLOGIN` já existem, mas ainda é
necessário associar logins distintos: `ROBO_DISPATCH_DATABASE_URL` usa o
primeiro; o login privado do Samsung recebe o segundo, além dos privilégios já
exigidos pelos coletores e pela fila Pichau. O destino permanece vazio e não
deve receber tráfego até que esses acessos e cada consumidor sejam configurados
e verificados separadamente.
