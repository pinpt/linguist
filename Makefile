.PHONY: all docker dev build release

NAME := linguist
ORG := pinpt
PKG := $(ORG)/$(NAME)
REPO_ID ?= 0

SHELL := /bin/bash
BASEDIR := $(shell echo $${PWD})
BUILD := $(shell git rev-parse HEAD | cut -c1-8)
COMMITSHA := $(shell git rev-parse HEAD)
SRC := $(shell find . -type f -name '*.go' -not -path './vendor/*' -not -path './.git/*' -not -path './hack/*')
VERSION := $(shell cat $(BASEDIR)/VERSION)
DOCKERFILE ?= Dockerfile
DOCKERNAME ?= $(NAME)
DOCKERTAG ?= $(shell git describe --always)
DOCKERPKG := $(ORG)/$(DOCKERNAME):$(DOCKERTAG)

all: build

docker:
	@docker build --build-arg COMMITSHA=$(COMMITSHA) --build-arg VERSION=$(VERSION) --build-arg BUILD=$(BUILD) --build-arg NAME=$(NAME) --build-arg REPO_ID=$(REPO_ID) -t $(DOCKERPKG) -f $(DOCKERFILE) .

dev: docker

build: dev

release-dev: dev
	docker push $(DOCKERPKG)

push:
	docker push $(DOCKERPKG)

release:
	DOCKERTAG=$(VERSION) make docker push
