DOCKER_NAMESPACE ?= gnomesoft
IMAGE ?= myapp
DOCKER_FILE ?= Dockerfile
DOCKER_TAG ?= $(shell git log --format="%h" -n 1)
DOCKER_PORT ?= 8080
DOCKER_BUILD_ARGS ?= '--build-arg="ARCH=amd64"'
DOCKER_PASS ?= ''

.PHONY: _auth _build _test _push all

all:
	$(MAKE) auth build push

with_test:
	$(MAKE) auth build test push

_auth:
	@echo ${DOCKER_PASS} | docker login -u ${DOCKER_NAMESPACE} --password-stdin

_build:
	docker build ${DOCKER_BUILD_ARGS} --tag ${DOCKER_NAMESPACE}/${IMAGE}:${DOCKER_TAG} ./${IMAGE} -f ${IMAGE}/${DOCKER_FILE}

_test:
	docker run --rm -d -p ${DOCKER_PORT}:${DOCKER_PORT} ${DOCKER_NAMESPACE}/${IMAGE}:${DOCKER_TAG}
	bash ./test_container.sh ${IMAGE}
	docker stop $$(docker ps -q --filter "label=name=${IMAGE}")

_push:
	docker push ${DOCKER_NAMESPACE}/${IMAGE}:${DOCKER_TAG}
	docker tag ${DOCKER_NAMESPACE}/${IMAGE}:${DOCKER_TAG} ${DOCKER_NAMESPACE}/${IMAGE}:latest
	docker push ${DOCKER_NAMESPACE}/${IMAGE}:latest
	echo "Do not use the latest tag in production !!"

auth:
	$(MAKE) _auth

build:
	$(MAKE) _build

test:
	$(MAKE) _test

push:
	$(MAKE) _push
