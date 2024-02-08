package utils

import (
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
