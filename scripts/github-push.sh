#!/usr/bin/env bash
# Push local commits to GitHub via native git push.
# The old REST-API (git/trees) write path is blocked by the Claude Code cloud
# git proxy (confirmed HTTP 403 on git/trees POST, see WEEKLY-REVIEW.md
# "Week ending 2026-09-11" root-cause note) — native `git push` still works.
# Usage: bash scripts/github-push.sh "commit message" file1 [file2 ...]
# Expects the commit to already exist locally (git commit before calling this).
# The message/file args are accepted for call-site compatibility and logging
# only; this script does not create a commit.
# Exit codes: 0 = success, 1 = usage error, 2 = push failed after retries
set -euo pipefail

BRANCH="main"
MESSAGE="${1:-}"
shift || true
FILES=("$@")

if [[ -z "$MESSAGE" ]] || [[ ${#FILES[@]} -eq 0 ]]; then
  echo "usage: bash scripts/github-push.sh \"commit message\" file1 [file2 ...]" >&2
  exit 1
fi

MAX_ATTEMPTS=5
for attempt in $(seq 1 "$MAX_ATTEMPTS"); do
  if ERR=$(git push origin "HEAD:${BRANCH}" 2>&1); then
    echo "github-push: pushed HEAD -> origin/${BRANCH} ($(git rev-parse --short HEAD))"
    exit 0
  fi

  echo "github-push: push failed, attempt ${attempt}/${MAX_ATTEMPTS} — retrying with rebase onto fresh origin tip" >&2
  echo "$ERR" >&2

  git fetch origin "${BRANCH}"
  git rebase "origin/${BRANCH}"
done

echo "github-push: FAILED after ${MAX_ATTEMPTS} attempts — giving up" >&2
exit 2
