#!/data/data/com.termux/files/usr/bin/bash

# Gerencia o Appium local em uma sessao tmux durante a coleta. O Chrome e
# aberto pelo UiAutomator2; nenhum servidor Appium fica exposto na rede.
set -Eeuo pipefail
umask 077

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TERMUX_PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
CONFIG_FILE="${PICHAU_ENV_FILE:-$TERMUX_PREFIX/etc/robo-pichau/env}"
SESSION="${PICHAU_APPIUM_SESSION:-robo-pichau-appium}"
LOG_DIR="$TERMUX_PREFIX/var/log/robo-pichau"
LOG_FILE="$LOG_DIR/appium.log"
SDK_DIR="${ANDROID_HOME:-$TERMUX_PREFIX/android-sdk}"
ACAO="${1:-start}"

[[ "$#" -le 1 ]] || {
    echo "Uso: pichau-android-appium.sh [start|stop|status]" >&2
    exit 2
}
[[ "$ACAO" == "start" || "$ACAO" == "stop" || "$ACAO" == "status" ]] || {
    echo "Uso: pichau-android-appium.sh [start|stop|status]" >&2
    exit 2
}

mkdir -p "$LOG_DIR"
chmod 700 "$LOG_DIR"

# Este script e filho do runner, que segura o flock da coleta. O servidor ADB
# e o tmux sao persistentes e nao podem herdar esse descritor.
exec 9>&- 2>/dev/null || true

if [[ "$ACAO" == "stop" ]]; then
    if tmux has-session -t "$SESSION" 2>/dev/null; then
        tmux kill-session -t "$SESSION"
    fi
    exit 0
fi

if [[ "$ACAO" == "status" ]]; then
    tmux has-session -t "$SESSION" 2>/dev/null || exit 1
    "$TERMUX_PREFIX/bin/python" -c \
        'import urllib.request; urllib.request.urlopen("http://127.0.0.1:4723/status", timeout=1)' \
        >/dev/null 2>&1
    exit $?
fi

# Le somente as duas opcoes de transporte necessarias quando o runner ainda
# nao resolveu um endpoint. O arquivo inteiro continua sendo validado pelo
# runner antes de qualquer coleta.
if [[ -z "${PICHAU_ANDROID_UDID+x}" && -f "$CONFIG_FILE" ]]; then
    while IFS= read -r linha || [[ -n "$linha" ]]; do
        [[ -z "$linha" || "$linha" == \#* ]] && continue
        [[ "$linha" == *=* ]] || continue
        chave="${linha%%=*}"
        valor="${linha#*=}"
        case "$chave" in
            PICHAU_ANDROID_UDID) PICHAU_ANDROID_UDID="$valor" ;;
            PICHAU_ANDROID_ADB_PORT) PICHAU_ANDROID_ADB_PORT="$valor" ;;
        esac
    done < "$CONFIG_FILE"
fi

unset ADB_SERVER_SOCKET
ADB_PORT="${PICHAU_ANDROID_ADB_PORT:-5037}"
[[ "$ADB_PORT" =~ ^[0-9]{1,5}$ ]] \
    && ((10#$ADB_PORT >= 1 && 10#$ADB_PORT <= 65535)) || {
    echo "pichau-android-appium: porta ADB invalida" >&2
    exit 1
}
if [[ "${PICHAU_ANDROID_UDID:-}" == *:* ]]; then
    adb -P "$ADB_PORT" connect "$PICHAU_ANDROID_UDID" >/dev/null 2>&1 || true
fi

if tmux has-session -t "$SESSION" 2>/dev/null; then
    :
else
    if [[ -f "$LOG_FILE" && "$(stat -c '%s' "$LOG_FILE")" -gt 5242880 ]]; then
        mv -f "$LOG_FILE" "$LOG_FILE.1"
    fi
    touch "$LOG_FILE"
    chmod 600 "$LOG_FILE"

    tmux new-session -d -s "$SESSION" \
        "unset ADB_SERVER_SOCKET DATABASE_URL PICHAU_ANDROID_WIFI_HOST PICHAU_ANDROID_WIFI_SERVICE PICHAU_ANDROID_UDID PICHAU_ANDROID_ADB_PORT; export ANDROID_HOME=$(printf '%q' "$SDK_DIR"); export ANDROID_SDK_ROOT=$(printf '%q' "$SDK_DIR"); exec appium --address 127.0.0.1 --port 4723 --log-level error >>$(printf '%q' "$LOG_FILE") 2>&1"
fi

for _tentativa in {1..30}; do
    if "$TERMUX_PREFIX/bin/python" -c \
        'import urllib.request; urllib.request.urlopen("http://127.0.0.1:4723/status", timeout=1)' \
        >/dev/null 2>&1; then
        exit 0
    fi
    sleep 1
done

echo "pichau-android-appium: Appium nao ficou pronto em 30 segundos" >&2
exit 1
