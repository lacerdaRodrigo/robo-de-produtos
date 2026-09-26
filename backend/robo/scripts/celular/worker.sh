#!/data/data/com.termux/files/usr/bin/bash

# Worker único de agenda e despacho do Samsung. A fila Postgres só é consultada
# ao iniciar, quando chega um dispatch GitHub ou no horário de uma coleta.
set -Eeuo pipefail
umask 077

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROBO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)"
TERMUX_PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
if [[ -n "${ROBO_ENV_FILE:-}" ]]; then
    CONFIG_FILE="$ROBO_ENV_FILE"
elif [[ -n "${PICHAU_ENV_FILE:-}" ]]; then
    CONFIG_FILE="$PICHAU_ENV_FILE"
elif [[ -f "$TERMUX_PREFIX/etc/robo-celular/env" ]]; then
    CONFIG_FILE="$TERMUX_PREFIX/etc/robo-celular/env"
else
    CONFIG_FILE="$TERMUX_PREFIX/etc/robo-pichau/env"
fi
LOG_DIR="$TERMUX_PREFIX/var/log/robo-celular"
LOG_FILE="$LOG_DIR/worker.log"
LOCK_DIR="$TERMUX_PREFIX/var/run"
# Mantém o nome do lock conhecido pelo runner Pichau durante a migração.
LOCK_FILE="$LOCK_DIR/robo-pichau-worker.lock"
VENV_DIR="$ROBO_ROOT/.venv"
MODO="${1:---daemon}"
WAKE_LOCK_OWNER="worker"

fail() {
    echo "robo-celular-worker: $*" >&2
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
        ROBO_GITHUB_REPOSITORY|ROBO_GITHUB_POLL_SECONDS|ROBO_CELULAR_STATE_FILE|LIMIAR_PARCEIROS|LIMIAR_LOJAS_INTER)
            export "$chave=$valor"
            ;;
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
    echo "$(date --iso-8601=seconds) worker celular ativo com wake lock"
fi

ROBO_GITHUB_POLL_SECONDS="${ROBO_GITHUB_POLL_SECONDS:-180}"
[[ "$ROBO_GITHUB_POLL_SECONDS" =~ ^[0-9]+$ ]] \
    && ((ROBO_GITHUB_POLL_SECONDS >= 120 && ROBO_GITHUB_POLL_SECONDS <= 3600)) \
    || fail "ROBO_GITHUB_POLL_SECONDS deve estar entre 120 e 3600"
export ROBO_GITHUB_POLL_SECONDS

argumentos=()
[[ "$MODO" == "--once" ]] && argumentos+=(--once)
if PYTHONPATH="$ROBO_ROOT/src${PYTHONPATH:+:$PYTHONPATH}" \
    PYTHONUNBUFFERED=1 "$VENV_DIR/bin/python" -m robo_celular.daemon "${argumentos[@]}"; then
    exit 0
else
    status=$?
    echo "$(date --iso-8601=seconds) worker celular encerrou status=$status" >&2
    exit "$status"
fi
