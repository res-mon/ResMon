package database

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"io/fs"

	"github.com/golang-migrate/migrate/v4"
	"github.com/golang-migrate/migrate/v4/database"
	"github.com/golang-migrate/migrate/v4/database/sqlite3"
	"github.com/yerTools/ResMon/generated/go/model"
)

const (
	startPragmas = `
PRAGMA analysis_limit = 0;
PRAGMA auto_vacuum = 0;
PRAGMA automatic_index = 1;
PRAGMA cache_size = 4000; 
PRAGMA cell_size_check = 1;
PRAGMA defer_foreign_keys = 0;
PRAGMA encoding = 'UTF-8'; 
PRAGMA ignore_check_constraints = 0;
PRAGMA journal_mode = WAL; 
PRAGMA legacy_alter_table = 0;
PRAGMA page_size = 8192;
PRAGMA recursive_triggers = 1;	
`
	endPragmas = `
PRAGMA integrity_check;
VACUUM;
ANALYZE;
PRAGMA optimize;
PRAGMA shrink_memory;
`
)

func setup(
	ctx context.Context, db *sql.DB, migrationsFS fs.FS,
) (database.Driver, *migrate.Migrate, error) {
	_, err := db.ExecContext(ctx, startPragmas)
	if err != nil {
		return nil, nil, fmt.Errorf("could not set start pragmas: %w", err)
	}

	driver, err := sqlite3.WithInstance(db, &sqlite3.Config{
		MigrationsTable: "migration_state",
		DatabaseName:    "",
		NoTxWrap:        false,
	})

	if err != nil {
		return nil, nil, fmt.Errorf("could not create driver: %w", err)
	}

	targetVersion, err := registerMigrationContainer(ctx, db, migrationsFS)
	if err != nil {
		driver.Close()
		return nil, nil, fmt.Errorf(
			"could not register migration container: %w", err)
	}

	m, err := migrate.NewWithDatabaseInstance(
		"migrationcontainer://",
		"sqlite3", driver,
	)
	if err != nil {
		driver.Close()
		return nil, nil, fmt.Errorf("could not create migrate: %w", err)
	}

	err = m.Migrate(targetVersion)
	if err != nil && !errors.Is(err, migrate.ErrNoChange) {
		m.Close()
		return nil, nil, fmt.Errorf(
			"could not migrate database to target version %d: %w",
			targetVersion, err)
	}

	mdl, err := model.Prepare(ctx, db)
	if err != nil {
		m.Close()
		return nil, nil, fmt.Errorf("could not prepare model: %w", err)
	}

	err = mdl.Close()
	if err != nil {
		m.Close()
		return nil, nil, fmt.Errorf("could not close prepared model: %w", err)
	}

	_, err = db.ExecContext(ctx, endPragmas)
	if err != nil {
		m.Close()
		return nil, nil, fmt.Errorf("could not set end pragmas: %w", err)
	}

	return driver, m, nil
}
