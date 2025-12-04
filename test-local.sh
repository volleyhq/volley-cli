#!/bin/bash

# Quick test script for local development
# Usage: ./test-local.sh <ingestion_id> [forward_to_url]

API_URL="${VOLLEY_API_URL:-http://localhost:8080}"
INGESTION_ID="$1"
FORWARD_TO="${2:-http://localhost:3000/webhook}"

if [ -z "$INGESTION_ID" ]; then
  echo "Usage: $0 <ingestion_id> [forward_to_url]"
  echo ""
  echo "Example:"
  echo "  $0 abc123xyz"
  echo "  $0 abc123xyz http://localhost:3000/webhook"
  echo ""
  echo "Set VOLLEY_API_URL environment variable to override API URL"
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

