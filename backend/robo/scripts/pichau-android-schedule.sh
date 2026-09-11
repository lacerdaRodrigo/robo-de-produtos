#!/data/data/com.termux/files/usr/bin/bash

# Agenda uma verificação de recuperação da fila. Este job não coleta por conta
# própria: o worker só executa quando existe uma solicitação do GitHub Actions.
# A coleta recorrente segue 09h30/14h30/20h30 pelo workflow Pichau.
set -Eeuo pipefail
umask 077

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
RECOVER="${PICHAU_RECOVER:-$SCRIPT_DIR/pichau-android-recover.sh}"
JOB_ID="${PICHAU_JOB_ID:-7301}"
PERIOD_MS="${PICHAU_PERIOD_MS:-900000}"

[[ -x "$RECOVER" ]] || {
    echo "pichau-android-schedule: recuperador nao executavel: $RECOVER" >&2
    exit 1
}
command -v termux-job-scheduler >/dev/null 2>&1 || {
    echo "pichau-android-schedule: instale Termux:API" >&2
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
