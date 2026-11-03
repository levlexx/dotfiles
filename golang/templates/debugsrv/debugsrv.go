// Package debugsrv serves profiling endpoints on a private address, for
// `gprof` (dotfiles/golang/bin/gprof). Copied into a project by `gprof init`.
//
// Off unless DEBUG_ADDR is set, and it should stay on loopback
// (localhost:6060): `kubectl port-forward` still reaches it inside a pod.
// Never put it on the public port.
//
//	func main() {
//		debugsrv.Start()
//		...
//	}
//
// Endpoints:
//
//	/debug/pprof/...   CPU, heap, allocs, goroutine, mutex, block, trace
//	/debug/fgprof      wall-clock profile: CPU plus time spent waiting on I/O
//	/debug/flight      last seconds of execution trace (flight recorder):
//	                   grab it right after a latency spike
package debugsrv

import (
	"log/slog"
	"net/http"
	"net/http/pprof"
	"os"
	"runtime"
	"runtime/trace"
	"time"

	"github.com/felixge/fgprof"
)

// Start serves the debug endpoints in the background when DEBUG_ADDR is set.
func Start() {
	addr := os.Getenv("DEBUG_ADDR")
	if addr == "" {
		return
	}

	// sample 1 in 5 contended mutex events and blocking events >= 10µs; cheap
	// enough for a debug build, off in production unless DEBUG_ADDR is set
	runtime.SetMutexProfileFraction(5)
	runtime.SetBlockProfileRate(int((10 * time.Microsecond).Nanoseconds()))

	mux := http.NewServeMux()
	mux.HandleFunc("/debug/pprof/", pprof.Index)
	mux.HandleFunc("/debug/pprof/cmdline", pprof.Cmdline)
	mux.HandleFunc("/debug/pprof/profile", pprof.Profile)
	mux.HandleFunc("/debug/pprof/symbol", pprof.Symbol)
	mux.HandleFunc("/debug/pprof/trace", pprof.Trace)
	mux.Handle("/debug/fgprof", fgprof.Handler())

	fr := trace.NewFlightRecorder(trace.FlightRecorderConfig{
		MinAge:   10 * time.Second,
		MaxBytes: 32 << 20,
	})
	if err := fr.Start(); err != nil {
		slog.Warn("debugsrv: flight recorder disabled", "err", err)
	} else {
		mux.HandleFunc("/debug/flight", func(w http.ResponseWriter, _ *http.Request) {
			w.Header().Set("Content-Type", "application/octet-stream")
			if _, err := fr.WriteTo(w); err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
			}
		})
	}

	srv := &http.Server{Addr: addr, Handler: mux, ReadHeaderTimeout: 5 * time.Second}
	go func() {
		slog.Info("debugsrv: listening", "addr", addr)
		if err := srv.ListenAndServe(); err != nil {
			slog.Error("debugsrv: stopped", "err", err)
		}
	}()
}
