#!/bin/bash

# Load configuration
CONFIG_FILE=".page_config"
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "❌ Missing .page_config file. Please create it with API_URL, TOKEN, and AUTH."
    exit 1
fi
source "$CONFIG_FILE"

# Prompt user for input
read -p "📝 Title: " TITLE
read -p "📌 Tags: " TAGS

# Generate slug from title
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9 ]//g' | tr ' ' '-' | sed 's/-\+/-/g' | sed 's/^-//;s/-$//')

# Let user write content in Markdown using their default editor
TMP_FILE=$(mktemp /tmp/markdown_XXXX.md)
echo "# Replace with your content" > "$TMP_FILE"
${EDITOR:-nano} "$TMP_FILE"

# Read the content back from the temp file
CONTENT=$(<"$TMP_FILE")

# Clean up the temporary file
rm "$TMP_FILE"

# Build JSON payload
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

# Send POST request
echo "🚀 Sending POST request to $API_URL ..."
RESPONSE=$(curl -s -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d @payload.json)

# Output result
echo "📬 Response:"
echo "$RESPONSE"
