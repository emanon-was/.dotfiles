SHELL := bash

# この makefile が置かれたプロジェクトのルートと名前。
PROJECT_ROOT ?= $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
PROJECT_NAME ?= $(shell basename "$(PROJECT_ROOT)")

# docker build に渡す基本設定。
DOCKER_CONTEXT ?= .
DOCKERFILE ?= Dockerfile
DOCKER_BUILD_ARGS ?=

# docker run に渡す基本設定。
DOCKER_RUN_ARGS ?=
DOCKER_COMMAND ?=
DOCKER_ENTRYPOINT ?=
DOCKER_WORKDIR ?= /workspace

# AWS_ACCOUNT_ID と AWS_DEFAULT_REGION がある場合は ECR を registry として使う。
ifdef AWS_ACCOUNT_ID
ifdef AWS_DEFAULT_REGION
DOCKER_REGISTRY ?= $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_DEFAULT_REGION).amazonaws.com
endif
endif

# image 名と tag。tag は現在の git branch 名から作る。
DOCKER_IMAGE_NAME ?= $(PROJECT_NAME)
DOCKER_IMAGE ?= $(if $(DOCKER_REGISTRY),$(DOCKER_REGISTRY)/$(DOCKER_IMAGE_NAME),$(DOCKER_IMAGE_NAME))
DOCKER_TAG ?= $(shell git rev-parse --abbrev-ref HEAD 2>/dev/null | sed 's#[^A-Za-z0-9_.-]#_#g')
DOCKER_TAG := $(if $(DOCKER_TAG),$(DOCKER_TAG),latest)
DOCKER_FULL_IMAGE ?= $(DOCKER_IMAGE):$(DOCKER_TAG)

.PHONY: docker.image docker.build docker.push docker.run docker.shell docker.cmd
.PHONY: docker.local.run docker.local.shell docker.local.cmd

# build/push/run で使う image 名を表示する。
docker.image:
	@printf '%s\n' "$(DOCKER_FULL_IMAGE)"

# Docker image を build する。
docker.build:
	docker build \
		-f "$(DOCKERFILE)" \
		-t "$(DOCKER_FULL_IMAGE)" \
		$(DOCKER_BUILD_ARGS) \
		"$(DOCKER_CONTEXT)"

# Docker image を registry へ push する。
docker.push:
	docker push "$(DOCKER_FULL_IMAGE)"

# Docker image をそのまま実行する。必要なら DOCKER_COMMAND を渡す。
docker.run:
	$(call docker_run,$(DOCKER_FULL_IMAGE),$(DOCKER_RUN_ARGS),$(DOCKER_COMMAND))

# entrypoint を外して bash shell で入る。
docker.shell:
	$(call docker_run,$(DOCKER_FULL_IMAGE),$(DOCKER_RUN_ARGS) --entrypoint=,/bin/bash)

# 任意の entrypoint と command で実行する。
docker.cmd:
	$(call docker_run,$(DOCKER_FULL_IMAGE),$(DOCKER_RUN_ARGS) --entrypoint="$(DOCKER_ENTRYPOINT)",$(DOCKER_COMMAND))

# プロジェクトルートを container に mount して実行する。
docker.local.run:
	$(call docker_local_run,$(DOCKER_FULL_IMAGE),$(DOCKER_RUN_ARGS),$(DOCKER_COMMAND))

# プロジェクトルートを mount した状態で bash shell に入る。
docker.local.shell:
	$(call docker_local_run,$(DOCKER_FULL_IMAGE),$(DOCKER_RUN_ARGS) --entrypoint=,/bin/bash)

# プロジェクトルートを mount し、任意の entrypoint と command で実行する。
docker.local.cmd:
	$(call docker_local_run,$(DOCKER_FULL_IMAGE),$(DOCKER_RUN_ARGS) --entrypoint="$(DOCKER_ENTRYPOINT)",$(DOCKER_COMMAND))

# terminal から実行している場合だけ -it を付けて docker run する。
define docker_run
	@tty_args=""; \
	if [ -t 0 ] && [ -t 1 ]; then tty_args="-it"; fi; \
	docker run $$tty_args --rm $(2) "$(1)" $(3)
endef

# プロジェクトルートを DOCKER_WORKDIR に mount して docker run する。
define docker_local_run
	$(call docker_run,$(1),$(2) -v "$(PROJECT_ROOT):$(DOCKER_WORKDIR)" -w "$(DOCKER_WORKDIR)",$(3))
endef
