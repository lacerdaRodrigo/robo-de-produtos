# Scripts do executor celular

- `boot.sh`: valida a configuração privada, instala o watchdog e assume o
  processo foreground do worker no boot.
- `worker.sh [--daemon|--once]`: inicia o daemon único ou executa um ciclo de
  diagnóstico/agenda. O lock impede instâncias concorrentes.
- `worker-once.sh`: adaptador para Termux:API Job Scheduler.
- `schedule-watchdog.sh`: registra o job 7301 para recuperação a cada 15 min;
  o watchdog não consulta o banco nem agenda coletas.
- `recover.sh`: tenta recuperar o mesmo worker.
- `status.sh`: verifica checkout, arquivo privado, worker, watchdog, fila e ADB
  sem imprimir valores secretos.

O worker lê `PREFIX/etc/robo-celular/env` (aceita os caminhos históricos
`ROBO_ENV_FILE`, `PICHAU_ENV_FILE` e `PREFIX/etc/robo-pichau/env`). O arquivo deve
ser do usuário do Termux e ter modo `0600` ou `0400`. `DATABASE_URL` é
obrigatória; `ROBO_GITHUB_REPOSITORY`, `ROBO_GITHUB_POLL_SECONDS` e
`ROBO_CELULAR_STATE_FILE` são opcionais. Não grave credenciais neste README.

A grade fica em `robo_celular.agenda`; não configure crons separados no
Android. Após reboot, siga o procedimento Samsung Android 14 em
[`docs/prd/PRD-EXECUCAO-COLETORES.md`](../../../../docs/prd/PRD-EXECUCAO-COLETORES.md)
e no PRD Pichau. Tela bloqueada não equivale a aparelho desligado.
