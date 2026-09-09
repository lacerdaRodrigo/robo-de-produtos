#!/data/data/com.termux/files/usr/bin/bash

# Copiar para $PREFIX/../home/.termux/boot/ depois de revisar o caminho do
# repositorio. O clone recomendado fica em $PREFIX/opt/robo.
# O Appium local, o worker persistente e o watchdog sao recriados no boot. A
# coleta só acontece quando o GitHub Actions cria uma solicitação na fila.
set -Eeuo pipefail
umask 077

TERMUX_PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
REPO_ROOT="${PICHAU_REPO_ROOT:-$TERMUX_PREFIX/opt/robo}"
APPium="$REPO_ROOT/backend/robo/scripts/pichau-android-appium.sh"
SCHEDULE="$REPO_ROOT/backend/robo/scripts/pichau-android-schedule.sh"
WORKER="$REPO_ROOT/backend/robo/scripts/pichau-android-worker.sh"
WORKER_ONCE="$REPO_ROOT/backend/robo/scripts/pichau-android-worker-once.sh"
LOG_DIR="$TERMUX_PREFIX/var/log/robo-pichau"
BOOT_LOG="$LOG_DIR/boot.log"

mkdir -p "$LOG_DIR"
chmod 700 "$LOG_DIR"
touch "$BOOT_LOG"
chmod 600 "$BOOT_LOG"
exec >> "$BOOT_LOG" 2>&1
echo "$(date --iso-8601=seconds) inicio boot Pichau Android"

[[ -x "$APPium" ]] || {
    echo "pichau-android-boot: Appium nao executavel: $APPium" >&2
    exit 1
}
[[ -x "$SCHEDULE" ]] || {
    echo "pichau-android-boot: agendador nao executavel: $SCHEDULE" >&2
    exit 1
}
[[ -x "$WORKER" ]] || {
    echo "pichau-android-boot: worker nao executavel: $WORKER" >&2
    exit 1
}
[[ -x "$WORKER_ONCE" ]] || {
    echo "pichau-android-boot: worker de uma rodada nao executavel: $WORKER_ONCE" >&2
    exit 1
}

CONFIG_FILE="${PICHAU_ENV_FILE:-${PREFIX:-/data/data/com.termux/files/usr}/etc/robo-pichau/env}"
if [[ -f "$CONFIG_FILE" ]] && grep -q '^DATABASE_URL=.' "$CONFIG_FILE"; then
    WORKER_SESSION="${PICHAU_WORKER_SESSION:-robo-pichau-worker}"
    if tmux has-session -t "$WORKER_SESSION" 2>/dev/null; then
        echo "$(date --iso-8601=seconds) worker ja estava ativo"
        :
    else
        tmux new-session -d -s "$WORKER_SESSION" "$WORKER --daemon"
        echo "$(date --iso-8601=seconds) worker iniciado"
    fi
    if "$SCHEDULE"; then
        echo "$(date --iso-8601=seconds) watchdog agendado"
    else
        echo "$(date --iso-8601=seconds) falha ao agendar watchdog" >&2
    fi
else
    echo "$(date --iso-8601=seconds) DATABASE_URL ausente; worker nao iniciado" >&2
fi

if PICHAU_APPIUM_SKIP_WAIT=1 "$APPium"; then
    echo "$(date --iso-8601=seconds) Appium iniciado no boot"
else
    echo "$(date --iso-8601=seconds) Appium falhou no boot; o runner tentara novamente na coleta" >&2
fi
echo "$(date --iso-8601=seconds) fim boot Pichau Android"
