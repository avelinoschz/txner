-- +goose Up
-- +goose StatementBegin
CREATE TABLE card_types (
    card_type_id INT PRIMARY KEY,
    card_type_name VARCHAR(20)
);

INSERT INTO card_types (card_type_id, card_type_name) VALUES
(1, 'debit'),
(2, 'credit');

CREATE TABLE users (
    user_id INT PRIMARY KEY,
    email VARCHAR(100)
);

CREATE TABLE movements (
    movement_id INT PRIMARY KEY,
    user_id INT,
    movement_date DATE,
    amount DECIMAL(10, 2),
    card_type_id INT,
    description TEXT,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (card_type_id) REFERENCES card_types(card_type_id)
);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP TABLE movements;

DROP TABLE users;

DROP TABLE card_types;
-- +goose StatementEnd