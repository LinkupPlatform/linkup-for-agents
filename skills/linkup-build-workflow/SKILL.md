---
name: linkup-build-workflow
description: Use when someone has a business goal rather than a single query — "how can I use Linkup?", "enrich my leads", "build a competitor tracker", "research before my meeting", "vet this vendor". Turns a goal into a multi-step Linkup workflow (which endpoint, which calls, what feeds the next step, where another tool takes over), grounded in bundled workflow patterns and 18 ready-made recipes.
---

# Linkup Build Workflow

Use this when the user describes an outcome, not a search. Your job is to turn a business goal into a concrete, executable chain of Linkup steps with clear inputs, outputs, and handoffs — not a single query.

## Method

1. **Define the final artifact.** What does the user actually get (a sourced company list, an enriched CRM record, a risk report, a briefing)?
2. **Route to a pattern.** Match the goal to one of the 8 workflow patterns (enrichment, research & intelligence, monitoring, verification, grounded content, procurement/compliance, answer engines, verticalized agents) or a ready recipe.
3. **Split into narrow retrieval steps.** Each step does one retrieval job. Avoid vague steps like "do sales research."
4. **Pick the endpoint per step** — `/v1/search` for lists, enrichment fields, known-URL scrapes, and handoff data; `/v1/research` for long-running reports, market maps, sector risk, and complex dossiers; `/v1/extract` for bulk rows from a known listing page. Don't use `/research` just because a task sounds important.
5. **Choose output type per step** — `searchResults` for discovery another step inspects, `sourcedAnswer` for user-facing summaries, `structured` (with schema) for data written to software.
6. **Name the handoffs.** Be explicit about what Linkup does *not* do: CRM writes, email verification, sequencing, spreadsheets, scheduling. Don't claim Linkup is a private email database or system of record.

## Two modes

- **Idea generation** ("how can I use Linkup?"): produce 5–7 workflow ideas matched to the user's role/industry, each with name, who it's for, what it produces, first input to ask for, and 3–5 Linkup steps.
- **Goal decomposition** (a specific goal): produce one complete workflow following the schema — inputs to ask for, ordered Linkup steps with `depth`/`outputType`, output contract, and handoffs.

## Use the bundled knowledge and recipes

Read these in this skill's `references/` directory before assembling a workflow:

- `references/LINKUP_WORKFLOW_GUIDE.md` — the pattern catalog: 8 patterns plus legal/medical/financial/developer playbooks, with worked examples and decision tables. Use it to recognize the right pattern.
- `references/LINKUP_WORKFLOW_OPTIMIZER_KNOWLEDGE.md` — the procedure for assembling a goal into steps, endpoint selection rules, research defaults, handoff rules, and output formats.
- `references/workflows/WORKFLOW_SCHEMA.md` — the standard format for an implementation-ready workflow.
- `references/workflows/` — 18 ready-to-adapt recipes across `sales/`, `marketing/`, and `research/` (start from `references/workflows/README.md`). Fill the placeholders with the user's specifics rather than writing from scratch.

For the individual Linkup calls inside a workflow, use the `linkup-search` skill (query construction), and `linkup-deep-research` / `linkup-bulk-extract` for the async endpoints.
