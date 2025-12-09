package api

import (
	"fmt"
	"net/url"
	"time"
)

type Event struct {
	EventID    string                `json:"event_id"`
	SourceID   uint64                `json:"source_id"`
	SourceSlug string                `json:"source_slug"`
	RawBody    string                `json:"raw_body"`
	Headers    map[string][]string   `json:"headers,omitempty"`
	CreatedAt  time.Time             `json:"created_at"`
	EntryTime  *time.Time            `json:"entry_time"`
	ExitTime   *time.Time            `json:"exit_time"`
}

type TriggerResponse struct {
	Status  string `json:"status"`
	EventID string `json:"event_id"`
}

func (c *Client) TriggerWebhook(sourceID string, payload map[string]interface{}) (*TriggerResponse, error) {
	var resp TriggerResponse
	path := fmt.Sprintf("/hook/%s", sourceID)
	if err := c.doJSONRequest("POST", path, payload, &resp); err != nil {
		return nil, err
	}
	return &resp, nil
}

// PayloadResponseItem matches the API response format for payloads
type PayloadResponseItem struct {
	ID             uint64                 `json:"id"`
	EventID        string                 `json:"event_id"`
	SourceID       uint64                 `json:"source_id"`
	SourceSlug     string                 `json:"source_slug"`
	ConnectionID   *uint64                `json:"connection_id"`
	DestinationID  *uint64                `json:"destination_id"`
	RawBody        string                 `json:"raw_body"`
	Headers        map[string]interface{} `json:"headers"` // API returns as map[string]interface{}
	Remarks        *string                `json:"remarks"`
	CreatedAt      time.Time              `json:"created_at"`
}

type PayloadsResponse struct {
	Payloads []PayloadResponseItem `json:"payloads"`
}

// convertPayloadToEvent converts API response format to Event struct
// CRITICAL: This function must preserve headers and raw body EXACTLY as received
// to maintain webhook signature validation (e.g., Paddle-Signature, Stripe signatures, etc.)
func convertPayloadToEvent(payload PayloadResponseItem) Event {
	// Convert headers from map[string]interface{} to map[string][]string
	// Header names and values must be preserved EXACTLY (case-sensitive, exact strings)
	// This matches the pattern used in GetEvent() to ensure consistency
	headers := make(map[string][]string)
	if payload.Headers != nil {
		for k, v := range payload.Headers {
			// Preserve header name exactly (map key preserves case in Go)
			switch val := v.(type) {
			case string:
				// Single header value - preserve exactly
				headers[k] = []string{val}
			case []interface{}:
				// Multiple header values - convert each to string, preserving exact values
				strs := make([]string, 0, len(val))
				for _, item := range val {
					if str, ok := item.(string); ok {
						strs = append(strs, str) // Preserve exact string value
					} else {
						// Fallback: convert non-string to string (shouldn't happen for headers, but be safe)
						strs = append(strs, fmt.Sprintf("%v", item))
					}
				}
				headers[k] = strs
			case []string:
				// Already in correct format - use directly
				headers[k] = val
			default:
				// Fallback for any other type - convert to string
				headers[k] = []string{fmt.Sprintf("%v", val)}
			}
		}
	}

	return Event{
		EventID:    payload.EventID,
		SourceID:    payload.SourceID,
		SourceSlug:  payload.SourceSlug,
		RawBody:    payload.RawBody, // CRITICAL: Preserve raw body exactly (byte-for-byte) for signature validation
		Headers:    headers,         // CRITICAL: Preserve headers exactly for signature validation
		CreatedAt:  payload.CreatedAt,
	}
}

func (c *Client) GetEvents(projectID uint64, limit int) ([]Event, error) {
	var resp PayloadsResponse
	path := fmt.Sprintf("/api/projects/%d/payloads?limit=%d", projectID, limit)
	if err := c.doJSONRequest("GET", path, nil, &resp); err != nil {
		return nil, err
	}
	
	// Convert response items to Event structs
	events := make([]Event, len(resp.Payloads))
	for i, payload := range resp.Payloads {
		events[i] = convertPayloadToEvent(payload)
	}
	return events, nil
}

// GetEventsBySource gets events for a specific source with optional time filtering
// This is more efficient than GetEvents + filtering client-side
func (c *Client) GetEventsBySource(projectID uint64, sourceID uint64, limit int, startTime *time.Time) ([]Event, error) {
	var resp PayloadsResponse
	
	// Build query parameters with proper URL encoding
	params := url.Values{}
	params.Set("source_id", fmt.Sprintf("%d", sourceID))
	params.Set("limit", fmt.Sprintf("%d", limit))
	if startTime != nil {
		params.Set("start_time", startTime.Format(time.RFC3339))
	}
	
	path := fmt.Sprintf("/api/projects/%d/payloads?%s", projectID, params.Encode())
	
	if err := c.doJSONRequest("GET", path, nil, &resp); err != nil {
		return nil, err
	}
	
	// Convert response items to Event structs
	events := make([]Event, len(resp.Payloads))
	for i, payload := range resp.Payloads {
		events[i] = convertPayloadToEvent(payload)
	}
	return events, nil
}

func (c *Client) GetEvent(eventID string, projectID uint64) (*Event, error) {
	// Use the requests endpoint with search parameter to find by event_id
	// Search uses LIKE with wildcards, so we need to find exact match
	type RequestsResponse struct {
		Requests []struct {
			ID          uint64                   `json:"id"`
			EventID     string                   `json:"event_id"`
			SourceID    uint64                   `json:"source_id"`
			SourceSlug  string                   `json:"source_slug"`
			RawBody     string                   `json:"raw_body"`
			Headers     map[string]interface{}    `json:"headers"`
			CreatedAt   string                   `json:"created_at"`
		} `json:"requests"`
	}

	var resp RequestsResponse
	// URL encode the event_id for the search parameter
	path := fmt.Sprintf("/api/projects/%d/requests?search=%s&limit=50", projectID, eventID)
	if err := c.doJSONRequest("GET", path, nil, &resp); err != nil {
		return nil, fmt.Errorf("failed to search for event: %w", err)
	}

	// Find the exact match (search might return partial matches)
	for _, req := range resp.Requests {
		if req.EventID == eventID {
			// Convert headers format
			headers := make(map[string][]string)
			if req.Headers != nil {
				for k, v := range req.Headers {
					switch val := v.(type) {
					case string:
						headers[k] = []string{val}
					case []interface{}:
						strs := make([]string, 0, len(val))
						for _, item := range val {
							if str, ok := item.(string); ok {
								strs = append(strs, str)
							}
						}
						headers[k] = strs
					case []string:
						headers[k] = val
					}
				}
			}

			// Parse created_at
			createdAt, _ := time.Parse(time.RFC3339, req.CreatedAt)

			return &Event{
				EventID:    req.EventID,
				SourceID:   req.SourceID,
				SourceSlug: req.SourceSlug,
				RawBody:    req.RawBody,
				Headers:    headers,
				CreatedAt:  createdAt,
			}, nil
		}
	}

	return nil, fmt.Errorf("event '%s' not found", eventID)
}

func (c *Client) ReplayEvent(sourceID uint64, eventID string) error {
	path := fmt.Sprintf("/api/projects/%d/replay-event", sourceID)
	body := map[string]string{"event_id": eventID}
	return c.doJSONRequest("POST", path, body, nil)
}

