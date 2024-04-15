package cmd

import (
	"fmt"
	"reswarmify-cli/release"

	"github.com/spf13/cobra"
)

func init() {
	rootCmd.AddCommand(version)
}

var version = &cobra.Command{
	Use:   "version",
	Short: "Displays the current version of the Reswarmify binary",
	Run:   versionCommand,
}

func versionCommand(cmd *cobra.Command, args []string) {
	version := release.GetVersion()
	fmt.Println(version)
}
