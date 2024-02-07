package prompts

import (
	"os/exec"
	"reswarmify-cli/utils"
	"strings"

	"github.com/cqroot/prompt"
	"github.com/cqroot/prompt/multichoose"
)

func Continue() (bool, error) {
	val, err := prompt.New().Ask("Continue?").Choose([]string{"Yes", "No"})
	if err != nil {
		return false, err
	}

	if val == "Yes" {
		return true, nil
	}

	return false, nil
}

func SetupOptions() ([]string, []int, error) {
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

	if usingNetworkManager {
		options = append(options, "(NetworkManager Only) Add and connect to the WiFi connection provided in the .reswarm file")
		defaultIndexes = append(defaultIndexes, 2)
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
