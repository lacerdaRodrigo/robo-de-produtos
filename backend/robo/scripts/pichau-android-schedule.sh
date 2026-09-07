#!/usr/bin/env bash

# Agenda uma verificação de recuperação da fila. Este job não coleta por conta
# própria: o worker só executa quando existe uma solicitação do GitHub Actions.
# A coleta recorrente segue 09h/14h/20h pelo workflow Pichau.
set -Eeuo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKER="${PICHAU_WORKER:-$SCRIPT_DIR/pichau-android-worker.sh}"
WORKER_ONCE="${PICHAU_WORKER_ONCE:-$SCRIPT_DIR/pichau-android-worker-once.sh}"
JOB_ID="${PICHAU_JOB_ID:-7301}"
PERIOD_MS="${PICHAU_PERIOD_MS:-900000}"

[[ -x "$WORKER" ]] || {
    echo "pichau-android-schedule: worker nao executavel: $WORKER" >&2
    exit 1
}
[[ -x "$WORKER_ONCE" ]] || {
    echo "pichau-android-schedule: worker de uma rodada nao executavel: $WORKER_ONCE" >&2
    exit 1
}
command -v termux-job-scheduler >/dev/null 2>&1 || {
    echo "pichau-android-schedule: instale Termux:API" >&2
    exit 1
}

termux-job-scheduler \
    --job-id "$JOB_ID" \
    --script "$WORKER_ONCE" \
    --period-ms "$PERIOD_MS" \
    --network unmetered \
    --battery-not-low true \
    --storage-not-low true \
    --persisted true
