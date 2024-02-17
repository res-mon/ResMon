package database

import (
	"bytes"
	"context"
	"database/sql"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"sort"
	"strconv"
	"strings"

	"github.com/golang-migrate/migrate/v4/source"
	"github.com/yerTools/ResMon/generated/go/model"
)

func registerMigrationContainer(
	ctx context.Context, db *sql.DB, migrationsFS fs.FS,
) (latestVersion uint, err error) {
	entries, err := fs.ReadDir(migrationsFS, ".")
	if err != nil {
		return 0, fmt.Errorf("could not read migration directory: %w", err)
	}

	if len(entries) == 0 {
		return 0, errors.New("no migrations found")
	}

	migrationMap := make(map[uint]migration)

	versionLength := 0
	for _, entry := range entries {
		name := entry.Name()

		if entry.IsDir() {
			return 0, fmt.Errorf(
				"migration directory contains subdirectories: %s", name)
		}

		up := strings.HasSuffix(name, ".up.sql")
		if !up && !strings.HasSuffix(name, ".down.sql") {
			return 0, fmt.Errorf(
				"migration file does not have "+
					"'.up.sql' or '.down.sql' extension: %s", name)
		}

		versionIndex := strings.Index(name, "_")
		if versionIndex <= 0 {
			return 0, fmt.Errorf(
				"migration file does not have version, "+
					"expected number followed by underscore ('_'): %s", name)
		}

		if versionLength == 0 {
			versionLength = versionIndex
		} else if versionLength != versionIndex {
			return 0, fmt.Errorf(
				"migration file does not have consistent version length, "+
					"expected %d but got %d: %s",
				versionLength, versionIndex, name)
		}

		version, err := strconv.ParseUint(name[:versionIndex], 10, 32)
		if err != nil {
			return 0, fmt.Errorf(
				"could not parse migration version '%s' from file '%s': %w",
				name[:versionIndex], name, err)
		}

		identifier := name[versionIndex+1:]
		if up {
			identifier = identifier[:len(identifier)-len(".up.sql")]
		} else {
			identifier = identifier[:len(identifier)-len(".down.sql")]
		}

		if identifier == "" {
			return 0, fmt.Errorf(
				"migration file does not have identifier, expected identifier "+
					"after version and underscore ('_'): %s", name)
		}

		var m migration
		var ok bool
		if m, ok = migrationMap[uint(version)]; !ok {
			m = migration{
				version:    uint(version),
				identifier: identifier,
			}
		} else if m.identifier != identifier {
			return 0, fmt.Errorf(
				"migration file does not have consistent identifier, "+
					"expected '%s' but got '%s': %s",
				m.identifier, identifier, name)
		}

		if up && m.hasUp {
			return 0, fmt.Errorf(
				"migration file has multiple up files for version %d: %s",
				m.version, name)
		} else if !up && m.hasDown {
			return 0, fmt.Errorf(
				"migration file has multiple down files for version %d: %s",
				m.version, name)
		}

		if up {
			m.hasUp = true
		} else {
			m.hasDown = true
		}

		file, err := migrationsFS.Open(name)
		if err != nil {
			return 0, fmt.Errorf(
				"could not open migration file '%s': %w", name, err)
		}

		content, err := io.ReadAll(file)
		if err != nil {
			return 0, fmt.Errorf(
				"could not read migration file '%s': %w", name, err)
		}

		if up {
			m.up = content
		} else {
			m.down = content
		}

		migrationMap[uint(version)] = m
	}

	for _, m := range migrationMap {
		if !m.hasUp {
			return 0, fmt.Errorf(
				"migration file does not have up file for version %d: %s",
				m.version, m.identifier)
		} else if !m.hasDown {
			return 0, fmt.Errorf(
				"migration file does not have down file for version %d: %s",
				m.version, m.identifier)
		}
	}

	migrations := make([]migration, 0, len(migrationMap))
	for _, m := range migrationMap {
		migrations = append(migrations, m)
	}

	sort.Slice(migrations, func(i, j int) bool {
		return migrations[i].version < migrations[j].version
	})

	latestVersion = migrations[len(migrations)-1].version

	_, err = db.ExecContext(ctx, string(migrations[0].up))
	if err != nil {
		return 0, fmt.Errorf("could not apply first migration: %w", err)
	}

	mdl := model.New(db)
	for _, m := range migrations {
		err = mdl.CreateMigrationScript(ctx, model.CreateMigrationScriptParams{
			Version:    int64(m.version),
			Identifier: m.identifier,
			Up:         string(m.up),
			Down:       string(m.down),
		})

		if err != nil {
			return 0, fmt.Errorf("could not insert migration script: %w", err)
		}
	}

	existingScripts, err := mdl.ListMigrationScripts(ctx)
	if err != nil {
		return 0, fmt.Errorf("could not list migration scripts: %w", err)
	}

	for _, script := range existingScripts {
		if _, ok := migrationMap[uint(script.Version)]; ok {
			continue
		}

		migrationMap[uint(script.Version)] = migration{
			version:    uint(script.Version),
			identifier: script.Identifier,
			up:         []byte(script.Up),
			down:       []byte(script.Down),
			hasUp:      true,
			hasDown:    true,
		}
	}

	migrations = make([]migration, 0, len(migrationMap))
	for _, m := range migrationMap {
		migrations = append(migrations, m)
	}

	sort.Slice(migrations, func(i, j int) bool {
		return migrations[i].version < migrations[j].version
	})

	migrationIndex := make(map[uint]int, len(migrations))
	for i, m := range migrations {
		migrationIndex[m.version] = i
	}

	source.Register("migrationcontainer", &migrationContainer{
		migrations:     migrations,
		migrationMap:   migrationMap,
		migrationIndex: migrationIndex,
	})

	return latestVersion, nil
}

type migration struct {
	version    uint
	identifier string
	up         []byte
	down       []byte
	hasUp      bool
	hasDown    bool
}

type migrationContainer struct {
	migrations     []migration
	migrationMap   map[uint]migration
	migrationIndex map[uint]int
}

func (c *migrationContainer) assertNotEmpty() error {
	if c != nil && len(c.migrations) != 0 {
		return nil
	}

	return errors.New("migration container is empty")
}

func (c *migrationContainer) Close() error {
	return c.assertNotEmpty()
}

func (c *migrationContainer) First() (version uint, err error) {
	err = c.assertNotEmpty()
	if err != nil {
		return 0, err
	}

	return c.migrations[0].version, nil
}

func (c *migrationContainer) Next(version uint) (nextVersion uint, err error) {
	err = c.assertNotEmpty()
	if err != nil {
		return
	}

	if index, ok := c.migrationIndex[version]; ok {
		if index+1 < len(c.migrations) {
			return c.migrations[index+1].version, nil
		}
	}

	return version, nil
}

func (c *migrationContainer) Open(url string) (source.Driver, error) {
	err := c.assertNotEmpty()
	if err != nil {
		return nil, err
	}

	return c, nil
}

func (c *migrationContainer) Prev(version uint) (prevVersion uint, err error) {
	err = c.assertNotEmpty()
	if err != nil {
		return
	}

	if index, ok := c.migrationIndex[version]; ok {
		if index > 0 {
			return c.migrations[index-1].version, nil
		}
	}

	return version, nil
}

func (c *migrationContainer) ReadDown(
	version uint,
) (r io.ReadCloser, identifier string, err error) {
	err = c.assertNotEmpty()
	if err != nil {
		return
	}

	if index, ok := c.migrationIndex[version]; ok {
		return io.NopCloser(
				bytes.NewReader(c.migrations[index].down)),
			c.migrations[index].identifier,
			nil
	}

	return nil, "", errors.New("migration not found")
}

func (c *migrationContainer) ReadUp(
	version uint,
) (r io.ReadCloser, identifier string, err error) {
	err = c.assertNotEmpty()
	if err != nil {
		return
	}

	if index, ok := c.migrationIndex[version]; ok {
		return io.NopCloser(
				bytes.NewReader(c.migrations[index].up)),
			c.migrations[index].identifier,
			nil
	}

	return nil, "", errors.New("migration not found")
}
