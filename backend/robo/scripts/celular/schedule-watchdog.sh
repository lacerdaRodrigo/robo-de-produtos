#!/data/data/com.termux/files/usr/bin/bash

# Agenda a recuperação do worker único do Samsung. O job 7301 não consulta o
# banco nem executa coleta se o daemon já estiver ativo.
set -Eeuo pipefail
umask 077

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
RECOVER="${ROBO_CELULAR_RECOVER:-$SCRIPT_DIR/recover.sh}"
JOB_ID="${PICHAU_JOB_ID:-7301}"
PERIOD_MS="${PICHAU_PERIOD_MS:-900000}"

[[ -x "$RECOVER" ]] || {
    echo "robo-celular-schedule: recuperador nao executavel" >&2
    exit 1
}
command -v termux-job-scheduler >/dev/null 2>&1 || {
    echo "robo-celular-schedule: instale Termux:API" >&2
    exit 1
}

termux-job-scheduler \
    --job-id "$JOB_ID" \
    --script "$RECOVER" \
    --period-ms "$PERIOD_MS" \
    --network any \
    --battery-not-low false \
    --storage-not-low false \
    --persisted true
