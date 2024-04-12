-- +goose Up
-- +goose StatementBegin
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    email TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER SEQUENCE users_id_seq RESTART WITH 1000;

INSERT INTO users (id, email) VALUES
(1000, 'john.doe@mail.com');

CREATE TABLE account_types (
    id BIGSERIAL PRIMARY KEY,
    short_name TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO account_types (id, short_name) VALUES
(1, 'debit'),
(2, 'credit');

CREATE TABLE accounts (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    account_type_id BIGINT NOT NULL,
    balance DECIMAL(10, 2) NOT NULL CHECK (balance >= 0),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (account_type_id) REFERENCES account_types(id)
);

INSERT INTO accounts (id, user_id, account_type_id, balance) VALUES
(1, 1000, 1, 0),
(2, 1000, 2, 0);

CREATE TABLE transactions (
    id BIGINT PRIMARY KEY,
    account_id BIGINT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    date DATE NOT NULL,
    FOREIGN KEY (account_id) REFERENCES accounts(id)
);

CREATE INDEX idx_account_transactions ON transactions (account_id, date DESC);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP TABLE transactions;

DROP TABLE accounts;

DROP TABLE account_types;

DROP TABLE users;
-- +goose StatementEnd