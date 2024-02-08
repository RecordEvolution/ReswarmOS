package agent

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"reswarmify-cli/fs"
	"reswarmify-cli/release"
)

const AGENT_DIR = "/opt/reagent"
const AGENT_PATH = "/opt/reagent/reagent-latest"
const AGENT_CLOUD_URL = "https://storage.googleapis.com/re-agent/linux/%s/%s/reagent"

type VersionInfo struct {
	Production string `json:"production"`
	Test       string `json:"test"`
	Local      string `json:"local"`
	All        string `json:"all"`
}

func GetLatestVersionInfo() (VersionInfo, error) {
	url := "https://storage.googleapis.com/re-agent/availableVersions.json"

	response, err := http.Get(url)
	if err != nil {
		return VersionInfo{}, err
	}
	defer response.Body.Close()

	body, err := io.ReadAll(response.Body)
	if err != nil {
		return VersionInfo{}, err
	}

	var versionInfo VersionInfo
	err = json.Unmarshal(body, &versionInfo)
	if err != nil {
		return VersionInfo{}, err
	}

	return versionInfo, nil
}

func DownloadAgent() error {
	if err := os.MkdirAll(AGENT_DIR, os.ModePerm); err != nil {
		return err
	}

	latestVersionInfo, err := GetLatestVersionInfo()
	if err != nil {
		return err
	}

	architecture := release.GetBuildArch()
	if architecture == "" {
		panic("invalid state: architecture not set")
	}

	agentURL := fmt.Sprintf(AGENT_CLOUD_URL, architecture, latestVersionInfo.Production)

	return fs.DownloadFileWithProgress(agentURL, AGENT_PATH)
}
