# Trading Strategy

## Mission
Beat the S&P 500 over the challenge window. Stocks only — no options, ever.

## Capital & Constraints
- Starting capital: ~$10,000
- Platform: Alpaca
- Instruments: Stocks ONLY
- PDT limit: 3 day trades per 5 rolling days (account < $25k)

## Core Rules
1. NO OPTIONS — ever
2. 75-85% deployed
3. 5-6 positions at a time, max 20% each
4. 10% trailing stop on every position as a real GTC order
5. Cut losers at -7% manually
6. Tighten trail: 7% at +15%, 5% at +20%
7. Never within 3% of current price; never move a stop down
8. Max 3 new trades per week
9. Follow sector momentum
10. Exit a sector after 2 consecutive failed trades
11. Patience > activity

## Entry Checklist
- Specific catalyst?
- Sector in momentum?
- Stop level (7-10% below entry)
- Target (min 2:1 R:R)

## Regime-Aware Adjustments

Classify today's regime at the start of every pre-market run. Stamp it in RESEARCH-LOG.md.
Market-open and midday routines READ the regime; they never reclassify.

### Regime Matrix

| Regime | Detection                                   | Max positions | Max %/position | Target deployed | New trades/week |
|--------|---------------------------------------------|---------------|----------------|-----------------|-----------------|
| Bull   | SPY >= +2% above 50DMA AND VIX < 15        | 6             | 20%            | 85%             | 3               |
| Chop   | SPY within +/-2% of 50DMA OR VIX 15-25     | 4             | 15%            | 60%             | 2               |
| Bear   | SPY < -2% below 50DMA OR VIX > 25          | 2             | 10%            | 30%             | 1               |

Hard floor rule: regime limits only TIGHTEN Nate's base rules, never loosen them.

### Regime Detection Queries (run at pre-market Step 3a)
- bash scripts/tavily.sh "SPY price and 50-day moving average today"
- bash scripts/tavily.sh "VIX level right now"
Compute SPY % distance from 50DMA, apply matrix, stamp result at top of RESEARCH-LOG entry.

### Weekly Auto-Tuning (triggered in weekly-review Step 5)
Rules applied automatically when stat thresholds are met. Every mutation logged as "### Rule Changes This Week".
- 2 consecutive weeks underperformed S&P by >2%: tighten current regime max %/position by -3pp (floor: 10%)
- 2 consecutive weeks beat S&P by >2% AND max drawdown < 5%: loosen by +3pp (ceiling: regime matrix max)
- Sector with 2 consecutive losing trades: append to Avoid Sectors cooldown block below (2-week ban)

## Avoid Sectors (2-week cooldown)

<!-- Weekly review appends sector bans here. Format: SECTOR — added YYYY-MM-DD, expires YYYY-MM-DD -->
