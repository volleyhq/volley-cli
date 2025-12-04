package api

import (
	"fmt"
)

type Source struct {
	ID          uint64 `json:"id"`
	Slug        string `json:"slug"`
	IngestionID string `json:"ingestion_id"`
	EPS         int    `json:"eps"`
	Status      string `json:"status"`
}

type SourcesResponse struct {
	Sources []Source `json:"sources"`
}

func (c *Client) GetSources(projectID uint64) ([]Source, error) {
	var resp SourcesResponse
	path := fmt.Sprintf("/api/projects/%d/sources", projectID)
	if err := c.doJSONRequest("GET", path, nil, &resp); err != nil {
		return nil, err
	}
	return resp.Sources, nil
}

func (c *Client) GetSource(sourceID uint64) (*Source, error) {
	var source Source
	path := fmt.Sprintf("/api/sources/%d", sourceID)
	if err := c.doJSONRequest("GET", path, nil, &source); err != nil {
		return nil, err
	}
	return &source, nil
}

type SourceWithProject struct {
	Source    *Source
	ProjectID uint64
}

// GetSourceByIngestionID finds a source by searching all projects
// This is a helper that searches through projects to find the source
func (c *Client) GetSourceByIngestionID(ingestionID string) (*Source, error) {
	sourceWithProject, err := c.GetSourceByIngestionIDWithProject(ingestionID)
	if err != nil {
		return nil, err
	}
	return sourceWithProject.Source, nil
}

// GetSourceByIngestionIDWithProject finds a source and returns it with the project ID
func (c *Client) GetSourceByIngestionIDWithProject(ingestionID string) (*SourceWithProject, error) {
	// Get all projects first
	projects, err := c.GetProjects()
	if err != nil {
		return nil, fmt.Errorf("failed to get projects: %w", err)
	}

	// Search through all projects for the source
	for _, project := range projects {
		sources, err := c.GetSources(project.ID)
		if err != nil {
			continue
		}
		for _, source := range sources {
			if source.IngestionID == ingestionID {
				return &SourceWithProject{
					Source:    &source,
					ProjectID: project.ID,
				}, nil
			}
		}
	}

	return nil, fmt.Errorf("source with ingestion_id '%s' not found", ingestionID)
}

