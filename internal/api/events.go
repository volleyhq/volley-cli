package api

import (
	"fmt"
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

type PayloadsResponse struct {
	Payloads []Event `json:"payloads"`
}

func (c *Client) GetEvents(projectID uint64, limit int) ([]Event, error) {
	var resp PayloadsResponse
	path := fmt.Sprintf("/api/projects/%d/payloads?limit=%d", projectID, limit)
	if err := c.doJSONRequest("GET", path, nil, &resp); err != nil {
		return nil, err
	}
	return resp.Payloads, nil
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

