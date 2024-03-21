package setup

import (
	"os"
	"os/exec"
	"reswarmify-cli/utils"
)

type SetupFunc func() error
type PostSetup func() error

func handleReagentSetup() error {
	_, err := exec.Command("systemctl", "enable", "reagent.service").Output()
	if err != nil {
		return err
	}

	_, err = exec.Command("systemctl", "enable", "reagent-manager.service").Output()
	if err != nil {
		return err
	}

	return nil
}

func handleReagentRemoval() error {
	_, err := exec.Command("/bin/bash", "/opt/reagent/reswarmify/scripts/remove-agent-services.sh").Output()
	if err != nil {
		return err
	}

	return nil
}

func handleREUserRemoval() error {
	_, err := exec.Command("/bin/bash", "/opt/reagent/reswarmify/scripts/reuser-removal.sh", "/opt/reagent/device-config.ini").Output()
	if err != nil {
		return err
	}

	return nil
}

func handleREUserSetup() error {
	_, err := exec.Command("/bin/bash", "/opt/reagent/reswarmify/scripts/reuser-setup.sh", "/opt/reagent/device-config.ini").Output()
	if err != nil {
		return err
	}

	return nil
}

func handleWifiSetup() error {
	_, err := exec.Command("/bin/bash", "/opt/reagent/reswarmify/scripts/rewifi.sh", "/opt/reagent/device-config.ini").Output()
	if err != nil {
		return err
	}

	return nil
}

func handleWifiRemoval() error {
	_, err := exec.Command("/bin/bash", "/opt/reagent/reswarmify/scripts/rewifi-removal.sh", "/opt/reagent/device-config.ini").Output()
	if err != nil {
		return err
	}

	return nil
}

func handleAgentRemoval() error {
	return os.RemoveAll("/opt/reagent")
}

func handleNvidiaSetup() error {
	return utils.Copy("/etc/docker/daemon-nvidia.json", "/etc/docker/daemon.json")
}

func handleNvidiaRemoval() error {
	// Don't need to remove it
	return nil
}

func HandleReswarmModeSetup() error {
	_, err := exec.Command("/bin/bash", "/opt/reagent/reswarmify/scripts/reswarm.sh").Output()
	if err != nil {
		return err
	}

	return nil
}

func EnableAndStartServices() error {
	_, err := exec.Command("/bin/bash", "/opt/reagent/reswarmify/scripts/enable-services.sh").Output()
	if err != nil {
		return err
	}

	return nil
}

func handlePostReagentSetup() error {
	_, err := exec.Command("systemctl", "start", "reagent.service").Output()
	if err != nil {
		return err
	}

	_, err = exec.Command("systemctl", "start", "reagent-manager.service").Output()
	if err != nil {
		return err
	}

	return nil
}

func Reboot() error {
	_, err := exec.Command("reboot", "now").Output()
	if err != nil {
		return err
	}

	return nil
}

var setupFunc = map[int]SetupFunc{
	0: handleReagentSetup,
	1: handleREUserSetup,
	2: handleWifiSetup,
	3: handleNvidiaSetup,
}

var removalFunc = map[int]SetupFunc{
	0: handleReagentRemoval,
	1: handleREUserRemoval,
	2: handleWifiRemoval,
	3: handleNvidiaRemoval,
	4: handleAgentRemoval,
}

var postSetupFunc = map[int]SetupFunc{
	0: handlePostReagentSetup,
}

func RemoveAll() error {
	for index := range removalFunc {
		err := HandleRemoval(index)
		if err != nil {
			return err
		}
	}

	return nil
}

func HandleRemoval(index int) error {
	return removalFunc[index]()
}

func HandleSetup(index int) error {
	return setupFunc[index]()
}

func HandlePostSetup(index int) error {
	fun := postSetupFunc[index]
	if fun != nil {
		return fun()
	}

	return nil
}
