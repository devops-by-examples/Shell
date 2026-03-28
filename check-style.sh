#!/bin/bash

# --- Configuration ---
# Define colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "--Running style checks on shell scripts...--"

# check if ShellCheck is installed / have ShellCheck installed
if ! command -v shellcheck &> /dev/null; then
    echo -e "${RED}Error: 'shellcheck' is not installed.${NC}"
    echo "Install it via: brew install shellcheck (macOS) or sudo apt install shellcheck (Linux)"
    exit 1
fi

# Find all .sh files and lint them - node modules and .git files not included
FILES=$(find . -name "*.sh" -not -path "*/node_modules/*" -not -path "*/.git/*")

if [ -z "$FILES" ]; then
    echo "No .sh files found to check."
    exit 0
fi

FAILED=0

for file in $FILES; do
    echo "Checking: $file"
    if shellcheck "$file"; then
        echo -e "${GREEN} $file looks good!${NC}"
    else
        echo -e "${RED} $file has style issues.${NC}"
        FAILED=1
    fi
done

if [ "$FAILED" -ne 0 ]; then
    echo -e "\n${RED} Style check failed. Please fix the issues above.${NC}"
    exit 1
else
    echo -e "\n${GREEN} All scripts passed the style check!${NC}"
    exit 0
fi