# Atalhos do repositório. Os comandos Flutter usam o checkout atual.

.DEFAULT_GOAL := help

.PHONY: help dev

help: ## Lista os atalhos do app
	@$(MAKE) --no-print-directory -C app help

dev: ## Executa o app Flutter atual no Android conectado
	@$(MAKE) --no-print-directory -C app dev
