package web

import (
	"context"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/99designs/gqlgen/graphql/handler"
	"github.com/99designs/gqlgen/graphql/handler/extension"
	"github.com/99designs/gqlgen/graphql/handler/transport"
	"github.com/99designs/gqlgen/graphql/playground"
	"github.com/gorilla/websocket"

	"github.com/yerTools/ResMon/generated/go/graph"
	"github.com/yerTools/ResMon/src/go/api"
	"github.com/yerTools/ResMon/src/go/database"
)

func startAPI(ctx context.Context, db *database.DB, mux *http.ServeMux) error {
	cfg, err := api.New(ctx, db)
	if err != nil {
		return fmt.Errorf("could not create new API: %w", err)
	}

	srv := handler.New(
		graph.NewExecutableSchema(cfg))

	srv.AddTransport(transport.Options{
		AllowedMethods: []string{
			"GET", "POST", "OPTIONS",
		},
	})

	srv.AddTransport(transport.Websocket{
		KeepAlivePingInterval: 10 * time.Second,
		Upgrader: websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool {
				return true
			},
		},
	})

	srv.AddTransport(transport.GET{})
	srv.AddTransport(transport.GRAPHQL{})
	srv.AddTransport(transport.SSE{})
	srv.AddTransport(transport.POST{})

	srv.Use(extension.Introspection{})

	mux.HandleFunc("GET /api", func(
		w http.ResponseWriter,
		r *http.Request,
	) {
		if r.Header.Get("Upgrade") == "" &&
			strings.Contains(strings.ToLower(
				r.Header.Get("Accept")), "text/html",
			) {
			http.Redirect(w, r, "/api/apollo", http.StatusFound)
			return
		}

		srv.ServeHTTP(w, r)
	})

	mux.HandleFunc("POST /api", srv.ServeHTTP)
	mux.HandleFunc("OPTIONS /api", srv.ServeHTTP)

	apolloHandler := playground.ApolloSandboxHandler(
		"ResMon - Apollo GraphQL Sandbox", "/api")

	mux.HandleFunc("/api/apollo", apolloHandler)

	return nil
}
