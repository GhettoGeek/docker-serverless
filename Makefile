NODE_ALPINE_IMAGE ?= node:lts-alpine
SERVERLESS_VERSION ?= $(shell docker run --rm $(NODE_ALPINE_IMAGE) npm show serverless version)
IMAGE_NAME ?= amaysim/serverless
IMAGE = $(IMAGE_NAME):$(SERVERLESS_VERSION)
ROOT_DIR = $(dir $(abspath $(firstword $(MAKEFILE_LIST))))

ciTest: deps build clean
ciDeploy: deps build push clean

deps:
	$(info Pull latest version of $(NODE_ALPINE_IMAGE))
	docker pull $(NODE_ALPINE_IMAGE)

build: env-SERVERLESS_VERSION
	docker build --no-cache \
		--build-arg NODE_ALPINE_IMAGE=$(NODE_ALPINE_IMAGE) \
		--build-arg SERVERLESS_VERSION=$(SERVERLESS_VERSION) \
		-t $(IMAGE) .
	docker run --rm $(IMAGE) bash -c 'serverless --version | grep $(SERVERLESS_VERSION)'

push: env-DOCKER_USERNAME env-DOCKER_ACCESS_TOKEN
	@echo "$(DOCKER_ACCESS_TOKEN)" | docker login --username "$(DOCKER_USERNAME)" --password-stdin docker.io
	docker push $(IMAGE)
	docker logout

pull:
	docker pull $(IMAGE)

shell:
	docker run --rm -it -v $(ROOT_DIR):/opt/app $(IMAGE) bash

clean:
	docker rmi -f $(IMAGE)

env-%:
	$(info Check if $* is not empty)
	@docker run --rm -e ENV_VAR=$($*) $(NODE_ALPINE_IMAGE) sh -c '[ -z "$$ENV_VAR" ] && echo "Error: $* is empty" && exit 1 || exit 0'
