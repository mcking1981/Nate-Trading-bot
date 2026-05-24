#!/usr/bin/env bash
# Research wrapper. All market research goes through Tavily.
# Usage: bash scripts/tavily.sh "<query>"
# Exits with code 3 if TAVILY_API_KEY is unset so callers can fall back to native WebSearch.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT/.env"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

query="${1:-}"
if [[ -z "$query" ]]; then
  echo "usage: bash scripts/tavily.sh \"<query>\"" >&2
  exit 1
fi

if [[ -z "${TAVILY_API_KEY:-}" ]]; then
  echo "WARNING: TAVILY_API_KEY not set. Fall back to native WebSearch." >&2
  exit 3
fi

DEPTH="${TAVILY_SEARCH_DEPTH:-advanced}"

payload="$(python -c "
import json, sys
print(json.dumps({
  'query': sys.argv[1],
  'search_depth': sys.argv[2],
  'include_answer': True,
  'max_results': 5,
  'include_raw_content': False,
}))
" "$query" "$DEPTH")"

curl -fsS https://api.tavily.com/search \
  -H "Authorization: Bearer $TAVILY_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$payload"
echo
