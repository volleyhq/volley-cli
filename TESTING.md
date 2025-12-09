# Testing Volley CLI Locally

This guide explains how to test the Volley CLI against your local Hookstream server.

## Prerequisites

1. **Local Hookstream server running** on `http://localhost:8080`
2. **Go 1.21+** installed
3. **A test account** in your local Hookstream instance

## Setup

### 1. Build the CLI

```bash
cd volley-cli
make build
```

This will create `build/volley` (or `build/volley.exe` on Windows).

### 2. Add to PATH (optional)

```bash
# macOS/Linux
export PATH=$PATH:$(pwd)/build

# Or create a symlink
ln -s $(pwd)/build/volley /usr/local/bin/volley
```

Or just use the binary directly:
```bash
./build/volley --help
```

## Testing Steps

### 1. Test Authentication

First, make sure your local Hookstream server is running:

```bash
# In hookstream directory
go run cmd/server/main.go
```

Then test login:

```bash
# Point to local API
./build/volley --api-url http://localhost:8080 login
```

You'll be prompted for:
- Email: (your test user email)
- Password: (your test user password)

### 2. Check Authentication Status

```bash
./build/volley --api-url http://localhost:8080 status
```

This should show:
- Authentication Status: ✓ Authenticated
- Your email and user details
- Current organization (if you have one)

### 3. Create a Test Source

**Simplified Setup:** You only need to create a source - no connection required for localhost testing!

1. **Create an organization** (if you don't have one):
   - Use the console UI at `http://localhost:5173/console`
   - Or use curl:
   ```bash
   curl -X POST http://localhost:8080/api/org \
     -H "Authorization: Bearer YOUR_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"name": "Test Org"}'
   ```

2. **Create a project** (if you don't have one):
   ```bash
   curl -X POST http://localhost:8080/api/projects \
     -H "Authorization: Bearer YOUR_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"name": "Test Project"}'
   ```

3. **Create a source** (connection not required):
   ```bash
   curl -X POST http://localhost:8080/api/projects/1/sources \
     -H "Authorization: Bearer YOUR_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{
       "slug": "test-source",
       "eps": 10
     }'
   ```

   Note the `ingestion_id` from the response - you'll need it for the listen command.

   **That's it!** You can now use the CLI to forward events to localhost without creating a connection.

### 4. Set Up a Local Webhook Receiver

In a separate terminal, start a simple webhook receiver:

```bash
# Using Python
python3 -m http.server 3000

# Or using Node.js
npx http-server -p 3000

# Or create a simple Go server (see below)
```

Or create a simple test server (`test-server.go`):

```go
package main

import (
	"fmt"
	"io"
	"net/http"
)

func main() {
	http.HandleFunc("/webhook", func(w http.ResponseWriter, r *http.Request) {
		body, _ := io.ReadAll(r.Body)
		fmt.Printf("Received webhook:\n")
		fmt.Printf("Headers: %v\n", r.Header)
		fmt.Printf("Body: %s\n\n", body)
		w.WriteHeader(200)
		w.Write([]byte("OK"))
	})
	
	fmt.Println("Test webhook receiver listening on :3000")
	http.ListenAndServe(":3000", nil)
}
```

Run it:
```bash
go run test-server.go
```

### 5. Test the Listen Command

Now test webhook forwarding:

```bash
./build/volley --api-url http://localhost:8080 listen \
  --source YOUR_INGESTION_ID \
  --forward-to http://localhost:3000/webhook
```

Replace `YOUR_INGESTION_ID` with the ingestion ID from step 3.

### 6. Trigger a Test Webhook

In another terminal, send a test webhook to your source:

```bash
curl -X POST http://localhost:8080/hook/YOUR_INGESTION_ID \
  -H "Content-Type: application/json" \
  -d '{
    "event": "test",
    "data": {
      "message": "Hello from test webhook",
      "timestamp": "2024-12-04T15:00:00Z"
    }
  }'
```

You should see:
1. The webhook being received by Hookstream
2. The CLI detecting the new delivery attempt
3. The CLI forwarding it to your local receiver
4. Your test server printing the received webhook

## Debugging

### Enable Verbose Output

```bash
./build/volley --api-url http://localhost:8080 --verbose listen \
  --source YOUR_INGESTION_ID \
  --forward-to http://localhost:3000/webhook
```

### Check Configuration

The CLI stores config in:
- macOS/Linux: `~/.config/volley/config.json`
- Windows: `%APPDATA%\volley\config.json`

You can check/edit it directly:
```bash
cat ~/.config/volley/config.json
```

### Common Issues

1. **"not authenticated" error**:
   - Run `volley login` again
   - Make sure you're using the correct API URL

2. **"source not found" error**:
   - Check the ingestion ID is correct
   - Make sure the source exists in your local database

3. **"no connections found" error**:
   - This error no longer appears! The CLI now works without connections
   - If you see this, you may be using an older version - update to the latest
   - The CLI automatically uses direct event polling when no connections exist

4. **Webhooks not forwarding**:
   - Check your local receiver is running
   - Check the forward-to URL is correct
   - Enable verbose mode to see what's happening

## Running Tests

```bash
make test
```

## Quick Test Script

Create a `test-local.sh` script:

```bash
#!/bin/bash

API_URL="http://localhost:8080"
INGESTION_ID="$1"
FORWARD_TO="${2:-http://localhost:3000/webhook}"

if [ -z "$INGESTION_ID" ]; then
  echo "Usage: $0 <ingestion_id> [forward_to_url]"
  exit 1
fi

echo "Testing Volley CLI..."
echo "API URL: $API_URL"
echo "Source: $INGESTION_ID"
echo "Forward to: $FORWARD_TO"
echo ""

./build/volley --api-url "$API_URL" listen \
  --source "$INGESTION_ID" \
  --forward-to "$FORWARD_TO"
```

Make it executable:
```bash
chmod +x test-local.sh
```

Run it:
```bash
./test-local.sh YOUR_INGESTION_ID
```

