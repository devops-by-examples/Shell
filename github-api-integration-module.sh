
################################
# Author: Abhishek
# Version: v1
# Description: Script to communicate with GitHub API
# Dependencies: curl, GitHub token
# Usage: ./script.sh [token] [API endpoint]
################################

if [ ${#@} -lt 2 ]; then
    echo "usage: $0 [your github token] [REST expression]"
    exit 1;
fi

GITHUB_TOKEN=$1
GITHUB_API_REST=$2

GITHUB_API_HEADER_ACCEPT="Accept: application/vnd.github.v3+json"

TMPFILE=`mktemp /tmp/github.XXXXXX` || exit 1 
trap "rm -f $TMPFILE" EXIT



# Check GitHub API rate limit befre starting
echo "Checking API rate limit..." >&2
RATE_REMAINING=$(curl -s -H "${GITHUB_API_HEADER_ACCEPT}" -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/rate_limit" | grep -o '"remaining":[0-9]*' | head -1 | cut -d':' -f2)

if [ "$RATE_REMAINING" -lt 10 ]; then
    echo "WARNING: Only $RATE_REMAINING API calls remaining" >&2
    echo "Continue? (y/n): " >&2
    read -n 1 -r ANSWER
    echo
    if [[ ! $ANSWER =~ [Yy] ]]; then
        echo "Exiting..." >&2
        exit 1
    fi
else
    echo "Rate limit OK: $RATE_REMAINING calls remaining" >&2
fi



function rest_call {
    curl -s $1 -H "${GITHUB_API_HEADER_ACCEPT}" -H "Authorization: token $GITHUB_TOKEN" >> $TMPFILE
}

# single page result-s (no pagination), have no Link: section, the grep result is empty
last_page=`curl -s -I "https://api.github.com${GITHUB_API_REST}" -H "${GITHUB_API_HEADER_ACCEPT}" -H "Authorization: token $GITHUB_TOKEN" | grep '^Link:' | sed -e 's/^Link:.*page=//g' -e 's/>.*$//g'`

# does this result use pagination?
if [ -z "$last_page" ]; then
    # no - this result has only one page
    rest_call "https://api.github.com${GITHUB_API_REST}"
else

    # yes - this result is on multiple pages
    for p in `seq 1 $last_page`; do
        rest_call "https://api.github.com${GITHUB_API_REST}?page=$p"
    done
fi

cat $TMPFILE
