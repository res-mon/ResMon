// Code generated by sqlc. DO NOT EDIT.
// versions:
//   sqlc v1.26.0

package model

type ActivityLog struct {
	Timestamp int64 `db:"timestamp" json:"timestamp"`
	Active    int64 `db:"active" json:"active"`
}

type MigrationScript struct {
	Version    int64  `db:"version" json:"version"`
	Identifier string `db:"identifier" json:"identifier"`
	Up         string `db:"up" json:"up"`
	Down       string `db:"down" json:"down"`
}
