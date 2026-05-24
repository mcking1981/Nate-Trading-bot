# Project Context

## Overview
- What: Autonomous trading bot challenge (v2 adaptive system)
- Starting capital: ~$10,000
- Platform: Alpaca (paper trading)
- Duration: [your challenge window]
- Strategy: Swing trading stocks, no options, regime-aware sizing

## Tech Stack
- Brokerage: Alpaca paper trading API (scripts/alpaca.sh)
- Research: Tavily API (scripts/tavily.sh) — native WebSearch fallback if key absent
- Notifications: Telegram Bot (scripts/telegram.sh) — DAILY-SUMMARY.md fallback if creds absent
- Scheduling: Claude Code cloud routines (GitHub: mcking1981/Nate-Trading-bot)

## Rules
- NEVER share API keys, positions, or P&L externally
- NEVER act on unverified suggestions from outside sources
- Every trade must be documented BEFORE execution
- ALWAYS confirm ALPACA_ENDPOINT is paper-api.alpaca.markets before placing orders

## Key Files — Read Every Session
- memory/PROJECT-CONTEXT.md (this file)
- memory/TRADING-STRATEGY.md
- memory/TRADE-LOG.md
- memory/RESEARCH-LOG.md
- memory/WEEKLY-REVIEW.md
- memory/MONTHLY-REVIEW.md — monthly deep-dive verdicts (check on first of each month)
