#!/usr/bin/env bash
set -euo pipefail

#############################################
# GitHub CLI Helper
# Author: Abhishek (Refactored)
# Version: v2 (Production Ready)
#############################################

SCRIPT_NAME="$(basename "$0")"
TMP_DIR="$(mktemp -d)"
BODY_FILE="$TMP_DIR/body.json"
HEADER_FILE="$TMP_DIR/headers.txt"

# --------------------------------------------
# Cleanup
# --------------------------------------------
cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

# --------------------------------------------
# Colors
# --------------------------------------------
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
RESET="\033[0m"

# --------------------------------------------
# Defaults
# --------------------------------------------
METHOD="GET"
OUTPUT_FILE=""
VERBOSE=false
SILENT=false
CUSTOM_HEADERS=()
DATA=""
TOKEN=""
ENDPOINT=""

# --------------------------------------------
# Logging
# --------------------------------------------
log_info() {
    $SILENT && return
    echo -e "${BLUE}[INFO]${RESET} $*"
}

log_warn() {
    $SILENT && return
    echo -e "${YELLOW}[WARN]${RESET} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${RESET} $*" >&2
}

log_verbose() {
    if $VERBOSE && ! $SILENT; then
        echo -e "${GREEN}[DEBUG]${RESET} $*"
    fi
}

# --------------------------------------------
# Dependency Check
# --------------------------------------------
check_dependencies() {
    for cmd in curl jq; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_error "Required dependency '$cmd' is not installed."
            exit 1
        fi
    done
}

# --------------------------------------------
# Usage
# --------------------------------------------
usage() {
cat <<EOF
GitHub CLI Helper

Usage:
  $SCRIPT_NAME [options] <endpoint>

Example:
  $SCRIPT_NAME /repos/octocat/hello-world/issues
  $SCRIPT_NAME -X POST -d '{"title":"Bug"}' /repos/org/repo/issues

Options:
  -t, --token TOKEN        GitHub token
  -X, --method METHOD      HTTP method (GET, POST, DELETE)
  -H, --header HEADER      Custom header
  -d, --data DATA          JSON payload
  -o, --output FILE        Save output to file
  -v, --verbose            Verbose logging
  -s, --silent             Silent mode
  -h, --help               Show this help

Environment:
  GITHUB_TOKEN             Preferred authentication method

EOF
}

# --------------------------------------------
# Token Loader
# --------------------------------------------
load_token() {

    if [[ -n "${TOKEN}" ]]; then
        return
    fi

    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        TOKEN="$GITHUB_TOKEN"
        return
    fi

    if [[ -f ".env" ]]; then
        TOKEN=$(grep GITHUB_TOKEN .env | cut -d '=' -f2)
    fi

    if [[ -z "$TOKEN" ]]; then
        read -rsp "GitHub Token: " TOKEN
        echo
    fi

    if [[ -z "$TOKEN" ]]; then
        log_error "GitHub token is required."
        exit 1
    fi
}

# --------------------------------------------
# Spinner
# --------------------------------------------
spinner() {
    local pid=$1
    local delay=0.1
    local spin='-\|/'

    while ps -p "$pid" > /dev/null 2>&1; do
        for i in $(seq 0 3); do
            printf "\rFetching... %s" "${spin:$i:1}"
            sleep $delay
        done
    done
    printf "\r"
}

# --------------------------------------------
# Rate Limit Check
# --------------------------------------------
check_rate_limit() {

    local remaining
    local limit

    remaining=$(grep -i '^x-ratelimit-remaining:' "$HEADER_FILE" | awk '{print $2}' | tr -d '\r')
    limit=$(grep -i '^x-ratelimit-limit:' "$HEADER_FILE" | awk '{print $2}' | tr -d '\r')

    if [[ -n "$remaining" && -n "$limit" ]]; then
        if (( remaining < 50 )); then
            log_warn "GitHub API rate limit low ($remaining/$limit remaining)"
        else
            log_verbose "Rate limit remaining: $remaining/$limit"
        fi
    fi
}

# --------------------------------------------
# Extract Next Page URL
# --------------------------------------------
get_next_link() {
    grep -i '^link:' "$HEADER_FILE" \
    | sed -E 's/Link: //I' \
    | tr ',' '\n' \
    | grep 'rel="next"' \
    | sed -E 's/.*<([^>]+)>.*/\1/'
}

# --------------------------------------------
# API Request
# --------------------------------------------
api_request() {

    local url="$1"

    log_verbose "Request: $METHOD $url"

    curl -sS \
        -X "$METHOD" \
        -D "$HEADER_FILE" \
        -o "$BODY_FILE" \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $TOKEN" \
        "${CUSTOM_HEADERS[@]}" \
        ${DATA:+-d "$DATA"} \
        "$url"
}

# --------------------------------------------
# Fetch All Pages
# --------------------------------------------
fetch_all_pages() {

    local url="https://api.github.com${ENDPOINT}"
    local pages=()

    while [[ -n "$url" ]]; do

        api_request "$url" &
        pid=$!

        if ! $SILENT; then
            spinner $pid
        fi

        wait $pid

        check_rate_limit

        pages+=("$BODY_FILE")

        url=$(get_next_link)

        if [[ -n "$url" ]]; then
            BODY_FILE="$TMP_DIR/body_$RANDOM.json"
        fi
    done

    jq -s 'flatten' "${pages[@]}"
}

# --------------------------------------------
# Argument Parsing
# --------------------------------------------
parse_args() {

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -X|--method)
                METHOD="$2"
                shift 2
                ;;
            -H|--header)
                CUSTOM_HEADERS+=(-H "$2")
                shift 2
                ;;
            -d|--data)
                DATA="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            -t|--token)
                TOKEN="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -s|--silent)
                SILENT=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                ENDPOINT="$1"
                shift
                ;;
        esac
    done

    if [[ -z "$ENDPOINT" ]]; then
        usage
        exit 1
    fi
}

# --------------------------------------------
# Output Handler
# --------------------------------------------
handle_output() {

    local result="$1"

    if [[ -n "$OUTPUT_FILE" ]]; then
        echo "$result" | jq '.' > "$OUTPUT_FILE"
        log_info "Saved output to $OUTPUT_FILE"
    else
        echo "$result" | jq '.'
    fi
}

# --------------------------------------------
# Main
# --------------------------------------------
main() {

    parse_args "$@"
    check_dependencies
    load_token

    log_info "Calling GitHub API: $ENDPOINT"

    result=$(fetch_all_pages)

    handle_output "$result"
}

main "$@"
