package setup

import (
	"os"
	"os/exec"
	"reswarmify-cli/utils"
)

type SetupFunc func() error
type PostSetup func() error

const ScriptDirectory = "/opt/reagent/reswarmify/scripts/"
const DeviceConfigPath = "/opt/reagent/device-config.ini"
const ReuserRemoval = "reuser-removal"
const ReuserSetup = "reuser-setup"
const ReWifi = "rewifi"
const ReWifiRemoval = "rewifi-removal"
const DisableServices = "disable-services"
const CleanupOverlay = "cleanup-overlay"
const Reswarm = "reswarm"

func runScript(scriptName string, passConfig bool) error {
	args := []string{ScriptDirectory + scriptName + ".sh"}
	if passConfig {
		args = append(args, DeviceConfigPath)
	}

	_, err := exec.Command("/bin/bash", args...).Output()
	if err != nil {
		return err
	}

	return nil
}

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

func handleREUserRemoval() error {
	return runScript(ReuserRemoval, true)
}

func handleREUserSetup() error {
	return runScript(ReuserSetup, true)
}

func handleWifiSetup() error {
	return runScript(ReWifi, true)
}

func handleWifiRemoval() error {
	return runScript(ReWifiRemoval, true)
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

func handleDisableServices() error {
	return runScript(DisableServices, false)
}

func handleOverlayCleanup() error {
	return runScript(CleanupOverlay, false)
}

func HandleReswarmModeSetup() error {
	return runScript(Reswarm, false)
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
	0: handleREUserRemoval,
	1: handleWifiRemoval,
	2: handleNvidiaRemoval,
	3: handleDisableServices,
	4: handleOverlayCleanup,
	5: handleAgentRemoval,
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
