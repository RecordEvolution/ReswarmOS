/*
Copyright © 2024 NAME HERE <EMAIL ADDRESS>
*/
package cmd

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"ironflock-init/agent"
	"ironflock-init/docker"
	"ironflock-init/fs"
	"ironflock-init/packagemanager"
	"ironflock-init/prompts"
	"ironflock-init/setup"
	"ironflock-init/utils"
	"os"

	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:   "ironflock-init",
	Short: "CLI tool to initialize your IronFlock device",
	Long:  ``,
	Run: func(cmd *cobra.Command, args []string) {
		root(cmd, args)
	},
}

var reswarmFilePath string

func Execute() {
	err := rootCmd.Execute()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

func init() {
	rootCmd.Flags().StringVarP(&reswarmFilePath, "config", "c", "", "Path to .flock config file")
	rootCmd.MarkFlagRequired("config")
}

func root(cmd *cobra.Command, args []string) {
	configPath := cmd.Flag("config").Value.String()
	_, err := os.Stat(configPath)
	if err != nil && errors.Is(err, os.ErrNotExist) {
		fmt.Println("The file whose path you provided does not exist")
		os.Exit(1)
		return
	}

	reswarmFileObj, err := os.Open(configPath)
	if err != nil {
		fmt.Println("Failed to open .flock file: " + err.Error())
		os.Exit(1)
		return
	}

	defer reswarmFileObj.Close()

	reswarmFileByte, err := io.ReadAll(reswarmFileObj)
	if err != nil {
		fmt.Println("Failed to open .flock file: " + err.Error())
		os.Exit(1)
		return
	}

	var reswarmFile map[string]interface{}
	if json.Unmarshal(reswarmFileByte, &reswarmFile) != nil {
		fmt.Println("The configuration file is invalid")
		os.Exit(1)
		return
	}

	if utils.ReswarmifiedAlready() {
		fmt.Println("The system has already been initialized. Please remove your previous IronFlock installation and try again")
		os.Exit(1)
		return
	}

	fmt.Printf("Starting IronFlock initialization process with config file: %s\n", reswarmFilePath)
	fmt.Println()

	utils.Copy(configPath, "/boot")

	packages := []string{
		"jq",
		"ca-certificates",
		"curl",
		"gnupg",
		"lsb-release",
		"net-tools",
		"iproute2",
		"dnsutils",
		"network-manager",
		"openssh-server",
	}

	fmt.Println("The IronFlock initialization will install the following packages: ")
	fmt.Println(packages)
	fmt.Println()

	cont, err := prompts.Continue("")
	if err != nil {
		fmt.Println("Failed to prompt user: ", err.Error())
		os.Exit(1)
		return
	}

	if !cont {
		fmt.Println("The above mentioned packages are required in order to initialize your system")
		os.Exit(1)
		return
	}

	err = packagemanager.UpdatePackages()
	if err != nil {
		fmt.Println("Failed to update packages: ", err.Error())
		os.Exit(1)
		return
	}

	err = packagemanager.InstallPackage(packages)
	if err != nil {
		fmt.Println("Failed to install packages: ", err.Error())
		os.Exit(1)
		return
	}

	utils.Clear()

	fmt.Println("The packages were successfully installed.")

	fmt.Println()

	dockerInstalled := true
	dockerClient, err := docker.NewDocker()
	if err != nil {
		dockerInstalled = false
	} else {
		if !dockerClient.Running() {
			dockerInstalled = false
		}
	}

	if !dockerInstalled {
		fmt.Println("Docker was not found on this system")
		fmt.Println("In order for you to access the IronFlock Platform you'll need to have Docker installed")

		cont, err := prompts.Continue("")
		if err != nil {
			fmt.Println("Failed to prompt user: ", err.Error())
			os.Exit(1)
			return
		}

		if !cont {
			fmt.Println("Sorry, but Docker is required")
			os.Exit(1)
			return
		}

		fmt.Println("Installing Docker, please note that this can take some time...")
		fmt.Println()

		err = docker.InstallDocker()
		if err != nil {
			fmt.Println("Failed to install Docker: ", err.Error())
			os.Exit(1)
			return
		}

		utils.Clear()

		fmt.Println("Docker successfully installed")

	} else {
		// fmt.Println("Found a working Docker installation, skipping installation step...")
	}

	err = fs.ReswarmifyRootfs(false)
	if err != nil {
		fmt.Println("Failed to overlay Rootfs: ", err.Error())
		os.Exit(1)
		return
	}

	fmt.Println("The FlockAgent will now be installed")
	fmt.Println("With the FlockAgent, your device gains access to the IronFlock platform. This allows you to remotely manage your device and apps.")

	cont, err = prompts.Continue("Install the FlockAgent?")
	if err != nil {
		fmt.Println("Failed to prompt user: ", err.Error())
		os.Exit(1)
		return
	}

	if !cont {
		fmt.Println("The FlockAgent is required!")
		os.Exit(1)
		return
	}

	err = agent.DownloadAgent()
	if err != nil {
		fmt.Println("Failed to download the FlockAgent: ", err.Error())
		os.Exit(1)
		return
	}

	utils.Clear()

	fmt.Println("The FlockAgent was successfully installed!")

	fmt.Println()

	fmt.Println("IronFlock initialization process will set up the necessary configuration and services to ensure your experience with the IronFlock platform is flawless")
	fmt.Println("You can customize what IronFlock initialization process will do exactly. However, in most cases, the default settings will suffice for your needs")
	fmt.Println()

	_, indexes, err := prompts.SetupOptions(reswarmFile)
	if err != nil {
		os.Exit(1)
		return
	}

	// Setup
	for _, index := range indexes {
		err := setup.HandleSetup(index)
		if err != nil {
			fmt.Println("Failed to run setup: ", err.Error())

			os.Exit(1)
			return
		}
	}

	utils.Clear()

	fmt.Println("The IronFlock initialization process is complete.")
	fmt.Println()

	cont, err = prompts.Continue("Reboot now?")
	if err != nil {
		fmt.Println("Failed to prompt user: ", err.Error())
	}

	if cont {
		err := setup.Reboot()
		if err != nil {
			fmt.Println("Failed to trigger reboot: ", err.Error())

			os.Exit(1)
			return
		}
	}

	os.Exit(0)
}
