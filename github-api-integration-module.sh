#!/bin/bash
################################
# Author: Abhishek (Improved)
# Version: v2
#
# This script communicates with the GitHub REST API
# Usage:
#   ./script.sh <GitHub Token> <REST endpoint>
# Example:
#   ./script.sh ghp_XXXXXX /repos/owner/repo/issues
################################

# ---------------- Input Validation ----------------
if [ $# -lt 2 ]; then
    echo "Usage: $0 [your GitHub token] [REST endpoint]"
    exit 1
fi

GITHUB_TOKEN=$1
GITHUB_API_REST=$2
GITHUB_API_HEADER_ACCEPT="Accept: application/vnd.github.v3+json"

# ---------------- Temporary File Setup ----------------
TMPFILE=$(mktemp /tmp/$(basename $0).XXXXXX) || exit 1
trap "rm -f $TMPFILE" EXIT  # Clean up temp file on exit

# ---------------- Function to Call REST API ----------------
rest_call() {
    curl -sf "$1" \
        -H "$GITHUB_API_HEADER_ACCEPT" \
        -H "Authorization: token $GITHUB_TOKEN" >> "$TMPFILE" || {
            echo "Error: API call failed -> $1"
            exit 1
        }
}

# ---------------- Pagination Handling ----------------
# Check if there is a Link header indicating multiple pages
last_page=$(curl -sI "https://api.github.com${GITHUB_API_REST}" \
    -H "$GITHUB_API_HEADER_ACCEPT" \
    -H "Authorization: token $GITHUB_TOKEN" \
    | grep -i '^Link:' \
    | grep -o 'page=[0-9]*>; rel="last"' \
    | grep -o '[0-9]*')

if [ -z "$last_page" ]; then
    # Single page result
    rest_call "https://api.github.com${GITHUB_API_REST}"
else
    # Multiple pages
    for p in $(seq 1 $last_page); do
        rest_call "https://api.github.com${GITHUB_API_REST}?page=$p"
    done
fi

# ---------------- Output ----------------
# Pretty print JSON if jq is installed
if command -v jq >/dev/null 2>&1; then
    cat "$TMPFILE" | jq .
else
    cat "$TMPFILE"
fi
