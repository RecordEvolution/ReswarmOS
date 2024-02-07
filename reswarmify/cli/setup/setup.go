package setup

import "os/exec"

type SetupFunc func() error
type PostSetup func() error

func handleReagentSetup() error {
	err := handleReswarmModeSetup()
	if err != nil {
		return err
	}

	_, err = exec.Command("systemctl", "enable", "reagent.service").Output()
	if err != nil {
		return err
	}

	_, err = exec.Command("systemctl", "enable", "reagent-manager.service").Output()
	if err != nil {
		return err
	}

	return nil
}

func handleREUserSetup() error {
	_, err := exec.Command("/bin/bash", "/usr/sbin/reuser-setup.sh", "/opt/reagent/device-config.ini").Output()
	if err != nil {
		return err
	}

	return nil
}

func handleWifiSetup() error {
	_, err := exec.Command("/bin/bash", "/usr/sbin/rewifi.sh", "/opt/reagent/device-config.ini").Output()
	if err != nil {
		return err
	}

	return nil
}

func handleReswarmModeSetup() error {
	_, err := exec.Command("/bin/bash", "/usr/sbin/reswarm.sh").Output()
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
}

var postSetupFunc = map[int]SetupFunc{
	0: handlePostReagentSetup,
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
