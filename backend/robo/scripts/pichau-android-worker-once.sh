#!/data/data/com.termux/files/usr/bin/bash

# Adaptador sem argumentos para o Termux:API Job Scheduler.
set -Eeuo pipefail
umask 077

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/pichau-android-worker.sh" --once
