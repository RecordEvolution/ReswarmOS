package fs

import (
	"io"
	"net/http"
	"os"

	"github.com/schollz/progressbar/v3"
)

const ROOTFS_TEMP_DIR = "/tmp/rootfs"
const AGENT_DIR = "/opt/reagent"
const ROOTFS_TEMP_TAR_GZ = "/tmp/rootfs.tar.gz"
const ROOTFS_REMOTE_URL = "https://storage.googleapis.com/reswarmos/reswarmify/rootfs.tar.gz?new=1"

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

	f, err := os.OpenFile(resultPath, os.O_CREATE|os.O_WRONLY, 0755)
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

	f, err := os.OpenFile(resultPath, os.O_CREATE|os.O_WRONLY, 0755)
	if err != nil {
		return err
	}

	defer f.Close()

	bar := progressbar.DefaultBytes(resp.ContentLength)

	_, err = io.Copy(io.MultiWriter(f, bar), resp.Body)

	return err
}
