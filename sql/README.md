# SQL

This directory is for all the SQL related stuff. Main two parts are: queries and migrations.

## Queries

These are the raw queries to be used by [sqlc](https://github.com/sqlc-dev/sqlc) the tool to geneate the go code to connect to the database.

## Migrations

For the migrations, the project is using [goose](https://github.com/pressly/goose).

In the `Makefile` you can find all the commands to execute basic and/or common actions. Like:

- `make setup-deps` take care of all the dependencies. This installs the `goose` binaries. For the installation been as close as possible to the project, it creates a dir at root called `./bin` where all the needed binaries, such as `goose`, would be stored.

- `make dev-db-migrate` abstracts the process of applying the `goose` command to migrate. For now, is applying all migrations `up`, but could be targeting specific versions.
- `make dev-db-status` abstracts the goose command to lookup the current migration version, and if there are any pending ones.

In case you need to create a new migration the raw `goose` command is the following:

```shell
$ ./bin/goose -dir "./sql/migrations" create new_awesome_migration sql
2024/04/11 22:03:27 Created new file: sql/migrations/20240411220327_new_awesome_migration.sql
```

For more information, refer to the `goose` github `README.md`
