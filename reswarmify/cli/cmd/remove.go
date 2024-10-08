package cmd

import (
	"fmt"
	"ironflock-init/fs"
	"ironflock-init/setup"
	"ironflock-init/utils"
	"os"

	"github.com/spf13/cobra"
)

func init() {
	rootCmd.AddCommand(remove)
}

var remove = &cobra.Command{
	Use:   "remove",
	Short: "Removes the current IronFlock installation",
	Run:   removeCommand,
}

func removeCommand(cmd *cobra.Command, args []string) {

	if !utils.ReswarmifiedAlready() {
		fmt.Println("The system has not been initialized for IronFlock. Cannot remove existing installation")
		os.Exit(1)
		return
	}

	fmt.Println("Intializing removal process...")

	// Download the latest files in case the device is a legacy reswarmified device
	if utils.IsLegacyReswarmifiedDevice() {
		err := fs.ReswarmifyRootfs(false)
		if err != nil {
			fmt.Println("An error occurred while trying to overlay the rootfs: ", err.Error())
			os.Exit(1)
			return
		}
	}

	err := setup.Unreswarmify()
	if err != nil {
		fmt.Println("An error occurred while uninstalling the device: ", err.Error())
		os.Exit(1)
		return
	}

	fmt.Println("The device was successfully unreswarmified")
}
