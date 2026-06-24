// Package proxy configures corporate-proxy support for ironflock-init so the
// tool works on hosts that only reach the internet through an HTTP proxy.
//
// It mirrors the behaviour of the appliance installer (install_ironflock.sh):
// the proxy is resolved from flags (falling back to the standard environment
// variables), exported into the process environment so every download routes
// through it (apt, the get-docker.sh script, the agent download, and Go's own
// HTTP client), and written as a systemd drop-in so the Docker daemon can pull
// images. All operations are no-ops when no proxy is configured.
package proxy

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

// DropInPath is the systemd drop-in that points the Docker daemon at the proxy.
const DropInPath = "/etc/systemd/system/docker.service.d/http-proxy.conf"

// ReagentDropInPath is the systemd drop-in that gives the reagent service its
// proxy environment. The reagent process downloads its own OTA updates over
// HTTP(S), so without this it cannot fetch new agent versions behind a proxy.
const ReagentDropInPath = "/etc/systemd/system/reagent.service.d/http-proxy.conf"

// Config holds the resolved corporate proxy settings.
type Config struct {
	HTTP    string
	HTTPS   string
	NoProxy string
}

// Resolve builds the proxy config from explicit flag values, falling back to the
// standard proxy environment variables (upper- or lower-case). This matches the
// resolution order used by the appliance installer.
func Resolve(httpFlag, httpsFlag, noProxyFlag string) Config {
	return Config{
		HTTP:    firstNonEmpty(httpFlag, os.Getenv("HTTP_PROXY"), os.Getenv("http_proxy")),
		HTTPS:   firstNonEmpty(httpsFlag, os.Getenv("HTTPS_PROXY"), os.Getenv("https_proxy")),
		NoProxy: firstNonEmpty(noProxyFlag, os.Getenv("NO_PROXY"), os.Getenv("no_proxy")),
	}
}

// Enabled reports whether any proxy was configured.
func (c Config) Enabled() bool {
	return c.HTTP != "" || c.HTTPS != ""
}

// Apply exports the proxy settings into the current process environment (both
// upper- and lower-case) so everything ironflock-init shells out to — apt, the
// get-docker.sh installer, wget/curl — and Go's own HTTP client route through
// the proxy. No-op when no proxy is configured.
func (c Config) Apply() {
	if !c.Enabled() {
		return
	}
	setBoth := func(upper, lower, val string) {
		if val == "" {
			return
		}
		os.Setenv(upper, val)
		os.Setenv(lower, val)
	}
	setBoth("HTTP_PROXY", "http_proxy", c.HTTP)
	setBoth("HTTPS_PROXY", "https_proxy", c.HTTPS)
	setBoth("NO_PROXY", "no_proxy", c.noProxyWithDefaults())
}

// ConfigureDockerDaemon writes the systemd drop-in that points the Docker daemon
// at the proxy and restarts Docker so it can pull images. Idempotent: it only
// restarts Docker when the drop-in actually changes. No-op when no proxy is
// configured. Mirrors configure_docker_proxy in install_ironflock.sh.
func (c Config) ConfigureDockerDaemon() error {
	if !c.Enabled() {
		return nil
	}

	desired := c.serviceEnvironmentBlock()

	if existing, err := os.ReadFile(DropInPath); err == nil && string(existing) == desired {
		fmt.Println("Docker daemon proxy already configured (" + DropInPath + ")")
		return nil
	}

	if err := os.MkdirAll(filepath.Dir(DropInPath), 0755); err != nil {
		return err
	}
	if err := os.WriteFile(DropInPath, []byte(desired), 0644); err != nil {
		return err
	}
	fmt.Println("Configured Docker daemon proxy via " + DropInPath)

	if err := exec.Command("systemctl", "daemon-reload").Run(); err != nil {
		return err
	}
	if err := exec.Command("systemctl", "restart", "docker").Run(); err != nil {
		return fmt.Errorf("failed to restart docker after writing proxy config: %w", err)
	}

	// Wait for the daemon to come back before the steps that follow rely on it.
	for i := 0; i < 30; i++ {
		if exec.Command("docker", "info").Run() == nil {
			return nil
		}
		time.Sleep(time.Second)
	}
	return fmt.Errorf("docker did not become ready after restart (proxy config)")
}

// ConfigureReagentService writes a systemd drop-in so the reagent service runs
// with the corporate proxy in its environment. The reagent process fetches its
// own OTA agent updates over HTTP(S), and Go's HTTP client reads HTTP_PROXY /
// HTTPS_PROXY / NO_PROXY from the environment, so without this drop-in agent
// updates fail behind a proxy. Idempotent and a no-op when no proxy is
// configured. The drop-in is picked up when systemd next loads the unit — setup
// enables/starts reagent after this runs, and the host reboots at the end.
func (c Config) ConfigureReagentService() error {
	if !c.Enabled() {
		return nil
	}

	desired := c.serviceEnvironmentBlock()

	if existing, err := os.ReadFile(ReagentDropInPath); err == nil && string(existing) == desired {
		fmt.Println("Reagent service proxy already configured (" + ReagentDropInPath + ")")
		return nil
	}

	if err := os.MkdirAll(filepath.Dir(ReagentDropInPath), 0755); err != nil {
		return err
	}
	if err := os.WriteFile(ReagentDropInPath, []byte(desired), 0644); err != nil {
		return err
	}
	fmt.Println("Configured reagent service proxy via " + ReagentDropInPath)

	// Reload so the drop-in takes effect for any subsequent start of the unit.
	// Ignore the error: the unit may not be loaded yet on a fresh install, and
	// setup's own enable/start (plus the final reboot) re-reads it regardless.
	_ = exec.Command("systemctl", "daemon-reload").Run()
	return nil
}

// serviceEnvironmentBlock renders the `[Service]` drop-in body that exports the
// proxy settings as systemd Environment= lines. Shared by the Docker daemon and
// reagent service drop-ins.
func (c Config) serviceEnvironmentBlock() string {
	var b strings.Builder
	b.WriteString("[Service]\n")
	if c.HTTP != "" {
		fmt.Fprintf(&b, "Environment=\"HTTP_PROXY=%s\"\n", c.HTTP)
	}
	if c.HTTPS != "" {
		fmt.Fprintf(&b, "Environment=\"HTTPS_PROXY=%s\"\n", c.HTTPS)
	}
	fmt.Fprintf(&b, "Environment=\"NO_PROXY=%s\"\n", c.noProxyWithDefaults())
	return b.String()
}

// noProxyWithDefaults keeps loopback off the proxy in addition to whatever the
// operator supplied.
func (c Config) noProxyWithDefaults() string {
	var parts []string
	seen := map[string]bool{}
	add := func(s string) {
		s = strings.TrimSpace(s)
		if s == "" || seen[s] {
			return
		}
		seen[s] = true
		parts = append(parts, s)
	}
	for _, p := range strings.Split(c.NoProxy, ",") {
		add(p)
	}
	for _, p := range []string{"localhost", "127.0.0.1", "::1"} {
		add(p)
	}
	return strings.Join(parts, ",")
}

func firstNonEmpty(vals ...string) string {
	for _, v := range vals {
		if v != "" {
			return v
		}
	}
	return ""
}
