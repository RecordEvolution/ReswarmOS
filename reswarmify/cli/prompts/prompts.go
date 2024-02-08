package prompts

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"reswarmify-cli/utils"
	"strings"

	"github.com/cqroot/prompt"
	"github.com/cqroot/prompt/multichoose"
)

func Continue(message string) (bool, error) {
	if message == "" {
		message = "Continue?"
	}

	val, err := prompt.New().Ask(message).Choose([]string{"Yes", "No"})
	if err != nil {
		return false, err
	}

	if val == "Yes" {
		return true, nil
	}

	return false, nil
}

func SetupOptions(reswarmFile map[string]interface{}) ([]string, []int, error) {
	out, err := exec.Command("systemctl", "status", "NetworkManager").Output()
	if err != nil {
		return nil, nil, err
	}

	usingNetworkManager := strings.Contains(string(out), "Active: active")
	options := []string{
		"Automatically start the REAgent on boot and keep it running in the background",
		"Create a RecordEvolution user for your device",
	}
	defaultIndexes := []int{0, 1}

	wifissid := reswarmFile["wlanssid"]
	wifipasswd := reswarmFile["passwd"]
	noWifi := wifipasswd != nil && wifissid != nil

	if wifipasswd == nil && wifissid == nil {
		fmt.Println("WiFi SSID and Password were not provided. If this was not intentional, please provide the WiFi credentials in the .reswarm file")
		fmt.Println()
	}

	if usingNetworkManager && noWifi {
		options = append(options, "(NetworkManager Only) Add and connect to the WiFi connection provided in the .reswarm file")
		defaultIndexes = append(defaultIndexes, 2)
	}

	nvidiaRuntimeFound := true
	_, err = os.Stat("/usr/bin/nvidia-container-runtime")
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			nvidiaRuntimeFound = false
		} else {
			return nil, nil, err
		}
	}

	if nvidiaRuntimeFound {
		options = append(options, "Configure Docker to use Nvidia Runtime")
		if usingNetworkManager && noWifi {
			defaultIndexes = append(defaultIndexes, 3)
		} else {
			defaultIndexes = append(defaultIndexes, 2)
		}
	}

	services, err := prompt.New().Ask("Customize your Reswarmify process:").MultiChoose(options,
		multichoose.WithDefaultIndexes(0, defaultIndexes),
		multichoose.WithHelp(true),
	)

	var indexes []int
	for _, service := range services {
		indexes = append(indexes, utils.FindIndex(options, service))
	}

	if err != nil {
		return nil, nil, err
	}

	return options, indexes, nil
}
