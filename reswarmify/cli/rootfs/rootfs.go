package rootfs

import (
	"io"
	"net/http"
	"os"

	"github.com/schollz/progressbar/v3"
)

func Download() error {
	req, err := http.NewRequest("GET", "https://storage.googleapis.com/reswarmos/reswarmify/rootfs.tar.gz", nil)
	if err != nil {
		return err
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return err
	}

	defer resp.Body.Close()

	f, err := os.OpenFile("/tmp/rootfs.tar.gz", os.O_CREATE|os.O_WRONLY, 0644)
	defer f.Close()
	if err != nil {
		return err
	}

	bar := progressbar.DefaultBytes(
		resp.ContentLength,
		"downloading",
	)
	io.Copy(io.MultiWriter(f, bar), resp.Body)

	return nil

}
