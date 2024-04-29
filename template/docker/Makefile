#
# Arguments
# ==============
# - DOCKER_IMAGE
# - DOCKER_TAG
# - AWS_ACCOUNT_ID
# - AWS_DEFAULT_REGION
#

docker.build:
	@echo "DOCKER_IMAGE:    $(DOCKER_IMAGE)"
	@echo "DOCKER_TAG:      $(DOCKER_TAG)"
	@echo "DOCKER_DESCRIBE: $(DOCKER_DESCRIBE)"
	$(call docker_build,$(DOCKER_IMAGE):$(DOCKER_TAG))
	@if [ ! -z "$(DOCKER_DESCRIBE)" ]; then \
		$(call docker_build,$(DOCKER_IMAGE):$(DOCKER_DESCRIBE)); \
	fi

docker.push:
	@if [ "$(REGISTRY)" != "local" ]; then \
		$(call docker_push,$(DOCKER_IMAGE):$(DOCKER_TAG)); \
		if [ ! -z "$(DOCKER_DESCRIBE)" ]; then \
			$(call docker_push,$(DOCKER_IMAGE):$(DOCKER_DESCRIBE)); \
		fi \
	fi

docker.run:
	$(call docker_run,$(DOCKER_IMAGE):$(DOCKER_TAG),,$(CMD))

docker.shell:
	$(call docker_run,$(DOCKER_IMAGE):$(DOCKER_TAG),--entrypoint=,/bin/bash || exit 0)

docker.cmd:
	$(call docker_run,$(DOCKER_IMAGE):$(DOCKER_TAG),--entrypoint=$(ENTRYPOINT),$(CMD))

docker.local.run:
	$(call docker_local_run,$(DOCKER_IMAGE):$(DOCKER_TAG),,$(CMD))

docker.local.shell:
	$(call docker_local_run,$(DOCKER_IMAGE):$(DOCKER_TAG),--entrypoint=,/bin/bash || exit 0)

docker.local.cmd:
	$(call docker_local_run,$(DOCKER_IMAGE):$(DOCKER_TAG),--entrypoint=$(ENTRYPOINT),$(CMD))

define docker_build
	docker build -t $(1) .
endef

define docker_push
	docker push $(1)
endef

define docker_run
  @if [ -t 1 ]; then \
    docker run -it --rm $(2) $(1) $(3); \
  else \
    docker run --rm $(2) $(1) $(3); \
  fi
endef

define docker_workdir
	$(1) := $(shell docker run -it --rm --entrypoint=pwd $(2))
endef

define docker_local_run
	$(eval $(call docker_workdir,WORKDIR,$(1)))
	$(call docker_run,$(1),$(2) -v $(ROOTDIR):$(WORKDIR),$(3))
endef

SHELL        := $(shell which bash)
ROOTDIR      := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
APPLICATION  := $(shell basename $(ROOTDIR))

ifeq ($(shell [[ ! -z "$(AWS_ACCOUNT_ID)" && ! -z "$(AWS_DEFAULT_REGION)" ]] && echo 0 ),0)
	REGISTRY := aws
	DOCKER_IMAGE := $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_DEFAULT_REGION).amazonaws.com/$(APPLICATION)
else
	REGISTRY := local
	DOCKER_IMAGE := $(APPLICATION)
endif

ifeq ($(DOCKER_TAG),)
	DOCKER_TAG := $(shell git rev-parse --abbrev-ref HEAD | sed -e 's/\//_/')
else
	DOCKER_DESCRIBE := $(shell git describe --tags --match $(DOCKER_TAG))
endif
