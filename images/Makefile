DOCKER_NAMESPACE ?= gnomesoft
IMAGE ?= myapp
DOCKER_FILE ?= Dockerfile
DOCKER_TAG ?= $(shell git log --format="%h" -n 1)
DOCKER_PORT ?= 8080

all:
	$(MAKE) auth build push

with_test:
	$(MAKE) auth build test push

_auth:
	$(echo ${DOCKER_PASS} | docker login -u ${DOCKER_NAMESPACE} --password-stdin)

_build:
	docker build --tag ${DOCKER_NAMESPACE}/${IMAGE}:${DOCKER_TAG} ./${IMAGE} -f ${IMAGE}/${DOCKER_FILE}

_test:
	docker run --rm -d -p ${DOCKER_PORT}:${DOCKER_PORT} ${DOCKER_NAMESPACE}/${IMAGE}:${DOCKER_TAG}
	bash ./test_container.sh ${IMAGE}
	docker stop $$(docker ps -q --filter "label=name=${IMAGE}")

_push:
	docker push ${DOCKER_NAMESPACE}/${IMAGE}:${DOCKER_TAG}

auth:
	$(MAKE) _auth

build:
	$(MAKE) _build

test:
	$(MAKE) _test

push:
	$(MAKE) _push