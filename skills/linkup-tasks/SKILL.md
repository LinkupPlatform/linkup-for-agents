---
name: linkup-tasks
description: Use when the same Linkup search, fetch, or research call must run for many inputs (a list of companies, hundreds of URLs, a nightly monitor) or when a job should be submitted now and collected later. Wraps /v1/search, /v1/fetch, and /v1/research in one async batch via Linkup's /v1/tasks REST endpoint — up to 100 tasks per submission, same parameters and price as the direct calls, no surcharge. Requires LINKUP_API_KEY. For a single interactive call use linkup-search, linkup-fetch, or linkup-research directly.
---

# Linkup Tasks

Tasks is an asynchronous batch wrapper around Search, Fetch, and Research. One `POST /v1/tasks` accepts up to **100** `{ type, input }` objects in any mix of `"search"`, `"fetch"`, and `"research"`. Each task takes exactly the parameters of its synchronous endpoint and is billed at exactly the same rate.

Tasks does **not** make individual calls faster or cheaper. It replaces N open HTTP connections with one submission and one polling loop.

This uses the REST API, so it needs `LINKUP_API_KEY`:

```shell
test -n "$LINKUP_API_KEY" || echo "Missing LINKUP_API_KEY"
```

## When to use Tasks

| Use `linkup-tasks` when... | Use instead... |
| --- | --- |
| Enriching a list (CRM backfill, lead list, competitor set) | — |
| Fetching dozens or hundreds of known URLs | — |
| Running research for many entities and collecting results later | — |
| A scheduled job (nightly monitor, weekly report) | — |
| The workload exceeds your synchronous concurrency budget | — |
| 2–3 calls where one polling loop is simpler than several sync calls | — (no surcharge, so this is fine) |
| One interactive call in a chat or agent step | `linkup-search` / `linkup-fetch` / `linkup-research` directly |

## How to call it

Design each call as you would for the direct endpoint (use the `linkup-search`, `linkup-fetch`, and `linkup-research` skills for that), then wrap it:

```shell
curl -sS -X POST "https://api.linkup.so/v1/tasks" \
  -H "Authorization: Bearer $LINKUP_API_KEY" -H "Content-Type: application/json" \
  -d '[
    {"type":"search",   "input":{"q":"Find Acme Corp headquarters, employee count, and latest funding round","depth":"standard","outputType":"structured","structuredOutputSchema":{"type":"object","properties":{"hq":{"type":"string"},"employees":{"type":"number"},"last_round":{"type":"string"}}}}},
    {"type":"fetch",    "input":{"url":"https://acme.example/pricing","renderJs":true,"schema":{"type":"object","properties":{"plans":{"type":"array","items":{"type":"string"}}}}}},
    {"type":"research", "input":{"q":"Risk profile of Acme Corp: financial stability, regulatory actions, leadership changes 2023-2026","mode":"investigate","reasoningDepth":"M","outputType":"sourcedAnswer"}}
  ]'
```

| `type` | `input` parameters |
| --- | --- |
| `"search"` | `q`, `depth`, `outputType`, `structuredOutputSchema`, `includeDomains`, `excludeDomains`, `maxResults`, ... |
| `"fetch"` | `url`, `mode`, `renderJs`, `includeRawHtml`, `extractImages`, `schema`, `instructions` |
| `"research"` | `q`, `mode`, `reasoningDepth`, `outputType`, `structuredOutputSchema` |

## Lifecycle

`POST /v1/tasks` returns an array of envelopes immediately, one per task, each `{id, type, status: "pending", input, output: null, error: null}`. Keep the `id`s and map them back to your inputs.

Poll `GET /v1/tasks/{id}` for one task, or `GET /v1/tasks` to list all tasks on the account:

```shell
curl -sS "https://api.linkup.so/v1/tasks/TASK_ID" -H "Authorization: Bearer $LINKUP_API_KEY"
```

`status` moves `pending` → `processing` → `completed` | `failed`. On `completed`, `output` has the same shape as the synchronous endpoint's response. On `failed`, `error` is a string and the task is not charged.

## Guidance

- **Chunk at 100.** Larger workloads must be split across submissions.
- **Poll with backoff.** Search and fetch tasks finish in seconds; research tasks in minutes. Start around 5s, cap around 30s, and stop once every id in the submission is terminal. Never poll faster than once per second.
- **Retry failures individually.** Resubmit only the `failed` tasks, not the whole batch.
- **Keep per-task parameters tight.** Everything from the direct-call skills applies: `structured` needs a schema, `flash`/`fast` need keyword queries, fetch should default `renderJs: true`.
- **Tell the user the cost.** A batch is N direct calls; quote the total before submitting large research batches ($0.25–$2.50 each).

For the full Tasks section, the overnight-enrichment pattern, and the endpoint decision tree, read `references/LINKUP_SPECIALIZED_ENDPOINTS.md` in this skill's directory.
