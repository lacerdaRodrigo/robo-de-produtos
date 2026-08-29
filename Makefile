# Atalhos do repositório. Os comandos Flutter usam o checkout atual.

.DEFAULT_GOAL := help

.PHONY: help dev apk

help: ## Lista os atalhos do app
	@$(MAKE) --no-print-directory -C app help

dev: ## Executa o app Flutter atual no Android conectado
	@$(MAKE) --no-print-directory -C app dev

apk: ## Gera o APK de release do app para copiar a outro Android
	@$(MAKE) --no-print-directory -C app apk
