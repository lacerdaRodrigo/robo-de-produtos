# PRD — Execução local dos coletores no Samsung e filas Neon

**Status em 2026-09-26:** arquitetura e código preparados neste branch. O novo
projeto Neon recebeu o schema `001`–`026` e `028`–`032`; a migration `027`, que
faz backfill de dados antigos, foi intencionalmente omitida. Nenhum dado foi
migrado: usuários, catálogo e históricos seguem vazios. Os grupos e grants por
consumidor existem; os logins distintos permanecem `NOLOGIN` até a ativação
segura. O Samsung não foi instalado e API, Actions e Termux ainda não foram
apontados ao destino.

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

## Credenciais e segurança

- `ROBO_DISPATCH_DATABASE_URL`: secret do Actions usado apenas para solicitar
  coletas Livelo/Inter; pertence a um login associado ao grupo
  `robo_dispatcher`, que só executa a função de solicitação.
- `PICHAU_DISPATCH_DATABASE_URL`: secret existente/renovado para o dispatcher
  Pichau, sem fallback para um `DATABASE_URL` amplo.
- `DATABASE_URL`: arquivo privado `/etc/robo-celular/env` no Termux. O login do
  telefone precisa publicar os domínios e a fila Pichau e receber associação ao
  grupo `robo_executor` para reivindicar/finalizar a fila genérica.
- A API Production continua usando seu próprio secret `DATABASE_URL` na Vercel.
  A atualização para o projeto Neon de destino precisa ser feita separadamente.

No destino novo, as migrations `001`–`026` e `028`–`032` já foram aplicadas e
os grupos `robo_dispatcher NOLOGIN` e `robo_executor NOLOGIN` foram criados. A
`027` não foi executada: ela transfere seleções/eventos legados, não estrutura,
e não faz parte de uma instalação vazia. As roles de login `radar_api`,
`radar_actions_robo`, `radar_actions_pichau` e `radar_samsung` foram criadas sem
login e associadas aos grupos previstos. Falta provisionar senhas fora do
repositório, ativar os logins e provar que as permissões efetivas correspondem
à separação prevista. A API não recebe acesso às filas; o coletor não recebe
acesso às tabelas pessoais. Nunca colocar strings de conexão reais no Git,
logs, Issues públicas ou neste documento.

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

## Não realizado pelo código

O schema, as roles e os grants do projeto Neon novo foram provisionados sem
migrar dados. Permanecem pendentes: ativar e testar logins, atualizar os secrets
GitHub/Vercel/Termux, instalar o checkout no Samsung, validar o job 7301 e
observar execuções reais. Após o corte, catálogos e históricos precisam ser
recriados por coletas; seleções e demais dados pessoais não reaparecem
automaticamente.
