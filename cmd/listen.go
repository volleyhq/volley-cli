package cmd

import (
	"bytes"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"github.com/volleyhq/volley-cli/internal/api"
	"github.com/volleyhq/volley-cli/internal/config"
)

var (
	forwardURL string
	sourceID   string
)

var listenCmd = &cobra.Command{
	Use:   "listen",
	Short: "Forward webhooks to a local endpoint",
	Long: `Listen for webhooks from a source and forward them to a local endpoint.
This is useful for local development and testing.

The CLI will poll for new webhook events and forward them to your local server.

Example:
  volley listen --source abc123xyz --forward-to http://localhost:3000/webhook`,
	RunE: runListen,
}

func init() {
	listenCmd.Flags().StringVarP(&forwardURL, "forward-to", "f", "", "URL to forward webhooks to (required)")
	listenCmd.Flags().StringVarP(&sourceID, "source", "s", "", "Source ingestion ID (required)")
	listenCmd.MarkFlagRequired("forward-to")
	listenCmd.MarkFlagRequired("source")

	rootCmd.AddCommand(listenCmd)
}

func runListen(cmd *cobra.Command, args []string) error {
	cfg := config.Load()
	if cfg.Token == "" {
		return fmt.Errorf("not authenticated. Run 'volley login' first")
	}

	// Use API URL from flag, config, or default
	apiURL := viper.GetString("api_url")
	if apiURL == "" && cfg.APIURL != "" {
		apiURL = cfg.APIURL
	}
	if apiURL == "" {
		apiURL = viper.GetString("api_url") // Will use default from root.go
	}

	apiClient := api.NewClient(apiURL)
	apiClient.SetToken(cfg.Token)

	// Get source details to find source ID and project ID
	sourceWithProject, err := apiClient.GetSourceByIngestionIDWithProject(sourceID)
	if err != nil {
		return fmt.Errorf("failed to get source: %w", err)
	}
	source := sourceWithProject.Source
	projectID := sourceWithProject.ProjectID

	// Get connections for this source to find which connection to monitor
	connections, err := apiClient.GetConnectionsBySource(source.ID)
	if err != nil {
		return fmt.Errorf("failed to get connections: %w", err)
	}

	if len(connections) == 0 {
		return fmt.Errorf("no connections found for source '%s'. Please create a connection first", sourceID)
	}

	// Use the first enabled connection, or create a temporary one
	connectionID := connections[0].ID

	fmt.Printf("Ready! Forwarding webhooks from source '%s' to %s\n", sourceID, forwardURL)
	fmt.Printf("Source: %s (ID: %d)\n", source.Slug, source.ID)
	fmt.Printf("Connection: %s (ID: %d)\n", connections[0].Name, connectionID)
	fmt.Println("Press Ctrl+C to stop\n")

	// Handle graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)

	// Record when we started listening - only forward events created after this
	startTime := time.Now()
	// Track forwarded event IDs to avoid duplicates
	forwardedEventIDs := make(map[string]bool)
	pollInterval := 2 * time.Second

	// Poll for new delivery attempts
	ticker := time.NewTicker(pollInterval)
	defer ticker.Stop()

	for {
		select {
		case <-sigChan:
			fmt.Println("\n✓ Shutting down...")
			return nil
		case <-ticker.C:
			// Get recent delivery attempts for this connection
			attempts, err := apiClient.GetDeliveryAttempts(connectionID, 20)
			if err != nil {
				if viper.GetBool("verbose") {
					fmt.Fprintf(os.Stderr, "Warning: failed to get delivery attempts: %v\n", err)
				}
				continue
			}

			// Filter attempts: only process those created after we started and haven't forwarded yet
			for i := len(attempts) - 1; i >= 0; i-- {
				attempt := attempts[i]

				// Skip if we've already processed this event
				if forwardedEventIDs[attempt.EventID] {
					continue
				}

				// Check if this attempt is new (created after we started)
				if attempt.CreatedAt == "" {
					// No timestamp - skip it to be safe
					forwardedEventIDs[attempt.EventID] = true
					continue
				}

				createdAt, err := time.Parse(time.RFC3339, attempt.CreatedAt)
				if err != nil {
					// Can't parse timestamp - skip it
					forwardedEventIDs[attempt.EventID] = true
					if viper.GetBool("verbose") {
						fmt.Fprintf(os.Stderr, "Warning: failed to parse timestamp for event %s: %v\n", attempt.EventID, err)
					}
					continue
				}

				// Skip old events (created before we started listening)
				if !createdAt.After(startTime) {
					forwardedEventIDs[attempt.EventID] = true
					continue
				}

				// Mark as processed immediately to avoid duplicates
				forwardedEventIDs[attempt.EventID] = true

				// Query event directly by event_id with retries
				// New events might take a moment to be indexed
				var event *api.Event
				maxRetries := 5
				for retry := 0; retry < maxRetries; retry++ {
					event, err = apiClient.GetEvent(attempt.EventID, projectID)
					if err == nil {
						break
					}
					// If event not found, wait longer and retry (might not be indexed yet)
					if retry < maxRetries-1 {
						// Exponential backoff: 1s, 2s, 3s, 4s
						delay := time.Duration(retry+1) * time.Second
						time.Sleep(delay)
					}
				}
				
				if err != nil {
					if viper.GetBool("verbose") {
						fmt.Fprintf(os.Stderr, "Warning: failed to get event %s after %d retries: %v\n", attempt.EventID, maxRetries, err)
					}
					continue
				}

				// Forward to local endpoint
				if err := forwardEvent(event, forwardURL); err != nil {
					fmt.Fprintf(os.Stderr, "✗ Failed to forward event %s: %v\n", attempt.EventID, err)
				} else {
					fmt.Printf("✓ Forwarded event %s -> %s\n", attempt.EventID, forwardURL)
				}
			}
		}
	}
}

func forwardEvent(event *api.Event, targetURL string) error {
	client := &http.Client{Timeout: 10 * time.Second}

	// Forward raw body as-is to preserve exact bytes (important for signature verification)
	// Re-encoding JSON would change the exact bytes and break webhook signatures
	body := []byte(event.RawBody)

	req, err := http.NewRequest("POST", targetURL, bytes.NewReader(body))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	// Forward original headers first (preserves signature headers like Paddle-Signature)
	if event.Headers != nil {
		for key, values := range event.Headers {
			for _, value := range values {
				req.Header.Add(key, value)
			}
		}
	}

	// Set/override headers (only if not already set from original headers)
	if req.Header.Get("Content-Type") == "" {
		req.Header.Set("Content-Type", "application/json")
	}
	if req.Header.Get("User-Agent") == "" {
		req.Header.Set("User-Agent", "Volley-CLI/1.0")
	}
	
	// Add Volley-specific headers for tracking
	req.Header.Set("X-Volley-Event-ID", event.EventID)
	req.Header.Set("X-Volley-Source-ID", strconv.FormatUint(event.SourceID, 10))
	req.Header.Set("X-Volley-Source-Slug", event.SourceSlug)

	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 400 {
		return fmt.Errorf("local endpoint returned %d", resp.StatusCode)
	}

	return nil
}

