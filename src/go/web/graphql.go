package web

import (
	"net/http"
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

	srv.AddTransport(transport.SSE{})
	srv.AddTransport(transport.POST{})
	srv.AddTransport(transport.Websocket{
		KeepAlivePingInterval: 10 * time.Second,
		Upgrader: websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool {
				return true
			},
		},
	})
	srv.Use(extension.Introspection{})

	router.GET("/api", func(
		w http.ResponseWriter,
		r *http.Request,
		_ httprouter.Params,
	) {
		if r.Header.Get("Upgrade") == "websocket" {
			srv.ServeHTTP(w, r)
			return
		}

		playground.
			Handler("ResMon API", "/api").
			ServeHTTP(w, r)
	})

	router.POST("/api", func(
		w http.ResponseWriter,
		r *http.Request,
		_ httprouter.Params,
	) {
		srv.ServeHTTP(w, r)
	})
}
