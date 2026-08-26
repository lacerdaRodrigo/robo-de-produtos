# Atalhos de build, validação e dispositivos do app Flutter.
#
# Rode `make help` (ou `make`) para listar os alvos.
# Uso: `make build-release`, `make log`, etc.

API_URL ?= https://robo-de-produtos.vercel.app
APP_CHECK ?= false
APK_DEBUG := build/app/outputs/flutter-apk/app-debug.apk
APK_RELEASE := build/app/outputs/flutter-apk/app-release.apk
APP_ID := br.com.radarbeneficios.app

.DEFAULT_GOAL := help

.PHONY: help build-release build-debug release-install install install-debug open stop log log-now log-sys analyze format test clean

## Lista todos os alvos disponíveis.
help: ## Lista todos os alvos disponíveis
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort
	@echo ""
	@echo "Uso: make <alvo> [API_URL=...] [APP_CHECK=true|false]"
	@echo "Ex.: make build-release API_URL=https://meu-app.vercel.app"

# ── Build ──────────────────────────────────────────────────────────────────

build-release: ## Gera o APK de release apontando para a API de produção, sem App Check
	flutter build apk --release \
		--dart-define=API_URL=$(API_URL) \
		--dart-define=ATIVAR_APP_CHECK=$(APP_CHECK)

build-debug: ## Gera o APK de debug (mais rápido, com logs de diagnóstico)
	flutter build apk --debug \
		--dart-define=API_URL=$(API_URL) \
		--dart-define=ATIVAR_APP_CHECK=$(APP_CHECK)

release-install: build-release install open ## Builda o release, instala no aparelho e abre o app

install: ## Instala o APK de release existente no aparelho
	adb install -r $(APK_RELEASE)

install-debug: ## Instala o APK de debug existente no aparelho
	adb install -r $(APK_DEBUG)

# ── Dispositivo / logs ─────────────────────────────────────────────────────

open: ## Abre o app no aparelho conectado
	adb shell am start -n $(APP_ID)/.MainActivity

stop: ## Fecha o app no aparelho
	adb shell am force-stop $(APP_ID)

log: ## Limpa o log, abre o app e mostra a tag flutter em tempo real (Ctrl+C sai)
	adb logcat -c
	adb shell am start -n $(APP_ID)/.MainActivity
	adb logcat -v time | grep -iE "flutter|radar|firebase|appcheck|Unhandled|Exception"

log-now: ## Mostra a última rodada de logs do app (sem stream)
	@PID=$$(adb shell pidof $(APP_ID) | tr -d '\r'); \
	if [ -z "$$PID" ]; then echo "app não está aberto"; exit 1; fi; \
	adb logcat -d -v brief --pid=$$PID | grep -iE "flutter|error|exception|401|perfil|token|firebase" | tail -60

log-sys: ## Mostra os últimos 200 logs do sistema
	adb logcat -d -t 200

# ── Qualidade ──────────────────────────────────────────────────────────────

analyze: ## Valida estilo do código Flutter
	flutter analyze

format: ## Formata o código Dart
	dart format lib test

test: ## Roda os testes Flutter
	flutter test

clean: ## Remove artefatos de build local (inclusive APKs)
	flutter clean
	rm -rf build