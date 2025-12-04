package config

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
)

type Config struct {
	Token  string `json:"token"`
	Email  string `json:"email"`
	APIURL string `json:"api_url,omitempty"`
}

func Load() *Config {
	cfg := &Config{}
	configPath := getConfigPath()

	data, err := os.ReadFile(configPath)
	if err != nil {
		// Config file doesn't exist, return empty config
		return cfg
	}

	if err := json.Unmarshal(data, cfg); err != nil {
		// Invalid config, return empty config
		return cfg
	}

	return cfg
}

func (c *Config) Save() error {
	configPath := getConfigPath()
	configDir := filepath.Dir(configPath)

	// Create config directory if it doesn't exist
	if err := os.MkdirAll(configDir, 0755); err != nil {
		return fmt.Errorf("failed to create config directory: %w", err)
	}

	data, err := json.MarshalIndent(c, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal config: %w", err)
	}

	if err := os.WriteFile(configPath, data, 0600); err != nil {
		return fmt.Errorf("failed to write config file: %w", err)
	}

	return nil
}

func getConfigPath() string {
	home, err := os.UserHomeDir()
	if err != nil {
		return ".volley-config.json"
	}

	// Use XDG_CONFIG_HOME on Linux, or standard locations
	if configHome := os.Getenv("XDG_CONFIG_HOME"); configHome != "" {
		return filepath.Join(configHome, "volley", "config.json")
	}

	// Default locations
	switch os := os.Getenv("GOOS"); os {
	case "windows":
		return filepath.Join(home, "AppData", "Roaming", "volley", "config.json")
	case "darwin", "linux":
		return filepath.Join(home, ".config", "volley", "config.json")
	default:
		return filepath.Join(home, ".config", "volley", "config.json")
	}
}

