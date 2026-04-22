package main
package setup

import (
	"fmt"
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
// of the config: old *.flock files in /boot are removed before the new one is
// copied in so the symlink target is unambiguous.
//
// The caller must have already validated that configPath exists and contains
// valid JSON.
func UpdateDeviceConfig(configPath string) error {
	abs, err := filepath.Abs(configPath)
	if err != nil {
		return fmt.Errorf("resolve config path: %w", err)
	}

	base := filepath.Base(abs)
	if !strings.HasSuffix(base, ".flock") {
		return fmt.Errorf("config file must have .flock extension: %s", base)
	}

	// Remove any existing *.flock files in /boot so the symlink target is
	// unambiguous and stale configs do not linger across reboots.
	entries, err := os.ReadDir(bootDir)
	if err != nil {
		return fmt.Errorf("read %s: %w", bootDir, err)
	}
	for _, e := range entries {
		if e.IsDir() {
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

	// Copy the new config into /boot.
	dest := filepath.Join(bootDir, base)
	if _, err := exec.Command("cp", "-f", abs, dest).CombinedOutput(); err != nil {
		return fmt.Errorf("copy %s -> %s: %w", abs, dest, err)
	}
	fmt.Printf("installed %s\n", dest)

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
