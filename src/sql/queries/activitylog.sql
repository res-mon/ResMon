-- name: IsActive :one
SELECT
  IFNULL(
    (
      SELECT
        "active"
      FROM
        "activity_log"
      ORDER BY
        "timestamp" DESC
      LIMIT
        1
    ),
    0
  ) AS "active";


-- name: AddActivity :exec
INSERT INTO
  "activity_log" ("timestamp", "active")
VALUES
  (@timestamp, @active);