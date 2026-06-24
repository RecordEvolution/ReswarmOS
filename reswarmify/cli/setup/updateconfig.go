package setup

import (
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

const (
	bootDir        = "/boot"
	deviceCfgLink  = "/opt/reagent/device-config.flock"
	reagentService = "reagent.service"
)

// UpdateDeviceConfig replaces the active *.flock device configuration on an
// already-reswarmified host and restarts reagent. It is a no-op-safe upgrade
// of the config: the new *.flock is installed into /boot first, then any other
// stale *.flock files are removed so the symlink target is unambiguous.
//
// The caller must have already validated that configPath exists and contains
// valid JSON.
func UpdateDeviceConfig(configPath string) error {
	// reagent updates are invoked from environments with a stripped PATH (the
	// systemd apply-update unit, sudo without -E). Guarantee the standard
	// system dirs are present so the systemctl call below resolves; the copy
	// itself is done natively and no longer depends on `cp` being on PATH.
	ensureSystemPath()

	abs, err := filepath.Abs(configPath)
	if err != nil {
		return fmt.Errorf("resolve config path: %w", err)
	}

	base := filepath.Base(abs)
	if !strings.HasSuffix(base, ".flock") {
		return fmt.Errorf("config file must have .flock extension: %s", base)
	}

	// Install the new config into /boot first, atomically. Writing before
	// removing stale files guarantees /boot is never left without a valid
	// *.flock if anything fails midway (the previous remove-then-copy order
	// could brick the host's config when the copy failed).
	dest := filepath.Join(bootDir, base)
	if err := copyFileAtomic(abs, dest); err != nil {
		return fmt.Errorf("copy %s -> %s: %w", abs, dest, err)
	}
	fmt.Printf("installed %s\n", dest)

	// Remove any other *.flock files in /boot so the symlink target is
	// unambiguous and stale configs do not linger across reboots.
	entries, err := os.ReadDir(bootDir)
	if err != nil {
		return fmt.Errorf("read %s: %w", bootDir, err)
	}
	for _, e := range entries {
		if e.IsDir() || e.Name() == base {
			continue
		}
		if strings.HasSuffix(e.Name(), ".flock") {
			p := filepath.Join(bootDir, e.Name())
			if err := os.Remove(p); err != nil {
				return fmt.Errorf("remove %s: %w", p, err)
			}
			fmt.Printf("removed stale %s\n", p)
		}
	}

	// Re-point the active-config symlink.
	_ = os.Remove(deviceCfgLink)
	if err := os.Symlink(dest, deviceCfgLink); err != nil {
		return fmt.Errorf("symlink %s -> %s: %w", deviceCfgLink, dest, err)
	}
	fmt.Printf("symlink %s -> %s\n", deviceCfgLink, dest)

	// Restart the agent so it picks up the new configuration.
	out, err := exec.Command("systemctl", "restart", reagentService).CombinedOutput()
	if err != nil {
		return fmt.Errorf("systemctl restart %s: %w (%s)", reagentService, err, strings.TrimSpace(string(out)))
	}
	fmt.Printf("restarted %s\n", reagentService)

	return nil
}

// copyFileAtomic copies src to dest by writing to a temp file in the
// destination directory, fsync-ing it, and renaming it into place. The rename
// is atomic within the same filesystem, so dest is either the old or the new
// content — never a truncated mix — and a failure never leaves dest missing.
// It is implemented natively (no `cp`) so it works regardless of $PATH.
func copyFileAtomic(src, dest string) error {
	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer in.Close()

	info, err := in.Stat()
	if err != nil {
		return err
	}

	tmp, err := os.CreateTemp(filepath.Dir(dest), ".flock-*.tmp")
	if err != nil {
		return err
	}
	tmpName := tmp.Name()
	// Best-effort cleanup; a no-op once the rename below succeeds.
	defer os.Remove(tmpName)

	if _, err := io.Copy(tmp, in); err != nil {
		tmp.Close()
		return err
	}
	if err := tmp.Sync(); err != nil {
		tmp.Close()
		return err
	}
	if err := tmp.Close(); err != nil {
		return err
	}
	if err := os.Chmod(tmpName, info.Mode().Perm()); err != nil {
		return err
	}
	return os.Rename(tmpName, dest)
}

// ensureSystemPath augments the process $PATH with the standard system
// directories if they are missing, so exec lookups (systemctl) resolve even
// when invoked from a minimal environment.
func ensureSystemPath() {
	stdDirs := []string{
		"/usr/local/sbin", "/usr/local/bin",
		"/usr/sbin", "/usr/bin",
		"/sbin", "/bin",
	}

	cur := os.Getenv("PATH")
	if cur == "" {
		os.Setenv("PATH", strings.Join(stdDirs, ":"))
		return
	}

	have := make(map[string]bool)
	for _, d := range strings.Split(cur, ":") {
		have[d] = true
	}

	missing := make([]string, 0, len(stdDirs))
	for _, d := range stdDirs {
		if !have[d] {
			missing = append(missing, d)
		}
	}
	if len(missing) > 0 {
		os.Setenv("PATH", cur+":"+strings.Join(missing, ":"))
	}
}
