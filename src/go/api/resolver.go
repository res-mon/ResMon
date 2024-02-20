package api

import (
	"context"

	"github.com/yerTools/ResMon/generated/go/graph"
)

var globalActive = false

type resolver graph.Resolver

type rootMutationResolver graph.Resolver
type rootQueryResolver graph.Resolver
type activityMutationResolver graph.Resolver

func (r resolver) RootMutation() graph.RootMutationResolver {
	return rootMutationResolver(r)
}

func (r resolver) RootQuery() graph.RootQueryResolver {
	return rootQueryResolver(r)
}

func (r resolver) ActivityMutation() graph.ActivityMutationResolver {
	return activityMutationResolver(r)
}

func (r activityMutationResolver) SetActive(ctx context.Context, obj *graph.ActivityMutation, active bool) (bool, error) {
	globalActive = active
	return active, nil
}

func (r rootMutationResolver) WorkClock(ctx context.Context) (*graph.WorkClockMutation, error) {
	return &graph.WorkClockMutation{
		Activity: &graph.ActivityMutation{
			SetActive: globalActive,
		},
	}, nil
}

func (r rootQueryResolver) WorkClock(ctx context.Context) (*graph.WorkClockQuery, error) {
	return &graph.WorkClockQuery{
		Activity: &graph.ActivityQuery{
			Active: globalActive,
		},
	}, nil
}

func New() graph.Config {
	return graph.Config{
		Resolvers: resolver(graph.Resolver{}),
	}
}
