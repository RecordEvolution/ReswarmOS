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

func SetupOptions(reswarmFile map[string]interface{}, autoconfirm bool, disableSuspend bool) ([]string, []int, error) {
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
		"Prevent the host from auto-suspending (masks systemd sleep targets; recommended for always-on devices)",
	}

	var options []string
	var defaultDisplayIndexes []int // positions in options, preselected in the prompt
	var defaultSetupIndexes []int   // matching indexes into allOptions / the setup handlers
	addOption := func(setupIndex int, preselected bool) {
		options = append(options, allOptions[setupIndex])
		if preselected {
			defaultDisplayIndexes = append(defaultDisplayIndexes, len(options)-1)
			defaultSetupIndexes = append(defaultSetupIndexes, setupIndex)
		}
	}

	addOption(0, true)
	addOption(1, true)

	wifissid := reswarmFile["wlanssid"]
	wifipasswd := reswarmFile["password"]

	noWifi := wifipasswd != nil && wifissid != nil

	if wifipasswd == nil && wifissid == nil {
		fmt.Println("WiFi SSID and Password were not provided. If this was not intentional, please provide the WiFi credentials in the .flock file")
		fmt.Println()
	}

	if usingNetworkManager && noWifi {
		addOption(2, true)
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
		addOption(3, true)
	}

	// Opt-in: desktop hosts auto-suspend and drop offline every ~15 minutes.
	// Preselected only via --disable-suspend, which is also what enables it
	// under --autoconfirm.
	addOption(4, disableSuspend)

	if autoconfirm {
		return options, defaultSetupIndexes, nil
	}

	services, err := prompt.New().Ask("Customize your IronFlock initialization process:").MultiChoose(options,
		multichoose.WithDefaultIndexes(0, defaultDisplayIndexes),
		multichoose.WithHelp(true),
	)
	if err != nil {
		return nil, nil, err
	}

	var indexes []int
	for _, service := range services {
		indexes = append(indexes, utils.FindIndex(allOptions, service))
	}

	return options, indexes, nil
}
