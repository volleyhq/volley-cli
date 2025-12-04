# Volley CLI

The official command-line interface for Volley - Webhook forwarding for local development.

Similar to Stripe CLI, Volley CLI allows you to forward webhooks from your Volley sources to your local development environment.

## Installation

### macOS (Homebrew)

```bash
brew tap volleyhq/volley
brew install volley
```

Or install directly:

```bash
brew install volleyhq/volley/volley
```

### Linux

Download the latest release from [GitHub Releases](https://github.com/volleyhq/volley-cli/releases) and extract:

```bash
# For amd64
wget https://github.com/volleyhq/volley-cli/releases/latest/download/volley-linux-amd64.tar.gz
tar -xzf volley-linux-amd64.tar.gz
sudo mv volley /usr/local/bin/

# For arm64
wget https://github.com/volleyhq/volley-cli/releases/latest/download/volley-linux-arm64.tar.gz
tar -xzf volley-linux-arm64.tar.gz
sudo mv volley /usr/local/bin/
```

### Windows

Download the latest release from [GitHub Releases](https://github.com/volleyhq/volley-cli/releases) and extract:

```powershell
# Download and extract
Invoke-WebRequest -Uri "https://github.com/volleyhq/volley-cli/releases/latest/download/volley-windows-amd64.zip" -OutFile "volley.zip"
Expand-Archive -Path volley.zip -DestinationPath .
# Add to PATH or move to a directory in your PATH
```

## Quick Start

1. **Login to your Volley account:**
   ```bash
   volley login
   ```

2. **Forward webhooks to your local server:**
   ```bash
   volley listen --source abc123xyz --forward-to http://localhost:3000/webhook
   ```

The CLI will poll for new webhook events and forward them to your local endpoint in real-time.

## Commands

### Authentication

- `volley login` - Authenticate with your Volley account
- `volley logout` - Log out and clear credentials
- `volley status` - Check authentication status

### Webhook Forwarding

- `volley listen --source <ingestion_id> --forward-to <url>` - Forward webhooks to a local endpoint

## Examples

### Forward webhooks to local development server

```bash
volley listen --source abc123xyz --forward-to http://localhost:3000/webhook
```

This will:
1. Connect to your Volley account
2. Monitor the source with ingestion ID `abc123xyz`
3. Poll for new webhook events
4. Forward them to `http://localhost:3000/webhook` in real-time

## How It Works

The CLI:
1. Authenticates with your Volley account
2. Finds the source by ingestion ID
3. Gets the connections for that source
4. Polls the API for new delivery attempts
5. Retrieves the full event payload
6. Forwards it to your local endpoint with original headers

## Configuration

The CLI stores configuration in:
- **macOS/Linux**: `~/.config/volley/config.json`
- **Windows**: `%APPDATA%\volley\config.json`

You can override the API endpoint:

```bash
volley --api-url https://api.volleyhooks.com listen --source abc123xyz --forward-to http://localhost:3000/webhook
```

## Development

```bash
# Build
make build

# Run tests
make test

# Install locally
make install

# Cross-platform builds
make release
```

## License

MIT License - See [LICENSE](LICENSE) file for details
