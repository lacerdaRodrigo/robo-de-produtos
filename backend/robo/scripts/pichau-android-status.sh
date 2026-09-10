#!/data/data/com.termux/files/usr/bin/bash

# Diagnostico local seguro do executor. Nao imprime DATABASE_URL, endpoint ADB,
# serial do aparelho nem valores privados do arquivo de configuracao.
set -Eeuo pipefail
umask 077

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROBO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$ROBO_ROOT/../.." && pwd)"
TERMUX_PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
CONFIG_FILE="${PICHAU_ENV_FILE:-$TERMUX_PREFIX/etc/robo-pichau/env}"
LOCK_FILE="$TERMUX_PREFIX/var/run/robo-pichau-worker.lock"
VENV_DIR="$ROBO_ROOT/.venv"
JOB_ID="${PICHAU_JOB_ID:-7301}"
status=0

ok() {
    echo "pichau-android-status: $1=ok"
}

falha() {
    echo "pichau-android-status: $1=falha" >&2
    status=2
}

if commit="$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null)"; then
    echo "pichau-android-status: checkout=$commit"
else
    falha "checkout"
fi

if [[ -f "$CONFIG_FILE" && -O "$CONFIG_FILE" ]] \
    && { [[ "$(stat -c '%a' "$CONFIG_FILE")" == "600" ]] \
        || [[ "$(stat -c '%a' "$CONFIG_FILE")" == "400" ]]; }; then
    ok "configuracao"
else
    falha "configuracao"
fi

unset DATABASE_URL
ADB_PORT="5037"
WIFI_HOST=""
WIFI_SERVICE="adb-tls-connect._tcp"
if [[ -f "$CONFIG_FILE" ]]; then
    while IFS= read -r linha || [[ -n "$linha" ]]; do
        [[ -z "$linha" || "$linha" == \#* || "$linha" != *=* ]] && continue
        chave="${linha%%=*}"
        valor="${linha#*=}"
        case "$chave" in
            DATABASE_URL) DATABASE_URL="$valor" ;;
            PICHAU_ANDROID_ADB_PORT) ADB_PORT="$valor" ;;
            PICHAU_ANDROID_WIFI_HOST) WIFI_HOST="$valor" ;;
            PICHAU_ANDROID_WIFI_SERVICE) WIFI_SERVICE="$valor" ;;
            *) ;;
        esac
    done < "$CONFIG_FILE"
fi

if [[ -e "$LOCK_FILE" ]] && ! flock -n "$LOCK_FILE" -c true 2>/dev/null; then
    ok "worker"
    echo "pichau-android-status: wake-lock-owner=worker"
else
    falha "worker"
    falha "wake-lock-owner"
fi

if command -v termux-job-scheduler >/dev/null 2>&1 \
    && termux-job-scheduler --pending 2>/dev/null | grep -Eq "Job[[:space:]]+$JOB_ID:"; then
    ok "watchdog"
else
    falha "watchdog"
fi

if [[ -n "${DATABASE_URL:-}" && -x "$VENV_DIR/bin/python" ]] \
    && DATABASE_URL="$DATABASE_URL" PYTHONPATH="$ROBO_ROOT/src${PYTHONPATH:+:$PYTHONPATH}" \
        "$VENV_DIR/bin/python" -m robo_pichau.fila_android health >/dev/null 2>&1; then
    ok "fila"
else
    falha "fila"
fi

adb_pronto=0
if command -v adb >/dev/null 2>&1 \
    && [[ "$ADB_PORT" =~ ^[0-9]{1,5}$ ]] \
    && ((10#$ADB_PORT >= 1 && 10#$ADB_PORT <= 65535)) \
    && [[ -n "$WIFI_HOST" && "$WIFI_HOST" =~ ^[A-Za-z0-9.-]+$ ]] \
    && [[ "$WIFI_SERVICE" =~ ^[A-Za-z0-9._-]+$ ]]; then
    unset ADB_SERVER_SOCKET
    adb -P "$ADB_PORT" start-server >/dev/null 2>&1 || true
    adb_target=""
    adb_ambiguo=0
    while read -r endpoint estado _resto; do
        [[ "$estado" == "device" && "$endpoint" == "$WIFI_HOST:"* ]] || continue
        porta_endpoint="${endpoint##*:}"
        [[ "$porta_endpoint" =~ ^[0-9]{1,5}$ ]] \
            && ((10#$porta_endpoint >= 1 && 10#$porta_endpoint <= 65535)) || continue
        [[ -z "$adb_target" || "$adb_target" == "$endpoint" ]] || adb_ambiguo=1
        adb_target="$endpoint"
    done < <(adb -P "$ADB_PORT" devices 2>/dev/null | sed '1d')
    if [[ -z "$adb_target" ]]; then
        while read -r servico endpoint _resto; do
            [[ "$servico" == "$WIFI_SERVICE" && "$endpoint" == "$WIFI_HOST:"* ]] || continue
            porta_endpoint="${endpoint##*:}"
            [[ "$porta_endpoint" =~ ^[0-9]{1,5}$ ]] \
                && ((10#$porta_endpoint >= 1 && 10#$porta_endpoint <= 65535)) || continue
            [[ -z "$adb_target" || "$adb_target" == "$endpoint" ]] || adb_ambiguo=1
            adb_target="$endpoint"
        done < <(adb -P "$ADB_PORT" mdns services 2>/dev/null || true)
    fi
    if [[ -n "$adb_target" && "$adb_ambiguo" == 0 ]]; then
        adb -P "$ADB_PORT" connect "$adb_target" >/dev/null 2>&1 || true
        if [[ "$(adb -P "$ADB_PORT" -s "$adb_target" get-state 2>/dev/null || true)" == "device" ]]; then
            adb_pronto=1
        fi
    fi
fi

if [[ "$adb_pronto" == 1 ]]; then
    ok "adb-wifi"
else
    falha "adb-wifi"
fi

if "$SCRIPT_DIR/pichau-android-appium.sh" status >/dev/null 2>&1; then
    echo "pichau-android-status: appium=ativo"
else
    echo "pichau-android-status: appium=ocioso"
fi

exit "$status"
