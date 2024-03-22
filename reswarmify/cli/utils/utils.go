package utils

import (
	"errors"
	"os"
	"os/exec"
)

func FindIndex(arr []string, str string) int {
	for i, v := range arr {
		if v == str {
			return i
		}
	}
	return -1
}

func ReswarmifiedAlready() bool {
	_, err := os.Stat("/opt/reagent/reswarm-mode")
	if err != nil && errors.Is(err, os.ErrNotExist) {
		return false
	}

	return true
}

func IsLegacyReswarmifiedDevice() bool {
	_, err := os.Stat("/opt/reagent/reswarmify")
	if err != nil && errors.Is(err, os.ErrNotExist) {
		return true
	}

	return false
}

func Copy(source string, dest string) error {
	_, err := exec.Command("cp", "-rf", source, dest).Output()
	if err != nil {
		return err
	}

	return nil
}

func Clear() error {
	cmd := exec.Command("clear")
	cmd.Stdout = os.Stdout
	err := cmd.Run()
	if err != nil {
		return err
	}

	return cmd.Wait()
}
