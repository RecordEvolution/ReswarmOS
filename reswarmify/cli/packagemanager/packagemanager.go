package packagemanager

import (
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"strings"
)

type PackageManager string

const (
	PACMAN PackageManager = "/usr/bin/pacman"
	DPKG   PackageManager = "/usr/bin/apt-get"
	YUM    PackageManager = "/usr/bin/yum"
	ZYPPER PackageManager = "/usr/bin/zypper"
)

func buildUpdateCommand() (string, []string, error) {
	pm, err := detectPackageManager()
	if err != nil {
		return "", []string{}, err
	}

	var updateParams []string
	switch pm {
	case PACMAN:
		updateParams = []string{"-Sy", "--noconfirm"}
	case DPKG:
		fallthrough
	case YUM:
		updateParams = []string{"update"}
	}

	return string(pm), updateParams, nil
}

func buildInstallCommand(packages []string) (string, []string, error) {
	pm, err := detectPackageManager()
	if err != nil {
		return "", []string{}, err
	}

	var installParams []string
	switch pm {
	case PACMAN:
		installParams = append(installParams, "-S", "--noconfirm")
	case DPKG:
		fallthrough
	case YUM:
		installParams = append(installParams, "install", "-y")
	}

	return string(pm), append(installParams, packages...), nil
}

func UpdatePackages() error {
	command, args, err := buildUpdateCommand()
	if err != nil {
		return err
	}

	cmd := exec.Command(command, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Start(); err != nil {
		return fmt.Errorf("command failed to run: %s", err.Error())
	}

	err = cmd.Wait()
	if err != nil {
		switch cmd.ProcessState.ExitCode() {
		case 100:
			return nil
		}
	}

	return err
}

func InstallPackage(packages []string) error {
	command, args, err := buildInstallCommand(packages)
	if err != nil {
		return err
	}

	cmd := exec.Command(command, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Start(); err != nil {
		return fmt.Errorf("command failed to run: %s", err.Error())
	}

	return cmd.Wait()

}

func detectPackageManager() (PackageManager, error) {
	issueFile, err := os.Open("/etc/issue")
	if err != nil {
		return "", err
	}

	defer issueFile.Close()

	issue, err := io.ReadAll(issueFile)
	if err != nil {
		return "", err
	}

	issueSplit := strings.Split(string(issue), " ")
	issuePart := issueSplit[0]

	switch issuePart {
	case "Arch":
		return PACMAN, nil
	case "Linux": // Linux Mint
		fallthrough
	case "Debian":
		fallthrough
	case "Ubuntu":
		return DPKG, nil
	case "CentOs":
		fallthrough
	case "Red": // Red Hat
		fallthrough
	case "Fedora":
		return YUM, nil
	case "SUSE":
		return ZYPPER, nil
	}

	return "", errors.New("unsupported package manager")
}
