# Cloud Routine Prompts

Paste each of these verbatim into its respective Claude Code cloud routine.
**Do not paraphrase.** The env-var check block and commit-and-push step are load-bearing.

## Cron Schedules (America/Chicago)

| Routine | File | Schedule |
|---------|------|----------|
| Pre-market | pre-market.md | `0 6 * * 1-5` (6:00 AM weekdays) |
| Market-open | market-open.md | `30 8 * * 1-5` (8:30 AM weekdays) |
| Midday | midday.md | `0 12 * * 1-5` (noon weekdays) |
| Daily summary | daily-summary.md | `0 15 * * 1-5` (3:00 PM weekdays) |
| Weekly review | weekly-review.md | `0 16 * * 5` (4:00 PM Fridays) |

## Setup Steps (per routine)

1. Go to Claude Code cloud → Routines → New Routine
2. Name it (e.g. "Trading bot pre-market")
3. Select your repo and branch: main
4. Add all environment variables (see env.template)
5. Toggle on **"Allow unrestricted branch pushes"**
6. Set cron schedule and timezone
7. Paste prompt from this directory verbatim
8. Save → click **"Run now"** once to verify
