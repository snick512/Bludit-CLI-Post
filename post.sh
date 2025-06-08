#!/bin/bash

# Load configuration
CONFIG_FILE=".page_config"
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "❌ Missing .page_config file. Please create it with API_URL, TOKEN, and AUTH."
    exit 1
fi
source "$CONFIG_FILE"

# --- Parse arguments ---
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --title)
            TITLE="$2"
            shift 2
            ;;
        --tags)
            TAGS="$2"
            shift 2
            ;;
        *)
            echo "❌ Unknown option: $1"
            echo "Usage: $0 --title \"My Title\" --tags \"tag1,tag2\""
            exit 1
            ;;
    esac
done

# Validate required args
if [[ -z "$TITLE" ]]; then
    echo "❌ Missing --title"
    exit 1
fi
if [[ -z "$TAGS" ]]; then
    echo "❌ Missing --tags"
    exit 1
fi

# Generate slug from title
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9 ]//g' | tr ' ' '-' | sed 's/-\+/-/g' | sed 's/^-//;s/-$//')

# Open Markdown editor
TMP_FILE=$(mktemp /tmp/markdown_XXXX.md)
echo "# Write your Markdown content below" > "$TMP_FILE"
${EDITOR:-nano} "$TMP_FILE"

# Read content
CONTENT=$(<"$TMP_FILE")
rm "$TMP_FILE"

# Build JSON
cat > payload.json <<EOF
{
  "token": "$TOKEN",
  "authentication": "$AUTH",
  "title": "$TITLE",
  "content": $(jq -Rs <<< "$CONTENT"),
  "slug": "$SLUG",
  "tags": "$TAGS"
}
EOF

# Send request
echo "🚀 Posting to $API_URL ..."
RESPONSE=$(curl -s -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d @payload.json)

# Show response
echo "📬 Response:"
echo "$RESPONSE"
