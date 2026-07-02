---
name: linkup-deep-research
description: ONLY when the user explicitly wants a thorough, exhaustive, or comprehensive multi-source investigation or report that can run for minutes — due diligence, market landscapes, "compare X across many entities", verified fact-finding. Slower and more expensive than linkup-web-search. For normal lookups and research use linkup-web-search instead; for bulk records from a page use linkup-bulk-extract. Uses Linkup's async /v1/research REST endpoint. Requires LINKUP_API_KEY.
---

# Linkup Deep Research

The Research endpoint is an autonomous agent that investigates the web iteratively for minutes, cross-checks claims across sources, and returns a synthesized, cited answer. Reach for it only when a single `deep` search can't cover the job — many entities, many facets, verification needed, or a report-style deliverable.

This uses the REST API, so it needs `LINKUP_API_KEY` in the environment:

```shell
test -n "$LINKUP_API_KEY" || echo "Missing LINKUP_API_KEY"
```

## Choose mode and depth explicitly

Always set `mode` and `reasoningDepth` for predictable latency, cost, and output shape.

- **mode** — `answer` (a precise question with one correct answer, self-verified), `investigate` (deep analysis of one defined entity), `research` (broad, multi-angle exploration across many entities). Rule of thumb: ends with "?" and expects one answer → `answer`; "the state of / analysis of" → `research`; one entity comprehensively → `investigate`.
- **reasoningDepth** — `S` (~2-5 min), `M` (~3-7 min, default for a bounded report), `L` (~5-10 min, market maps / multi-company), `XL` (~10-20 min, only when the user wants exhaustive coverage).
- **outputType** — `sourcedAnswer` for reports; `structured` only with a `structuredOutputSchema`.

## Submit, then poll with backoff

`POST /v1/research` returns `{id, status: "pending"}` immediately. Poll `GET /v1/research/{id}` with exponential backoff (start 2s, cap 10s) until `status` is `completed` or `failed`. Never poll faster than once per second. Failed tasks are not charged.

```shell
curl -sS -X POST "https://api.linkup.so/v1/research" \
  -H "Authorization: Bearer $LINKUP_API_KEY" -H "Content-Type: application/json" \
  -d '{"q":"Compare 2024 cloud revenue growth for Microsoft, Amazon, and Google from primary sources.","mode":"answer","reasoningDepth":"M","outputType":"sourcedAnswer"}'

curl -sS "https://api.linkup.so/v1/research/RESEARCH_ID" -H "Authorization: Bearer $LINKUP_API_KEY"
```

## Write a well-scoped prompt

Specify the angles to cover, leads to pursue, facts to verify, entities to compare, constraints/exclusions, and the output structure. More precise input yields more thorough, aligned output.

## Guidance

- Research costs more and runs for minutes ($0.25–$2.50 by depth). Tell the user what you're about to run and why before starting.
- Ground every claim in the returned `sources`. When done, summarize in plain English: what was researched, the answer, key sources, and roughly how long it took.
- Retry only transient failures (`429`, `5xx`) with backoff.

For the full decision matrix, mode examples, patterns, and polling details, read `references/LINKUP_SPECIALIZED_ENDPOINTS.md` (Research section) in this skill's directory.
