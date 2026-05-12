SHELL := bash

PROJECT_ROOT ?= $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
PROJECT_NAME ?= $(shell basename "$(PROJECT_ROOT)")

DOCKER_CONTEXT ?= .
DOCKERFILE ?= Dockerfile
DOCKER_BUILD_ARGS ?=
DOCKER_RUN_ARGS ?=
DOCKER_COMMAND ?=
DOCKER_ENTRYPOINT ?=
DOCKER_WORKDIR ?= /workspace

ifdef AWS_ACCOUNT_ID
ifdef AWS_DEFAULT_REGION
DOCKER_REGISTRY ?= $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_DEFAULT_REGION).amazonaws.com
endif
endif

DOCKER_IMAGE_NAME ?= $(PROJECT_NAME)
DOCKER_IMAGE ?= $(if $(DOCKER_REGISTRY),$(DOCKER_REGISTRY)/$(DOCKER_IMAGE_NAME),$(DOCKER_IMAGE_NAME))
DOCKER_TAG ?= $(shell git rev-parse --abbrev-ref HEAD 2>/dev/null | sed 's#[^A-Za-z0-9_.-]#_#g')
DOCKER_TAG := $(if $(DOCKER_TAG),$(DOCKER_TAG),latest)
DOCKER_FULL_IMAGE ?= $(DOCKER_IMAGE):$(DOCKER_TAG)

.PHONY: docker.image docker.build docker.push docker.run docker.shell docker.cmd
.PHONY: docker.local.run docker.local.shell docker.local.cmd

docker.image:
	@printf '%s\n' "$(DOCKER_FULL_IMAGE)"

docker.build:
	docker build \
		-f "$(DOCKERFILE)" \
		-t "$(DOCKER_FULL_IMAGE)" \
		$(DOCKER_BUILD_ARGS) \
		"$(DOCKER_CONTEXT)"

docker.push:
	docker push "$(DOCKER_FULL_IMAGE)"

docker.run:
	$(call docker_run,$(DOCKER_FULL_IMAGE),$(DOCKER_RUN_ARGS),$(DOCKER_COMMAND))

docker.shell:
	$(call docker_run,$(DOCKER_FULL_IMAGE),$(DOCKER_RUN_ARGS) --entrypoint=,/bin/bash)

docker.cmd:
	$(call docker_run,$(DOCKER_FULL_IMAGE),$(DOCKER_RUN_ARGS) --entrypoint="$(DOCKER_ENTRYPOINT)",$(DOCKER_COMMAND))

docker.local.run:
	$(call docker_local_run,$(DOCKER_FULL_IMAGE),$(DOCKER_RUN_ARGS),$(DOCKER_COMMAND))

docker.local.shell:
	$(call docker_local_run,$(DOCKER_FULL_IMAGE),$(DOCKER_RUN_ARGS) --entrypoint=,/bin/bash)

docker.local.cmd:
	$(call docker_local_run,$(DOCKER_FULL_IMAGE),$(DOCKER_RUN_ARGS) --entrypoint="$(DOCKER_ENTRYPOINT)",$(DOCKER_COMMAND))

define docker_run
	@tty_args=""; \
	if [ -t 0 ] && [ -t 1 ]; then tty_args="-it"; fi; \
	docker run $$tty_args --rm $(2) "$(1)" $(3)
endef

define docker_local_run
	$(call docker_run,$(1),$(2) -v "$(PROJECT_ROOT):$(DOCKER_WORKDIR)" -w "$(DOCKER_WORKDIR)",$(3))
endef
