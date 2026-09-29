#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/../.." && pwd)"
device_serial="${ANDROID_SERIAL:?Defina ANDROID_SERIAL com o serial do Samsung SM-M135M autorizado.}"
appium_port="${DEVICE_ACCEPTANCE_APPIUM_PORT:-4735}"
appium_home="$script_dir/node_modules/.appium-home"
state_dir="$(python3 -c 'from pathlib import Path; print(Path.home() / ".local/state/radar-mobile-device-acceptance")')"
run_id="$(date -u +%Y%m%dT%H%M%SZ)"
artifacts="$state_dir/evidence/$run_id"
appium_url="http://127.0.0.1:$appium_port/wd/hub"
server_log="$state_dir/appium-$run_id.log"

mkdir -p "$artifacts" "$appium_home"
chmod 700 "$state_dir" "$state_dir/evidence" "$artifacts" "$appium_home"
umask 077

if [[ -z "${ANDROID_HOME:-}${ANDROID_SDK_ROOT:-}" ]]; then
  adb_real_path="$(readlink -f "$(command -v adb)")"
  android_sdk_root="$(cd -- "$(dirname -- "$adb_real_path")/.." && pwd)"
  export ANDROID_HOME="$android_sdk_root"
  export ANDROID_SDK_ROOT="$android_sdk_root"
fi

devices="$(adb devices -l | awk 'NR > 1 && NF { print $1 }')"
if [[ "$devices" != "$device_serial" ]]; then
  echo "Conecte somente o Samsung SM-M135M autorizado (serial esperado: $device_serial)." >&2
  exit 2
fi

if [[ ! -x "$script_dir/node_modules/.bin/appium" ]]; then
  npm ci --prefix "$script_dir" --no-audit --no-fund
fi

installed_driver="$(APPIUM_HOME="$appium_home" "$script_dir/node_modules/.bin/appium" driver list --installed 2>&1 || true)"
if ! rg -q 'uiautomator2' <<< "$installed_driver"; then
  APPIUM_HOME="$appium_home" "$script_dir/node_modules/.bin/appium" \
    driver install --source=npm appium-uiautomator2-driver@8.7.0
fi

python3 - "$appium_port" <<'PY'
import socket
import sys

port = int(sys.argv[1])
with socket.socket() as server:
    if server.connect_ex(("127.0.0.1", port)) == 0:
        raise SystemExit(f"A porta local {port} já está em uso; não vou reutilizar outro servidor Appium.")
PY

APPIUM_HOME="$appium_home" "$script_dir/node_modules/.bin/appium" \
  --address 127.0.0.1 \
  --port "$appium_port" \
  --base-path /wd/hub \
  --log-level info \
  --use-drivers uiautomator2 \
  >"$server_log" 2>&1 &
appium_pid=$!
trap 'kill "$appium_pid" 2>/dev/null || true; wait "$appium_pid" 2>/dev/null || true' EXIT

if ! python3 - "$appium_url" <<'PY'
import json
import sys
import time
import urllib.request

url = sys.argv[1].replace("/wd/hub", "/wd/hub/status")
for _ in range(60):
    try:
        with urllib.request.urlopen(url, timeout=1) as response:
            json.load(response)
            raise SystemExit(0)
    except Exception:
        time.sleep(0.5)
raise SystemExit(1)
PY
then
  echo "Appium não iniciou; o log local está em $server_log" >&2
  exit 2
fi

python3 "$script_dir/run.py" --serial "$device_serial" --appium-url "$appium_url" --artifacts "$artifacts"
