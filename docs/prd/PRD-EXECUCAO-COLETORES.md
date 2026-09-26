# PRD — Execução local dos coletores no Samsung e filas Neon

**Status em 2026-09-26:** código mergeado na `main` pelos PRs #42 e #45 após CI
verde e publicado como `1.73.1`. O novo
projeto Neon recebeu o schema `001`–`026` e `028`–`032`; a migration `027`, que
faz backfill de dados antigos, foi intencionalmente omitida. Os quatro logins
foram validados, os secrets de dispatch já apontam ao destino novo e o Samsung
usa `radar_samsung` no arquivo privado. O worker, o boot e o watchdog 7301 estão
ativos e saudáveis. Três disparos manuais reais reconstruíram 255 parceiros
Livelo, 378 lojas Inter, 111 lojas do Compre direto e 1.223 produtos Pichau; as
execuções terminaram com sucesso e a Pichau publicou sete páginas sem duplicados.
A Vercel recebeu `radar_api` em Production e publicou a versão nova; o status
público ficou saudável, a outbox executou com sucesso e o aplicativo autenticado
leu do destino novo os catálogos Livelo (255), Inter Sites parceiros (378) e
Pichau (1.223). O banco e a credencial antigos seguem disponíveis por sete dias
para rollback.

Este documento é o contrato operacional comum de Livelo, Inter Sites parceiros,
Inter Compre direto e Pichau. As regras de extração e publicação continuam nos
PRDs de cada domínio; aqui ficam o agendamento, o despacho, as credenciais e a
recuperação.

## Decisão de arquitetura

O Neon continua sendo o banco dos catálogos, históricos e filas. O Samsung é um
executor dedicado, não o banco nem um servidor com disponibilidade garantida.
O GitHub Actions deixa de executar coletas agendadas e de esperar pela execução
do aparelho: os workflows de domínio ficam manuais e apenas enfileiram pedidos.

```text
Agendamento local ──────────────────────────────┐
Disparo manual → GitHub Actions → fila no Neon ─┼→ worker único no Samsung
                         GitHub Runs API ←──────┘       ├─ Livelo
                                                        ├─ Inter Cashback → Produtos
                                                        └─ Pichau
```

O daemon verifica o relógio local a cada 30 segundos e consulta a API pública de
execuções do GitHub a cada 180 segundos (configurável entre 120 e 3600), usando
ETag e limitando-se a `workflow_dispatch` concluídos com sucesso. Isso equivale
a cerca de 20 consultas por hora no padrão e mantém margem para a API pública
anônima mesmo na configuração mais rápida. O Android não guarda
token GitHub. O Neon não é consultado em loop ocioso: há acesso no boot para
drenar filas já aceitas, quando uma execução manual concluída é identificada,
nos horários de coleta e durante a publicação. A outbox da API é independente e
roda pelo workflow próprio uma vez por hora.

O SQLite no telefone contém somente chaves idempotentes de agenda, ETag e IDs de
execuções GitHub já tratadas. Não armazena catálogo nem histórico comercial; o
arquivo fica em `PREFIX/var/lib/robo-celular/estado.sqlite3`, com modo `0600`.

## Grade e concorrência

Todos os horários usam `America/Sao_Paulo`. As coletas são seriais: um coletor
não inicia enquanto outro estiver usando o executor.

| Fonte | Horários locais |
|---|---|
| Livelo | 09:10, 14:10 e 20:10 |
| Pichau | 09:30, 14:30 e 20:30 |
| Inter Sites parceiros e Compre direto | 10:30, 15:30 e 21:30 |

O slot só inicia até 90 segundos depois do horário. Um aparelho desligado,
worker parado ou rede indisponível não causa coleta retroativa: o slot perdido é
ignorado. A chave fonte/data/horário impede duplicação local. Uma execução
interrompida permanece registrada como iniciada, nunca como sucesso; uma nova
tentativa manual é explícita.

As duas rotinas do Inter preservam a separação de domínio e executam em série:
cashback primeiro, produtos depois. Falha na primeira encerra a rodada Inter;
falha na segunda não transforma a coleta de cashback em coleta de produtos nem
recomeça a primeira silenciosamente. Pichau continua usando seu runner Android,
fila existente, leases e ciclo de navegador.

## Disparos manuais e significado do status

`robo.yml`, `inter.yml` e `pichau.yml` não têm cron. Ao acioná-los manualmente,
o Actions grava um pedido idempotente no Neon e termina. O worker associa o
`workflow_run_id` à fila e executa quando o telefone estiver disponível. Assim,
um workflow verde confirma apenas o enfileiramento; sucesso ou falha da coleta
devem ser verificados no estado da fila, nos logs locais e na última execução
persistida pelo domínio. Pedidos aceitos não expiram só porque o celular estava
desligado.

Para Livelo e Inter, `migracoes/031_fila_coletas_android.sql` cria a fila e
funções com `SECURITY DEFINER`, `search_path` fechado, deduplicação por fonte e
ID de execução, claim atômico e lease de uma hora. Os coletores finalizam a
linha como sucesso ou falha. Pichau mantém a fila 022 já existente e o lease de
30 minutos; o workflow deixa de fazer polling e de converter demora em falha.

Na primeira inicialização, o worker drena pedidos persistidos antes de gravar o
baseline de IDs do GitHub. Isso permite recuperar pedidos mais antigos do que a
página pública de 100 execuções. Execuções ainda em andamento não são tratadas
como pedido concluído pela API.

## Organização do backend

| Pasta | Responsabilidade |
|---|---|
| `src/robo_celular/` | Agenda, daemon, estado SQLite, cliente GitHub e filas manuais |
| `src/robo_livelo/` | Coleta e regras Livelo |
| `src/robo_inter/` | Cashback e Compre direto, sem importar o pacote Livelo |
| `src/robo_pichau/` | Coleta, publicação e fila Android Pichau |
| `src/robo_compartilhado/` | Versão semântica comum |
| `scripts/celular/` | Boot, worker, watchdog, recuperação e status do Termux |
| `scripts/livelo/` | Utilitário do catálogo Livelo |
| `scripts/inter/` | Ferramentas Inter, incluindo medição sem escrita |
| `scripts/pichau/` | Runner e Appium Android |
| `testes/{celular,livelo,inter,pichau}/` | Testes por domínio; `testes/conftest.py` permanece compartilhado |

Os nomes antigos dos scripts Pichau na raiz de `scripts/` permanecem como links
de compatibilidade com Termux:Boot e instalações já existentes. Novos comandos
e documentação usam os caminhos organizados.
Os três pacotes de domínio exportam a versão de `robo_compartilhado`, e a
dependência `tzdata` garante que a agenda de Brasília carregue no Python do
Termux mesmo quando o sistema não fornece a base IANA.

## Credenciais e segurança

- `ROBO_DISPATCH_DATABASE_URL`: secret do Actions atualizado para
  `radar_actions_robo`, que só executa a função de solicitação Livelo/Inter.
- `PICHAU_DISPATCH_DATABASE_URL`: secret do Actions atualizado para
  `radar_actions_pichau`, que só lê/enfileira pedidos Pichau.
- `DATABASE_URL`: arquivo privado `/etc/robo-celular/env` no Termux. O login do
  telefone precisa publicar os domínios e a fila Pichau e receber associação ao
  grupo `robo_executor` para reivindicar/finalizar a fila genérica.
- A API Production usa seu próprio secret `DATABASE_URL` na Vercel, com o login
  restrito `radar_api` do projeto Neon de destino.

No destino novo, as migrations `001`–`026` e `028`–`032` já foram aplicadas e
os logins `radar_api`, `radar_actions_robo`, `radar_actions_pichau` e
`radar_samsung` estão ativos, associados aos grupos previstos e validados por
conexões direta e pooled. A `027` não foi executada: ela transfere
seleções/eventos legados, não estrutura, e não faz parte de uma instalação
vazia. A API não recebe acesso às filas; o coletor não recebe acesso às tabelas
pessoais. A variável de Production da Vercel foi atualizada para `radar_api` e
validada depois do deploy por status público, execução da outbox e leitura
autenticada dos três catálogos no aplicativo. O ADB do Samsung está autorizado
por USB e validado também pelo transporte Wi-Fi interno. Nunca colocar strings de
conexão reais no Git, logs, Issues públicas ou neste documento.

## Operação e aceite

O Samsung deve ficar dedicado, carregando, no Wi-Fi privado, com Termux,
Termux:API e Termux:Boot sem otimização agressiva de bateria. O worker
foreground e watchdog 7301 recuperam processos enquanto o Android está ligado;
não garantem religar o aparelho nem reativar Depuração por Wi-Fi após reboot.
Após reboot, vale o procedimento Samsung Android 14 documentado no
[`PRD-PICHAU.md`](PRD-PICHAU.md): ligar, primeiro desbloqueio, reativar
Depuração por Wi-Fi, parear/reativar por USB autorizado e então remover o cabo.

O gate operacional continua sendo nove execuções Pichau agendadas consecutivas
em 72 horas, com tela bloqueada e sem abrir o Termux. Uma falha reinicia essa
janela. Isso não substitui a checagem manual inicial de que Livelo e as duas
rotinas Inter também executaram e publicaram estados corretos.

## Pendências do rollout

O schema, as roles e os grants do projeto Neon novo foram provisionados sem
migrar dados. Os catálogos iniciais já foram reconstruídos por coleta; seleções
e demais dados pessoais não reaparecem automaticamente. O corte da API e a
validação autenticada em Production foram concluídos. Resta o gate de nove
execuções Pichau agendadas consecutivas em 72 horas, com tela bloqueada e sem
cabo de dados.
