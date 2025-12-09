package api

import (
	"fmt"
)

type User struct {
	ID    uint64 `json:"id"`
	Email string `json:"email"`
	Name  string `json:"name"`
}

type Organization struct {
	ID   uint64 `json:"id"`
	Name string `json:"name"`
	Slug string `json:"slug"`
}

type CLIAuthStartResponse struct {
	PairingCode string `json:"pairing_code"`
	DeviceCode  string `json:"device_code"`
	AuthURL     string `json:"auth_url"`
	ExpiresIn   int    `json:"expires_in"`
}

type CLIAuthPollResponse struct {
	Status string `json:"status"`
	Token  string `json:"token,omitempty"`
	Error  string `json:"error,omitempty"`
}

type GetUserResponse struct {
	User User `json:"user"`
}

func (c *Client) GetUser() (*User, error) {
	var resp GetUserResponse
	if err := c.doJSONRequest("GET", "/api/user", nil, &resp); err != nil {
		return nil, err
	}
	return &resp.User, nil
}

func (c *Client) GetOrganization() (*Organization, error) {
	var org Organization
	if err := c.doJSONRequest("GET", "/api/org", nil, &org); err != nil {
		return nil, fmt.Errorf("no active organization. Please create or switch to an organization first")
	}
	return &org, nil
}

func (c *Client) StartCLIAuth() (*CLIAuthStartResponse, error) {
	var resp CLIAuthStartResponse
	if err := c.doJSONRequest("POST", "/api/auth/cli/start", nil, &resp); err != nil {
		return nil, err
	}
	return &resp, nil
}

func (c *Client) PollCLIAuth(deviceCode string) (*CLIAuthPollResponse, error) {
	var resp CLIAuthPollResponse
	path := fmt.Sprintf("/api/auth/cli/poll?device_code=%s", deviceCode)
	if err := c.doJSONRequest("GET", path, nil, &resp); err != nil {
		return nil, err
	}
	return &resp, nil
}

