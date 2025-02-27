package prompts

import (
	"errors"
	"fmt"
	"ironflock-init/setup"
	"ironflock-init/utils"
	"os"
	"os/exec"
	"strings"

	"github.com/cqroot/prompt"
	"github.com/cqroot/prompt/multichoose"
)

func Continue(message string, autoconfirm bool) (bool, error) {
	if autoconfirm {
		return true, nil
	}
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

func SetupOptions(reswarmFile map[string]interface{}, autoconfirm bool) ([]string, []int, error) {
	// Need to setup device.ini and other to do other setup
	_, err := setup.HandleReswarmModeSetup()
	if err != nil {
		fmt.Println("Failed to handle reswarm mode setup: ", err.Error())
		return nil, nil, err
	}

	usingNetworkManager := false
	out, err := exec.Command("systemctl", "status", "NetworkManager").Output()
	if err == nil {
		usingNetworkManager = strings.Contains(string(out), "Active: active")
	}

	allOptions := []string{
		"Automatically start the FlockAgent on boot and keep it running in the background",
		"Create an IronFlock user for your device",
		"(NetworkManager Only) Add and connect to the WiFi connection provided in the .flock file",
		"Configure Docker to use Nvidia Runtime",
	}

	options := []string{
		allOptions[0],
		allOptions[1],
	}

	defaultIndexes := []int{0, 1}

	wifissid := reswarmFile["wlanssid"]
	wifipasswd := reswarmFile["password"]

	noWifi := wifipasswd != nil && wifissid != nil

	if wifipasswd == nil && wifissid == nil {
		fmt.Println("WiFi SSID and Password were not provided. If this was not intentional, please provide the WiFi credentials in the .flock file")
		fmt.Println()
	}

	if usingNetworkManager && noWifi {
		options = append(options, allOptions[2])
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
		options = append(options, allOptions[3])
		if usingNetworkManager && noWifi {
			defaultIndexes = append(defaultIndexes, 3)
		} else {
			defaultIndexes = append(defaultIndexes, 2)
		}
	}

	if autoconfirm {
		return options, defaultIndexes, nil
	}

	services, err := prompt.New().Ask("Customize your IronFlock initialization process:").MultiChoose(options,
		multichoose.WithDefaultIndexes(0, defaultIndexes),
		multichoose.WithHelp(true),
	)

	var indexes []int
	for _, service := range services {
		indexes = append(indexes, utils.FindIndex(allOptions, service))
	}

	if err != nil {
		return nil, nil, err
	}

	return options, indexes, nil
}
