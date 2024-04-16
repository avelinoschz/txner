-- name: GetAccountByID :one
SELECT
    *
FROM
    accounts
WHERE
    id = $1
ORDER BY
    created_at DESC
LIMIT
    1;