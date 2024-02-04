package model

import (
	"gorm.io/gorm"
)

type User struct {
	Model
}

func (u *User) BeforeUpdate(tx *gorm.DB) error {
	return BeforeUpdateErr
}
