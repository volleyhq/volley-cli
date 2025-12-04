package api

type Project struct {
	ID   uint64 `json:"id"`
	Name string `json:"name"`
}

type ProjectsResponse struct {
	Projects []Project `json:"projects"`
}

func (c *Client) GetProjects() ([]Project, error) {
	var resp ProjectsResponse
	if err := c.doJSONRequest("GET", "/api/projects", nil, &resp); err != nil {
		return nil, err
	}
	return resp.Projects, nil
}

