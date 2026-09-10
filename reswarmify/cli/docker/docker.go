package docker

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"

	"github.com/docker/docker/client"
)

// Docker is installed from get.docker.com, which still needs the internet: the
// appliance download mirror carries only the IronFlock bootstrap artefacts, not
// distro packages. On an offline OT device Docker (and the apt packages
// ironflock-init installs) must be preinstalled — a running daemon skips this
// step entirely.
const GET_DOCKER = "https://get.docker.com"

type Docker struct {
	client *client.Client
}

func NewDocker() (Docker, error) {
	client, err := client.NewClientWithOpts(client.FromEnv, client.WithAPIVersionNegotiation())
	if err != nil {
		return Docker{}, err
	}

	return Docker{client: client}, nil
}

func (cli *Docker) Running() bool {
	ctx := context.Background()
	_, err := cli.client.Ping(ctx)
	return err == nil
}

func InstallDocker() error {
	req, err := http.NewRequest("GET", GET_DOCKER, nil)
	if err != nil {
		return err
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return err
	}

	defer resp.Body.Close()

	dockerScriptPath := fmt.Sprintf("%s/%s", os.TempDir(), "get-docker.sh")
	f, err := os.OpenFile(dockerScriptPath, os.O_CREATE|os.O_WRONLY, 0755)
	if err != nil {
		return err
	}

	defer f.Close()

	_, err = io.Copy(f, resp.Body)
	if err != nil {
		return err
	}

	cmd := exec.Command("/bin/bash", dockerScriptPath)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	err = cmd.Start()
	if err != nil {
		return err
	}

	return cmd.Wait()
}
