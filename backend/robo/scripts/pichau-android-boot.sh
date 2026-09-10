#!/data/data/com.termux/files/usr/bin/bash

# Instalar como link simbolico em $PREFIX/../home/.termux/boot/ depois de
# revisar o caminho do repositorio. O clone recomendado fica em $PREFIX/opt/robo.
# O worker persistente e o watchdog sao recriados no boot. O Appium fica
# desligado enquanto o aparelho esta ocioso e sobe sob demanda na coleta.
set -Eeuo pipefail
umask 077

TERMUX_PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
REPO_ROOT="${PICHAU_REPO_ROOT:-$TERMUX_PREFIX/opt/robo}"
SCHEDULE="$REPO_ROOT/backend/robo/scripts/pichau-android-schedule.sh"
WORKER="$REPO_ROOT/backend/robo/scripts/pichau-android-worker.sh"
LOG_DIR="$TERMUX_PREFIX/var/log/robo-pichau"
BOOT_LOG="$LOG_DIR/boot.log"

mkdir -p "$LOG_DIR"
chmod 700 "$LOG_DIR"
touch "$BOOT_LOG"
chmod 600 "$BOOT_LOG"
exec >> "$BOOT_LOG" 2>&1
echo "$(date --iso-8601=seconds) inicio boot Pichau Android"
if commit="$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null)"; then
    echo "$(date --iso-8601=seconds) checkout commit=$commit"
fi

[[ -x "$SCHEDULE" ]] || {
    echo "pichau-android-boot: agendador nao executavel: $SCHEDULE" >&2
    exit 1
}
[[ -x "$WORKER" ]] || {
    echo "pichau-android-boot: worker nao executavel: $WORKER" >&2
    exit 1
}
CONFIG_FILE="${PICHAU_ENV_FILE:-${PREFIX:-/data/data/com.termux/files/usr}/etc/robo-pichau/env}"
if [[ -f "$CONFIG_FILE" ]] && grep -q '^DATABASE_URL=.' "$CONFIG_FILE"; then
    if "$SCHEDULE"; then
        echo "$(date --iso-8601=seconds) watchdog agendado"
    else
        echo "$(date --iso-8601=seconds) falha ao agendar watchdog" >&2
    fi
else
    echo "$(date --iso-8601=seconds) DATABASE_URL ausente; worker nao iniciado" >&2
    exit 1
fi

echo "$(date --iso-8601=seconds) transferindo controle ao worker persistente"
exec "$WORKER" --daemon
