# 2. Data Cleaning

## Data Quality Issues Found

### Issue 1 — Bounce Rate Outliers
- **Problem:** Some campaigns show bounce rates >30% (industry average is 2%)
- **Fix:** Flagged for list hygiene review; included in analysis with annotation
- **Impact:** Deliverability metrics skewed for affected campaigns

### Issue 2 — Inconsistent Campaign Type Labels
- **Problem:** Variant spellings for the same campaign types
- **Fix:** Standardized campaign type names across all records

### Issue 3 — Missing Revenue Attribution
- **Problem:** Some campaigns have conversions but no revenue recorded
- **Fix:** Flagged; excluded from revenue-per-conversion calculations

### Issue 4 — Zero Send Counts
- **Problem:** A few records show 0 emails sent (likely test campaigns)
- **Fix:** Excluded from performance rate calculations

## Cleaning Summary

| Issue | Records | Action |
|-------|---------|--------|
| High bounce campaigns | ~15 | Flagged, annotated |
| Campaign type variants | ~30 | Normalized |
| Missing revenue | ~8 | Flagged, excluded from rev/conv |
| Zero send count | ~3 | Excluded from analysis |
