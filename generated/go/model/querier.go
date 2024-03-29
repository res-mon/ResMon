// Code generated by sqlc. DO NOT EDIT.
// versions:
//   sqlc v1.26.0

package model

import (
	"context"
)

type Querier interface {
	//ActiveDurations
	//
	//  SELECT
	//      "outer"."timestamp" AS "start_time",
	//      (
	//          SELECT
	//              MIN("inner"."timestamp")
	//          FROM
	//              "activity_log" "inner"
	//          WHERE
	//              "inner"."timestamp" > "outer"."timestamp" AND
	//              "inner"."active" = 0
	//      ) AS "end_time"
	//  FROM
	//      "activity_log" "outer"
	//  WHERE
	//      "outer"."active" = 1
	//  ORDER BY
	//      "start_time" DESC
	ActiveDurations(ctx context.Context) ([]ActiveDurationsRow, error)
	//AddActivity
	//
	//  INSERT INTO
	//      "activity_log" ("timestamp", "active")
	//  VALUES
	//      (?1, ?2)
	AddActivity(ctx context.Context, arg AddActivityParams) error
	//InsertMigrationScript
	//
	//  INSERT OR IGNORE INTO
	//      "migration_script" ("version", "identifier", "up", "down")
	//  VALUES
	//      (?1, ?2, ?3, ?4)
	InsertMigrationScript(ctx context.Context, arg InsertMigrationScriptParams) error
	//IsActive
	//
	//  SELECT
	//      CAST(
	//          IFNULL(
	//              (
	//                  SELECT
	//                      "active"
	//                  FROM
	//                      "activity_log"
	//                  ORDER BY
	//                      "timestamp" DESC
	//                  LIMIT
	//                      1
	//              ),
	//              0
	//          ) AS INTEGER
	//      ) AS "active",
	//      CAST(
	//          IFNULL(
	//              (
	//                  SELECT
	//                      "timestamp"
	//                  FROM
	//                      "activity_log"
	//                  ORDER BY
	//                      "timestamp" DESC
	//                  LIMIT
	//                      1
	//              ),
	//              0
	//          ) AS INTEGER
	//      ) AS "timestamp"
	IsActive(ctx context.Context) (IsActiveRow, error)
	//MigrationScripts
	//
	//  SELECT
	//      "version"   ,
	//      "identifier",
	//      "up"        ,
	//      "down"
	//  FROM
	//      "migration_script"
	MigrationScripts(ctx context.Context) ([]MigrationScript, error)
}

var _ Querier = (*Queries)(nil)
