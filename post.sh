#!/bin/bash
set -euo pipefail

# Load secure configuration
CONFIG_FILE=".page_config"
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "❌ Missing .page_config file. Please create it with API_URL, TOKEN, and AUTH."
    exit 1
fi
source "$CONFIG_FILE"

# --- Parse command-line arguments ---
TITLE=""
TAGS=""
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

# --- Validate input ---
if [[ -z "$TITLE" || -z "$TAGS" ]]; then
    echo "❌ Error: Both --title and --tags are required."
    exit 1
fi

# --- Sanitize title into slug ---
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9 ]//g' | tr ' ' '-' | sed 's/-\+/-/g' | sed 's/^-//;s/-$//')

# --- Secure temp file for markdown input ---
TMP_FILE=$(mktemp "/tmp/markdown_XXXXXX.md")
trap 'shred -u "$TMP_FILE" 2>/dev/null' EXIT

echo "# Write your Markdown content below" > "$TMP_FILE"
${EDITOR:-nano} "$TMP_FILE"

# --- Read Markdown content ---
CONTENT=$(<"$TMP_FILE")

# --- Secure JSON construction (no temp payload file) ---
JSON=$(jq -n \
    --arg token "$TOKEN" \
    --arg auth "$AUTH" \
    --arg title "$TITLE" \
    --arg content "$CONTENT" \
    --arg slug "$SLUG" \
    --arg tags "$TAGS" \
    '{
      token: $token,
      authentication: $auth,
      title: $title,
      content: $content,
      slug: $slug,
      tags: $tags
    }')

# --- Send POST request ---
echo "🚀 Posting securely to $API_URL ..."
RESPONSE=$(curl -s -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d "$JSON")

# --- Show response ---
echo "📬 Response:"
echo "$RESPONSE"
