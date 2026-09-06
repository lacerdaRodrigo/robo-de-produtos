#!/usr/bin/env bash

# Copiar para $PREFIX/../home/.termux/boot/ depois de revisar o caminho do
# repositorio. O clone recomendado fica em $PREFIX/opt/robo.
# O Appium local e o agendamento persistente sao recriados no boot; a coleta
# so acontece pelo job.
set -Eeuo pipefail

TERMUX_PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
REPO_ROOT="${PICHAU_REPO_ROOT:-$TERMUX_PREFIX/opt/robo}"
APPium="$REPO_ROOT/backend/robo/scripts/pichau-android-appium.sh"
SCHEDULE="$REPO_ROOT/backend/robo/scripts/pichau-android-schedule.sh"

[[ -x "$APPium" ]] || {
    echo "pichau-android-boot: Appium nao executavel: $APPium" >&2
    exit 1
}
[[ -x "$SCHEDULE" ]] || {
    echo "pichau-android-boot: agendador nao executavel: $SCHEDULE" >&2
    exit 1
}

"$APPium"
CONFIG_FILE="${PICHAU_ENV_FILE:-${PREFIX:-/data/data/com.termux/files/usr}/etc/robo-pichau/env}"
if [[ -f "$CONFIG_FILE" ]] && grep -q '^DATABASE_URL=.' "$CONFIG_FILE"; then
    exec "$SCHEDULE"
fi

echo "pichau-android-boot: DATABASE_URL ausente; Appium iniciado, agendamento aguardando a credencial." >&2
