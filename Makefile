.PHONY: all docker-nobinary docker-linguist build

NAME := linguist
ORG := pinpt
PKG := $(ORG)/$(NAME)
REPO_ID ?= 70075614
DOCKERFILE ?= Dockerfile
DOCKERNAME ?= $(NAME)
DOCKERLABEL ?= latest
DOCKERPKG ?= $(ORG)/$(DOCKERNAME):$(DOCKERLABEL)

SHELL := /bin/bash
BASEDIR := $(shell echo $${PWD})
BUILD := $(shell git rev-parse HEAD | cut -c1-8)
COMMITSHA := $(shell git rev-parse HEAD)
SRC := $(shell find . -type f -name '*.go' -not -path './vendor/*' -not -path './.git/*' -not -path './hack/*')
VERSION := $(shell cat $(BASEDIR)/VERSION)


all: build

docker-nobinary:
	@docker build --build-arg COMMITSHA=$(COMMITSHA) --build-arg VERSION=$(VERSION) --build-arg BUILD=$(BUILD) --build-arg NAME=$(NAME) --build-arg REPO_ID=$(REPO_ID) -t $(PKG) -f $(DOCKERFILE) .

docker-linguist:
	NAME=linguist DOCKERFILE=Dockerfile make docker-nobinary

build: docker-linguist