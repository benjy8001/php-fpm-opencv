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
		docker build --target fpm-prod -f php-fpm/$$php_version/Dockerfile ./php-fpm/$$php_version -t ${REGISTRY_DOMAIN}${IMAGE_PATH}-$$php_version:${VERSION}; \
	done

	docker build -f httpd/Dockerfile ./httpd -t ${REGISTRY_DOMAIN}${IMAGE_PATH}-httpd

## login on registry
registry_login:
	docker login ${REGISTRY_DOMAIN}

## push image
push_image: registry_login
	for php_version in $(PHP_VERSIONS); do \
		docker push ${REGISTRY_DOMAIN}${IMAGE_PATH}-$$php_version:${VERSION}; \
	done
	docker push ${REGISTRY_DOMAIN}${IMAGE_PATH}-httpd

## build image and tags it
build_http:
	docker build -f httpd/Dockerfile ./httpd -t ${REGISTRY_DOMAIN}${IMAGE_PATH}-httpd

## push image
push_http_image: registry_login
	docker push ${REGISTRY_DOMAIN}${IMAGE_PATH}-httpd

## build image and tags it
build_72:
	docker build --target fpm-prod -f php-fpm/7.2/Dockerfile ./php-fpm/7.2 -t ${REGISTRY_DOMAIN}${IMAGE_PATH}-7.2:${VERSION}; \

## push image
push_72_image: registry_login
	docker push ${REGISTRY_DOMAIN}${IMAGE_PATH}-7.2:${VERSION}

## build image and tags it
build_73:
	docker build --target fpm-prod -f php-fpm/7.3/Dockerfile ./php-fpm/7.3 -t ${REGISTRY_DOMAIN}${IMAGE_PATH}-7.3:${VERSION}; \

## push image
push_73_image: registry_login
	docker push ${REGISTRY_DOMAIN}${IMAGE_PATH}-7.3:${VERSION}