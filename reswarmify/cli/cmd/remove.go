package cmd

import (
	"fmt"
	"ironflock-init/download"
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

	// Download the latest files in case the device is a legacy reswarmified device.
	// The base comes from --download-base / IRONFLOCK_DL_BASE, else the active
	// .flock's update_url (an appliance mirror), else the IronFlock cloud.
	if utils.IsLegacyReswarmifiedDevice() {
		base, err := download.ResolveDownloadBase(downloadBase, setup.DeviceConfigLink)
		if err != nil {
			fmt.Println(err.Error())
			os.Exit(1)
		}
		err = fs.ReswarmifyRootfs(base, false)
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
