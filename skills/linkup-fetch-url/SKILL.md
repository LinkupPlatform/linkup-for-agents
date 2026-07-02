---
name: linkup-fetch-url
description: Use when you already know the exact URL and need its content as clean Markdown — a pricing page, article, docs page, or a URL found in a previous step. Uses the Linkup Fetch API via the `linkup-fetch` MCP tool or direct REST calls. Prefer this over linkup-web-search when the URL is known; prefer linkup-bulk-extract when you need many structured rows from one listing page.
---

# Linkup Fetch

When you already have the exact URL, use **Fetch** instead of search. It is faster and cheaper, and returns the page as clean Markdown (with JavaScript rendering and optional image extraction).

## How to call it

- If the **`linkup-fetch` MCP tool** is available, pass it the URL.
- Otherwise call the REST API directly. Requires `LINKUP_API_KEY`:

```shell
curl -sS -X POST "https://api.linkup.so/v1/fetch" \
  -H "Authorization: Bearer $LINKUP_API_KEY" -H "Content-Type: application/json" \
  -d '{"url":"https://example.com/pricing","renderJs":true}'
```

**Default JavaScript rendering to on** — many sites load content client-side, and the small latency cost is almost always worth the reliability. Turn it off only when speed matters more on a known-static page.

## When to use fetch vs the alternatives

| Use `linkup-fetch-url` when... | Use instead... |
| --- | --- |
| You have one URL and want its content as Markdown | — |
| You don't know which URL has the answer | `linkup-web-search` |
| You need many structured records from one listing page (team, catalog, jobs) | `linkup-bulk-extract` (`/v1/extract`) |
| You need to discover URLs and then scrape them | `linkup-web-search` with `depth: deep` |
| The URL is a LinkedIn profile or post | `linkup-web-search` (Fetch cannot authenticate into LinkedIn) |

Important: fetch reads page *content*; it cannot produce structured JSON from a page. If you need structured fields from a known page, use `linkup-bulk-extract` (`/v1/extract`) or the Search API with `outputType: structured`.

## After fetching

- Extract only the fields the task needs; don't dump the whole page back to the user.
- Keep the source URL so every claim can be verified.

For the full endpoint reference, read `references/LINKUP_API_REFERENCE.md` (Fetch API section) in this skill's directory.
