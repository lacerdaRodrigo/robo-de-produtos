# Scripts Pichau

- `run.sh`: valida ambiente Android/ADB Wi-Fi, inicia Appium sob demanda,
  executa uma coleta Pichau e restaura o estado do Chrome/tela ao final.
- `appium.sh [start|stop|status]`: gerencia a sessão local em `127.0.0.1`.

Execução agendada parte de `robo_celular` no Samsung; disparos manuais entram
pela fila Pichau do Neon e são reivindicados pelo mesmo worker. O arquivo
privado é `PREFIX/etc/robo-celular/env`; não publicar IP, porta ou credencial.
Veja [`PRD-PICHAU.md`](../../../../docs/prd/PRD-PICHAU.md) antes de
operar ou atualizar o aparelho.
