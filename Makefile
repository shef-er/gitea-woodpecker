#!/usr/bin/env make
# Makefile readme (ru): <http://linux.yaroslavl.ru/docs/prog/gnu_make_3-79_russian_manual.html>
# Makefile readme (en): <https://www.gnu.org/software/make/manual/html_node/index.html#SEC_Contents>

ifneq (,$(wildcard ./.env))
    include .env
    export
endif

DOCKER_BIN = $(shell command -v docker 2> /dev/null)
DC_BIN = $(shell command -v docker-compose 2> /dev/null)
DC_RUN_ARGS = --rm --user "$(shell id -u):$(shell id -g)"
CERTBOT_COMMAND = certbot certonly --agree-tos --webroot --webroot-path /var/www/acme-challenge --rsa-key-size $(NGINX_SSL_KEY_SIZE) --email $(EMAIL) -d $(DOMAIN)

.PHONY : help build up down restart shell logs pull dhparam cert cert-renew
.DEFAULT_GOAL : help

help: ## Show this help
	@printf "\033[33m%s:\033[0m\n" 'Available commands'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[32m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build containers
	$(DC_BIN) build

shell: ## Start shell into gitea container
	$(DC_BIN) run $(DC_RUN_ARGS) gitea sh

up: ## Create and start containers
	$(DC_BIN) up --detach

down: ## Stop and remove containers, networks, images, and volumes
	$(DC_BIN) down -t 5

restart: down up ## Restart all containers

logs: ## Show docker logs
	$(DC_BIN) logs --follow

pull: ## Pulling newer versions of used docker images
	$(DC_BIN) pull

dhparam: ## Generate dhparam
	@openssl dhparam -out $(NGINX_DHPARAM_FILENAME) $(NGINX_DHPARAM_SIZE)

cert: ## Generate new ssl certificate via certbot
	@$(DC_BIN) -f docker-compose.fallback.yml up --detach
	@$(DC_BIN) -f docker-compose.fallback.yml run --rm --entrypoint "$(CERTBOT_COMMAND)" certbot
	@$(DC_BIN) -f docker-compose.fallback.yml down

cert-renew: ## Renew ssl certificate via certbot
	@$(DC_BIN) run --rm --entrypoint "$(CERTBOT_COMMAND)" certbot

