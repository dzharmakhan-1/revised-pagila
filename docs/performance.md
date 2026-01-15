# Performance & Indexing Strategy

Indexes exist on:
- date_id
- category_sk
- store_sk
- geography_sk
- (date_id, category_sk)

These reflect the most common analytical access patterns:
- Time slicing
- Category analysis
- Store comparisons