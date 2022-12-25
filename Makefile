#!/usr/bin/env make
# Makefile readme (ru): <http://linux.yaroslavl.ru/docs/prog/gnu_make_3-79_russian_manual.html>
# Makefile readme (en): <https://www.gnu.org/software/make/manual/html_node/index.html#SEC_Contents>

DOCKER_BIN = $(shell command -v docker 2> /dev/null)
DC_BIN = $(shell command -v docker-compose 2> /dev/null)

.DEFAULT_GOAL: help

.PHONY: help
help: ## Show this help
	@printf "\033[33m%s:\033[0m\n" 'Available commands'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[32m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: build
build: ## Build containers
	$(DC_BIN) build

.PHONY: up
up: ## Create and start containers
	$(DC_BIN) up --detach

.PHONY: down
down: ## Stop and remove containers, networks, images, and volumes
	$(DC_BIN) down -t 5

.PHONY: restart
restart: down up ## Restart all containers

.PHONY: logs
logs: ## Show docker logs
	$(DC_BIN) logs --follow

.PHONY: setup
setup: ## Run setup script
	sh setup.sh
