# Nate Trading Bot

An autonomous AI trading agent built on Claude Code. Manages a ~$10,000 Alpaca account
using a disciplined swing-trading strategy. No options — stocks only.

## Quick Start

1. Copy `env.template` to `.env` and fill in your credentials
2. Open this repo in Claude Code
3. Run `/portfolio` to verify your Alpaca connection
4. Review `memory/TRADING-STRATEGY.md` before doing anything else

## Structure

```
├── CLAUDE.md              # Agent rulebook (auto-loaded every session)
├── env.template           # Template — copy to .env locally, never commit
├── .gitignore             # Excludes .env
├── .claude/commands/      # Local slash commands
├── routines/              # Cloud routine prompts (paste into CC cloud UI)
├── scripts/               # API wrappers (alpaca, perplexity, clickup)
└── memory/                # Agent state — all committed to main
```

## Cloud Routines

See `routines/README.md` for cron schedules and setup steps.

## Hard Rules

- NO options. Ever.
- Max 5-6 positions, 20% each
- 10% trailing stop on every position (real GTC order)
- Cut losers at -7%. Patience > activity.
