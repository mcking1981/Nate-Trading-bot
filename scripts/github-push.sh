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
MSG_JSON=$(python3 -c "import sys,json; print(json.dumps(sys.argv[1]))" "$MESSAGE")

# Retry loop: another routine may advance the ref between our read and our
# write. On a non-fast-forward conflict, re-fetch the new tip and rebuild the
# commit on top of it instead of failing outright (which previously caused
# the agent to fall back to MCP GitHub tools and strand commits on orphan
# branches that never got merged to main).
MAX_ATTEMPTS=5
for attempt in $(seq 1 "$MAX_ATTEMPTS"); do
  BRANCH_SHA=$(curl -fsS -H "$AUTH" \
    "${API}/git/refs/heads/${BRANCH}" \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['object']['sha'])")

  TREE_SHA=$(curl -fsS -H "$AUTH" \
    "${API}/git/commits/${BRANCH_SHA}" \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['tree']['sha'])")

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

  NEW_COMMIT=$(curl -fsS -X POST -H "$AUTH" -H "Content-Type: application/json" \
    "${API}/git/commits" \
    -d "{\"message\":${MSG_JSON},\"tree\":\"${NEW_TREE}\",\"parents\":[\"${BRANCH_SHA}\"]}" \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['sha'])")

  HTTP_CODE=$(curl -sS -o /tmp/github-push-patch-resp.json -w "%{http_code}" \
    -X PATCH -H "$AUTH" -H "Content-Type: application/json" \
    "${API}/git/refs/heads/${BRANCH}" \
    -d "{\"sha\":\"${NEW_COMMIT}\"}")

  if [[ "$HTTP_CODE" == "200" ]]; then
    echo "github-push: pushed ${#FILES[@]} file(s) → ${REPO}:${BRANCH} (${NEW_COMMIT:0:7})"
    exit 0
  fi

  echo "github-push: ref update failed (HTTP $HTTP_CODE), attempt ${attempt}/${MAX_ATTEMPTS} — retrying with fresh tip" >&2
  cat /tmp/github-push-patch-resp.json >&2
done

echo "github-push: FAILED after ${MAX_ATTEMPTS} attempts — giving up" >&2
exit 2
