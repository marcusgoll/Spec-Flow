# Performance Benchmarking

**Purpose**: Validate API response times and page load performance against documented targets.

---

## Performance Targets

**From spec.md success criteria**:
- API p50 (median): <200ms
- API p95 (95th percentile): <500ms
- Page load (initial): <2 seconds
- Time to Interactive (TTI): <3 seconds

---

## API Performance Testing

```bash
# Using curl with timing
curl -w "@curl-format.txt" -o /dev/null -s "http://localhost:3000/api/endpoint"

# Format file (curl-format.txt):
time_namelookup:  %{time_namelookup}s\n
time_connect:  %{time_connect}s\n
time_total:  %{time_total}s\n
```

**Run 10 requests and calculate p50/p95**:
```bash
for i in {1..10}; do
  curl -w "%{time_total}\n" -o /dev/null -s "http://localhost:3000/api/endpoint"
done | sort -n
```

---

## Page Load Testing

**Using Lighthouse CI**:
```bash
npm install -g @lhci/cli
lhci autorun --url=http://localhost:3000
```

**Check metrics**:
- First Contentful Paint (FCP): <1.8s
- Largest Contentful Paint (LCP): <2.5s
- Time to Interactive (TTI): <3.8s
- Total Blocking Time (TBT): <300ms

---

## Results Format

```markdown
## Performance Results

### API Performance
- GET /api/users: p50=145ms, p95=320ms ✅
- POST /api/orders: p50=230ms, p95=580ms ❌ (exceeds p95 target)

### Page Load Performance
- Homepage: LCP=1.9s ✅, TTI=2.8s ✅
- Dashboard: LCP=3.2s ❌ (exceeds target)
```

**See [../reference.md](../reference.md#performance) for complete testing guide**
