INSTALL_BIN_DIR := $(CURDIR)/bin

export GOBIN := $(INSTALL_BIN_DIR)

GOOSE_VERSION := v3.10.0

DOCKER_COMPOSE_DEV_DB_PROJECT := dev-db

DEV_DB_POSTGRESQL_PORT := 5432
DEV_DB_BASE_POSTGRESQL_URL := postgres://postgres@localhost:$(DEV_DB_POSTGRESQL_PORT)/?sslmode=disable
DEV_DB_POSTGRESQL_NAME := txner
DEV_DB_POSTGRESQL_URL := postgres://postgres@localhost:$(DEV_DB_POSTGRESQL_PORT)/$(DEV_DB_POSTGRESQL_NAME)?sslmode=disable

.PHONY: setup-deps
setup:
	go install -tags='no_mysql no_sqlite3 no_ydb' github.com/pressly/goose/v3/cmd/goose@$(GOOSE_VERSION)

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
dev-db-migrate: ## TODO target a specific migration version.
dev-db-migrate: export DATABASE_URL=$(DEV_DB_POSTGRESQL_URL)
dev-db-migrate:
	"$(INSTALL_BIN_DIR)/goose" -dir "$(CURDIR)/sql/migrations" postgres "${DATABASE_URL}" up

.PHONY: ensure-test-db
ensure-test-db: export DATABASE_URL=$(DEV_DB_BASE_POSTGRESQL_URL)
ensure-test-db:
	echo "SELECT 'CREATE DATABASE $(DEV_DB_POSTGRESQL_NAME)' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$(DEV_DB_POSTGRESQL_NAME)')\gexec" | psql "$(DATABASE_URL)"
	$(MAKE) dev-db-migrate

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
	fi

.PHONY: connect-dev-db
connect-dev-db: check-psql
	psql -h localhost -p $(DEV_DB_POSTGRESQL_PORT) -U postgres $(DEV_DB_POSTGRESQL_NAME)