# IronFlock Init (`ironflock-init`)

`ironflock-init` is a Go CLI tool that connects an existing Debian/Ubuntu Linux system to the [IronFlock](https://ironflock.com) platform — a process called **reswarmification**. It installs the `reagent` agent, configures Docker and systemd services, and overlays the root filesystem with all the files needed to participate in the IronFlock platform.

## Requirements

- Debian or Ubuntu-based OS (x86_64, arm64, armv5/v6/v7)
- systemd as the init system
- Root / sudo access
- Docker<sup>*</sup>

<small>* Installed automatically by `ironflock-init` if not already present — that step downloads from get.docker.com and needs internet access. Devices enrolled through an appliance without internet must have Docker preinstalled (see [Enrol through an appliance](#enrol-through-an-appliance-offline-devices)).</small>

## Installation

Download and install the binary for your architecture with a single command:

Using curl:
```bash
curl -sSL https://instance-registry.ironflock.com/dl/reswarmify/install.sh | bash
```

Using wget:
```bash
wget -qO- https://instance-registry.ironflock.com/dl/reswarmify/install.sh | bash
```

`install.sh` auto-detects your CPU architecture (`uname -m`), fetches the
latest version number from the download base, downloads the matching
`ironflock-init` binary and verifies it against the `.sha256` sidecar
published next to it (a missing sidecar — older releases — is reported as a
warning; a mismatch or a failed download aborts).

The download base defaults to the IronFlock cloud
(`https://instance-registry.ironflock.com/dl`). Set `IRONFLOCK_DL_BASE` to
fetch from an appliance mirror instead — see
[Enrol through an appliance](#enrol-through-an-appliance-offline-devices).

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
  -s, --disable-suspend Prevent the host from auto-suspending by masking the
                        systemd sleep targets. Recommended for always-on devices;
                        desktop installs may otherwise drop offline every ~15 min.
      --download-base string
                        Base URL of the download mirror (appliance:
                        http://<host>:15002/dl). Defaults to the .flock's
                        update_url, else the IronFlock cloud. Also read from
                        the IRONFLOCK_DL_BASE environment variable.
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

### Prevent the host from auto-suspending

Desktop installs (Ubuntu/Debian with GDM/GNOME) ship an idle-suspend timer that
fires even at the login screen; on the sleep signal NetworkManager tears the
NIC down, so the device drops offline for ~40s every ~15 minutes and every
platform connection is cut. For always-on devices, mask the systemd sleep
targets at install time:

```bash
sudo ironflock-init -c /path/to/device.flock --disable-suspend
```

Interactive installs also offer this as an (unselected) option in the setup
menu; `--disable-suspend` preselects it and is what enables it under
`--autoconfirm`. It is opt-in because a reswarmified host may double as a
workstation whose owner wants suspend to keep working.

The mask persists after `ironflock-init remove`. To undo it manually:

```bash
sudo systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target
```

### Enrol through an appliance (offline devices)

An IronFlock appliance mirrors the bootstrap artefacts, so edge devices
without internet access can be enrolled through it. The appliance serves the
same layout as the cloud under its device-facing download base `<DL>`:
`http://<appliance-host>:15002/dl` in plain mode,
`https://registry.<appliance-domain>/dl` in domain mode. Every `.flock` the
appliance issues carries that base as `update_url`, which the device agent
also uses for its OTA updates.

Prerequisites on the device — the mirror covers only IronFlock artefacts, not
distro packages:

- Docker installed and running (otherwise `ironflock-init` tries
  get.docker.com, which needs the internet).
- The apt packages `ironflock-init` installs already present: `jq`,
  `ca-certificates`, `curl`, `gnupg`, `lsb-release`, `net-tools`, `iproute2`,
  `dnsutils`, `network-manager`, `openssh-server`. A failing `apt-get update`
  is tolerated; `apt-get install` of already-installed packages needs no
  network.
- `wget` or `curl`, plus `sha256sum` (coreutils) or `shasum`, for `install.sh`.

Then, on the device:

```bash
curl -sSL <DL>/reswarmify/install.sh | IRONFLOCK_DL_BASE=<DL> bash
scp user@workstation:/path/to/device.flock .
sudo ./ironflock-init -c device.flock
```

`ironflock-init` resolves its download base in this order and prints the
choice once: `--download-base` flag, `IRONFLOCK_DL_BASE` environment variable,
the `.flock`'s `update_url`, then the IronFlock cloud. Note that `sudo` drops
environment variables by default, so for the root invocations pass the flag
(`sudo ./ironflock-init --download-base <DL> ...`) or
`sudo IRONFLOCK_DL_BASE=<DL> ./ironflock-init ...`; the variable is mainly for
`install.sh`. The mirror's host is added to `NO_PROXY` automatically when a
corporate proxy is configured, so a LAN appliance is never dialled through it. Cloud-issued `.flock`
files carry no `update_url`, so no flag is needed in either case; the flag and
variable exist to override a `.flock` and for `ironflock-init remove`, which
re-downloads the rootfs overlay on legacy hosts. The agent binary is verified
against the `.sha256` sidecar the mirror publishes next to it; the cloud
bucket lacks sidecars for older agent releases, which is reported as a
warning rather than an error.

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
3. **Installs system packages**: `jq`, `ca-certificates`, `curl`, `gnupg`, `lsb-release`, `net-tools`, `iproute2`, `dnsutils`, `network-manager`, `openssh-server`. (The legacy `setup.sh` additionally installed `earlyoom`; the CLI does not.)
4. **Downloads and extracts** `rootfs.tar.gz` from the download base (`<base>/reswarmify/rootfs.tar.gz`), overlaying it onto `/`. This installs all IronFlock-specific configs, scripts, and systemd units.
5. **Downloads the `reagent` binary** from `<base>/re-agent/linux/<arch>/<version>/reagent`, verifies it against its `.sha256` sidecar and places it in `/opt/reagent/`.
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
│   ├── download/           # Download base (cloud vs appliance mirror) + .sha256 verification
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
├── Justfile                # Build, publish and release recipes
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
just build-all-docker
```

Or build locally if you have a Go toolchain:

```bash
just build-all
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

Releases follow the IronFlock release standard (see
`REDeployments/docs/RELEASE.md`). Commit your work first — the release runs
off a clean tree — then:

```bash
just release-patch    # or release-minor
```

This bumps `cli/release/version.txt` and every channel in
`availableVersions.json`, builds all binaries in Docker, uploads them to
`gs://reswarmos/reswarmify/<os>/<arch>/<version>/ironflock-init` (each with
a `.sha256` sidecar), republishes `install.sh`, uploads `version.txt` and
`availableVersions.json`, and finishes with a release commit tagged
`reswarmify-v<version>` that carries the version bump alone.

To build and publish without releasing (e.g. re-publishing the current
version), use `just rollout`.

#### Rootfs Overlay

After changing any file under `rootfs/`:

```bash
just rollout-rootfs
```

This tars the `rootfs/` directory and uploads it as `rootfs.tar.gz` to GCS (with `Cache-Control: no-cache` so devices always fetch the latest).

#### install.sh

`install.sh` is published by `just publish-install`, which `just rollout` (and
therefore every `just release-*`) runs — so a release always republishes the
script and the bucket copy cannot lag the repo. Run it on its own after
changing only the script:

```bash
just publish-install
```

Note: the bucket copy that predates this recipe was uploaded by hand in 2024
and still points at `storage.googleapis.com`; the next rollout replaces it.

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
├── linux/<arch>/<version>/ironflock-init
└── linux/<arch>/<version>/ironflock-init.sha256   # written by publish.sh; older releases have none
```

Clients never hit the bucket directly. The cloud serves it through the
download proxy as `https://instance-registry.ironflock.com/dl/reswarmify/...`
(`.../dl/reswarmos/reswarmify/...` is an alias kept for existing clients — use
the short form), and an appliance mirrors the same bucket under
`<DL>/reswarmify/...` next to the agent binaries at `<DL>/re-agent/...`, so
devices without internet access bootstrap through it. On the appliance mirror
every binary has its `.sha256` sidecar.
