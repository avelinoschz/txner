INSTALL_BIN_DIR := $(CURDIR)/bin
BUILD_TARGET_DIR := $(CURDIR)/generated/bin
SQL_DIR := $(CURDIR)/sql

export GOBIN := $(INSTALL_BIN_DIR)

GOOSE_VERSION := v3.10.0
SQLC_VERSION := v1.19.1

DOCKER_COMPOSE_DEV_DB_PROJECT := dev-db

DEV_DB_POSTGRESQL_PORT := 5432
DEV_DB_BASE_POSTGRESQL_URL := postgres://postgres@localhost:$(DEV_DB_POSTGRESQL_PORT)/?sslmode=disable
DEV_DB_POSTGRESQL_NAME := txner
DEV_DB_POSTGRESQL_URL := postgres://postgres@localhost:$(DEV_DB_POSTGRESQL_PORT)/$(DEV_DB_POSTGRESQL_NAME)?sslmode=disable

.PHONY: setup-go
setup-go:
	go install github.com/kyleconroy/sqlc/cmd/sqlc@$(SQLC_VERSION)
	go install -tags='no_mysql no_sqlite3 no_ydb' github.com/pressly/goose/v3/cmd/goose@$(GOOSE_VERSION)

.PHONY: setup-node
setup-node:
	npm install sql-formatter

.PHONY: lint-sql
lint-sql:
	npx sql-formatter -h

.PHONY: ensure-docker
ensure-docker:
	@if ! docker info >/dev/null 2>&1; then \
		echo "Docker is not available. Please ensure Docker is installed and running."; \
		exit 1; \
	fi

.PHONY: dev-db-status
dev-db-status: export DATABASE_URL=$(DEV_DB_POSTGRESQL_URL)
dev-db-status:
	"$(INSTALL_BIN_DIR)/goose" -dir "$(CURDIR)/sql/migrations" postgres "${DATABASE_URL}" status

.PHONY: dev-db-migrate
dev-db-migrate: # TODO target a specific migration version.
dev-db-migrate: export DATABASE_URL=$(DEV_DB_POSTGRESQL_URL)
dev-db-migrate:
	"$(INSTALL_BIN_DIR)/goose" -dir "$(CURDIR)/sql/migrations" postgres "${DATABASE_URL}" up

.PHONY: ensure-test-db
ensure-test-db: export DATABASE_URL=$(DEV_DB_BASE_POSTGRESQL_URL)
ensure-test-db:
	echo "SELECT 'CREATE DATABASE $(DEV_DB_POSTGRESQL_NAME)' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$(DEV_DB_POSTGRESQL_NAME)')\gexec" | psql "$(DATABASE_URL)"
	$(MAKE) dev-db-migrate
	$(MAKE) dump-db-schema

.PHONY: run-dev-db
run-dev-db: ensure-docker
	docker-compose -p $(DOCKER_COMPOSE_DEV_DB_PROJECT) -f $(CURDIR)/docker/compose/docker-compose-postgres.yaml up --detach

.PHONY: wait-dev-db
wait-dev-db: run-dev-db
	scripts/wait-for-postgres.sh 20 0.2 $(DEV_DB_POSTGRESQL_PORT)

.PHONY: ensure-dev-db
ensure-dev-db:
ensure-dev-db: export DB_POSTGRESQL_PORT=$(DEV_DB_POSTGRESQL_PORT)
ensure-dev-db: wait-dev-db ensure-test-db
	@true

.PHONY: clean-dev-db
clean-dev-db: ensure-docker
	docker-compose -p $(DOCKER_COMPOSE_DEV_DB_PROJECT) -f $(CURDIR)/docker/compose/docker-compose-postgres.yaml down --volumes

.PHONY: stop-dev-db
stop-dev-db: ensure-docker
	docker-compose -p $(DOCKER_COMPOSE_DEV_DB_PROJECT) -f $(CURDIR)/docker/compose/docker-compose-postgres.yaml down

.PHONY: check-psql
check-psql:
	@if ! psql --version >/dev/null 2>&1; then \
		echo "psql is not installed. Please install PostgreSQL client."; \
		exit 1; \
	fi

.PHONY: dump-db-schema
dump-db-schema:
	pg_dump -h localhost -p $(DB_POSTGRESQL_PORT) -U postgres -d $(DEV_DB_POSTGRESQL_NAME) \
		--schema-only \
		--no-owner \
		--no-privileges \
		--no-publications \
		--no-subscriptions \
		--no-tablespaces \
		| grep -v -e "Dumped by pg_dump" -e "Dumped from database version" > $(CURDIR)/sql/schema.sql

.PHONY: connect-dev-db
connect-dev-db: check-psql
	psql -h localhost -p $(DEV_DB_POSTGRESQL_PORT) -U postgres $(DEV_DB_POSTGRESQL_NAME)

.PHONY: format-sql
format-sql: # TODO apply on multiple query files
	npx sql-formatter $(SQL_DIR)/query.sql --config $(SQL_DIR)/formatter/config.json --fix 

.PHONY: build-go
build-go:
	CGO_ENABLED=0 go build -o $(BUILD_TARGET_DIR)/go/cmd/txner $(CURDIR)/go/cmd/txner/

.PHONY:
run-go: build-go
	$(BUILD_TARGET_DIR)/go/cmd/txner
