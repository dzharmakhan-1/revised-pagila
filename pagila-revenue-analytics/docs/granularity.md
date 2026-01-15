# Fact Table Granularity

The fact table grain defines what a single row represents.

In this project:

> One row = revenue from one payment, for one category, in one store, in one geography, on one date.

This choice ensures:
- Maximum analytical flexibility
- No hidden aggregation
- Clear traceability back to source transactions