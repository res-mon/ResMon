// Code generated by sqlc. DO NOT EDIT.
// versions:
//   sqlc v1.25.0

package model

import (
	"context"
	"database/sql"
	"fmt"
)

type DBTX interface {
	ExecContext(context.Context, string, ...interface{}) (sql.Result, error)
	PrepareContext(context.Context, string) (*sql.Stmt, error)
	QueryContext(context.Context, string, ...interface{}) (*sql.Rows, error)
	QueryRowContext(context.Context, string, ...interface{}) *sql.Row
}

func New(db DBTX) *Queries {
	return &Queries{db: db}
}

func Prepare(ctx context.Context, db DBTX) (*Queries, error) {
	q := Queries{db: db}
	var err error
	if q.activeDurationsStmt, err = db.PrepareContext(ctx, activeDurations); err != nil {
		return nil, fmt.Errorf("error preparing query ActiveDurations: %w", err)
	}
	if q.addActivityStmt, err = db.PrepareContext(ctx, addActivity); err != nil {
		return nil, fmt.Errorf("error preparing query AddActivity: %w", err)
	}
	if q.insertMigrationScriptStmt, err = db.PrepareContext(ctx, insertMigrationScript); err != nil {
		return nil, fmt.Errorf("error preparing query InsertMigrationScript: %w", err)
	}
	if q.isActiveStmt, err = db.PrepareContext(ctx, isActive); err != nil {
		return nil, fmt.Errorf("error preparing query IsActive: %w", err)
	}
	if q.migrationScriptsStmt, err = db.PrepareContext(ctx, migrationScripts); err != nil {
		return nil, fmt.Errorf("error preparing query MigrationScripts: %w", err)
	}
	return &q, nil
}

func (q *Queries) Close() error {
	var err error
	if q.activeDurationsStmt != nil {
		if cerr := q.activeDurationsStmt.Close(); cerr != nil {
			err = fmt.Errorf("error closing activeDurationsStmt: %w", cerr)
		}
	}
	if q.addActivityStmt != nil {
		if cerr := q.addActivityStmt.Close(); cerr != nil {
			err = fmt.Errorf("error closing addActivityStmt: %w", cerr)
		}
	}
	if q.insertMigrationScriptStmt != nil {
		if cerr := q.insertMigrationScriptStmt.Close(); cerr != nil {
			err = fmt.Errorf("error closing insertMigrationScriptStmt: %w", cerr)
		}
	}
	if q.isActiveStmt != nil {
		if cerr := q.isActiveStmt.Close(); cerr != nil {
			err = fmt.Errorf("error closing isActiveStmt: %w", cerr)
		}
	}
	if q.migrationScriptsStmt != nil {
		if cerr := q.migrationScriptsStmt.Close(); cerr != nil {
			err = fmt.Errorf("error closing migrationScriptsStmt: %w", cerr)
		}
	}
	return err
}

func (q *Queries) exec(ctx context.Context, stmt *sql.Stmt, query string, args ...interface{}) (sql.Result, error) {
	switch {
	case stmt != nil && q.tx != nil:
		return q.tx.StmtContext(ctx, stmt).ExecContext(ctx, args...)
	case stmt != nil:
		return stmt.ExecContext(ctx, args...)
	default:
		return q.db.ExecContext(ctx, query, args...)
	}
}

func (q *Queries) query(ctx context.Context, stmt *sql.Stmt, query string, args ...interface{}) (*sql.Rows, error) {
	switch {
	case stmt != nil && q.tx != nil:
		return q.tx.StmtContext(ctx, stmt).QueryContext(ctx, args...)
	case stmt != nil:
		return stmt.QueryContext(ctx, args...)
	default:
		return q.db.QueryContext(ctx, query, args...)
	}
}

func (q *Queries) queryRow(ctx context.Context, stmt *sql.Stmt, query string, args ...interface{}) *sql.Row {
	switch {
	case stmt != nil && q.tx != nil:
		return q.tx.StmtContext(ctx, stmt).QueryRowContext(ctx, args...)
	case stmt != nil:
		return stmt.QueryRowContext(ctx, args...)
	default:
		return q.db.QueryRowContext(ctx, query, args...)
	}
}

type Queries struct {
	db                        DBTX
	tx                        *sql.Tx
	activeDurationsStmt       *sql.Stmt
	addActivityStmt           *sql.Stmt
	insertMigrationScriptStmt *sql.Stmt
	isActiveStmt              *sql.Stmt
	migrationScriptsStmt      *sql.Stmt
}

func (q *Queries) WithTx(tx *sql.Tx) *Queries {
	return &Queries{
		db:                        tx,
		tx:                        tx,
		activeDurationsStmt:       q.activeDurationsStmt,
		addActivityStmt:           q.addActivityStmt,
		insertMigrationScriptStmt: q.insertMigrationScriptStmt,
		isActiveStmt:              q.isActiveStmt,
		migrationScriptsStmt:      q.migrationScriptsStmt,
	}
}
