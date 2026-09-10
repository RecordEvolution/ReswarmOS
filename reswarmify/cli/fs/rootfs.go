package fs

import (
	"fmt"
	"io"
	"net/http"
	"os"

	"github.com/schollz/progressbar/v3"
)

const ROOTFS_TEMP_DIR = "/tmp/rootfs"
const AGENT_DIR = "/opt/reagent"
const ROOTFS_TEMP_TAR_GZ = "/tmp/rootfs.tar.gz"

// Rootfs overlay tarballs relative to the download base (the IronFlock cloud
// or an appliance mirror — see package download for the layout); the %s is
// the base. The query string is a cache-buster.
const ROOTFS_URL_FMT = "%s/reswarmify/rootfs.tar.gz?new=1"
const ROOTFS_DEV_URL_FMT = "%s/reswarmify/rootfs-dev.tar.gz?new=1"

func DownloadFile(URL string, resultPath string) error {
	req, err := http.NewRequest("GET", URL, nil)
	if err != nil {
		return err
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return err
	}

	defer resp.Body.Close()

	// Bail before touching the destination file: an error response (e.g. a 404
	// from the storage bucket) carries an HTML/XML body that must never be
	// written over the target as if it were the real download.
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("download failed: %s returned status %s", URL, resp.Status)
	}

	// O_TRUNC: a previous, longer download must not leave a stale tail behind
	// the new content — a checksum over the file would reject it.
	f, err := os.OpenFile(resultPath, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0755)
	if err != nil {
		return err
	}

	defer f.Close()

	_, err = io.Copy(f, resp.Body)
	if err != nil {
		return err
	}

	return nil
}

func DownloadFileWithProgress(URL string, resultPath string) error {
	req, err := http.NewRequest("GET", URL, nil)
	if err != nil {
		return err
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return err
	}

	defer resp.Body.Close()

	// Bail before creating the destination file: a 404 (or any non-200) when
	// fetching a new agent version returns an error body that must not be
	// written into the agent binary path. Cancel the download instead.
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("download failed: %s returned status %s", URL, resp.Status)
	}

	// O_TRUNC: see DownloadFile — the agent binary is verified against its
	// .sha256 sidecar right after this, so no stale tail may survive.
	f, err := os.OpenFile(resultPath, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0755)
	if err != nil {
		return err
	}

	defer f.Close()

	bar := progressbar.DefaultBytes(resp.ContentLength)

	_, err = io.Copy(io.MultiWriter(f, bar), resp.Body)

	return err
}
