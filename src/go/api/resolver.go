package api

import (
	"context"
	"fmt"
	"slices"
	"time"

	"github.com/yerTools/ResMon/generated/go/graph"
	"github.com/yerTools/ResMon/generated/go/model"
	"github.com/yerTools/ResMon/src/go/api/scalar"
	"github.com/yerTools/ResMon/src/go/database"
	"github.com/yerTools/ResMon/src/go/utility"
)

type resolver graph.Resolver

type rootMutationResolver graph.Resolver
type rootQueryResolver graph.Resolver
type rootSubscriptionResolver graph.Resolver
type activityMutationResolver graph.Resolver
type historyQueryResolver graph.Resolver

var globalState state

type state struct {
	workingClock *utility.LazySubscribable[*graph.WorkClockQuery]
	general      *utility.ComputedSubscribable[*graph.GeneralQuery]
}

func getHistoryItems(ctx context.Context, mdl *model.Queries) ([]*graph.HistoryItem, error) {
	durations, err := mdl.ActiveDurations(ctx)
	if err != nil {
		return nil, fmt.Errorf(
			"could not get active durations: %w", err)
	}

	historyItems := make([]*graph.HistoryItem, len(durations))
	for i, duration := range durations {
		var end *scalar.Timestamp
		if duration.EndTime != nil {
			if value, ok := duration.EndTime.(int64); ok {
				timestamp := scalar.TimestampFromTime(
					time.Unix(0, value))
				end = &timestamp
			}
		}

		historyItems[i] = &graph.HistoryItem{
			Start: scalar.TimestampFromTime(
				time.Unix(0, duration.StartTime)),
			End: end,
		}
	}

	return historyItems, nil
}

func initState(ctx context.Context, db *database.DB) (state, error) {
	workingClock, err := utility.NewLazySubscribable(
		func(ctx context.Context) (*graph.WorkClockQuery, error) {
			mdl, err := db.NewModel()
			if err != nil {
				return nil, fmt.Errorf("could not create model: %w", err)
			}
			defer mdl.Close()

			isActive, err := mdl.IsActive(ctx)
			if err != nil {
				return nil, fmt.Errorf("could not get active state: %w", err)
			}

			historyItems, err := getHistoryItems(ctx, mdl)
			if err != nil {
				return nil, fmt.Errorf("could not get history items: %w", err)
			}

			var since time.Time
			if isActive.Timestamp == 0 {
				since = time.Now()
			} else {
				since = time.Unix(0, isActive.Timestamp)
			}

			return &graph.WorkClockQuery{
				Activity: &graph.ActivityQuery{
					Active: isActive.Active != 0,
					Since:  scalar.TimestampFromTime(since),
				},
				History: &graph.HistoryQuery{
					HistoryItems: historyItems,
				},
			}, nil
		},
		func(
			ctx context.Context, oldValue, newValue *graph.WorkClockQuery,
		) (*graph.WorkClockQuery, error) {
			if oldValue.Activity.Active == newValue.Activity.Active {
				return oldValue, nil
			}

			mdl, err := db.NewModel()
			if err != nil {
				return nil, fmt.Errorf("could not create model: %w", err)
			}
			defer mdl.Close()

			var active int64
			if newValue.Activity.Active {
				active = 1
			}

			now := time.Now()

			err = mdl.AddActivity(ctx, model.AddActivityParams{
				Timestamp: now.UnixNano(),
				Active:    active,
			})
			if err != nil {
				return nil, fmt.Errorf("could not add activity: %w", err)
			}

			historyItems, err := getHistoryItems(ctx, mdl)
			if err != nil {
				return nil, fmt.Errorf("could not get history items: %w", err)
			}

			return &graph.WorkClockQuery{
				Activity: &graph.ActivityQuery{
					Active: newValue.Activity.Active,
					Since:  scalar.TimestampFromTime(now),
				},
				History: &graph.HistoryQuery{
					HistoryItems: historyItems,
				},
			}, nil
		},
		32,
	)

	if err != nil {
		return state{}, fmt.Errorf("could not create working clock: %w", err)
	}

	general, err := utility.NewComputedSubscribable(
		ctx,
		func(ctx context.Context) (*graph.GeneralQuery, error) {
			return &graph.GeneralQuery{
				Time: &graph.GeneralTimeQuery{
					Current: scalar.TimestampFromTime(time.Now()),
				},
			}, nil
		},
		10*time.Second,
		32,
	)
	if err != nil {
		return state{}, fmt.Errorf("could not create general: %w", err)
	}

	return state{
		workingClock: workingClock,
		general:      general,
		//history:      history,
	}, nil
}

func (r resolver) RootMutation() graph.RootMutationResolver {
	return rootMutationResolver(r)
}

func (r resolver) RootQuery() graph.RootQueryResolver {
	return rootQueryResolver(r)
}

func (r resolver) RootSubscription() graph.RootSubscriptionResolver {
	return rootSubscriptionResolver(r)
}

func (r resolver) ActivityMutation() graph.ActivityMutationResolver {
	return activityMutationResolver(r)
}

func (r resolver) HistoryQuery() graph.HistoryQueryResolver {
	return historyQueryResolver(r)
}

func (activityMutationResolver) SetActive(
	ctx context.Context, obj *graph.ActivityMutation, active bool,
) (*graph.ActivityQuery, error) {
	current, err := globalState.workingClock.Current(ctx)
	if err != nil {
		return nil, fmt.Errorf("could not get current working clock state: %w", err)
	}

	if current.Activity.Active == active {
		return current.Activity, nil

	}

	current, err = globalState.workingClock.Set(ctx, &graph.WorkClockQuery{
		Activity: &graph.ActivityQuery{
			Active: active,
		},
	})
	if err != nil {
		return nil, fmt.Errorf("could not set working clock state: %w", err)
	}

	return current.Activity, nil
}

func (rootMutationResolver) WorkClock(ctx context.Context) (*graph.WorkClockMutation, error) {
	current, err := globalState.workingClock.Current(ctx)
	if err != nil {
		return nil, fmt.Errorf("could not get current working clock state: %w", err)
	}

	return &graph.WorkClockMutation{
		Activity: &graph.ActivityMutation{
			SetActive: current.Activity,
		},
	}, nil
}

func (historyQueryResolver) HistoryItems(
	ctx context.Context, obj *graph.HistoryQuery,
	from *scalar.Timestamp, to *scalar.Timestamp, limit *int,
) ([]*graph.HistoryItem, error) {
	current, err := globalState.workingClock.Current(ctx)
	if err != nil {
		return nil, fmt.Errorf("could not get current working clock state: %w", err)
	}

	filter := func(
		items []*graph.HistoryItem,
		keep func(item *graph.HistoryItem) bool,
	) []*graph.HistoryItem {
		result := make([]*graph.HistoryItem, 0, len(items))
		for _, item := range items {
			if keep(item) {
				result = append(result, item)
			}
		}
		return result
	}

	result := current.History.HistoryItems
	if from != nil {
		result = filter(result, func(item *graph.HistoryItem) bool {
			return item.End == nil || *item.End >= *from
		})

		slices.Reverse(result)
	}

	if to != nil {
		result = filter(result, func(item *graph.HistoryItem) bool {
			return item.Start <= *to
		})
	}

	if limit != nil && *limit > 0 {
		result = result[:*limit]
	}

	return result, nil
}

func (rootQueryResolver) WorkClock(ctx context.Context) (*graph.WorkClockQuery, error) {
	current, err := globalState.workingClock.Current(ctx)
	if err != nil {
		return nil, fmt.Errorf("could not get current working clock state: %w", err)
	}

	return current, nil
}

func (rootSubscriptionResolver) WorkClock(ctx context.Context) (<-chan *graph.WorkClockQuery, error) {
	ch, err := globalState.workingClock.Subscribe(ctx)
	if err != nil {
		return nil, fmt.Errorf("could not subscribe to working clock state: %w", err)
	}

	return ch, nil
}

func (rootSubscriptionResolver) General(ctx context.Context) (<-chan *graph.GeneralQuery, error) {
	ch, err := globalState.general.Subscribe(ctx)
	if err != nil {
		return nil, fmt.Errorf("could not subscribe to working clock state: %w", err)
	}

	return ch, nil
}

func New(ctx context.Context, db *database.DB) (graph.Config, error) {
	state, err := initState(ctx, db)
	if err != nil {
		return graph.Config{}, fmt.Errorf("could not create state: %w", err)
	}

	globalState = state

	return graph.Config{
		Resolvers: resolver(graph.Resolver{}),
	}, nil
}
