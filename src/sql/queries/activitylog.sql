-- name: IsActive :one
SELECT
  CAST(
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
    ) AS INTEGER
  ) AS "active",
  CAST(
    IFNULL(
      (
        SELECT
          "timestamp"
        FROM
          "activity_log"
        ORDER BY
          "timestamp" DESC
        LIMIT
          1
      ),
      0
    ) AS INTEGER
  ) AS "timestamp";


-- name: AddActivity :exec
INSERT INTO
  "activity_log" ("timestamp", "active")
VALUES
  (@timestamp, @active);