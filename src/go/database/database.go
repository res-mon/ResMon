package database

import (
	"context"
	"fmt"

	"github.com/yerTools/ResMon/src/go/database/model"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

type database struct {
	db *gorm.DB
}

func OpenDB(ctx context.Context, path string) (*database, error) {
	db, err := gorm.Open(sqlite.Open(path), &gorm.Config{})
	if err != nil {
		return nil, fmt.Errorf("could not open database: %w", err)
	}

	d := &database{
		db: db,
	}

	err = d.setup(ctx)
	if err != nil {
		d.Close()
		return nil, fmt.Errorf("could not setup database: %w", err)
	}

	return d, nil
}

type Product struct {
	model.Model
	Code  string
	Price uint
}

func (d *database) setup(ctx context.Context) error {
	// Migrate the schema
	d.db.AutoMigrate(&Product{})

	// Create
	d.db.Create(&Product{Code: "D42", Price: 100})

	// Read
	var product Product
	d.db.First(&product, 1)                 // find product with integer primary key
	d.db.First(&product, "code = ?", "D42") // find product with code D42

	// Update - update product's price to 200
	d.db.Model(&product).Update("Price", 200)
	// Update - update multiple fields
	d.db.Model(&product).Updates(Product{Price: 200, Code: "F42"}) // non-zero fields
	d.db.Model(&product).Updates(map[string]interface{}{"Price": 200, "Code": "F42"})

	// Delete - delete product
	d.db.Delete(&product, 1)

	return nil
}

func (d *database) Close() error {
	db, err := d.db.DB()
	if err != nil {
		return fmt.Errorf("could not get database: %w", err)
	}

	return db.Close()
}
