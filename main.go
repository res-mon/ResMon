package main

import (
	"context"
	"embed"
	"fmt"
	"io/fs"
	"os"
	"os/exec"
	"os/signal"
	"sync"
	"syscall"
	"time"

	"github.com/yerTools/ResMon/src/go/database"
	"github.com/yerTools/ResMon/src/go/web"
)

//go:embed webroot
var webroot embed.FS

//go:embed src/sql/migrations
var migrations embed.FS

func createContext(killTimeout time.Duration) (
	ctx context.Context, killCtx context.Context,
	cancelCtx context.CancelFunc,
	cancelKillCtx context.CancelFunc,
) {

	killCtx, cancelKillCtx = context.WithCancel(context.Background())
	ctx, cancelCtx = context.WithCancel(killCtx)

	go func() {
		sigChan := make(chan os.Signal, 3)
		signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM, syscall.SIGINT)
		<-sigChan
		cancelCtx()
	}()

	go func() {
		<-ctx.Done()
		sigChan := make(chan os.Signal, 3)
		signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM, syscall.SIGINT)
		select {
		case <-sigChan:
		case <-time.After(killTimeout):
		}
		cancelKillCtx()
	}()

	return
}

func main() {
	ctx, killCtx, shutdown, _ := createContext(time.Second * 10)

	var devMode bool
	for _, a := range os.Args {
		if a == "--dev" {
			devMode = true
		}
	}

	err := os.MkdirAll("data", os.ModePerm)
	if err != nil {
		panic(fmt.Sprintf("could not create data directory: %v", err))
	}

	migrationsFS, err := fs.Sub(migrations, "src/sql/migrations")
	if err != nil {
		panic(fmt.Sprintf("could not get embedded migrations: %v", err))
	}

	fmt.Println("opening database ...")
	db, err := database.OpenDB(ctx, "./data/database.db", migrationsFS)
	if err != nil {
		panic(fmt.Sprintf("could not open database: %v", err))
	}
	defer db.Close()

	fmt.Println("starting web server at http://127.0.0.1:8321/ ...")
	svr := web.NewServer(8321, "webroot", webroot, devMode)

	var wg sync.WaitGroup
	wg.Add(1)

	go (func() {
		err := svr.Run(ctx, killCtx, shutdown, db)

		if err != nil {
			panic(fmt.Sprintf("an error occurred: %v", err))
		}
		wg.Done()
	})()

	if len(os.Args) == 2 && os.Args[1] == "--generate-elm-graphql-schema" {
		cmdStruct := exec.Command(
			"npx", "elm-graphql",
			"http://127.0.0.1:8321/api",
			"--base", "Graph",
			"--output", "generated/elm",
			"--scalar-codecs", "Api.ScalarCodecs")
		out, err := cmdStruct.Output()
		fmt.Println(string(out))
		if err != nil {
			panic(err)
		}
		shutdown()
	}

	wg.Wait()
}
