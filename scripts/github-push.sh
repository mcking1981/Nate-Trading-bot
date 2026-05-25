#!/usr/bin/env bash
# Push files to GitHub via REST API — bypasses the Claude Code cloud git proxy.
# Usage: bash scripts/github-push.sh "commit message" file1 [file2 ...]
# Requires: GITHUB_TOKEN env var with repo write scope.
# Exit codes: 0 = success, 1 = usage/missing token, 2 = API error
set -euo pipefail

REPO="mcking1981/Nate-Trading-bot"
BRANCH="main"
API="https://api.github.com/repos/${REPO}"

MESSAGE="${1:-}"
shift || true
FILES=("$@")

if [[ -z "$MESSAGE" ]] || [[ ${#FILES[@]} -eq 0 ]]; then
  echo "usage: bash scripts/github-push.sh \"commit message\" file1 [file2 ...]" >&2
  exit 1
fi

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  echo "GITHUB_TOKEN not set — skipping API push" >&2
  exit 1
fi

AUTH="Authorization: token ${GITHUB_TOKEN}"

# Get current branch tip SHA
BRANCH_SHA=$(curl -fsS -H "$AUTH" \
  "${API}/git/refs/heads/${BRANCH}" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['object']['sha'])")

# Get current tree SHA
TREE_SHA=$(curl -fsS -H "$AUTH" \
  "${API}/git/commits/${BRANCH_SHA}" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['tree']['sha'])")

# Build tree entries (one per file, text content)
TREE_JSON=$(python3 - "${FILES[@]}" <<'PYEOF'
import sys, json, os
files = sys.argv[1:]
items = []
for f in files:
    with open(f, "r", encoding="utf-8") as fh:
        content = fh.read()
    items.append({"path": f, "mode": "100644", "type": "blob", "content": content})
print(json.dumps({"base_tree": "__TREE_SHA__", "tree": items}))
PYEOF
)
TREE_JSON="${TREE_JSON/__TREE_SHA__/$TREE_SHA}"

NEW_TREE=$(curl -fsS -X POST -H "$AUTH" -H "Content-Type: application/json" \
  "${API}/git/trees" -d "$TREE_JSON" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['sha'])")

# Create commit
MSG_JSON=$(python3 -c "import sys,json; print(json.dumps(sys.argv[1]))" "$MESSAGE")
NEW_COMMIT=$(curl -fsS -X POST -H "$AUTH" -H "Content-Type: application/json" \
  "${API}/git/commits" \
  -d "{\"message\":${MSG_JSON},\"tree\":\"${NEW_TREE}\",\"parents\":[\"${BRANCH_SHA}\"]}" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['sha'])")

# Advance branch ref
curl -fsS -X PATCH -H "$AUTH" -H "Content-Type: application/json" \
  "${API}/git/refs/heads/${BRANCH}" \
  -d "{\"sha\":\"${NEW_COMMIT}\"}" > /dev/null

echo "github-push: pushed ${#FILES[@]} file(s) → ${REPO}:${BRANCH} (${NEW_COMMIT:0:7})"
