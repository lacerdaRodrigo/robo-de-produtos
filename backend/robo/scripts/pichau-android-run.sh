#!/data/data/com.termux/files/usr/bin/bash

# Runner local do Termux. O arquivo de configuracao e lido como dados simples
# KEY=VALUE; ele nunca e executado como shell script.
set -Eeuo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROBO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
TERMUX_PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
CONFIG_FILE="${PICHAU_ENV_FILE:-$TERMUX_PREFIX/etc/robo-pichau/env}"
LOG_DIR="$TERMUX_PREFIX/var/log/robo-pichau"
LOCK_DIR="$TERMUX_PREFIX/var/run"
LOCK_FILE="$LOCK_DIR/robo-pichau.lock"
LOG_FILE="$LOG_DIR/coleta-$(date +%F).log"
VENV_DIR="$ROBO_ROOT/.venv"
APPIUM_SCRIPT="$ROBO_ROOT/scripts/pichau-android-appium.sh"
CODIGO_ADB_AUSENTE=30
CODIGO_ADB_SERVIDOR=31
CODIGO_ADB_DESCOBERTA_WIFI=32
CODIGO_ADB_CONEXAO_WIFI=33
CODIGO_ADB_ESTADO_WIFI=34

agora_ms() {
    date +%s%3N
}

fail() {
    local mensagem="$1"
    local codigo="${2:-2}"
    mkdir -p "${LOG_DIR:-/data/data/com.termux/files/usr/var/log/robo-pichau}" \
        2>/dev/null || true
    if [[ -n "${LOG_FILE:-}" ]]; then
        echo "$(date --iso-8601=seconds) falha preflight codigo=$codigo mensagem=$mensagem" \
            >> "$LOG_FILE" 2>/dev/null || true
    fi
    echo "pichau-android-run: $mensagem" >&2
    exit "$codigo"
}

mkdir -p "$LOG_DIR" "$LOCK_DIR"
chmod 700 "$LOG_DIR" "$LOCK_DIR"

[[ -f "$CONFIG_FILE" ]] || fail "arquivo de configuracao ausente: $CONFIG_FILE"
[[ -O "$CONFIG_FILE" ]] || fail "arquivo de configuracao nao pertence ao usuario atual"
[[ "$(stat -c '%a' "$CONFIG_FILE")" == "600" || "$(stat -c '%a' "$CONFIG_FILE")" == "400" ]] \
    || fail "arquivo de configuracao deve ter permissao 600 ou 400"

# O formato aceito e intencionalmente pequeno: nao ha expansao de shell,
# command substitution ou interpretacao de aspas.
while IFS= read -r linha || [[ -n "$linha" ]]; do
    [[ -z "$linha" ]] && continue
    [[ "$linha" == \#* ]] && continue
    [[ "$linha" == *=* ]] || fail "linha invalida no arquivo de configuracao"
    chave="${linha%%=*}"
    valor="${linha#*=}"
    [[ "$chave" =~ ^[A-Z][A-Z0-9_]*$ ]] || fail "nome de variavel invalido"
    case "$chave" in
        DATABASE_URL|PICHAU_MODO_NAVEGADOR|PICHAU_ESTRATEGIA_LEITURA|PICHAU_ANDROID_ORDENACAO|PICHAU_APPIUM_URL|PICHAU_ANDROID_DEVICE_NAME|PICHAU_ANDROID_UDID|PICHAU_ANDROID_ADB_PORT|PICHAU_ANDROID_TRANSPORTE|PICHAU_ANDROID_WIFI_HOST|PICHAU_ANDROID_WIFI_SERVICE|LOG_LEVEL)
            export "$chave=$valor"
            ;;
        *)
            fail "variavel nao permitida no arquivo de configuracao: $chave"
            ;;
    esac
done < "$CONFIG_FILE"

[[ -n "${DATABASE_URL:-}" ]] || fail "DATABASE_URL ausente"
PICHAU_MODO_NAVEGADOR="${PICHAU_MODO_NAVEGADOR:-android}"
export PICHAU_MODO_NAVEGADOR
[[ "$PICHAU_MODO_NAVEGADOR" == "android" ]] \
    || fail "PICHAU_MODO_NAVEGADOR do aparelho deve ser android"
case "$DATABASE_URL" in
    *sslmode=require*|*sslmode=verify-ca*|*sslmode=verify-full*) ;;
    *) fail "DATABASE_URL precisa exigir SSL (sslmode=require, verify-ca ou verify-full)" ;;
esac

command -v adb >/dev/null 2>&1 || fail "adb ausente; instale Android Platform Tools" "$CODIGO_ADB_AUSENTE"
ADB_PORT="${PICHAU_ANDROID_ADB_PORT:-5037}"
TRANSPORTE="${PICHAU_ANDROID_TRANSPORTE:-wifi}"
[[ "$TRANSPORTE" == "wifi" ]] || fail \
    "PICHAU_ANDROID_TRANSPORTE deve ser wifi" "$CODIGO_ADB_DESCOBERTA_WIFI"
[[ "${PICHAU_ANDROID_UDID:-}" == "auto" ]] || fail \
    "PICHAU_ANDROID_UDID deve ser auto no transporte wifi" "$CODIGO_ADB_DESCOBERTA_WIFI"
WIFI_HOST="${PICHAU_ANDROID_WIFI_HOST:-}"
[[ -n "$WIFI_HOST" && "$WIFI_HOST" =~ ^[A-Za-z0-9.-]+$ ]] || fail \
    "PICHAU_ANDROID_WIFI_HOST invalido" "$CODIGO_ADB_DESCOBERTA_WIFI"
WIFI_SERVICE="${PICHAU_ANDROID_WIFI_SERVICE:-adb-tls-connect._tcp}"
[[ "$WIFI_SERVICE" =~ ^[A-Za-z0-9._-]+$ ]] || fail \
    "PICHAU_ANDROID_WIFI_SERVICE invalido" "$CODIGO_ADB_DESCOBERTA_WIFI"
unset ADB_SERVER_SOCKET
adb -P "$ADB_PORT" start-server >/dev/null 2>&1 \
    || fail "servidor ADB local nao iniciou" "$CODIGO_ADB_SERVIDOR"

descobrir_endpoint_wifi() {
    local servicos servico endpoint host candidato=""
    for _tentativa in {1..30}; do
        servicos="$(adb -P "$ADB_PORT" mdns services 2>/dev/null || true)"
        while read -r servico endpoint _resto; do
            [[ "$servico" == "$WIFI_SERVICE" ]] || continue
            [[ "$endpoint" == *:* ]] || continue
            host="${endpoint%:*}"
            [[ "$host" == "$WIFI_HOST" ]] || continue
            if [[ -n "$candidato" && "$candidato" != "$endpoint" ]]; then
                return 2
            fi
            candidato="$endpoint"
        done <<< "$servicos"
        if [[ -n "$candidato" ]]; then
            printf '%s\n' "$candidato"
            return 0
        fi
        sleep 1
    done
    return 1
}

if ADB_TARGET="$(descobrir_endpoint_wifi)"; then
    :
else
    status_descoberta=$?
    if [[ "$status_descoberta" == 2 ]]; then
        fail "mais de um endpoint ADB Wi-Fi encontrado" "$CODIGO_ADB_DESCOBERTA_WIFI"
    fi
    fail "endpoint ADB Wi-Fi nao encontrado" "$CODIGO_ADB_DESCOBERTA_WIFI"
fi

adb -P "$ADB_PORT" connect "$ADB_TARGET" >/dev/null 2>&1 \
    || fail "nao foi possivel conectar ao ADB Wi-Fi" "$CODIGO_ADB_CONEXAO_WIFI"
estado_adb="$(adb -P "$ADB_PORT" -s "$ADB_TARGET" get-state 2>/dev/null || true)"
[[ "$estado_adb" == "device" ]] || fail \
    "ADB Wi-Fi nao esta pronto (estado=${estado_adb:-indisponivel})" "$CODIGO_ADB_ESTADO_WIFI"
export PICHAU_ANDROID_UDID="$ADB_TARGET"
export PICHAU_ANDROID_TRANSPORTE="$TRANSPORTE"

command -v flock >/dev/null 2>&1 || fail "flock ausente; instale util-linux"
command -v termux-wake-lock >/dev/null 2>&1 || fail "termux-wake-lock ausente; instale Termux:API"
[[ -x "$VENV_DIR/bin/python" ]] || fail "ambiente Python ausente: $VENV_DIR"
[[ -x "$APPIUM_SCRIPT" ]] || fail "script Appium ausente: $APPIUM_SCRIPT"

exec 9>"$LOCK_FILE"
flock -n 9 || exit 0

# Retencao curta de logs operacionais. Nenhuma variavel de ambiente e exibida.
find "$LOG_DIR" -type f -name 'coleta-*.log' -mtime +14 -delete
if [[ -f "$LOG_FILE" && "$(stat -c '%s' "$LOG_FILE")" -gt 5242880 ]]; then
    mv -f "$LOG_FILE" "$LOG_FILE.1"
fi

termux-wake-lock >/dev/null
liberou_wake_lock=0
liberar_wake_lock() {
    if [[ "$liberou_wake_lock" == 0 ]]; then
        termux-wake-unlock >/dev/null 2>&1 || true
        liberou_wake_lock=1
    fi
}
trap liberar_wake_lock EXIT

{
    inicio_runner_ms="$(agora_ms)"
    echo "$(date --iso-8601=seconds) inicio coleta Pichau Android"
    echo "$(date --iso-8601=seconds) executor ADB transporte=wifi"
    cd "$ROBO_ROOT"
    inicio_preparo_ms="$(agora_ms)"
    "$APPIUM_SCRIPT"
    fim_preparo_ms="$(agora_ms)"
    echo "$(date --iso-8601=seconds) Pichau performance: etapa=preparo_runner "\
        "duracao_ms=$((fim_preparo_ms - inicio_preparo_ms))"
    if PYTHONPATH="$ROBO_ROOT/src${PYTHONPATH:+:$PYTHONPATH}" \
        PYTHONUNBUFFERED=1 "$VENV_DIR/bin/python" -m robo_pichau.principal; then
        status=0
    else
        status=$?
    fi
    fim_runner_ms="$(agora_ms)"
    echo "$(date --iso-8601=seconds) Pichau performance: etapa=runner "\
        "duracao_ms=$((fim_runner_ms - inicio_runner_ms)) status=$status"
    echo "$(date --iso-8601=seconds) fim coleta Pichau Android status=$status"
    exit "$status"
} >> "$LOG_FILE" 2>&1
