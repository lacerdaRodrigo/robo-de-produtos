#!/usr/bin/env bash

# Agenda uma execucao aproximada a cada seis horas, sem exigir carregamento.
# O job tem ID proprio para que a configuracao seja idempotente e nao cancele
# jobs de outros aplicativos. A bateria baixa pode impedir o inicio do job;
# nao ha alerta automatico de bateria neste script.
set -Eeuo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
RUNNER="${PICHAU_RUNNER:-$SCRIPT_DIR/pichau-android-run.sh}"
JOB_ID="${PICHAU_JOB_ID:-7301}"
PERIOD_MS="${PICHAU_PERIOD_MS:-21600000}"

[[ -x "$RUNNER" ]] || {
    echo "pichau-android-schedule: runner nao executavel: $RUNNER" >&2
    exit 1
}
command -v termux-job-scheduler >/dev/null 2>&1 || {
    echo "pichau-android-schedule: instale Termux:API" >&2
    exit 1
}

termux-job-scheduler \
    --job-id "$JOB_ID" \
    --script "$RUNNER" \
    --period-ms "$PERIOD_MS" \
    --network unmetered \
    --battery-not-low true \
    --storage-not-low true \
    --persisted true
