package web

import (
	"net/http"
	"strings"
	"time"

	"github.com/99designs/gqlgen/graphql/handler"
	"github.com/99designs/gqlgen/graphql/handler/extension"
	"github.com/99designs/gqlgen/graphql/handler/transport"
	"github.com/99designs/gqlgen/graphql/playground"
	"github.com/gorilla/websocket"
	"github.com/julienschmidt/httprouter"

	"github.com/yerTools/ResMon/generated/go/graph"
	"github.com/yerTools/ResMon/src/go/api"
)

func startAPI(router *httprouter.Router) {
	srv := handler.New(
		graph.NewExecutableSchema(api.New()))

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

	handle := func(
		w http.ResponseWriter,
		r *http.Request,
		_ httprouter.Params,
	) {
		srv.ServeHTTP(w, r)
	}

	router.GET("/api", func(
		w http.ResponseWriter,
		r *http.Request,
		_ httprouter.Params,
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

	router.POST("/api", handle)
	router.OPTIONS("/api", handle)

	apolloHandler := playground.ApolloSandboxHandler(
		"ResMon - Apollo GraphQL Sandbox", "/api")

	router.Handler("DELETE", "/api/apollo", apolloHandler)
	router.Handler("GET", "/api/apollo", apolloHandler)
	router.Handler("HEAD", "/api/apollo", apolloHandler)
	router.Handler("PATCH", "/api/apollo", apolloHandler)
	router.Handler("POST", "/api/apollo", apolloHandler)
	router.Handler("PUT", "/api/apollo", apolloHandler)
}
