DOCKER_RELEASE_REG=lsyf
DOCKER_IMAGE=bookstack
DOCKER_IMAGE_DEV=${DOCKER_IMAGE}-dev
DOCKER_INTERNAL_TAG := 22.04.02.lf.3
DOCKER_RELEASE_TAG := ${DOCKER_INTERNAL_TAG}
BUILD_DATE := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
VCS_URL := https://github.com/lsyf/docker-bookstack-wiki

.PHONY: build  push pull release

build:
	docker image build . \
	-t $(DOCKER_RELEASE_REG)/$(DOCKER_IMAGE_DEV):$(DOCKER_INTERNAL_TAG) \
	--build-arg VCS_REF=$(DOCKER_INTERNAL_TAG) \
	--build-arg BUILD_DATE=$(BUILD_DATE) \
	--build-arg VCS_URL=$(VCS_URL)

push-dev:
	docker push $(DOCKER_RELEASE_REG)/$(DOCKER_IMAGE_DEV):$(DOCKER_INTERNAL_TAG)

pull:
	docker pull $(DOCKER_RELEASE_REG)/$(DOCKER_IMAGE_DEV):$(DOCKER_INTERNAL_TAG)

release:
	docker tag $(DOCKER_RELEASE_REG)/$(DOCKER_IMAGE_DEV):$(DOCKER_INTERNAL_TAG) $(DOCKER_RELEASE_REG)/$(DOCKER_IMAGE):$(DOCKER_RELEASE_TAG)
	docker tag $(DOCKER_RELEASE_REG)/$(DOCKER_IMAGE_DEV):$(DOCKER_INTERNAL_TAG) $(DOCKER_RELEASE_REG)/$(DOCKER_IMAGE):latest

push-release:
	docker push $(DOCKER_RELEASE_REG)/$(DOCKER_IMAGE):$(DOCKER_RELEASE_TAG)
	docker push $(DOCKER_RELEASE_REG)/$(DOCKER_IMAGE):latest


e2e:
	@BOOKSTACK_IMAGE="$(DOCKER_RELEASE_REG)/${DOCKER_IMAGE_DEV}:${DOCKER_INTERNAL_TAG}" docker-compose -f docker-compose.test.yml up -d
	@BOOKSTACK_IMAGE="$(DOCKER_RELEASE_REG)/${DOCKER_IMAGE_DEV}:${DOCKER_INTERNAL_TAG}" docker-compose -f docker-compose.test.yml run --rm sut
	@BOOKSTACK_IMAGE="$(DOCKER_RELEASE_REG)/${DOCKER_IMAGE_DEV}:${DOCKER_INTERNAL_TAG}" docker-compose -f docker-compose.test.yml down -v

