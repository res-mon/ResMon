package database

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"io/fs"

	"github.com/golang-migrate/migrate/v4"
	migrateDB "github.com/golang-migrate/migrate/v4/database"
	"github.com/golang-migrate/migrate/v4/database/sqlite3"
	_ "github.com/mattn/go-sqlite3"

	"github.com/yerTools/ResMon/generated/go/model"
)

var errDatabaseIsNil = errors.New("database is nil")

type database struct {
	db      *sql.DB
	driver  migrateDB.Driver
	migrate *migrate.Migrate
}

func OpenDB(
	ctx context.Context, path string, migrationsFS fs.FS,
) (*database, error) {
	db, err := sql.Open("sqlite3", path)
	if err != nil {
		return nil, fmt.Errorf("could not open database: %w", err)
	}

	err = db.PingContext(ctx)
	if err != nil {
		db.Close()
		return nil, fmt.Errorf("could not ping database: %w", err)
	}

	driver, err := sqlite3.WithInstance(db, &sqlite3.Config{
		MigrationsTable: "migrations",
		DatabaseName:    "",
		NoTxWrap:        false,
	})

	if err != nil {
		db.Close()
		return nil, fmt.Errorf("could not create driver: %w", err)
	}

	targetVersion, err := registerMigrationContainer(ctx, db, migrationsFS)
	if err != nil {
		driver.Close()
		return nil, fmt.Errorf(
			"could not register migration container: %w", err)
	}

	m, err := migrate.NewWithDatabaseInstance(
		"migrationcontainer://",
		"sqlite3", driver,
	)
	if err != nil {
		driver.Close()
		return nil, fmt.Errorf("could not create migrate: %w", err)
	}

	err = m.Migrate(targetVersion)
	if err != nil && !errors.Is(err, migrate.ErrNoChange) {
		m.Close()
		return nil, fmt.Errorf(
			"could not migrate database to target version %d: %w",
			targetVersion, err)
	}

	mdl, err := model.Prepare(ctx, db)
	if err != nil {
		m.Close()
		return nil, fmt.Errorf("could not prepare model: %w", err)
	}

	err = mdl.Close()
	if err != nil {
		m.Close()
		return nil, fmt.Errorf("could not close prepared model: %w", err)
	}

	result := database{
		db:      db,
		driver:  driver,
		migrate: m,
	}

	return &result, nil
}

func (db *database) Close() error {
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
