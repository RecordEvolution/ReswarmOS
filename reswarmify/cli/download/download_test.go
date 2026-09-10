package download

import (
	"crypto/sha256"
	"encoding/hex"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestResolvePrecedence(t *testing.T) {
	cases := []struct {
		name, flag, env, flock string
		want, source           string
	}{
		{"flag beats env and flock", "http://flag/dl", "http://env/dl", "http://flock/dl", "http://flag/dl", "--download-base"},
		{"env beats flock", "", "http://env/dl", "http://flock/dl", "http://env/dl", EnvVar},
		{"flock beats default", "", "", "http://flock/dl", "http://flock/dl", ".flock " + FlockField},
		{"default when nothing set", "", "", "", DefaultBase, "default"},
		{"flag trailing slash trimmed", "http://flag/dl/", "", "", "http://flag/dl", "--download-base"},
		{"env repeated slashes trimmed", "", "http://env/dl///", "", "http://env/dl", EnvVar},
		{"flock trailing slash trimmed", "", "", "https://registry.example.com/dl/", "https://registry.example.com/dl", ".flock " + FlockField},
		{"blank flag falls through", "   ", "http://env/dl", "", "http://env/dl", EnvVar},
		{"slash-only flag falls through", "/", "", "", DefaultBase, "default"},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got, source, err := resolve(tc.flag, tc.env, tc.flock)
			if err != nil || got != tc.want || source != tc.source {
				t.Fatalf("resolve(%q, %q, %q) = (%q, %q, %v), want (%q, %q)",
					tc.flag, tc.env, tc.flock, got, source, err, tc.want, tc.source)
			}
		})
	}
	// A flag or env value without scheme/host is rejected up front.
	for _, bad := range []string{"10.20.0.5:15002/dl", "appliance/dl", "ftp://x/dl", "http:///dl"} {
		if _, _, err := resolve(bad, "", ""); err == nil {
			t.Errorf("flag %q accepted", bad)
		}
		if _, _, err := resolve("", bad, ""); err == nil {
			t.Errorf("env %q accepted", bad)
		}
	}
	if h := Host("http://10.20.0.5:15002/dl"); h != "10.20.0.5:15002" {
		t.Errorf("Host = %q", h)
	}
}

func writeFlock(t *testing.T, content string) string {
	t.Helper()
	path := filepath.Join(t.TempDir(), "device.flock")
	if err := os.WriteFile(path, []byte(content), 0600); err != nil {
		t.Fatal(err)
	}
	return path
}

func TestFlockUpdateURL(t *testing.T) {
	cases := []struct{ name, content, want string }{
		{"appliance plain mode", `{"name":"dev","update_url":"http://10.0.0.5:15002/dl"}`, "http://10.0.0.5:15002/dl"},
		{"appliance domain mode", `{"update_url":"https://registry.plant.example/dl"}`, "https://registry.plant.example/dl"},
		{"surrounding whitespace trimmed", `{"update_url":"  https://registry.plant.example/dl  "}`, "https://registry.plant.example/dl"},
		{"field absent (cloud flock)", `{"name":"dev","endpoint_url":"wss://cbw.ironflock.com"}`, ""},
		{"field not a string", `{"update_url": 42}`, ""},
		{"field null", `{"update_url": null}`, ""},
		{"empty string", `{"update_url":""}`, ""},
		{"non-http scheme", `{"update_url":"ftp://mirror/dl"}`, ""},
		{"relative value", `{"update_url":"registry/dl"}`, ""},
		{"invalid json", `{not json`, ""},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			if got := flockUpdateURL(writeFlock(t, tc.content)); got != tc.want {
				t.Fatalf("flockUpdateURL(%s) = %q, want %q", tc.content, got, tc.want)
			}
		})
	}
	t.Run("missing file", func(t *testing.T) {
		if got := flockUpdateURL(filepath.Join(t.TempDir(), "nope.flock")); got != "" {
			t.Fatalf("got %q, want empty", got)
		}
	})
	t.Run("empty path", func(t *testing.T) {
		if got := flockUpdateURL(""); got != "" {
			t.Fatalf("got %q, want empty", got)
		}
	})
}

func TestResolveDownloadBase(t *testing.T) {
	flock := writeFlock(t, `{"update_url":"http://appliance:15002/dl/"}`)

	t.Setenv(EnvVar, "")
	if got, err := ResolveDownloadBase("", flock); err != nil || got != "http://appliance:15002/dl" {
		t.Fatalf("flock: got %q err %v", got, err)
	}
	if got, err := ResolveDownloadBase("", ""); err != nil || got != DefaultBase {
		t.Fatalf("default: got %q err %v", got, err)
	}

	t.Setenv(EnvVar, "https://mirror.example/dl/")
	if got, err := ResolveDownloadBase("", flock); err != nil || got != "https://mirror.example/dl" {
		t.Fatalf("env: got %q err %v", got, err)
	}
	if got, err := ResolveDownloadBase("http://flag/dl/", flock); err != nil || got != "http://flag/dl" {
		t.Fatalf("flag: got %q err %v", got, err)
	}
	t.Setenv(EnvVar, "not a url")
	if _, err := ResolveDownloadBase("", flock); err == nil {
		t.Fatal("invalid env accepted")
	}
}

// sidecarServer serves payload at /reagent and whatever the test wants at
// /reagent.sha256.
func sidecarServer(t *testing.T, payload []byte, sidecar func(http.ResponseWriter)) *httptest.Server {
	t.Helper()
	mux := http.NewServeMux()
	mux.HandleFunc("/reagent", func(w http.ResponseWriter, r *http.Request) { w.Write(payload) })
	mux.HandleFunc("/reagent.sha256", func(w http.ResponseWriter, r *http.Request) { sidecar(w) })
	srv := httptest.NewServer(mux)
	t.Cleanup(srv.Close)
	return srv
}

func TestVerifySidecar(t *testing.T) {
	payload := []byte("pretend this is a reagent binary")
	sum := sha256.Sum256(payload)
	digest := hex.EncodeToString(sum[:])

	body := func(s string) func(http.ResponseWriter) {
		return func(w http.ResponseWriter) { w.Write([]byte(s)) }
	}
	status := func(code int) func(http.ResponseWriter) {
		return func(w http.ResponseWriter) { w.WriteHeader(code) }
	}

	cases := []struct {
		name     string
		sidecar  func(http.ResponseWriter)
		wantErr  bool
		fileKept bool
	}{
		{"bare digest matches", body(digest + "\n"), false, true},
		{"sha256sum format matches", body(digest + "  reagent\n"), false, true},
		{"upper-case digest matches", body(strings.ToUpper(digest)), false, true},
		{"mismatch is an error and removes the file", body(strings.Repeat("0", 64) + "\n"), true, false},
		{"missing sidecar is a warning", status(http.StatusNotFound), false, true},
		{"server error is an error", status(http.StatusInternalServerError), true, true},
		{"malformed sidecar is an error", body("not-a-digest\n"), true, true},
		{"empty sidecar is an error", body(""), true, true},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			srv := sidecarServer(t, payload, tc.sidecar)
			path := filepath.Join(t.TempDir(), "reagent-latest")
			if err := os.WriteFile(path, payload, 0755); err != nil {
				t.Fatal(err)
			}

			err := VerifySidecar(srv.URL+"/reagent", path)
			if (err != nil) != tc.wantErr {
				t.Fatalf("VerifySidecar: err = %v, wantErr %v", err, tc.wantErr)
			}
			_, statErr := os.Stat(path)
			if kept := statErr == nil; kept != tc.fileKept {
				t.Fatalf("file kept = %v, want %v (stat: %v)", kept, tc.fileKept, statErr)
			}
		})
	}
}
