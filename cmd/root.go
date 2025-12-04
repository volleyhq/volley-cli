package cmd

import (
	"fmt"
	"os"
	"strings"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"github.com/volleyhq/volley-cli/internal/config"
)

var (
	cfgFile     string
	apiURL      string
	apiKey      string
	verbose     bool
	version     = "dev"
	commit      = "unknown"
	buildDate   = "unknown"
)

// rootCmd represents the base command when called without any subcommands
var rootCmd = &cobra.Command{
	Use:   "volley",
	Short: "Volley CLI - Webhook as a Service",
	Long: `Volley CLI is the official command-line interface for Volley,
a reliable webhook middleware platform.

Use volley to forward webhooks to your local development environment,
trigger test events, manage sources and connections, and more.`,
	Version: fmt.Sprintf("%s (commit: %s, built: %s)", version, commit, buildDate),
}

// Execute adds all child commands to the root command and sets flags appropriately.
func Execute() error {
	return rootCmd.Execute()
}

func init() {
	cobra.OnInitialize(initConfig)

	// Global flags
	rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (default is $HOME/.config/volley/config.json)")
	rootCmd.PersistentFlags().StringVar(&apiURL, "api-url", "", "API endpoint URL (overrides config file)")
	rootCmd.PersistentFlags().StringVar(&apiKey, "api-key", "", "API key for authentication (overrides config file)")
	rootCmd.PersistentFlags().BoolVarP(&verbose, "verbose", "v", false, "verbose output")

	// Bind flags to viper
	viper.BindPFlag("api_url", rootCmd.PersistentFlags().Lookup("api-url"))
	viper.BindPFlag("api_key", rootCmd.PersistentFlags().Lookup("api-key"))
	viper.BindPFlag("verbose", rootCmd.PersistentFlags().Lookup("verbose"))
}

// initConfig reads in config file and ENV variables if set.
func initConfig() {
	if cfgFile != "" {
		// Use config file from the flag.
		viper.SetConfigFile(cfgFile)
	} else {
		// Search config in home directory with name ".volley" (without extension).
		configDir := getConfigDir()
		viper.AddConfigPath(configDir)
		viper.SetConfigType("json")
		viper.SetConfigName("config")
	}

	viper.SetEnvPrefix("VOLLEY")
	viper.AutomaticEnv() // read in environment variables that match

	// Set defaults FIRST (before reading config)
	viper.SetDefault("api_url", "https://api.volleyhooks.com")
	viper.SetDefault("api_key", "")

	// If a config file is found, read it in.
	if err := viper.ReadInConfig(); err == nil {
		if verbose {
			fmt.Fprintf(os.Stderr, "Using config file: %s\n", viper.ConfigFileUsed())
		}
		// After reading config, check if api_url from config is localhost
		// If so, reset it to the production default
		configAPIURL := viper.GetString("api_url")
		if strings.Contains(configAPIURL, "localhost") || strings.Contains(configAPIURL, "127.0.0.1") {
			// Ignore localhost from config - use production default
			viper.Set("api_url", "https://api.volleyhooks.com")
		}
	}

	// Load API URL from config if not provided via flag
	// But only use config if it's not localhost (for production use)
	cfg := config.Load()
	if apiURL == "" && cfg.APIURL != "" {
		// Only use config API URL if it's not localhost (production use)
		// If user wants localhost, they should use --api-url flag explicitly
		if !strings.Contains(cfg.APIURL, "localhost") && !strings.Contains(cfg.APIURL, "127.0.0.1") {
			viper.Set("api_url", cfg.APIURL)
		}
	}
	
	// Override with command-line flags (highest priority)
	if apiURL != "" {
		viper.Set("api_url", apiURL)
	}
	if apiKey != "" {
		viper.Set("api_key", apiKey)
	}
}

// getConfigDir returns the configuration directory based on OS
func getConfigDir() string {
	home, err := os.UserHomeDir()
	if err != nil {
		return "."
	}

	// Use XDG_CONFIG_HOME on Linux, or standard locations
	if configHome := os.Getenv("XDG_CONFIG_HOME"); configHome != "" {
		return configHome + "/volley"
	}

	// Default locations
	switch os := os.Getenv("GOOS"); os {
	case "windows":
		return home + "\\AppData\\Roaming\\volley"
	case "darwin", "linux":
		return home + "/.config/volley"
	default:
		return home + "/.config/volley"
	}
}

