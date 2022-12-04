#!/usr/bin/env make
# Makefile readme (ru): <http://linux.yaroslavl.ru/docs/prog/gnu_make_3-79_russian_manual.html>
# Makefile readme (en): <https://www.gnu.org/software/make/manual/html_node/index.html#SEC_Contents>

ifneq (,$(wildcard ./.env))
    include .env
    export
endif

SHELL = /bin/sh
DOCKER_BIN = $(shell command -v docker 2> /dev/null)
DC_BIN = $(shell command -v docker-compose 2> /dev/null)
DC_RUN_ARGS = --rm --user "$(shell id -u):$(shell id -g)"

cwd = $(shell pwd)

.PHONY : help build up down restart shell logs pull gen-dhparam gen-certificates gen-certificates-staging gen-dummy-cert
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

gen-dhparam: ## Generate dhparam
	@openssl dhparam -out $(NGINX_DHPARAM_FILENAME) $(NGINX_DHPARAM_SIZE)

gen-certificates: ## Generate ssl certificate via certbot
	@$(DC_BIN) -f docker-compose.fallback.yml up
	@$(DC_BIN) -f docker-compose.fallback.yml run --rm --entrypoint "certbot certonly --agree-tos --webroot --webroot-path /var/www/certbot --rsa-key-size $(NGINX_SSL_KEY_SIZE) --email $(EMAIL) -d $(DOMAIN)" certbot
	@$(DC_BIN) -f docker-compose.fallback.yml down

gen-certificates-staging: ## Generate staging ssl certificate via certbot
	@$(DC_BIN) -f docker-compose.fallback.yml up
	@$(DC_BIN) -f docker-compose.fallback.yml run --rm --entrypoint "certbot certonly --staging --agree-tos --webroot --webroot-path /var/www/certbot --rsa-key-size $(NGINX_SSL_KEY_SIZE) --email $(EMAIL) -d $(DOMAIN)" certbot
	@$(DC_BIN) -f docker-compose.fallback.yml down

gen-dummy-cert: ## Generate dummy ssl certificate
	@$(DC_BIN) -f docker-compose.fallback.yml run --rm --entrypoint "openssl req -x509 -nodes -days 1 -newkey rsa:$(NGINX_SSL_KEY_SIZE) -keyout '$(NGINX_SSL_KEY_FILENAME)' -out '$(NGINX_SSL_CERT_FILENAME)' -subj '/CN=$(DOMAIN)'" certbot
