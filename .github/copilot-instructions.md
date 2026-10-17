# ReswarmOS Copilot Instructions

ReswarmOS is a lightweight Linux OS for IoT devices, built with Buildroot and designed for the IronFlock platform. The project has two main components with distinct build systems and purposes. The device setup tool `ironflock-init` (formerly `reswarmify/`) is maintained in its own repository; its downloads stay under `gs://reswarmos/reswarmify/`.

## Architecture Overview

```
ReswarmOS/
├── buildroot/     # Buildroot-based OS images for embedded devices (RPi, Jetson, x86)
└── cubic/         # Ubuntu-based installer ISOs for x86/IPC hardware using Cubic tool
```

**Key Relationship**: Both produce systems that connect to IronFlock platform via the `reagent` agent. The `rootfs/` overlay directories in each component contain systemd services, configuration files, and scripts that make the OS "IronFlock-ready".

## Build Commands

### Buildroot Images (Raspberry Pi, Jetson, etc.)
```bash
cd buildroot/
# Configure target board in setup.yaml first (board, model, config fields)
make setup      # Build Docker container, prepare certificates
make build      # Run Buildroot compilation (~30-60min)
make release    # Compress, create RAUC bundle, upload to gs://reswarmos
```

### Cubic ISOs (x86 installers)
```bash
cd cubic/
make setup-amd64          # Launch Cubic GUI with project
make overlay-fs-amd64     # Apply rootfs overlay to custom-root
make setup-efi-amd64      # Copy preseed/boot configs for EFI
```

## Configuration Patterns

### `setup.yaml` (Buildroot)
Central configuration for image builds. Key fields:
- `board`/`model`: Must match directory structure in `config/<board>/<model>/`
- `config`: Path to Buildroot `.config` file (or uses default)
- `osvariant`: Included in image name and RAUC compatibility tag

### Board Config Structure
```
buildroot/config/
├── raspberrypi/raspberrypi4/config-full   # Buildroot .config
├── nvidia/jetson-nano/                     # NVIDIA boards
└── x86_64/pc/                              # Generic x86
```

When adding new boards: create directory matching `board/model` naming, add Buildroot config file.

## Rootfs Overlays

The `rootfs/` directories overlay the target filesystem. They follow Linux FHS:
- `etc/systemd/system/`: Systemd service units (reagent.service, reswarm.service, etc.)
- `usr/sbin/`: Shell scripts for boot-time setup (reswarm.sh, redocker.sh, rewifi.sh)
- `etc/rauc/`: RAUC update system configuration and certificates

**Pattern**: Services chain via systemd dependencies. `reswarm.service` → `rehost.service` → `reagent.service`

## RAUC Update System

OTA updates use RAUC with A/B partition scheme:
- Bundles contain compressed rootfs + manifest
- Signed with certificates in `output-build/{cert,key}.pem`
- Compatibility tag format: `ReswarmOS-<variant>-<model>`

## Key Files Reference

| Purpose | Path |
|---------|------|
| OS version | `buildroot/setup.yaml` → `rootfs/etc/os-release` |
| Buildroot config | `buildroot/config/<board>/<model>/config*` |
| Supported boards list | `buildroot/supportedBoards.json` |
| RAUC system config | `buildroot/rootfs/etc/rauc/system.conf` |

## Cloud Storage

All releases go to `gs://reswarmos`:
- Images: `gs://reswarmos/<board>/<image>.img.gz`
- RAUC bundles: `gs://reswarmos/<board>/<bundle>.raucb`
- Device setup tool (`ironflock-init`, separate repository): `gs://reswarmos/reswarmify/`
- Certificates: `gs://reswarmos-certs/` (restricted)

Requires `gsutil` configured with appropriate GCP credentials.
