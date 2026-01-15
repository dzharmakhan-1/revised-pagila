# Architecture and Schema Design

This warehouse follows a classic star schema:

- Central fact table
- Independent denormalized dimensions
- No dimension-to-dimension joins

This minimizes query complexity and improves performance.
```
