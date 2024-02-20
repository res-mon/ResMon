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

	router.Handler("POST", "/api", srv)
	router.Handler("GET", "/api", playground.Handler("ResMon API", "/api"))
}
