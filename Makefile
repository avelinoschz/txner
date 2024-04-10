INSTALL_BIN_DIR := $(CURDIR)/bin

export GOBIN := $(INSTALL_BIN_DIR)

GOOSE_VERSION := v3.10.0

.PHONY: setup
setup:
	go install -tags='no_postgres no_mysql no_ydb' github.com/pressly/goose/v3/cmd/goose@$(GOOSE_VERSION)


