package agent

import (
	"encoding/json"
	"fmt"
	"io"
	"ironflock-init/download"
	"ironflock-init/fs"
	"ironflock-init/release"
	"net/http"
	"os"
)

const AGENT_DIR = "/opt/reagent"
const AGENT_PATH = "/opt/reagent/reagent-latest"

// Agent artefacts relative to the download base (the IronFlock cloud or an
// appliance mirror — see package download for the layout); the first %s is the
// base. The paths match what the agent itself appends to update_url for OTA
// updates, so one base serves both the bootstrap and later self-updates.
const AGENT_URL_FMT = "%s/re-agent/linux/%s/%s/reagent"
const AGENT_VERSIONS_URL_FMT = "%s/re-agent/availableVersions.json"

type VersionInfo struct {
	Production string `json:"production"`
	Test       string `json:"test"`
	Local      string `json:"local"`
	All        string `json:"all"`
}

// GetLatestVersionInfo fetches the agent version channels from base.
func GetLatestVersionInfo(base string) (VersionInfo, error) {
	url := fmt.Sprintf(AGENT_VERSIONS_URL_FMT, base)

	response, err := http.Get(url)
	if err != nil {
		return VersionInfo{}, err
	}
	defer response.Body.Close()

	if response.StatusCode != http.StatusOK {
		return VersionInfo{}, fmt.Errorf("failed to fetch agent version info: %s returned status %s", url, response.Status)
	}

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

// DownloadAgent installs the production agent for this build's architecture
// from base into AGENT_PATH and verifies it against the .sha256 sidecar the
// mirror publishes next to it: a missing sidecar (older cloud releases) is a
// warning, a mismatch is an error and removes the file.
func DownloadAgent(base string) error {
	if err := os.MkdirAll(AGENT_DIR, os.ModePerm); err != nil {
		return err
	}

	latestVersionInfo, err := GetLatestVersionInfo(base)
	if err != nil {
		return err
	}

	architecture := release.GetBuildArch()
	if architecture == "" {
		panic("invalid state: architecture not set")
	}

	agentURL := fmt.Sprintf(AGENT_URL_FMT, base, architecture, latestVersionInfo.Production)

	if err := fs.DownloadFileWithProgress(agentURL, AGENT_PATH); err != nil {
		return err
	}

	return download.VerifySidecar(agentURL, AGENT_PATH)
}
