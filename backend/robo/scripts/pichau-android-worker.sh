#!/data/data/com.termux/files/usr/bin/bash

# Worker persistente da fila Pichau. Ele não coleta por agenda própria: só
# executa quando o workflow cria uma solicitação no Postgres.
set -Eeuo pipefail
umask 077

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROBO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
TERMUX_PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
CONFIG_FILE="${PICHAU_ENV_FILE:-$TERMUX_PREFIX/etc/robo-pichau/env}"
LOG_DIR="$TERMUX_PREFIX/var/log/robo-pichau"
LOG_FILE="$LOG_DIR/worker.log"
LOCK_DIR="$TERMUX_PREFIX/var/run"
LOCK_FILE="$LOCK_DIR/robo-pichau-worker.lock"
VENV_DIR="$ROBO_ROOT/.venv"
MODO="${1:---daemon}"
INTERVALO_SEGUNDOS="${PICHAU_WORKER_INTERVAL_SECONDS:-30}"
WAKE_LOCK_OWNER="worker"

fail() {
    echo "pichau-android-worker: $*" >&2
    exit 1
}

[[ "$MODO" == "--daemon" || "$MODO" == "--once" ]] || fail "modo invalido"
[[ -f "$CONFIG_FILE" ]] || fail "arquivo de configuracao ausente: $CONFIG_FILE"
[[ -O "$CONFIG_FILE" ]] || fail "arquivo de configuracao nao pertence ao usuario atual"
[[ "$(stat -c '%a' "$CONFIG_FILE")" == "600" || "$(stat -c '%a' "$CONFIG_FILE")" == "400" ]] \
    || fail "arquivo de configuracao deve ter permissao 600 ou 400"

while IFS= read -r linha || [[ -n "$linha" ]]; do
    [[ -z "$linha" || "$linha" == \#* ]] && continue
    [[ "$linha" == *=* ]] || fail "linha invalida no arquivo de configuracao"
    chave="${linha%%=*}"
    valor="${linha#*=}"
    case "$chave" in
        DATABASE_URL) export DATABASE_URL="$valor" ;;
        *) ;;
    esac
done < "$CONFIG_FILE"

[[ -n "${DATABASE_URL:-}" ]] || fail "DATABASE_URL ausente"
case "$DATABASE_URL" in
    *sslmode=require*|*sslmode=verify-ca*|*sslmode=verify-full*) ;;
    *) fail "DATABASE_URL precisa exigir SSL" ;;
esac
[[ -x "$VENV_DIR/bin/python" ]] || fail "ambiente Python ausente: $VENV_DIR"
command -v flock >/dev/null 2>&1 || fail "flock ausente; instale util-linux"

mkdir -p "$LOG_DIR" "$LOCK_DIR"
chmod 700 "$LOG_DIR" "$LOCK_DIR"
if [[ -f "$LOG_FILE" && "$(stat -c '%s' "$LOG_FILE")" -gt 5242880 ]]; then
    mv -f "$LOG_FILE" "$LOG_FILE.1"
fi
touch "$LOG_FILE"
chmod 600 "$LOG_FILE"

exec 9>"$LOCK_FILE"
flock -n 9 || exit 0
exec >>"$LOG_FILE" 2>&1

liberou_wake_lock=0
liberar_wake_lock() {
    if [[ "$liberou_wake_lock" == 0 ]]; then
        termux-wake-unlock >/dev/null 2>&1 || true
        liberou_wake_lock=1
    fi
}

if [[ "$MODO" == "--daemon" ]]; then
    command -v termux-wake-lock >/dev/null 2>&1 \
        || fail "termux-wake-lock ausente; atualize o Termux"
    termux-wake-lock >/dev/null
    export PICHAU_WAKE_LOCK_OWNER="$WAKE_LOCK_OWNER"
    trap liberar_wake_lock EXIT
    trap 'exit 0' INT TERM HUP
    echo "$(date --iso-8601=seconds) worker persistente ativo com wake lock"
fi

executar_uma() {
    if PYTHONPATH="$ROBO_ROOT/src${PYTHONPATH:+:$PYTHONPATH}" \
        PYTHONUNBUFFERED=1 "$VENV_DIR/bin/python" -m robo_pichau.fila_android worker --once; then
        status=0
    else
        status=$?
    fi
    if [[ "$status" != 0 ]]; then
        echo "$(date --iso-8601=seconds) verificacao fila Pichau Android falhou status=$status"
    fi
    return "$status"
}

if [[ "$MODO" == "--once" ]]; then
    executar_uma
    exit $?
fi

verificacoes=0
while true; do
    executar_uma || true
    ((verificacoes += 1))
    if ((verificacoes % 60 == 0)); then
        echo "$(date --iso-8601=seconds) worker persistente ativo"
    fi
    sleep "$INTERVALO_SEGUNDOS"
done
