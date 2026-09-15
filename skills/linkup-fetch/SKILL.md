---
name: linkup-fetch
description: Use when you already know the exact URL and need its content as clean Markdown or as typed JSON — a pricing page, article, docs page, PDF, or a URL found in a previous step. Uses the Linkup Fetch API via the `linkup-fetch` MCP tool or direct REST calls. Prefer this over linkup-search when the URL is known; prefer linkup-extract only when you need many rows that span pagination or detail pages.
---

# Linkup Fetch

When you already have the exact URL, use **Fetch** instead of search. It is faster and cheaper, returns the page as clean Markdown (HTML up to 20 MB, PDF up to 100 MB), and can return typed JSON from that page in the same call.

## How to call it

- If the **`linkup-fetch` MCP tool** is available, pass it the URL.
- Otherwise — or when you need `mode: "pro"`, `schema`, raw HTML, or images — call the REST API directly. Requires `LINKUP_API_KEY`:

```shell
curl -sS -X POST "https://api.linkup.so/v1/fetch" \
  -H "Authorization: Bearer $LINKUP_API_KEY" -H "Content-Type: application/json" \
  -d '{"url":"https://example.com/pricing","renderJs":true}'
```

## Parameters that matter

| Parameter | Default | Use |
| --- | --- | --- |
| `renderJs` | `false` | **Set `true` in agent pipelines.** Many sites load content client-side. Turn off only for known-static pages. |
| `mode` | `"standard"` | `"pro"` for hard-to-retrieve pages: significantly higher success rate, higher cost. Independent of `renderJs`. Start on `"standard"`; retry with `"pro"` when markdown comes back empty or truncated. Don't default to `"pro"`. |
| `schema` | — | JSON Schema (`type: "object"`). Turns on structured output: response keeps `markdown` and adds `data`. Put per-field meaning in `description`s. Fields not on the page are omitted, even if `required`. |
| `instructions` | — | Optional, requires `schema`, ≤ 4,000 chars. Global rules the schema can't express ("public list prices only", "one item per city"). |
| `includeRawHtml` / `extractImages` | `false` | Raw HTML or image URLs alongside the markdown. |

Pricing: `standard` $0.001 (no JS) / $0.005 (JS); `pro` $0.005 / $0.01; `schema` adds $0.001 to any row.

## Typed JSON from a known page

```json
{
  "url": "https://www.linkup.so/careers",
  "renderJs": true,
  "schema": {
    "type": "object",
    "properties": {
      "jobs": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "position": { "type": "string", "description": "The job title" },
            "city": { "type": "string", "description": "City where the job is located" }
          }
        }
      }
    }
  },
  "instructions": "If a position is listed in multiple cities, emit one jobs item per city."
}
```

Keep schemas shallow (primitives and one level of arrays). Fetch reads **this URL only**: it does not follow links or crawl.

## When to use fetch vs the alternatives

| Use `linkup-fetch` when... | Use instead... |
| --- | --- |
| You have one URL and want its content as Markdown | — |
| You have one URL and code needs typed fields from that page | `linkup-fetch` with `schema` |
| You don't know which URL has the answer | `linkup-search` (use `outputType: structured` for fields) |
| You need many rows from a listing page that span pagination or detail pages | `linkup-extract` (`/v1/extract`, closed beta) |
| You need to discover URLs and then scrape them | `linkup-search` with `depth: deep` |
| The URL is a LinkedIn profile or post | `linkup-search` (Fetch cannot read LinkedIn) |
| You have dozens or hundreds of URLs | `linkup-tasks` (batch the fetches through `/v1/tasks`) |

## Common failures

| Symptom | Fix |
| --- | --- |
| Empty or very short markdown, "Loading..." boilerplate | `renderJs: true` |
| Still empty with JS on | `mode: "pro"` |
| `400` target not found / unreachable | Check the URL; do not retry blindly |
| `400` on `instructions` | `instructions` requires `schema` |
| Missing fields in `data` | The value is not on the page. Don't invent it; search for it instead |

## After fetching

- Extract only the fields the task needs; don't dump the whole page back to the user.
- Keep the source URL so every claim can be verified.

For the full endpoint reference, read `references/LINKUP_API_REFERENCE.md` (Fetch API section) in this skill's directory.
