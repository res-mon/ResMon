package utility

import (
	"context"
	"sync"
)

type subscribable[T any] struct {
	value       T
	subscribers []chan T
	bufferSize  int
	mutex       sync.Mutex
}

func NewSubscribable[T any](value T, bufferSize int) *subscribable[T] {
	return &subscribable[T]{
		value:      value,
		bufferSize: bufferSize,
	}
}

func (s *subscribable[T]) Set(value T) {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	s.value = value
	for _, c := range s.subscribers {
		c <- value
	}
}

func (s *subscribable[T]) Current() T {
	return s.value
}

func (s *subscribable[T]) Subscribe(ctx context.Context) <-chan T {
	ch := make(chan T, s.bufferSize)

	s.mutex.Lock()
	defer s.mutex.Unlock()

	s.subscribers = append(s.subscribers, ch)

	go func() {
		ch <- s.value

		<-ctx.Done()
		s.mutex.Lock()
		defer s.mutex.Unlock()
		for i, c := range s.subscribers {
			if c == ch {
				s.subscribers = append(s.subscribers[:i], s.subscribers[i+1:]...)
				close(ch)
				return
			}
		}
	}()

	return ch
}
