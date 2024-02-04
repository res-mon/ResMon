package model

import (
	"errors"
	"time"

	"gorm.io/gorm"
)

var BeforeUpdateErr = errors.New("could not update immutable model")

type Model struct {
	ID        uint           `gorm:"index"`
	CurrentID uint           `gorm:"primarykey"`
	CreatedAt time.Time      `gorm:"index"`
	DeletedAt gorm.DeletedAt `gorm:"index"`
}

type ImmutableModel interface {
	BeforeUpdate(tx *gorm.DB) error
}

func (m *Model) BeforeUpdate(tx *gorm.DB) error {
	return BeforeUpdateErr
}
