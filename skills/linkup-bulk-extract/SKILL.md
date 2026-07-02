---
name: linkup-bulk-extract
description: Use to pull many structured records from ONE known listing page — team directories, product/pricing catalogs, job listings, conference speakers, paginated lists. Uses Linkup's async /v1/extract REST endpoint and returns NDJSON rows. Requires LINKUP_API_KEY. For a single page's prose use linkup-fetch-url; for web discovery use linkup-web-search.
---

# Linkup Bulk Extract

The Extract endpoint turns a known web page into a table of structured records. Give it a seed URL plus a natural-language description of the rows you want, and it returns one JSON object per line (NDJSON), handling pagination automatically. It's built for 10s–1000s of records from a single listing page.

This uses the REST API, so it needs `LINKUP_API_KEY`:

```shell
test -n "$LINKUP_API_KEY" || echo "Missing LINKUP_API_KEY"
```

## When to use Extract

| Use `linkup-bulk-extract` when... | Use instead... |
| --- | --- |
| You have one URL and want many structured rows (team, catalog, jobs, speakers) | — |
| You want one page's content as prose/Markdown | `linkup-fetch-url` |
| You need to find information across the web | `linkup-web-search` |
| You need synthesis across many sources | `linkup-deep-research` |

## How to call it

Always provide a `schema` for production use (consistent output, clear required fields). Enable `verifyUrls` when extracted URLs will be used downstream (adds latency).

```shell
curl -sS -X POST "https://api.linkup.so/v1/extract" \
  -H "Authorization: Bearer $LINKUP_API_KEY" -H "Content-Type: application/json" \
  -d '{
    "q": "All pricing plans with plan name, monthly price, annual price, features, and usage limits",
    "url": "https://competitor.com/pricing",
    "schema": {"type":"object","properties":{"planName":{"type":"string"},"monthlyPrice":{"type":"string"},"annualPrice":{"type":"string"},"features":{"type":"array","items":{"type":"string"}}}}
  }'
```

## Async lifecycle

`POST /v1/extract` returns `{id, status: "pending"}`. Poll `GET /v1/extract/{id}` about every 30s (crawls run longer than research). When `completed`, the output has a `resultUrl` (24h expiry) — download it and parse one JSON object per line.

If you don't know the URL yet, first discover it with `linkup-web-search` (`"Find the careers page URL for {company}"`), then extract from the result.

For the full parameter reference, patterns, and pricing notes, read `references/LINKUP_SPECIALIZED_ENDPOINTS.md` (Extract section) in this skill's directory.
