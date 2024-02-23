package api

import (
	"context"

	"github.com/yerTools/ResMon/generated/go/graph"
	"github.com/yerTools/ResMon/src/go/utility"
)

type resolver graph.Resolver

type rootMutationResolver graph.Resolver
type rootQueryResolver graph.Resolver
type rootSubscriptionResolver graph.Resolver
type activityMutationResolver graph.Resolver

var globalActive = utility.NewSubscribable(&graph.WorkClockQuery{
	Activity: &graph.ActivityQuery{
		Active: false,
	},
}, 16)

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

func (activityMutationResolver) SetActive(ctx context.Context, obj *graph.ActivityMutation, active bool) (bool, error) {
	globalActive.Set(&graph.WorkClockQuery{
		Activity: &graph.ActivityQuery{
			Active: active,
		},
	})

	return active, nil
}

func (rootMutationResolver) WorkClock(ctx context.Context) (*graph.WorkClockMutation, error) {
	return &graph.WorkClockMutation{
		Activity: &graph.ActivityMutation{
			SetActive: globalActive.Current().Activity.Active,
		},
	}, nil
}

func (rootQueryResolver) WorkClock(ctx context.Context) (*graph.WorkClockQuery, error) {
	return &graph.WorkClockQuery{
		Activity: &graph.ActivityQuery{
			Active: globalActive.Current().Activity.Active,
		},
	}, nil
}

func (rootSubscriptionResolver) WorkClock(ctx context.Context) (<-chan *graph.WorkClockQuery, error) {
	return globalActive.Subscribe(ctx), nil
}

func New() graph.Config {
	return graph.Config{
		Resolvers: resolver(graph.Resolver{}),
	}
}
