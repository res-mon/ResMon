package web

import (
	"compress/gzip"
	"context"
	"embed"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"mime"
	"net"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"os/exec"
	"runtime"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/gorilla/websocket"
	"github.com/julienschmidt/httprouter"
)

type server struct {
	port         uint16
	rootPath     string
	embeddedRoot embed.FS
	devMode      bool
}

const indexName = "index.html"
const devDestination = "http://localhost:8122/"

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
}

func NewServer(
	port uint16, rootPath string, embeddedRoot embed.FS, devMode bool,
) *server {
	return &server{
		port:         port,
		rootPath:     rootPath,
		embeddedRoot: embeddedRoot,
		devMode:      devMode,
	}
}

func getNetworkAddresses() ([]string, error) {
	var result []string

	interfaces, err := net.Interfaces()
	if err != nil {
		return result, fmt.Errorf("could not get network interfaces: %w", err)
	}
	for _, i := range interfaces {
		addrs, err := i.Addrs()
		if err != nil {
			return result, fmt.Errorf("could not get interface addresses: %w", err)
		}
		for _, a := range addrs {
			switch v := a.(type) {
			case *net.IPAddr:
				result = append(result, v.String())
			case *net.IPNet:
				if !v.IP.IsPrivate() {
					continue
				}
				result = append(result, v.IP.String())
			}

		}
	}

	return result, nil
}

func (s *server) Run(ctx, killCtx context.Context, shutdown func()) error {
	router := httprouter.New()

	var err error
	if s.devMode {
		err = s.handleDefaultDev(router)
	} else {
		err = s.handleDefaultProd(router)
	}
	if err != nil {
		return fmt.Errorf("could not default route: %w", err)
	}

	srv := &http.Server{
		Addr:              fmt.Sprintf(":%d", s.port),
		ReadTimeout:       300 * time.Second,
		WriteTimeout:      300 * time.Second,
		IdleTimeout:       300 * time.Second,
		ReadHeaderTimeout: 300 * time.Second,
		Handler:           router,
	}

	var wg sync.WaitGroup
	var shutdownErr error

	wg.Add(1)
	go func() {
		<-ctx.Done()
		shutdownErr = srv.Shutdown(killCtx)
		wg.Done()
	}()

	addresses, err := getNetworkAddresses()
	if err != nil {
		fmt.Printf("could not get network addresses: %v\n", err)
	} else {
		for _, i := range addresses {
			fmt.Printf("listening at: http://%s:%d/\n", i, s.port)
		}
	}

	errChan := make(chan error)
	go (func() {
		errChan <- srv.ListenAndServe()
	})()

	if s.devMode {
		go (func() {
			err := openURL("http://localhost:8123/")
			if err != nil {
				errChan <- err
			}
		})()
	}

	err = <-errChan
	if err != http.ErrServerClosed {
		shutdown()
		return err
	}

	wg.Wait()
	if err == http.ErrServerClosed {
		return shutdownErr
	}

	return err
}

func openURL(url string) error {
	var cmd string
	var args []string

	switch runtime.GOOS {
	case "windows":
		cmd = "cmd"
		args = []string{"/c", "start"}
	case "darwin":
		cmd = "open"
	default: // "linux", "freebsd", "openbsd", "netbsd"
		cmd = "xdg-open"
	}
	args = append(args, url)
	return exec.Command(cmd, args...).Start()
}

func (s *server) handleDefaultDev(router *httprouter.Router) error {
	url, err := url.Parse(devDestination)
	if err != nil {
		return fmt.Errorf("could not parse reverse proxy url: %w", err)
	}

	proxy := httputil.NewSingleHostReverseProxy(url)
	router.NotFound = http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		proxy.ServeHTTP(w, r)
	})
	router.GET("/ws", webSocketDevProxyHandler)

	return nil
}

func (s *server) handleDefaultProd(router *httprouter.Router) error {
	root, err := fs.Sub(s.embeddedRoot, s.rootPath)
	if err != nil {
		return fmt.Errorf("embedded root directory not found: %w", err)
	}

	fileMap := map[string]string{
		"": indexName,
	}

	fs.WalkDir(root, ".", func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}

		if d.IsDir() {
			return nil
		}

		fileMap[strings.ToLower(path)] = path
		return nil
	})

	router.NotFound = http.HandlerFunc(func(
		w http.ResponseWriter, r *http.Request,
	) {
		s.withErr(func(
			w http.ResponseWriter, r *http.Request, p httprouter.Params,
		) error {
			var path string
			if r.URL != nil {
				requestPath := strings.TrimLeft(r.URL.Path, "/")

				var ok bool
				path, ok = fileMap[strings.ToLower(requestPath)]
				if !ok {
					path = requestPath
				}
			}
			if path == "" {
				path = indexName
			}

			stat, err := fs.Stat(root, path)
			if err != nil {
				if errors.Is(err, os.ErrNotExist) {
					path = indexName
					stat, err = fs.Stat(root, path)
				}
				if err != nil {
					return fmt.Errorf("could not get stat for file '%s': %w",
						path, err)
				}
			}
			immutable := path != indexName

			w.Header().Set("Last-Modified",
				stat.ModTime().UTC().Format(time.RFC1123))

			extensionIndex := strings.LastIndex(path, ".")
			if extensionIndex != -1 {
				var tag string
				switch strings.ToLower(path[extensionIndex:]) {
				case ".js":
					tag = "text/javascript; charset=utf-8"
				default:
					tag = mime.TypeByExtension(path[extensionIndex:])
				}

				w.Header().Set("Content-Type", tag)
				w.Header().Set("X-Content-Type-Options", "nosniff")
			}

			if immutable {
				w.Header().Set("Cache-Control", "max-age=31536000, immutable")
			} else {
				w.Header().Set("Cache-Control", "no-cache")
			}

			gz := strings.Contains(r.Header.Get("Accept-Encoding"), "gzip")
			if gz {
				w.Header().Set("Content-Encoding", "gzip")
			} else {
				w.Header().Set("Content-Length",
					strconv.FormatInt(stat.Size(), 10))
			}

			if r.Method == "HEAD" {
				return nil
			}

			file, err := root.Open(path)
			if err != nil {
				return fmt.Errorf("could not open file '%s': %w", path, err)
			}

			var dest io.Writer
			if gz {
				gzWriter := gzip.NewWriter(w)
				defer gzWriter.Close()
				dest = gzWriter
			} else {
				dest = w
			}

			_, err = io.Copy(dest, file)
			if err != nil {
				return fmt.Errorf("could not write file '%s': %w", path, err)
			}

			return nil
		})(w, r, nil)
	})

	return nil
}

func webSocketDevProxyHandler(w http.ResponseWriter, r *http.Request, _ httprouter.Params) {
	srcConn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		fmt.Printf("could not upgrade web socket dev proxy: %v\n", err)
		return
	}
	defer srcConn.Close()

	dstConn, _, err := websocket.DefaultDialer.Dial("ws://localhost:8122/ws", r.Header)
	if err != nil {
		fmt.Printf("could not connect to dev web socket: %v\n", err)
		return
	}
	defer dstConn.Close()

	go func() {
		for {
			messageType, p, err := srcConn.ReadMessage()
			if err != nil {
				fmt.Printf("could not read from incoming web socket connection: %v\n", err)
				return
			}
			if err := dstConn.WriteMessage(messageType, p); err != nil {
				fmt.Printf("could not write to destination dev web socket: %v\n", err)
				return
			}
		}
	}()

	for {
		messageType, p, err := dstConn.ReadMessage()
		if err != nil {
			fmt.Printf("could not read from destination dev web socket: %v\n", err)
			return
		}
		if err := srcConn.WriteMessage(messageType, p); err != nil {
			fmt.Printf("could not write to incoming web socket connection: %v\n", err)
			return
		}
	}
}

func (s *server) withErr(h func(
	w http.ResponseWriter, r *http.Request, p httprouter.Params,
) error) httprouter.Handle {
	return func(w http.ResponseWriter, r *http.Request, p httprouter.Params) {
		err := h(w, r, p)
		if err == nil {
			return
		}

		w.WriteHeader(http.StatusInternalServerError)
		errStr := err.Error()
		fmt.Fprintf(w, "An internal server error occurred: %s", errStr)
		if !strings.HasSuffix(errStr, ".") {
			fmt.Fprint(w, ".")
		}
	}
}
