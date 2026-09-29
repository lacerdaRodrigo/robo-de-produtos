#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/../.." && pwd)"
device_serial="${ANDROID_SERIAL:?Defina ANDROID_SERIAL com o serial do Samsung SM-M135M autorizado.}"
build_number="${DEVICE_ACCEPTANCE_BUILD_NUMBER:?Defina DEVICE_ACCEPTANCE_BUILD_NUMBER com um número de build novo para esta rodada.}"
build_name="$(sed -n 's/^version:[[:space:]]*\([^+[:space:]]*\).*/\1/p' "$repo_root/app/pubspec.yaml" | head -n 1)"
apk_path="$repo_root/app/build/app/outputs/flutter-apk/app-debug.apk"
temporary_dir="$(mktemp -d)"
chmod 700 "$temporary_dir"
trap 'rm -rf "$temporary_dir"' EXIT
cd "$repo_root/app"

if [[ -z "$build_name" ]]; then
  echo "Não consegui ler o nome de versão do app/pubspec.yaml." >&2
  exit 2
fi

devices="$(adb devices -l | awk 'NR > 1 && NF { print $1 }')"
if [[ "$devices" != "$device_serial" ]]; then
  echo "Conecte somente o Samsung SM-M135M autorizado (serial esperado: $device_serial)." >&2
  exit 2
fi

remote_apk="$(adb -s "$device_serial" shell pm path br.com.radarbeneficios.app | sed -n '1s/^package://p' | tr -d '\r')"
if [[ -z "$remote_apk" ]]; then
  echo "O app br.com.radarbeneficios.app não está instalado; não será feita instalação limpa." >&2
  exit 2
fi

flutter build apk --debug \
  --build-name="$build_name" \
  --build-number="$build_number" \
  --dart-define=API_URL=https://robo-de-produtos.vercel.app \
  --dart-define=ATIVAR_APP_CHECK=false \
  --no-pub

if [[ ! -f "$apk_path" ]]; then
  echo "O build não produziu o APK esperado." >&2
  exit 2
fi

adb -s "$device_serial" pull "$remote_apk" "$temporary_dir/installed.apk" >/dev/null
installed_signer="$(apksigner verify --print-certs "$temporary_dir/installed.apk" | sed -n 's/^Signer #1 certificate SHA-256 digest: //p')"
candidate_signer="$(apksigner verify --print-certs "$apk_path" | sed -n 's/^Signer #1 certificate SHA-256 digest: //p')"
if [[ -z "$installed_signer" || "$installed_signer" != "$candidate_signer" ]]; then
  echo "A assinatura do APK novo não corresponde; os dados do app foram preservados e nada foi instalado." >&2
  exit 3
fi

apk_sha256="$(sha256sum "$apk_path" | awk '{print $1}')"
adb -s "$device_serial" install -r "$apk_path"
version="$(adb -s "$device_serial" shell dumpsys package br.com.radarbeneficios.app | sed -n 's/.*versionName=\([^ ]*\).*/\1/p' | head -n 1 | tr -d '\r')"
version_code="$(adb -s "$device_serial" shell dumpsys package br.com.radarbeneficios.app | sed -n 's/.*versionCode=\([0-9]*\).*/\1/p' | head -n 1 | tr -d '\r')"

printf 'Installed package: br.com.radarbeneficios.app\nVersion: %s+%s\nAPK SHA-256: %s\nCommit: %s\n' \
  "$version" "$version_code" "$apk_sha256" "$(git -C "$repo_root" rev-parse --short HEAD)"
