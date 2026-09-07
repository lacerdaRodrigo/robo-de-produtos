#!/usr/bin/env bash

# Copiar para $PREFIX/../home/.termux/boot/ depois de revisar o caminho do
# repositorio. O clone recomendado fica em $PREFIX/opt/robo.
# O Appium local, o worker persistente e o watchdog sao recriados no boot. A
# coleta só acontece quando o GitHub Actions cria uma solicitação na fila.
set -Eeuo pipefail

TERMUX_PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
REPO_ROOT="${PICHAU_REPO_ROOT:-$TERMUX_PREFIX/opt/robo}"
APPium="$REPO_ROOT/backend/robo/scripts/pichau-android-appium.sh"
SCHEDULE="$REPO_ROOT/backend/robo/scripts/pichau-android-schedule.sh"
WORKER="$REPO_ROOT/backend/robo/scripts/pichau-android-worker.sh"
WORKER_ONCE="$REPO_ROOT/backend/robo/scripts/pichau-android-worker-once.sh"

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

"$APPium"
CONFIG_FILE="${PICHAU_ENV_FILE:-${PREFIX:-/data/data/com.termux/files/usr}/etc/robo-pichau/env}"
if [[ -f "$CONFIG_FILE" ]] && grep -q '^DATABASE_URL=.' "$CONFIG_FILE"; then
    WORKER_SESSION="${PICHAU_WORKER_SESSION:-robo-pichau-worker}"
    if tmux has-session -t "$WORKER_SESSION" 2>/dev/null; then
        :
    else
        tmux new-session -d -s "$WORKER_SESSION" "$WORKER --daemon"
    fi
    exec "$SCHEDULE"
fi

echo "pichau-android-boot: DATABASE_URL ausente; Appium iniciado, agendamento aguardando a credencial." >&2
