package api

import (
	"fmt"
)

type Connection struct {
	ID              uint64 `json:"id"`
	Name            string `json:"name"`
	SourceID        uint64 `json:"source_id"`
	SourceSlug      string `json:"source_slug"`
	DestinationID   uint64 `json:"destination_id"`
	DestinationURL  string `json:"destination_url"`
	Status          string `json:"status"`
	SourceEPS       int    `json:"source_eps"`
	DestinationEPS  int    `json:"destination_eps"`
}

type ConnectionsResponse struct {
	Connections []Connection `json:"connections"`
}

func (c *Client) GetConnections(projectID uint64) ([]Connection, error) {
	var resp ConnectionsResponse
	path := fmt.Sprintf("/api/projects/%d/connections", projectID)
	if err := c.doJSONRequest("GET", path, nil, &resp); err != nil {
		return nil, err
	}
	return resp.Connections, nil
}

func (c *Client) GetConnection(connectionID uint64) (*Connection, error) {
	var connection Connection
	path := fmt.Sprintf("/api/connections/%d", connectionID)
	if err := c.doJSONRequest("GET", path, nil, &connection); err != nil {
		return nil, err
	}
	return &connection, nil
}

// GetConnectionsBySource finds connections for a source by searching all projects
func (c *Client) GetConnectionsBySource(sourceID uint64) ([]Connection, error) {
	projects, err := c.GetProjects()
	if err != nil {
		return nil, fmt.Errorf("failed to get projects: %w", err)
	}

	var allConnections []Connection
	for _, project := range projects {
		connections, err := c.GetConnections(project.ID)
		if err != nil {
			continue
		}
		for _, conn := range connections {
			if conn.SourceID == sourceID {
				allConnections = append(allConnections, conn)
			}
		}
	}

	return allConnections, nil
}

type DeliveryAttempt struct {
	EventID      string  `json:"event_id"`
	Status       string  `json:"status"`
	ResponseCode int     `json:"response_code"`
	ErrorReason  string  `json:"error_reason"`
	DurationMs   int     `json:"duration_ms"`
	EntryTime    *string `json:"entry_time"`
	ExitTime     *string `json:"exit_time"`
	CreatedAt    string  `json:"created_at"`
}

// GetDeliveryAttempts gets recent delivery attempts for a connection
func (c *Client) GetDeliveryAttempts(connectionID uint64, limit int) ([]DeliveryAttempt, error) {
	type Response struct {
		Attempts []DeliveryAttempt `json:"attempts"`
	}
	var resp Response
	path := fmt.Sprintf("/api/connections/%d/attempts", connectionID)
	if err := c.doJSONRequest("GET", path, nil, &resp); err != nil {
		return nil, err
	}
	
	// Limit results if needed
	if limit > 0 && len(resp.Attempts) > limit {
		return resp.Attempts[:limit], nil
	}
	return resp.Attempts, nil
}

