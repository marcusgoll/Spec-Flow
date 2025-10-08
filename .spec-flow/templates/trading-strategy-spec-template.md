# Trading Strategy Specification: [STRATEGY NAME]

**Constitution**: v1.0.0
**Created**: [DATE]
**Status**: Draft
**Risk Level**: [Low/Medium/High]

---

## Strategy Overview

### Core Hypothesis
[What market inefficiency or pattern does this strategy exploit?]

### Trading Logic
**Entry Conditions**:
- [Condition 1: e.g., RSI < 30 and price > 50-day MA]
- [Condition 2: ...]

**Exit Conditions**:
- [Take profit: e.g., +5% gain]
- [Stop loss: e.g., -2% loss]
- [Time-based: e.g., hold max 3 days]

### Position Sizing
- Maximum position: [e.g., 5% of portfolio]
- Position calculation method: [e.g., Kelly Criterion, fixed percentage]

---

## Risk Management (§Risk_Management)

### Hard Limits
- **Max daily loss**: $[amount] or [%] of portfolio
- **Max trades per day**: [number]
- **Max position size**: [%] per stock
- **Max portfolio exposure**: [%] in active positions

### Stop Losses
- **Stop loss %**: [e.g., 2% below entry]
- **Trailing stop**: [Yes/No, if yes: %]
- **Time stop**: [e.g., close after 3 days regardless]

### Circuit Breakers
- Halt trading if daily loss exceeds [%]
- Halt if [N] consecutive losses
- Manual override required to resume

---

## Acceptance Criteria

### Strategy Validation
- [ ] Backtested against ≥2 years historical data
- [ ] Sharpe ratio ≥ [target, e.g., 1.0]
- [ ] Maximum drawdown < [%, e.g., 15%]
- [ ] Win rate ≥ [%, e.g., 55%]

### Safety Requirements (§Safety_First)
- [ ] All positions have stop losses
- [ ] Circuit breakers implemented and tested
- [ ] Paper trading validation (1 week minimum)
- [ ] Manual kill switch accessible

### Code Quality (§Code_Quality)
- [ ] Type hints on all functions
- [ ] Test coverage ≥90%
- [ ] All market data validated
- [ ] Error handling for API failures

---

## Data Requirements (§Data_Integrity)

### Market Data Needed
- **Price data**: [OHLCV, tick data, etc.]
- **Indicators**: [e.g., RSI, MACD, Bollinger Bands]
- **Timeframe**: [e.g., 1-minute, daily]
- **Data source**: [Robinhood API, backup source if any]

### Data Validation
- [ ] Check for missing/null values
- [ ] Verify timestamp ordering
- [ ] Validate price bounds (no negative prices)
- [ ] Handle market hours / closed days

---

## Testing Requirements (§Testing_Requirements)

### Unit Tests
- [ ] Entry signal logic
- [ ] Exit signal logic
- [ ] Position sizing calculation
- [ ] Risk limit enforcement
- [ ] Data validation functions

### Integration Tests
- [ ] Robinhood API connection (mocked)
- [ ] Order placement flow
- [ ] Position tracking
- [ ] Error handling scenarios

### Backtesting
- [ ] Historical data: [date range]
- [ ] Commission/slippage modeling
- [ ] Performance metrics calculated
- [ ] Edge cases tested (market gaps, halts)

### Paper Trading
- [ ] Live data, simulated orders
- [ ] Run duration: [e.g., 1-2 weeks]
- [ ] Performance vs. backtest validation
- [ ] All edge cases observed

---

## Implementation Checklist

### Phase 1: Strategy Logic
- [ ] Implement indicator calculations
- [ ] Write entry signal detector
- [ ] Write exit signal detector
- [ ] Add position sizing logic

### Phase 2: Risk Management
- [ ] Implement stop loss logic
- [ ] Add circuit breakers
- [ ] Create position limit checks
- [ ] Build kill switch mechanism

### Phase 3: Data Pipeline
- [ ] Fetch market data from Robinhood API
- [ ] Validate and clean data
- [ ] Calculate required indicators
- [ ] Handle missing data gracefully

### Phase 4: Testing
- [ ] Write and pass all unit tests
- [ ] Run integration tests
- [ ] Complete backtesting analysis
- [ ] Execute paper trading validation

### Phase 5: Monitoring & Logging (§Audit_Everything)
- [ ] Log all trade decisions with reasoning
- [ ] Log all API calls and responses
- [ ] Track performance metrics
- [ ] Alert on circuit breaker triggers

---

## Performance Metrics

### Expected Performance
- **Sharpe Ratio**: [target]
- **Max Drawdown**: [%]
- **Win Rate**: [%]
- **Average Gain**: [%]
- **Average Loss**: [%]
- **Profit Factor**: [ratio]

### Monitoring
- Daily P&L tracking
- Win/loss ratio monitoring
- Compare actual vs. backtested performance
- Alert if deviation > [threshold]

---

## Security Considerations (§Security)

- [ ] No API credentials in code
- [ ] Environment variables for secrets
- [ ] Minimal OAuth scopes requested
- [ ] API rate limiting respected

---

## Compliance & Legal

- [ ] Personal use only (not financial advice)
- [ ] Robinhood ToS compliance verified
- [ ] Pattern day trading rules considered
- [ ] Tax tracking implemented

---

## Quality Gates (Pre-Deploy)

Per Constitution §Pre_Deploy:
- [ ] 90%+ test coverage
- [ ] No high-severity vulnerabilities (`bandit` scan)
- [ ] Paper trading validation passed
- [ ] Risk limits configured and tested
- [ ] Circuit breakers active
- [ ] Logging to persistent storage
- [ ] Manual kill switch tested

---

## Notes

[Additional context, assumptions, or considerations]
