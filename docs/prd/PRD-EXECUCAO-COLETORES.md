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

**Consulta de leitura no M13 — 2026-10-03:** o ADB USB encontrou o Samsung
SM-M135M ligado; o Termux e processos `bash`/`python` também apareceram no
snapshot de processos. `status.sh` e os logs privados não foram lidos: o
`run-as com.termux` foi recusado porque o pacote não é debuggable. Essa
observação não confirma saúde das filas, resultados de slots ou nove execuções
Pichau consecutivas; o gate permanece aberto em [`PENDENCIAS.md`](../PENDENCIAS.md).

**Incidente em 2026-09-27:** o Samsung reiniciou em 26/09 às 15:40 com motivo
`reboot,userrequested`. A Depuração por Wi-Fi ficou desligada. O estado SQLite
local e o log do worker confirmaram sucesso nas agendas Livelo e Inter de 27/09
até 20:10/15:30, respectivamente; as coletas Pichau de 26/09 às 20:30 e de
27/09 às 09:30, 14:30 e 20:30 falharam no preflight com código `34` (ADB Wi-Fi
indisponível), antes de abrir o Chrome. Após reativação manual e `adb tcpip
5555` pelo USB autorizado, `status.sh` confirmou worker, watchdog, filas e
ADB Wi-Fi saudáveis. O disparo manual GitHub `36360364615` enfileirou a
solicitação Pichau `3`, concluída com sucesso na primeira tentativa (execução
`4`, sete páginas, 1.223 itens lidos e únicos, sem recuperação). O status final
confirmou Appium ocioso. Essa execução manual não substitui o gate: a janela de
nove execuções agendadas recomeça.

**Validação sem USB em 2026-09-27:** após a retirada do cabo de dados, o ADB
listou somente o transporte Wi-Fi e o Android permaneceu com a tela bloqueada.
O disparo manual GitHub `36362065611` criou a solicitação Pichau `4`. O worker
abriu Appium e Chrome sem despertar a tela; a fila no Neon confirmou sucesso
na primeira tentativa (execução `5`, sete páginas, 1.223 itens lidos e únicos,
sem recuperação). Essa segunda execução manual confirma o caminho sem USB,
mas também não conta para o gate de nove agendas consecutivas.

**Livelo e Inter em 2026-09-27:** os disparos manuais GitHub `36362885182`
(Livelo) e `36362887421` (Inter), feitos depois da agenda Inter das 21:30,
terminaram com estado `sucesso` na fila do Samsung. A execução Livelo `8`
registrou 255 parceiros e qualidade `completa`; Inter Sites parceiros `8`
registrou 378 lojas lidas e válidas. A execução Inter Compre direto `8`
terminou com estado `sucesso`, mas tinha zero lojas planejadas porque nenhuma
loja direta ativa estava selecionada; portanto não comprova coleta de produtos.
O SQLite local confirmou que as agendas Livelo das
20:10 e Inter das 21:30 já haviam terminado com sucesso antes desses pedidos;
nenhum horário da agenda foi alterado.

**Correção do Compre direto em 2026-09-28:** a lista administrativa autenticada
mostrava as 111 lojas do catálogo, mas nenhuma estava selecionada. No mobile,
Perfil → Administração abria somente a Zona de perigo, então não havia como
habilitar uma loja nessa jornada. A rota passou a abrir a página administrativa
existente; Casas Bahia foi selecionada pela chave do catálogo. Uma nova leitura
da API e a consulta direta somente leitura no banco confirmaram
`selecionada = true` e `ativa = true`. O workflow manual `36373453844` enfileirou
a rodada Inter sem alterar os horários agendados. A fila Android registrou o
pedido `7` com o run ID `36373453844`, uma tentativa e estado `sucesso`. A
execução `9` do banco terminou em sucesso: 1 loja planejada e bem-sucedida, 58
páginas, 2.070 itens lidos, 1.927 produtos únicos, 143 duplicados e qualidade
`completa`. O banco registrou 1.927 produtos ativos e 1.927 medições da
execução às `2026-09-28 03:25:01 UTC`. No Samsung `SM-M135M`, a busca `motorola` na tela
Compre direto retornou 66 ofertas da Casas Bahia e exibiu um cartão com preço e
cashback reais. A agenda permaneceu intacta.

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

Cada processo filho tem prazo finito: Livelo 15 minutos, Inter 50 minutos para
cashback e Compre direto em série e Pichau 20 minutos dentro do lease de 30.
No Android/Linux, o executor inicia cada comando em um grupo de processos; ao
estourar o prazo envia `SIGTERM` e, após cinco segundos sem encerrar, `SIGKILL`
ao grupo para não deixar Chrome/driver órfão. Timeout é falha explícita (`124`
nos executores gerais ou `executor-timeout` na fila Pichau), nunca sucesso
parcial silencioso.

Antes de assumir filas ou pedidos manuais, o worker exige checkout limpo, faz
fast-forward de `origin/main` e confirma que o commit solicitado pertence à
linha de histórico publicada. Depois instala a dependência do runner e grava
`.robo-installed-commit` somente após sucesso. Se o `pip install` falhar, o
próximo ciclo tenta instalar novamente mesmo que o checkout já esteja no SHA
novo. O marcador é local, não versionado, e não contém credenciais.

Quando código ou dependências mudam, o processo antigo não inicia nem reivindica
uma coleta. Ele termina com o status reservado `75`; `worker.sh` libera e
readquire o wake lock e inicia o daemon atualizado uma vez. A solicitação fica
pendente durante esse reinício. Se o novo processo também pedir restart, o
wrapper encerra com erro e o watchdog pode recuperá-lo; não há loop de restart
interno. A Pichau sincroniza antes do claim da fila, então uma atualização não
consome tentativa nem marca o pedido como falha.

Essa recuperação trata falha de instalação, mas a atualização do checkout ainda
é feita no diretório ativo; não equivale a uma troca atômica de releases nem a
rollback automático. A aceitação dessa estratégia deve ser acompanhada no
Samsung e segue pendente; o teste unitário não comprova a instalação real nem o
reinício no Termux.

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

## Runbook de Livelo e Inter

Este roteiro cobre Livelo, Inter Sites parceiros e Inter Compre direto. Os três
coletores escrevem no banco e podem gerar alertas/outbox; usar apenas em uma
execução operacional já autorizada. Não rodar localmente contra Production para
investigar ou fabricar um estado. O fluxo administrativo que escolhe as lojas
Compre direto também não é um disparo de coleta.

### Entradas e comandos

| Domínio | Entrada consultada | Comando do coletor | Limite e comportamento relevante |
|---|---|---|---|
| Livelo | Catálogo público; lojas acompanhadas/apelidos e preferências configuradas | `python -m robo_livelo.principal` | `LIMIAR_PARCEIROS` padrão 150; configuração local via `CAMINHO_CONFIG` |
| Inter Sites parceiros | Catálogo público do Shopping Inter; conjunto `favorita_inter` e `loja_inter` | `python -m robo_inter.principal_inter` | `LIMIAR_LOJAS_INTER` padrão 100 |
| Inter Compre direto | Lojas ativas selecionadas em `loja_direta_inter`; catálogo público de produtos | `python -m robo_inter.principal_produtos_inter` | 36 resultados por página; busca suplementar `smartphone`; pausa de 1,5 s; até três tentativas de rodada quando a contagem fica inconsistente |

Execute os comandos a partir de `backend/robo`, dentro do ambiente virtual e
com as dependências instaladas conforme [`backend/robo/README.md`](../../backend/robo/README.md).
Eles não aceitam seleção de loja como argumento operacional: Compre direto lê a
seleção ativa persistida. Uma falha no coletor de Sites parceiros encerra a
rodada Inter antes de começar Compre direto. A ordem da rodada é fixa: Sites
parceiros, depois Compre direto. Os dados de configuração e banco ficam no
arquivo privado da instalação; não os copiar para o shell gravado, logs, Issue
ou terminal compartilhado.

Variáveis operacionais sem valores secretos:

| Variável | Uso |
|---|---|
| `DATABASE_URL` | Conexão da execução do coletor ou do worker, fornecida pelo ambiente privado |
| `ROBO_DISPATCH_DATABASE_URL` | Secret do GitHub Actions injetado como `DATABASE_URL` apenas para enfileirar o pedido manual |
| `LIMIAR_PARCEIROS`, `LIMIAR_LOJAS_INTER` | Mínimos de integridade Livelo/Inter descritos acima |
| `CAMINHO_CONFIG` | Arquivo TOML local alternativo do coletor Livelo; não é usado pelo fluxo agendado para selecionar lojas |
| `ROBO_GITHUB_REPOSITORY` | Repositório consultado pelo daemon; padrão `lacerdaRodrigo/robo-de-produtos` |
| `ROBO_GITHUB_POLL_SECONDS` | Intervalo de consulta de execuções concluídas; padrão 180 s, intervalo aceito de 120 a 3600 s |
| `ROBO_CELULAR_STATE_FILE`, `PREFIX`, `LOG_LEVEL` | Caminho do estado local, prefixo Termux e nível de log do executor |

O Samsung carrega o ambiente privado do executor; Actions recebe somente o
secret restrito de despacho. Nunca usar `env`, `set -x`, `printenv` ou `cat` no
arquivo de ambiente como diagnóstico, pois isso expõe valores confidenciais.

### Agendamento, despacho e verificação

Os slots locais são Livelo às 09:10, 14:10 e 20:10, e as duas rotinas Inter às
10:30, 15:30 e 21:30, em `America/Sao_Paulo`. A fila consulta o daemon a cada
30 s; uma janela de até 90 s inicia o slot. Não há catch-up para slot perdido.
Execuções manuais dos workflows `robo.yml` e `inter.yml` apenas enfileiram
pedidos; `inter.yml` solicita a rodada completa do Inter, não escolhe entre
Sites parceiros e Compre direto. O worker observa Actions aproximadamente a
cada 180 s. Um run verde confirma o enqueue, não a coleta. Uma nova execução do
workflow cria um novo pedido; não existe retry terminal automático da fila.

Após autorização operacional para um novo disparo, o ponto de entrada é
`workflow_dispatch` em `robo.yml` (Livelo) ou `inter.yml` (rodada Inter). Os
comandos GitHub CLI equivalentes são `gh workflow run robo.yml --ref main` e
`gh workflow run inter.yml --ref main`. Este documento registra o procedimento;
não autoriza dispatch nem reexecução por si só. Evite disparar um workflow só
para “ver se funciona”, pois isso escreve fila, execução, catálogo e, quando
aplicável, notificações.

Verifique a execução nesta ordem, sempre sem imprimir credenciais ou dados
pessoais:

1. `backend/robo/scripts/celular/status.sh`: código 0 indica worker saudável;
   código 2 indica falha operacional/configuração.
2. GitHub Actions: confirme o run ID e que a conclusão significa pedido
   enfileirado, não coleta concluída.
3. Leia a linha correspondente de `coleta_android_fila`: fonte, estado,
   tentativa, `workflow_run_id`, horários e código de falha. Não mostre a URL de
   conexão no mesmo comando.
4. Consulte o log local privado em
   `$PREFIX/var/log/robo-celular/worker.log`; ele tem rotação acima de 5 MiB e
   modo `0600`.
5. Confira a última execução e sua qualidade nas tabelas de domínio abaixo; só
   estado `sucesso` com catálogo publicado confirma a coleta completa.

### Escritas, retries e falhas

| Domínio | Tabelas de execução/publicação | Efeitos adicionais |
|---|---|---|
| Livelo | `execucao`, `parceiro_livelo`, `pontuacao`, vínculo `loja.parceiro_livelo_id` | Eventos/outbox de alerta quando os critérios reais de mudança forem atendidos |
| Inter Sites parceiros | `execucao_inter`, `loja_inter`, `cashback_inter` | Eventos/outbox de alerta quando houver mudança elegível |
| Inter Compre direto | `execucao_produtos_inter`, `execucao_loja_produtos_inter`, `estagio_produto_inter`, `produto_direto_inter`, `medicao_produto_direto_inter` | Remove staging concluído e medições com mais de 30 dias; pode gerar eventos/outbox de preço |

Nenhum desses fluxos usa `oferta_direta_inter_atual`. Falhas do coletor
retornam código 1; sucesso retorna 0. O worker aplica timeout de 15 min a
Livelo e 50 min à rodada Inter inteira. Timeout geral termina em 124; falha ao
iniciar processo, em 127. A fila manual usa lease de uma hora. O worker tem um
único reinício controlado após atualização do checkout (código 75); isso não é
rollback da atualização.

Livelo e os dois adaptadores HTTP do Inter tentam a leitura até três vezes, com
timeout de 30 s e esperas de 2 s e 4 s. Inter repete erro de rede, HTTP 408,
429 e 5xx; outros 4xx falham sem retry. Uma resposta acima de 5 MiB falha sem
retry. Compre direto também repete a rodada até três vezes se os totais de
páginas forem inconsistentes; se nenhum retrato ficar consistente, publica o
melhor retrato como degradado, sem inativar produtos ausentes daquele recorte.
Uma rodada parcial retorna código 1. A fila não reexecuta automaticamente
falha terminal; uma retomada operacional requer novo dispatch autorizado.

### Diagnóstico rápido

| Sintoma | Checagem seguinte |
|---|---|
| Worker indisponível | `status.sh`; confirmar Android ligado, Termux worker e Wi-Fi. Após reboot, seguir a recuperação Samsung documentada acima; o Android não reativa sozinho a Depuração por Wi-Fi |
| Workflow verde sem catálogo novo | Verificar `coleta_android_fila`; workflow verde só confirma enqueue. Depois conferir worker.log e tabelas de execução do domínio |
| Fila sem progresso | Conferir estado/lease, idade do último log e relógio local. Não criar outro pedido até determinar se o anterior ainda está em execução |
| Inter sem execução de produtos | Conferir se Sites parceiros falhou primeiro; as etapas são seriais e uma falha na primeira impede a segunda |
| Compre direto parcial | Conferir estado/qualidade da rodada e páginas/totais. A rodada degradada conserva a última disponibilidade de itens não vistos; não marcar como catálogo completo |
| Segredo ou dado pessoal apareceu no log | Restringir o artefato, removê-lo do canal compartilhado e trocar a credencial exposta conforme o processo do provedor |

As falhas do domínio devem ser diagnosticadas pela execução persistida e pelo
código de falha; não inferir sucesso por quantidade não zero, workflow verde,
campo vazio ou ausência de alerta.

## Pendências do rollout

O schema, as roles e os grants do projeto Neon novo foram provisionados sem
migrar dados. Os catálogos iniciais já foram reconstruídos por coleta; seleções
e demais dados pessoais não reaparecem automaticamente. O corte da API e a
validação autenticada em Production foram concluídos. Resta o gate de nove
execuções Pichau agendadas consecutivas em 72 horas, com tela bloqueada e sem
cabo de dados.
