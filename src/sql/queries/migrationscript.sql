-- name: MigrationScripts :many
SELECT
  "version"   ,
  "identifier",
  "up"        ,
  "down"
FROM
  "migration_script";


-- name: InsertMigrationScript :exec
INSERT OR IGNORE INTO
  "migration_script" ("version", "identifier", "up", "down")
VALUES
  (@version, @identifier, @up, @down);