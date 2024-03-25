package setup

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"reswarmify-cli/utils"
	"sort"
)

type SetupFunc func() (chan string, error)
type PostSetup func() (chan string, error)

const ScriptDirectory = "/opt/reagent/reswarmify/scripts/"
const DeviceConfigPath = "/opt/reagent/device-config.ini"
const ReuserRemoval = "reuser-removal"
const ReuserSetup = "reuser-setup"
const ReWifi = "rewifi"
const ReWifiRemoval = "rewifi-removal"
const DisableServices = "disable-services"
const CleanupOverlay = "cleanup-overlay"
const Reswarm = "reswarm"

func runScript(scriptName string, passConfig bool) (chan string, error) {
	args := []string{ScriptDirectory + scriptName + ".sh"}
	if passConfig {
		args = append(args, DeviceConfigPath)
	}

	cmd := exec.Command("/bin/bash", args...)
	cmdReader, err := cmd.StdoutPipe()
	if err != nil {
		return nil, err
	}

	cmd.Stderr = cmd.Stdout

	logChan := make(chan string)
	scanner := bufio.NewScanner(cmdReader)
	go func() {
		for scanner.Scan() {
			chunk := scanner.Text()
			logChan <- chunk
		}

		close(logChan)
	}()

	err = cmd.Start()
	if err != nil {
		return nil, err
	}

	return logChan, nil
}

func handleReagentSetup() (chan string, error) {
	_, err := exec.Command("systemctl", "enable", "reagent.service").Output()
	if err != nil {
		return nil, err
	}

	_, err = exec.Command("systemctl", "enable", "reagent-manager.service").Output()
	if err != nil {
		return nil, err
	}

	return nil, nil
}

func stopDockerDaemon() (chan string, error) {
	_, err := exec.Command("systemctl", "stop", "docker.service").Output()
	if err != nil {
		return nil, err
	}

	_, err = exec.Command("systemctl", "stop", "docker.socket").Output()
	if err != nil {
		return nil, err
	}

	return nil, nil
}

func startDockerDaemon() (chan string, error) {
	_, err := exec.Command("systemctl", "start", "docker.service").Output()
	if err != nil {
		return nil, err
	}

	_, err = exec.Command("systemctl", "start", "docker.socket").Output()
	if err != nil {
		return nil, err
	}

	return nil, nil
}

func handleREUserRemoval() (chan string, error) {
	logChan, err := runScript(ReuserRemoval, true)
	if err != nil {
		return nil, err
	}

	go func() {
		for log := range logChan {
			fmt.Println(log)
		}
	}()

	return logChan, nil
}

func handleREUserSetup() (chan string, error) {
	return runScript(ReuserSetup, true)
}

func handleWifiSetup() (chan string, error) {
	return runScript(ReWifi, true)
}

func handleWifiRemoval() (chan string, error) {
	logChan, err := runScript(ReWifiRemoval, true)
	if err != nil {
		return nil, err
	}

	go func() {
		for log := range logChan {
			fmt.Println(log)
		}
	}()

	return logChan, nil
}

func handleAgentRemoval() (chan string, error) {
	fmt.Println("Removing REAgent directory..")

	err := os.RemoveAll("/opt/reagent")
	if err != nil {
		return nil, err
	}

	fmt.Println("REAgent files have been removed")

	return nil, nil
}

func handleNvidiaSetup() (chan string, error) {
	return nil, utils.Copy("/etc/docker/daemon-nvidia.json", "/etc/docker/daemon.json")
}

func handleNvidiaRemoval() (chan string, error) {
	// Don't need to remove it
	return nil, nil
}

func handleDisableServices() (chan string, error) {
	logChan, err := runScript(DisableServices, false)
	if err != nil {
		return nil, err
	}

	go func() {
		for log := range logChan {
			fmt.Println(log)
		}
	}()

	return logChan, nil
}

func handleOverlayCleanup() (chan string, error) {
	logChan, err := runScript(CleanupOverlay, false)
	if err != nil {
		return nil, err
	}

	go func() {
		for log := range logChan {
			fmt.Println(log)
		}
	}()

	return logChan, nil
}

func HandleReswarmModeSetup() (chan string, error) {
	return runScript(Reswarm, false)
}

func handlePostReagentSetup() (chan string, error) {
	_, err := exec.Command("systemctl", "start", "reagent.service").Output()
	if err != nil {
		return nil, err
	}

	_, err = exec.Command("systemctl", "start", "reagent-manager.service").Output()
	if err != nil {
		return nil, err
	}

	return nil, nil
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
	5: stopDockerDaemon,
	6: handleAgentRemoval,
	7: startDockerDaemon,
}

var postSetupFunc = map[int]SetupFunc{
	0: handlePostReagentSetup,
}

func Unreswarmify() error {
	var indexes []int
	for k := range removalFunc {
		indexes = append(indexes, k)
	}

	sort.Ints(indexes)

	for _, index := range indexes {
		err := HandleRemoval(index)
		if err != nil {
			return err
		}
	}

	return nil
}

func HandleRemoval(index int) error {
	_, err := removalFunc[index]()
	return err
}

func HandleSetup(index int) error {
	_, err := setupFunc[index]()
	return err
}

func HandlePostSetup(index int) error {
	fun := postSetupFunc[index]
	if fun != nil {
		_, err := fun()
		return err
	}

	return nil
}
