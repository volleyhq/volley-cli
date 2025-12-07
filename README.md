# Volley CLI

> The official command-line interface for [Volley](https://volleyhooks.com) - Webhook forwarding for local development.

[![GitHub release](https://img.shields.io/github/release/volleyhq/volley-cli.svg)](https://github.com/volleyhq/volley-cli/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Go Version](https://img.shields.io/badge/Go-%3E%3D1.21-blue)](https://golang.org/)

Similar to Stripe CLI, Volley CLI allows you to forward webhooks from your Volley sources to your local development environment. Perfect for testing webhooks locally without exposing your development server or dealing with changing URLs.

## What is Volley?

[Volley](https://volleyhooks.com) is a reliable webhook middleware platform that accepts webhooks from any source and dispatches them to your endpoints with guaranteed delivery, rate limiting, and comprehensive monitoring. Perfect for testing webhooks locally, debugging webhook issues, and building production webhook infrastructure.

**Key Features:**
- ✅ **Persistent Webhook URLs** - URLs that never change (unlike ngrok)
- ✅ **No Tunneling Required** - Your local server stays private
- ✅ **Guaranteed Delivery** - Automatic retries with exponential backoff
- ✅ **Built-in Monitoring** - Track every webhook event with detailed metrics
- ✅ **Rate Limiting** - Configurable events per second (EPS) at source and destination levels
- ✅ **Production Ready** - Same endpoint works for development and production

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

1. **Sign up for Volley** (if you haven't already):
   - Visit [volleyhooks.com](https://volleyhooks.com) to create a free account
   - Create a webhook source in the dashboard to get your ingestion ID

2. **Login to your Volley account:**
   ```bash
   volley login
   ```

3. **Forward webhooks to your local server:**
   ```bash
   volley listen --source abc123xyz --forward-to http://localhost:3000/webhook
   ```

The CLI will poll for new webhook events and forward them to your local endpoint in real-time.

## Why Volley Instead of ngrok?

Volley is a better alternative to ngrok for webhook testing and development:

| Feature | Volley | ngrok |
|---------|--------|-------|
| **Webhook URLs** | Permanent, never change | Change on every restart |
| **Tunneling Required** | ❌ No tunneling needed | ✅ Requires persistent tunnel |
| **Local Server Privacy** | ✅ Completely private | ⚠️ Exposed through tunnel |
| **Built-in Retry** | ✅ Automatic retries | ❌ No retry mechanism |
| **Monitoring & Logging** | ✅ Comprehensive dashboard | ❌ Limited (paid plans) |
| **Rate Limiting** | ✅ Configurable EPS | ❌ Not available |
| **Production Ready** | ✅ Same URL for dev/prod | ❌ Dev tool only |
| **Offline Support** | ✅ Webhooks queued | ❌ Must be online |
| **Cost** | Free tier: 10K events/month | Free tier: Limited features |

### Key Advantages

1. **No Tunneling Required**
   - Volley doesn't require a persistent tunnel connection
   - Your local server stays completely private
   - No need to keep a process running

2. **Persistent URLs**
   - Your webhook URL never changes: `https://api.volleyhooks.com/hook/abc123xyz`
   - No need to update webhook URLs in external services
   - Same URL works in development and production

3. **Production Features**
   - Automatic retry with exponential backoff
   - Comprehensive monitoring and logging
   - Rate limiting and throttling
   - Event replay and debugging tools

4. **Better Developer Experience**
   - Webhooks are queued if your local server is offline
   - Built-in monitoring dashboard
   - CLI tool similar to Stripe CLI
   - No port forwarding configuration needed

**Learn more:** [Why Volley Instead of ngrok?](https://docs.volleyhooks.com/use-cases/ngrok-alternative)

## Comparison with Other Tools

### Volley vs webhook.site

| Feature | Volley | webhook.site |
|---------|--------|--------------|
| **Permanent URLs** | ✅ Yes | ❌ Temporary URLs |
| **Local Development** | ✅ CLI forwarding | ❌ Web interface only |
| **Monitoring** | ✅ Full dashboard | ⚠️ Basic view |
| **Retry Mechanism** | ✅ Automatic | ❌ Manual |
| **Production Use** | ✅ Yes | ❌ Testing only |
| **Rate Limiting** | ✅ Configurable | ❌ Not available |

### Volley vs RequestBin

| Feature | Volley | RequestBin |
|---------|--------|------------|
| **Permanent URLs** | ✅ Yes | ❌ Temporary bins |
| **Webhook Delivery** | ✅ Active delivery | ❌ Passive viewing |
| **Retry Logic** | ✅ Automatic | ❌ Not available |
| **Production Ready** | ✅ Yes | ❌ Testing only |
| **Monitoring** | ✅ Comprehensive | ⚠️ Basic logs |

**Use Cases:**
- **Testing Stripe webhooks locally** - [Guide](https://docs.volleyhooks.com/use-cases/stripe-webhook-localhost)
- **Debugging Twilio webhooks** - [Guide](https://docs.volleyhooks.com/use-cases/debug-twilio-webhooks)
- **Webhook fan-out** - Send one webhook to multiple destinations
- **Multi-tenant webhooks** - Manage webhooks for SaaS platforms
- **Event replay** - Replay historical webhooks for testing

**See all use cases:** [docs.volleyhooks.com](https://docs.volleyhooks.com)

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

### Testing Stripe Webhooks Locally

1. **Create a Stripe webhook source in Volley dashboard**
2. **Get your permanent webhook URL**: `https://api.volleyhooks.com/hook/abc123xyz`
3. **Add this URL to Stripe Dashboard** → Webhooks → Add endpoint
4. **Start forwarding to your local server:**
   ```bash
   volley listen --source abc123xyz --forward-to http://localhost:3000/webhook
   ```
5. **Trigger test events in Stripe** - They'll be forwarded to your local server instantly!

**Full guide:** [Testing Stripe Webhooks Locally](https://docs.volleyhooks.com/use-cases/stripe-webhook-localhost)

### Testing with Multiple Destinations

You can forward the same webhook source to multiple local endpoints by running multiple CLI instances:

```bash
# Terminal 1: Forward to main API
volley listen --source abc123xyz --forward-to http://localhost:3000/webhook

# Terminal 2: Forward to webhook processor
volley listen --source abc123xyz --forward-to http://localhost:3001/process

# Terminal 3: Forward to logging service
volley listen --source abc123xyz --forward-to http://localhost:3002/log
```

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

## Resources

- **Website**: [volleyhooks.com](https://volleyhooks.com)
- **Documentation**: [docs.volleyhooks.com](https://docs.volleyhooks.com)
- **Dashboard**: [app.volleyhooks.com](https://app.volleyhooks.com)
- **Support**: [app.volleyhooks.com/console/help](https://app.volleyhooks.com/console/help)

## Related Projects

- [Volley Platform](https://volleyhooks.com) - The webhook middleware platform
- [Volley Documentation](https://docs.volleyhooks.com) - Complete guides and API reference

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - See [LICENSE](LICENSE) file for details

---

**Built with ❤️ by the Volley team**

[![GitHub stars](https://img.shields.io/github/stars/volleyhq/volley-cli?style=social)](https://github.com/volleyhq/volley-cli)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
