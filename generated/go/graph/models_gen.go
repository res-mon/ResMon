// Code generated by github.com/99designs/gqlgen, DO NOT EDIT.

package graph

import (
	"github.com/yerTools/ResMon/src/go/api/scalar"
)

type ActivityMutation struct {
	// Sets the current activity state.
	// This indicates if the user is currently working or not.
	// Returns the timestamp since the user is active.
	SetActive *ActivityQuery `json:"setActive"`
}

type ActivityQuery struct {
	// The timestamp since the activity state was last changed.
	// Returns the timestamp since the activity state was last changed.
	Since scalar.Timestamp `json:"since"`
	// This indicates if the user is currently working or not.
	// Returns the current activity state.
	Active bool `json:"active"`
}

type GeneralQuery struct {
	Time *GeneralTimeQuery `json:"time"`
}

type GeneralTimeQuery struct {
	Current scalar.Timestamp `json:"current"`
}

type HistoryItem struct {
	// The timestamp when the activity started.
	Start scalar.Timestamp `json:"start"`
	// The timestamp when the activity ended.
	// If the activity is still ongoing, this field is null.
	End *scalar.Timestamp `json:"end,omitempty"`
}

type HistoryQuery struct {
	// Returns the history of the user's activity.
	//
	// `limit` can be used to limit the number of history items returned.
	// If `limit` is not provided, no limit will be applied.
	//
	// When neither `from` nor `to` is provided, the fist entry will be the newest one.
	// All entries will be sorted by the `start` timestamp in descending order.
	//
	// When only `from` is provided, entries with the same, a later or no `end` timestamp will be returned.
	// This time they are sorted by the `start` timestamp in ascending order.
	//
	// When only `to` is provided, entries with the same or an earlier start timestamp will be returned.
	// This time they are sorted by the `start` timestamp in descending order.
	//
	// When both `from` and `to` are provided, entries which overlap the range will be returned.
	// This time they are sorted by the `start` timestamp in ascending order.
	HistoryItems []*HistoryItem `json:"historyItems"`
}

type RootMutation struct {
}

type RootQuery struct {
}

type RootSubscription struct {
}

type WorkClockMutation struct {
	Activity *ActivityMutation `json:"activity"`
}

type WorkClockQuery struct {
	Activity *ActivityQuery `json:"activity"`
	History  *HistoryQuery  `json:"history"`
}
