// Package download resolves where ironflock-init fetches its artefacts from
// and verifies downloads against their .sha256 sidecars.
//
// The IronFlock cloud serves the bootstrap artefacts under
// https://instance-registry.ironflock.com/dl. An appliance mirrors exactly the
// same layout under its own device-facing base (plain mode
// http://<appliance-host>:15002/dl, domain mode
// https://registry.<appliance-domain>/dl) so that edge devices WITHOUT
// internet access can be enrolled through the appliance. Every .flock an
// appliance writes carries that base as "update_url" — the same field the
// DeviceManagementAgent uses as its OTA base — so an appliance-enrolled device
// needs no extra configuration: its .flock says where to download from.
// Cloud-issued .flock files do not carry the field.
//
// Layout below the base (identical on the cloud and on an appliance):
//
//	<base>/re-agent/availableVersions.json
//	<base>/re-agent/linux/<arch>/<version>/reagent            (+ .sha256)
//	<base>/reswarmify/version.txt
//	<base>/reswarmify/install.sh
//	<base>/reswarmify/rootfs.tar.gz
//	<base>/reswarmify/linux/<arch>/<version>/ironflock-init   (+ .sha256)
//
// <base>/reswarmos/reswarmify/... is an alias of <base>/reswarmify/... on both;
// new code uses the short form.
package download

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"strings"
	"sync"
)

// DefaultBase is the IronFlock cloud download base.
const DefaultBase = "https://instance-registry.ironflock.com/dl"

// EnvVar overrides the download base from the environment. install.sh honours
// the same variable, so one export covers the whole bootstrap.
const EnvVar = "IRONFLOCK_DL_BASE"

// FlockField is the .flock key that carries an appliance's download base.
const FlockField = "update_url"

var logOnce sync.Once

// ResolveDownloadBase returns the base URL to download the rootfs overlay and
// the agent from, without a trailing slash. Precedence:
//
//  1. the --download-base flag (flag)
//  2. the IRONFLOCK_DL_BASE environment variable
//  3. the "update_url" field of the .flock at flockPath — ignored when the
//     file is missing or unparsable, or the field is absent or not an
//     absolute http(s) URL
//  4. DefaultBase, the IronFlock cloud
//
// A flag or environment value that is not an absolute http(s) URL is an
// error (a typo must not surface only after packages and Docker were
// installed). The chosen base is printed once per process.
func ResolveDownloadBase(flag, flockPath string) (string, error) {
	base, source, err := resolve(flag, os.Getenv(EnvVar), flockUpdateURL(flockPath))
	if err != nil {
		return "", err
	}
	logOnce.Do(func() {
		fmt.Printf("Download base: %s (from %s)\n", base, source)
	})
	return base, nil
}

// resolve applies the precedence to already-read values so it can be tested
// without touching the environment or the filesystem.
func resolve(flag, env, flock string) (base, source string, err error) {
	if v := normalize(flag); v != "" {
		if !absoluteHTTP(v) {
			return "", "", fmt.Errorf("--download-base %q is not an absolute http(s) URL (e.g. http://<appliance-host>:15002/dl)", flag)
		}
		return v, "--download-base", nil
	}
	if v := normalize(env); v != "" {
		if !absoluteHTTP(v) {
			return "", "", fmt.Errorf("%s=%q is not an absolute http(s) URL (e.g. http://<appliance-host>:15002/dl)", EnvVar, env)
		}
		return v, EnvVar, nil
	}
	if v := normalize(flock); v != "" {
		return v, ".flock " + FlockField, nil
	}
	return DefaultBase, "default", nil
}

// absoluteHTTP reports whether v parses as an http(s) URL with a host.
func absoluteHTTP(v string) bool {
	u, err := url.Parse(v)
	return err == nil && (u.Scheme == "http" || u.Scheme == "https") && u.Host != ""
}

// Host returns the host[:port] of base ("" when it does not parse), for
// NO_PROXY: an appliance mirror is on the LAN and must never be dialled
// through a corporate proxy.
func Host(base string) string {
	u, err := url.Parse(base)
	if err != nil {
		return ""
	}
	return u.Host
}

// normalize trims whitespace and trailing slashes so the base joins cleanly
// with the "/re-agent/..." and "/reswarmify/..." paths.
func normalize(v string) string {
	return strings.TrimRight(strings.TrimSpace(v), "/")
}

// flockUpdateURL reads the update_url field from the .flock at path. It
// returns "" for anything unusable — empty path, missing file, invalid JSON,
// absent or non-string field, or a value that is not an absolute http(s) URL —
// so the caller falls through to the next source.
func flockUpdateURL(path string) string {
	if path == "" {
		return ""
	}
	raw, err := os.ReadFile(path)
	if err != nil {
		return ""
	}
	var flock map[string]interface{}
	if err := json.Unmarshal(raw, &flock); err != nil {
		return ""
	}
	v, ok := flock[FlockField].(string)
	if !ok {
		return ""
	}
	v = strings.TrimSpace(v)
	if !absoluteHTTP(v) {
		return ""
	}
	return v
}

// VerifySidecar checks the file at path against the SHA-256 published next to
// its download URL (<fileURL>.sha256; first whitespace-separated token, hex,
// case-insensitive). On a mismatch the file is removed and an error returned.
//
// A 404 for the sidecar is not an error: the cloud bucket carries none for
// older releases, so a warning is printed and the download is accepted
// unverified. Any other failure to fetch or parse the sidecar is an error — a
// mirror that publishes sidecars must not have a broken one go unnoticed.
func VerifySidecar(fileURL, path string) error {
	sidecarURL := fileURL + ".sha256"

	resp, err := http.Get(sidecarURL)
	if err != nil {
		return fmt.Errorf("fetch checksum %s: %w", sidecarURL, err)
	}
	defer resp.Body.Close()

	switch resp.StatusCode {
	case http.StatusOK:
	case http.StatusNotFound:
		fmt.Printf("Warning: no checksum published at %s — download not verified\n", sidecarURL)
		return nil
	default:
		return fmt.Errorf("fetch checksum %s: status %s", sidecarURL, resp.Status)
	}

	body, err := io.ReadAll(io.LimitReader(resp.Body, 4096))
	if err != nil {
		return fmt.Errorf("read checksum %s: %w", sidecarURL, err)
	}
	expected, err := parseSidecar(body)
	if err != nil {
		return fmt.Errorf("checksum %s: %w", sidecarURL, err)
	}

	actual, err := fileSHA256(path)
	if err != nil {
		return err
	}
	if actual != expected {
		_ = os.Remove(path)
		return fmt.Errorf("checksum mismatch for %s: expected %s, got %s (file removed)", fileURL, expected, actual)
	}
	return nil
}

// parseSidecar extracts the lower-case hex digest from a sidecar body of the
// form "<hex>\n" or "<hex>  <filename>\n" (sha256sum output).
func parseSidecar(body []byte) (string, error) {
	fields := bytes.Fields(body)
	if len(fields) == 0 {
		return "", fmt.Errorf("empty sidecar")
	}
	digest := strings.ToLower(string(fields[0]))
	if len(digest) != sha256.Size*2 {
		return "", fmt.Errorf("malformed sidecar digest %q", digest)
	}
	if _, err := hex.DecodeString(digest); err != nil {
		return "", fmt.Errorf("malformed sidecar digest %q", digest)
	}
	return digest, nil
}

func fileSHA256(path string) (string, error) {
	f, err := os.Open(path)
	if err != nil {
		return "", err
	}
	defer f.Close()

	h := sha256.New()
	if _, err := io.Copy(h, f); err != nil {
		return "", err
	}
	return hex.EncodeToString(h.Sum(nil)), nil
}
