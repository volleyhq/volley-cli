package cmd

import (
	"fmt"
	"os/exec"
	"runtime"
	"time"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"github.com/volleyhq/volley-cli/internal/api"
	"github.com/volleyhq/volley-cli/internal/config"
)

var loginCmd = &cobra.Command{
	Use:   "login",
	Short: "Authenticate with Volley",
	Long: `Login to your Volley account using a pairing code flow.
The CLI will open your browser for authentication, and the token will be stored in your configuration file.`,
	RunE: runLogin,
}

var logoutCmd = &cobra.Command{
	Use:   "logout",
	Short: "Log out and clear credentials",
	Long:  `Log out from Volley and remove stored authentication token.`,
	RunE:  runLogout,
}

var statusCmd = &cobra.Command{
	Use:   "status",
	Short: "Check authentication status",
	Long:  `Check if you're authenticated and display your account information.`,
	RunE:  runStatus,
}

func init() {
	rootCmd.AddCommand(loginCmd)
	rootCmd.AddCommand(logoutCmd)
	rootCmd.AddCommand(statusCmd)
}

func runLogin(cmd *cobra.Command, args []string) error {
	apiClient := api.NewClient(viper.GetString("api_url"))

	// Start CLI authentication
	resp, err := apiClient.StartCLIAuth()
	if err != nil {
		return fmt.Errorf("failed to start authentication: %w", err)
	}

	fmt.Println("Your pairing code is:", resp.PairingCode)
	fmt.Println()
	fmt.Println("This pairing code verifies your authentication with Volley.")
	fmt.Println()
	fmt.Println("Opening browser automatically...")
	fmt.Printf("(If the browser doesn't open, visit: %s)\n", resp.AuthURL)
	fmt.Println("(^C to quit)")

	// Open browser automatically
	go func() {
		time.Sleep(500 * time.Millisecond)
		openBrowser(resp.AuthURL)
	}()

	// Start polling immediately (browser opens in background)
	fmt.Println()
	fmt.Println("Waiting for authentication...")
	
	ticker := time.NewTicker(2 * time.Second)
	defer ticker.Stop()
	timeout := time.After(10 * time.Minute)

	for {
		select {
		case <-timeout:
			return fmt.Errorf("authentication timeout - please try again")
		case <-ticker.C:
			pollResp, err := apiClient.PollCLIAuth(resp.DeviceCode)
			if err != nil {
				// Continue polling on error
				continue
			}

			if pollResp.Status == "complete" {
				// Save token to config
				cfg := config.Load()
				cfg.Token = pollResp.Token
				// Save API URL if provided via flag
				if apiURL := viper.GetString("api_url"); apiURL != "" {
					cfg.APIURL = apiURL
				}
				if err := cfg.Save(); err != nil {
					return fmt.Errorf("failed to save token: %w", err)
				}

				// Get user info to display
				apiClient.SetToken(pollResp.Token)
				user, err := apiClient.GetUser()
				if err == nil {
					fmt.Println("✓ Successfully logged in!")
					fmt.Printf("Welcome, %s!\n", user.Name)
				} else {
					fmt.Println("✓ Successfully logged in!")
				}
				return nil
			}
		}
	}
}

func openBrowser(url string) {
	var err error
	switch runtime.GOOS {
	case "linux":
		err = exec.Command("xdg-open", url).Start()
	case "windows":
		err = exec.Command("rundll32", "url.dll,FileProtocolHandler", url).Start()
	case "darwin":
		err = exec.Command("open", url).Start()
	default:
		err = fmt.Errorf("unsupported platform")
	}
	if err != nil {
		// Silently fail - user can open manually
	}
}

func runLogout(cmd *cobra.Command, args []string) error {
	cfg := config.Load()
	cfg.Token = ""
	cfg.Email = ""
	if err := cfg.Save(); err != nil {
		return fmt.Errorf("failed to clear credentials: %w", err)
	}

	fmt.Println("✓ Successfully logged out")
	return nil
}

func runStatus(cmd *cobra.Command, args []string) error {
	cfg := config.Load()
	if cfg.Token == "" {
		fmt.Println("Not authenticated. Run 'volley login' to authenticate.")
		return nil
	}

	apiClient := api.NewClient(viper.GetString("api_url"))
	apiClient.SetToken(cfg.Token)

	user, err := apiClient.GetUser()
	if err != nil {
		return fmt.Errorf("failed to get user info: %w", err)
	}

	fmt.Println("Authentication Status: ✓ Authenticated")
	fmt.Printf("Email: %s\n", user.Email)
	fmt.Printf("Name: %s\n", user.Name)
	fmt.Printf("User ID: %d\n", user.ID)

	// Try to get current organization
	org, err := apiClient.GetOrganization()
	if err == nil {
		fmt.Printf("\nCurrent Organization: %s (ID: %d)\n", org.Name, org.ID)
	}

	return nil
}

