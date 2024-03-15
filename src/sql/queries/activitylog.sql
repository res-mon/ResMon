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


-- name: ActiveDurations :many
SELECT
    "outer"."timestamp" AS "start_time",
    (
        SELECT
            MIN("inner"."timestamp")
        FROM
            "activity_log" "inner"
        WHERE
            "inner"."timestamp" > "outer"."timestamp" AND
            "inner"."active" = 0
    ) AS "end_time"
FROM
    "activity_log" "outer"
WHERE
    "outer"."active" = 1
ORDER BY
    "start_time" DESC;


-- name: AddActivity :exec
INSERT INTO
    "activity_log" ("timestamp", "active")
VALUES
    (@timestamp, @active);