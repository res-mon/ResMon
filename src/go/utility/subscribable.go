package utility

import (
	"context"
	"errors"
	"fmt"
	"sync"
	"time"
)

type Subscribable[T any] struct {
	value       T
	subscribers []chan T
	bufferSize  int
	mutex       sync.Mutex
}

func initSubscribable[T any](value T, bufferSize int) Subscribable[T] {
	return Subscribable[T]{
		value:      value,
		bufferSize: bufferSize,
	}
}

func NewSubscribable[T any](value T, bufferSize int) *Subscribable[T] {
	res := initSubscribable(value, bufferSize)
	return &res
}

func (s *Subscribable[T]) Current() T {
	return s.value
}

func (s *Subscribable[T]) setUnlocked(value T) T {
	s.value = value
	for _, c := range s.subscribers {
		c <- value
	}

	return value
}

func (s *Subscribable[T]) Set(value T) T {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	return s.setUnlocked(value)
}

func (s *Subscribable[T]) subscribeUnlocked(ctx context.Context) <-chan T {
	ch := make(chan T, s.bufferSize)
	s.subscribers = append(s.subscribers, ch)

	go func() {
		defer close(ch)

		ch <- s.value
		<-ctx.Done()

		s.mutex.Lock()
		defer s.mutex.Unlock()
		for i, c := range s.subscribers {
			if c == ch {
				s.subscribers = append(
					s.subscribers[:i],
					s.subscribers[i+1:]...)

				return
			}
		}
	}()

	return ch
}

func (s *Subscribable[T]) Subscribe(ctx context.Context) <-chan T {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	return s.subscribeUnlocked(ctx)
}

type LazySubscribable[T any] struct {
	Subscribable[T]
	loaded       bool
	loader       func(ctx context.Context) (T, error)
	beforeUpdate func(ctx context.Context, oldValue T, newValue T) (T, error)
}

func NewLazySubscribable[T any](
	loader func(ctx context.Context) (T, error),
	beforeUpdate func(ctx context.Context, oldValue T, newValue T) (T, error),
	bufferSize int,
) (*LazySubscribable[T], error) {

	if loader == nil {
		return nil, errors.New("loader is required for new lazy subscribable")
	}

	var value T

	return &LazySubscribable[T]{
		loader:       loader,
		beforeUpdate: beforeUpdate,
		Subscribable: initSubscribable(value, bufferSize),
	}, nil
}

func (s *LazySubscribable[T]) currentUnlocked(ctx context.Context) (T, error) {
	if s.loaded {
		return s.value, nil
	}

	value, err := s.loader(ctx)
	if err != nil {
		return value, fmt.Errorf("could not load value: %w", err)
	}

	s.value = value
	s.loaded = true

	return value, nil
}

func (s *LazySubscribable[T]) Current(ctx context.Context) (T, error) {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	return s.currentUnlocked(ctx)
}

func (s *LazySubscribable[T]) Set(ctx context.Context, value T) (T, error) {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	oldValue, err := s.currentUnlocked(ctx)
	if err != nil {
		return oldValue, fmt.Errorf("could not get current value: %w", err)
	}

	if s.beforeUpdate != nil {
		value, err = s.beforeUpdate(ctx, oldValue, value)
		if err != nil {
			return value, fmt.Errorf("before update failed: %w", err)
		}
	}

	return s.setUnlocked(value), nil
}

func (s *LazySubscribable[T]) Subscribe(ctx context.Context) (<-chan T, error) {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	_, err := s.currentUnlocked(ctx)
	if err != nil {
		return nil, fmt.Errorf("could not get current value: %w", err)
	}

	return s.subscribeUnlocked(ctx), nil
}

type ComputedSubscribable[T any] struct {
	Subscribable[T]
	compute  func(ctx context.Context) (T, error)
	interval time.Duration
}

func NewComputedSubscribable[T any](
	ctx context.Context,
	compute func(ctx context.Context) (T, error),
	interval time.Duration,
	bufferSize int,
) (*ComputedSubscribable[T], error) {

	if compute == nil {
		return nil, errors.New("compute is required for new computed subscribable")
	}

	value, err := compute(ctx)
	if err != nil {
		return nil, fmt.Errorf("could not compute initial value: %w", err)
	}

	result := &ComputedSubscribable[T]{
		compute:      compute,
		interval:     interval,
		Subscribable: initSubscribable(value, bufferSize),
	}

	if interval > 0 {
		go func() {
			ticker := time.NewTicker(interval)
			defer ticker.Stop()

			for {
				select {
				case <-ctx.Done():
					return
				case <-ticker.C:
					result.SetCurrent(ctx)
				}
			}
		}()
	}

	return result, nil
}

func (s *ComputedSubscribable[T]) setCurrentUnlocked(ctx context.Context) (T, error) {
	value, err := s.compute(ctx)
	if err != nil {
		return value, fmt.Errorf("could not compute value: %w", err)
	}

	s.setUnlocked(value)

	return value, nil
}

func (s *ComputedSubscribable[T]) SetCurrent(ctx context.Context) (T, error) {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	return s.setCurrentUnlocked(ctx)
}

func (s *ComputedSubscribable[T]) Subscribe(ctx context.Context) (<-chan T, error) {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	_, err := s.setCurrentUnlocked(ctx)
	if err != nil {
		return nil, fmt.Errorf("could not get current value: %w", err)
	}

	return s.subscribeUnlocked(ctx), nil
}
