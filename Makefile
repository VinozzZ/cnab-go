ifeq ($(OS),Windows_NT)
	TARGET = $(PROJECT).exe
	SHELL  = cmd.exe
	CHECK  = where.exe
else
	TARGET = $(PROJECT)
	SHELL  ?= bash
	CHECK  ?= which
endif

.PHONY: fetch-schemas
fetch-schemas:
	@go run fetch-schemas.go

.PHONY: build
build:
	go build ./...

.PHONY: test
test:
	go test ./...

.PHONY: lint
lint:
	golangci-lint run --config ./golangci.yml

.PHONY: create-test-cluster
create-test-cluster:
	./e2e-kind.sh create_kind_cluster

.PHONY: delete-test-cluster
delete-test-cluster:
	./e2e-kind.sh delete_kind_cluster

GOPATH := $(shell go env GOPATH)
HAS_GOLANGCI := $(shell $(CHECK) golangci-lint)
GOLANGCI_VERSION := v1.21.0
HAS_KIND := $(shell $(CHECK) kind)
HAS_KUBECTL := $(shell $(CHECK) kubectl)
HAS_GOCOV_XML := $(shell $(CHECK) gocov-xml;)
HAS_GOCOV := $(shell $(CHECK) gocov;)
HAS_GO_JUNIT_REPORT := $(shell $(CHECK) go-junit-report;)

.PHONY: bootstrap
bootstrap:

ifndef HAS_GOLANGCI
	curl -sfL https://install.goreleaser.com/github.com/golangci/golangci-lint.sh | sh -s -- -b $(GOPATH)/bin $(GOLANGCI_VERSION)
endif
ifndef HAS_KIND
	go get sigs.k8s.io/kind@v0.11.1
endif
ifndef HAS_KUBECTL
	echo "Follow instructions at https://kubernetes.io/docs/tasks/tools/install-kubectl/ to install kubectl."
endif
ifndef HAS_GOCOV_XML
	go get github.com/AlekSi/gocov-xml
endif
ifndef HAS_GOCOV
	go get github.com/axw/gocov/gocov@v1.0.0
endif
ifndef HAS_GO_JUNIT_REPORT
	go get github.com/jstemmer/go-junit-report@v0.9.1
endif

	@# go get to install global tools with modules modify our dependencies. Reset them back
	git checkout go.mod go.sum

.PHONY: coverage
coverage: compile-integration-tests
	./e2e-kind.sh main

.PHONY: compile-integration-tests
compile-integration-tests:
	@go test -tags=integration -run nothing ./...
