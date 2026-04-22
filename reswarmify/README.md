# IronFlock Init (`ironflock-init`)

`ironflock-init` is a Go CLI tool that connects an existing Debian/Ubuntu Linux system to the [IronFlock](https://ironflock.com) platform — a process called **reswarmification**. It installs the `reagent` agent, configures Docker and systemd services, and overlays the root filesystem with all the files needed to participate in the IronFlock platform.

## Requirements

- Debian or Ubuntu-based OS (x86_64, arm64, armv5/v6/v7)
- systemd as the init system
- Root / sudo access
- Docker<sup>*</sup>

<small>* Installed automatically by `ironflock-init` if not already present.</small>

## Installation

Download and install the binary for your architecture with a single command:

Using curl:
```bash
curl -sSL https://storage.googleapis.com/reswarmos/reswarmify/install.sh | bash
```

Using wget:
```bash
wget -qO- https://storage.googleapis.com/reswarmos/reswarmify/install.sh | bash
```

`install.sh` auto-detects your CPU architecture (`uname -m`), fetches the latest version number from GCS, and downloads the matching `ironflock-init` binary.

## Usage

```
CLI tool to initialize your IronFlock device

Usage:
  ironflock-init [flags]
  ironflock-init [command]

Available Commands:
  completion  Generate the autocompletion script for the specified shell
  help        Help about any command
  remove      Remove the currently installed IronFlock setup
  version     Display the current version of the ironflock-init binary

Flags:
  -c, --config string   Path to .flock device config file (required)
  -a, --autoconfirm     Run without interactive prompts, accepting all defaults
  -u, --update-config   Replace the active .flock on an already-reswarmified host
                        and restart reagent. On a fresh host this falls back to
                        a full install, making the flag idempotent.
  -h, --help            Help for ironflock-init
```

### Reswarmify a device

1. Create a virtual device on the IronFlock platform and download its `.flock` config file.
2. Run:

```bash
sudo ironflock-init -c /path/to/device.flock
```

### Update the device configuration

Use `--update-config` (`-u`) to swap the `.flock` on a host that is already
reswarmified without going through the full install flow. This removes any
existing `*.flock` files from `/boot`, installs the new one, re-points the
`/opt/reagent/device-config.flock` symlink and restarts `reagent.service`:

```bash
sudo ironflock-init -c /path/to/new-device.flock --update-config --autoconfirm
```

On a host that has NOT been reswarmified yet, the same command performs a
full reswarmification — so the flag is safe to use in installer scripts that
run on both fresh and already-provisioned hosts.

### Remove IronFlock from a device

```bash
sudo ironflock-init remove
```

This disables all IronFlock systemd services, removes the reagent user, reverts WiFi/network changes, cleans up the rootfs overlay, and deletes `/opt/reagent`.

---

## What Reswarmification Does

When `ironflock-init -c device.flock` runs, it performs these steps in order:

1. **Validates** the `.flock` JSON config and checks the device is not already reswarmified.
2. **Copies** the `.flock` config to `/boot` for persistence across reboots.
3. **Installs system packages**: `jq`, `ca-certificates`, `curl`, `gnupg`, `net-tools`, `iproute2`, `dnsutils`, `network-manager`, `openssh-server`.
4. **Downloads and extracts** `rootfs.tar.gz` from GCS, overlaying it onto `/`. This installs all IronFlock-specific configs, scripts, and systemd units.
5. **Downloads the `reagent` binary** from `gs://re-agent` and places it in `/opt/reagent/`.
6. **Installs Docker** if not already present.
7. **Runs setup scripts** from `/opt/reagent/reswarmify/scripts/` (user creation, WiFi config, service configuration, etc.).
8. **Enables systemd services**: `reagent.service` and `reagent-manager.service`.

After completion the device connects to the IronFlock platform and is visible in the dashboard.

---

## Repository Structure

```
reswarmify/
├── cli/                    # Go source for ironflock-init
│   ├── main.go
│   ├── go.mod
│   ├── cmd/                # Cobra CLI commands (root, remove, version)
│   ├── agent/              # reagent binary download/management
│   ├── docker/             # Docker installation and configuration
│   ├── fs/                 # rootfs overlay download and extraction
│   ├── packagemanager/     # apt package installation
│   ├── prompts/            # Bubble Tea interactive TUI prompts
│   ├── setup/              # Reswarmification and removal orchestration
│   ├── utils/              # Helpers (reswarmify state checks, file ops)
│   └── release/
│       └── version.txt     # Current binary version (e.g. 1.2.2)
│
├── rootfs/                 # Overlay applied to the target device's /
│   ├── etc/                # NetworkManager, apt, Docker, systemd, profile.d configs
│   └── opt/reagent/
│       └── reswarmify/
│           ├── scripts/    # Shell scripts executed during setup/removal
│           └── services/   # Systemd units installed onto the device
│
├── scripts/
│   ├── build.sh            # Cross-compile a single arch binary
│   ├── build-all.sh        # Cross-compile all arch binaries in parallel
│   └── publish.sh          # Upload built binaries to GCS
│
├── build/                  # Compiled binaries (gitignored)
│
├── targets                 # List of Go cross-compilation targets
├── availableVersions.json  # Version channels (production, test, local)
├── install.sh              # Arch-detecting installer script (hosted on GCS)
├── setup.sh                # Legacy Bash-only reswarmification script
├── Dockerfile              # Build container for reproducible cross-compilation
├── makefile
└── archive/                # Legacy Bash scripts (pre-CLI, for reference)
```

### Rootfs Scripts (`rootfs/opt/reagent/reswarmify/scripts/`)

| Script | Purpose |
|--------|---------|
| `reswarm.sh` | Main reagent/reswarm configuration |
| `reagent-setup.sh` | reagent binary configuration |
| `reagent-manager.sh` | reagent manager setup |
| `reuser-setup.sh` | Create the IronFlock system user |
| `reuser-removal.sh` | Remove the IronFlock system user |
| `rewifi.sh` | Configure WiFi via NetworkManager |
| `rewifi-removal.sh` | Revert WiFi configuration |
| `enable-services.sh` | Enable IronFlock systemd services |
| `disable-services.sh` | Disable IronFlock systemd services |
| `cleanup-overlay.sh` | Remove overlaid files on uninstall |
| `reconfigure.sh` | Update device config without full reinstall |
| `reparse-ini.sh` / `reparse-json.sh` | Config file format parsing helpers |
| `restart-reagent.sh` | Restart the reagent service |
| `reswarmos-update-check.sh` | OTA update availability check |

### Systemd Services (installed onto the device)

| Service | Purpose |
|---------|---------|
| `reagent.service` | IronFlock agent (main platform connection) |
| `reagent-manager.service` | Manages reagent lifecycle |
| `rehost.service` | Hostname configuration |
| `reswarm.service` | Reswarm init sequence |
| `reuser.service` | System user setup at boot |
| `rewifi.service` | WiFi configuration at boot |

---

## Development

### Building

Build all architecture binaries inside a Docker container (recommended for reproducible output):

```bash
make build-all-docker
```

Or build locally if you have a Go toolchain:

```bash
make build-all
# or for a single target:
bash scripts/build.sh cli/ build/reswarmify-linux-amd64 linux/amd64
```

Supported targets (defined in `targets`):

| Binary | Architecture |
|--------|-------------|
| `reswarmify-linux-amd64` | x86_64 |
| `reswarmify-linux-arm64` | ARM 64-bit |
| `reswarmify-linux-armv7` | ARM 32-bit v7 |
| `reswarmify-linux-armv6` | ARM 32-bit v6 |
| `reswarmify-linux-armv5` | ARM 32-bit v5 |

### Rollout

#### Binary

1. Bump `cli/release/version.txt`.
2. Update `availableVersions.json` for the relevant channels (`production`, `test`).
3. Commit and push, then:

```bash
make rollout
```

This builds all binaries in Docker, uploads them to `gs://reswarmos/reswarmify/<os>/<arch>/<version>/ironflock-init`, and uploads `version.txt` and `availableVersions.json`.

#### Rootfs Overlay

After changing any file under `rootfs/`:

```bash
make rollout-rootfs
```

This tars the `rootfs/` directory and uploads it as `rootfs.tar.gz` to GCS (with `Cache-Control: no-cache` so devices always fetch the latest).

#### install.sh

If `install.sh` changes, upload it manually to `gs://reswarmos/reswarmify/install.sh`.

---

## Cloud Storage Layout

All artifacts are stored in `gs://reswarmos/reswarmify/`:

```
gs://reswarmos/reswarmify/
├── install.sh
├── version.txt
├── availableVersions.json
├── rootfs.tar.gz
├── rootfs-dev.tar.gz
└── linux/<arch>/<version>/ironflock-init
```
