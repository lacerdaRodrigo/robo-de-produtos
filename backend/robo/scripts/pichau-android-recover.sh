#!/data/data/com.termux/files/usr/bin/bash

# Recupera o worker persistente. O flock do worker torna chamadas repetidas
# inofensivas quando o daemon iniciado pelo Termux:Boot continua saudável.
set -Eeuo pipefail
umask 077

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/pichau-android-worker.sh" --daemon
