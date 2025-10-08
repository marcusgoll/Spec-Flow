# Backtest Report: [STRATEGY NAME]

**Constitution**: v1.0.0
**Date**: [DATE]
**Data Period**: [START_DATE] to [END_DATE]
**Strategy Version**: [VERSION]

---

## Executive Summary

**Result**: [PASS/FAIL] - [Brief one-line verdict]

**Key Metrics**:
- Total Return: [%]
- Sharpe Ratio: [ratio]
- Max Drawdown: [%]
- Win Rate: [%]

**Recommendation**: [Proceed to paper trading / Needs improvement / Reject]

---

## Performance Metrics

### Returns
- **Total Return**: [%]
- **Annualized Return**: [%]
- **Monthly Returns**: [avg %]
- **Best Month**: [%] ([DATE])
- **Worst Month**: [%] ([DATE])

### Risk-Adjusted
- **Sharpe Ratio**: [ratio] (Target: ≥1.0)
- **Sortino Ratio**: [ratio]
- **Calmar Ratio**: [ratio]
- **Maximum Drawdown**: [%] (Limit: <15%)
- **Average Drawdown**: [%]

### Trade Statistics
- **Total Trades**: [number]
- **Win Rate**: [%] (Target: ≥55%)
- **Profit Factor**: [ratio] (wins/losses)
- **Average Gain**: [%]
- **Average Loss**: [%]
- **Best Trade**: [%]
- **Worst Trade**: [%]
- **Average Hold Time**: [days/hours]

---

## Trade Distribution

### By Outcome
- Winning Trades: [number] ([%])
- Losing Trades: [number] ([%])
- Break-even: [number] ([%])

### By Size
- Large wins (>5%): [number]
- Small wins (<5%): [number]
- Small losses (<2%): [number]
- Large losses (>2%): [number]

### By Duration
- Intraday: [number]
- 1-3 days: [number]
- 3-7 days: [number]
- >7 days: [number]

---

## Risk Analysis

### Drawdowns
- Max Drawdown: [%] on [DATE]
- Drawdown Duration: [days]
- Recovery Time: [days]
- Number of Drawdowns >5%: [number]

### Risk Limits Validation
- [ ] No position exceeded 5% portfolio limit
- [ ] No daily loss exceeded [%] limit
- [ ] All positions had stop losses
- [ ] Circuit breakers would have triggered [N] times

### Volatility
- Daily Volatility: [%]
- Annualized Volatility: [%]
- Beta (vs SPY): [ratio]

---

## Strategy Behavior

### Entry Patterns
- Most common entry signal: [description]
- Entry success rate: [%]
- False signals filtered: [number]

### Exit Patterns
- Take profit exits: [%]
- Stop loss exits: [%]
- Time-based exits: [%]
- Signal-based exits: [%]

### Market Conditions
- Bull market performance: [%]
- Bear market performance: [%]
- Sideways market performance: [%]
- High volatility performance: [%]

---

## Data Quality

### Data Coverage
- Total bars: [number]
- Missing data points: [number] ([%])
- Data source: [Robinhood API / other]
- Data validation: [PASS/FAIL]

### Handling Issues
- [ ] Missing bars handled correctly
- [ ] Market gaps accounted for
- [ ] After-hours data excluded
- [ ] Dividends/splits adjusted

---

## Comparison to Benchmark

### vs Buy & Hold SPY
- Strategy Return: [%]
- SPY Return: [%]
- Alpha: [%]
- Correlation: [ratio]

### vs Risk-Free Rate
- Strategy Return: [%]
- Risk-Free Rate (10Y Treasury): [%]
- Excess Return: [%]

---

## Edge Cases Tested

### Market Events
- [ ] Market crash (COVID-19 2020)
- [ ] Bull run (2023-2024)
- [ ] High volatility periods
- [ ] Earnings season behavior
- [ ] Fed announcement days

### Technical Scenarios
- [ ] Low liquidity stocks
- [ ] Circuit breaker triggers
- [ ] Consecutive losses
- [ ] Streak of wins
- [ ] Whipsaw conditions

---

## Quality Gate Assessment

Per Constitution §Pre_Deploy:

### Performance Requirements
- [ ] Sharpe Ratio ≥ 1.0: [PASS/FAIL]
- [ ] Max Drawdown < 15%: [PASS/FAIL]
- [ ] Win Rate ≥ 55%: [PASS/FAIL]
- [ ] Positive Profit Factor: [PASS/FAIL]

### Risk Management
- [ ] All trades had stop losses: [PASS/FAIL]
- [ ] Position limits respected: [PASS/FAIL]
- [ ] Circuit breakers effective: [PASS/FAIL]

### Data Integrity
- [ ] No data quality issues: [PASS/FAIL]
- [ ] All validation checks passed: [PASS/FAIL]

**Overall Quality Gate**: [PASS/FAIL]

---

## Failure Analysis (if applicable)

### Why Strategy Failed
- [Root cause 1]
- [Root cause 2]

### Trades That Lost Most Money
1. [Symbol] on [DATE]: [%] loss - Reason: [analysis]
2. [Symbol] on [DATE]: [%] loss - Reason: [analysis]

### Improvement Recommendations
- [Suggestion 1]
- [Suggestion 2]

---

## Next Steps

### If PASS
1. [ ] Proceed to paper trading
2. [ ] Monitor for 1-2 weeks
3. [ ] Compare paper vs backtest results
4. [ ] If paper trading successful, consider real money (small)

### If FAIL
1. [ ] Analyze failure patterns
2. [ ] Adjust strategy parameters
3. [ ] Re-run backtest
4. [ ] Document learnings in DONT_DO.md

---

## Appendix

### Configuration Used
```python
# Strategy parameters
[parameter_name] = [value]
[parameter_name] = [value]
```

### Commission & Slippage
- Commission: $[amount] per trade
- Slippage: [%] assumed
- Market impact: [included/excluded]

### Data Files
- Backtest code: `backtests/[strategy_name]_backtest.py`
- Results CSV: `backtests/results/[strategy_name]_[date].csv`
- Trade log: `backtests/logs/[strategy_name]_trades.json`
