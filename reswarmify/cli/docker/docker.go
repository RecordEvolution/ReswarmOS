package docker

import (
	"bufio"
	"context"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"

	"github.com/docker/docker/client"
)

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
	cmd.Stderr = cmd.Stdout

	cmdStdout, err := cmd.StdoutPipe()
	if err != nil {
		return err
	}

	go func() {
		scanner := bufio.NewScanner(cmdStdout)
		for scanner.Scan() {
			output := scanner.Text()
			fmt.Println(output)
		}
	}()

	err = cmd.Start()
	if err != nil {
		return err
	}

	return cmd.Wait()
}
