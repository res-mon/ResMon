package database

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"io/fs"
	"strings"

	"github.com/golang-migrate/migrate/v4"
	"github.com/golang-migrate/migrate/v4/database"
	_ "github.com/mattn/go-sqlite3"
)

var errDatabaseIsNil = errors.New("database is nil")

type db struct {
	db      *sql.DB
	driver  database.Driver
	migrate *migrate.Migrate
}

func OpenDB(
	ctx context.Context, path string, migrationsFS fs.FS,
) (*db, error) {
	var pathBuilder strings.Builder
	pathBuilder.WriteString(path)

	if strings.Contains(path, "?") {
		pathBuilder.WriteByte('&')
	} else {
		pathBuilder.WriteByte('?')
	}
	pathBuilder.WriteString("_pragma=page_size(8192)")

	sqlDB, err := sql.Open("sqlite3", pathBuilder.String())
	if err != nil {
		return nil, fmt.Errorf("could not open database: %w", err)
	}

	err = sqlDB.PingContext(ctx)
	if err != nil {
		sqlDB.Close()
		return nil, fmt.Errorf("could not ping database: %w", err)
	}

	driver, m, err := setup(ctx, sqlDB, migrationsFS)
	if err != nil {
		sqlDB.Close()
		return nil, fmt.Errorf("could not setup database: %w", err)
	}

	result := db{
		db:      sqlDB,
		driver:  driver,
		migrate: m,
	}

	return &result, nil
}

func (db *db) Close() error {
	if db == nil {
		return errDatabaseIsNil
	}

	sourceErr, driverErr := db.migrate.Close()
	if sourceErr != nil {
		return fmt.Errorf("could not close source: %w", sourceErr)
	}
	if driverErr != nil {
		return fmt.Errorf("could not close driver: %w", driverErr)
	}

	return nil
}
