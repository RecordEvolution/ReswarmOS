package cmd

import (
	"fmt"
	"os"
	"reswarmify-cli/setup"
	"reswarmify-cli/utils"

	"github.com/spf13/cobra"
)

func init() {
	rootCmd.AddCommand(remove)
}

var remove = &cobra.Command{
	Use:   "remove",
	Short: "Removes the current reswarmify installation",
	Run:   removeCommand,
}

func removeCommand(cmd *cobra.Command, args []string) {
	if !utils.ReswarmifiedAlready() {
		fmt.Println("The system has not been reswarmified. Cannot remove existing installation")
		os.Exit(1)
		return
	}

	err := setup.RemoveAll()
	if err != nil {
		fmt.Println("An error occurred while unreswarmifying the device: ", err.Error())
		os.Exit(1)
		return
	}
}
