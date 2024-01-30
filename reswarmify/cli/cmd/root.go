/*
Copyright © 2024 NAME HERE <EMAIL ADDRESS>
*/
package cmd

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"os/signal"
	"reswarmify-cli/packagemanager"

	"github.com/spf13/cobra"
)

// rootCmd represents the base command when called without any subcommands
var rootCmd = &cobra.Command{
	Use:   "reswarmify-cli",
	Short: "CLI tool to help reswarmify your device",
	Long:  ``,
	Run: func(cmd *cobra.Command, args []string) {
		root(cmd, args)
	},
}

var reswarmFilePath string

// Execute adds all child commands to the root command and sets flags appropriately.
// This is called by main.main(). It only needs to happen once to the rootCmd.
func Execute() {

	err := rootCmd.Execute()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

func init() {
	rootCmd.Flags().StringVarP(&reswarmFilePath, "config", "c", "", "Path to .reswarm config file")
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

	reswarmFile, err := os.Open(configPath)
	if err != nil {
		fmt.Println("Failed to open Reswarm file: " + err.Error())
		os.Exit(1)
		return
	}

	defer reswarmFile.Close()

	reswarmFiles, err := io.ReadAll(reswarmFile)
	if err != nil {
		fmt.Println("Failed to open Reswarm file: " + err.Error())
		os.Exit(1)
		return
	}

	var result map[string]interface{}
	if json.Unmarshal(reswarmFiles, &result) != nil {
		fmt.Println("The configuration file is invalid")
		os.Exit(1)
		return
	}

	fmt.Printf("Intialising Reswarmify process with config file: %s\n", reswarmFilePath)

	// _, err = prompt.New().Ask("Choose:").AdvancedChoose([]choose.Choice{
	// 	{Text: "Item 1", Note: "The note for item 1"},
	// 	{Text: "Another item", Note: "The note for item 2"},
	// 	{Text: "Item 3", Note: "The note for item 3"},
	// })

	packagemanager.InstallPackage([]string{"jq"})

	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt)

	<-sigChan
}
