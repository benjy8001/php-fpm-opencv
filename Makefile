SHELL=/bin/sh

## Colors
ifndef VERBOSE
.SILENT:
endif
PHP_VERSIONS := 7.2 7.3 7.4
PHP_VERSION ?= $(lastword $(sort $(PHP_VERSIONS)))
COLOR_COMMENT=\033[0;32m
IMAGE_PATH=/benjy80/php-fpm-opencv
REGISTRY_DOMAIN=docker.io
VERSION=4.1.1
IMAGE=${REGISTRY_DOMAIN}${IMAGE_PATH}:${VERSION}

## Help
help:
	printf "${COLOR_COMMENT}Usage:${COLOR_RESET}\n"
	printf " make [target]\n\n"
	printf "${COLOR_COMMENT}Available targets:${COLOR_RESET}\n"
	awk '/^[a-zA-Z\-\_0-9\.@]+:/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")); \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			printf " ${COLOR_INFO}%-16s${COLOR_RESET} %s\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)

## build and push image
all: build push_image

## build image and tags it
build:
	@for php_version in $(PHP_VERSIONS); do \
		docker build -f $$php_version/Dockerfile . -t ${REGISTRY_DOMAIN}${IMAGE_PATH}-$$php_version:${VERSION}; \
	done

## login on registry
registry_login:
	docker login ${REGISTRY_DOMAIN}

## push image
push_image: registry_login
	for php_version in $(PHP_VERSIONS); do \
		docker push ${REGISTRY_DOMAIN}${IMAGE_PATH}-$$php_version:${VERSION}; \
	done
