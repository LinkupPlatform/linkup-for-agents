# AGENTS.md

This repository is a context pack for using the [Linkup](https://www.linkup.so) web search API. Read
this file first, then open the specific document that matches the task in front of you. Do not guess
Linkup's behavior from memory — the documents here are the source of truth.

## Route yourself by task

| If the user wants to... | Read |
|-------------------------|------|
| Understand what Linkup can do (endpoints, output types, auth) | `knowledge/LINKUP_API_REFERENCE.md` |
| Decide the request shape before writing a query | `knowledge/LINKUP_AGENT_QUERY_MENTAL_MODEL.md` |
| Write or improve a single search query | `knowledge/LINKUP_PROMPT_OPTIMIZER_KNOWLEDGE.md` |
| Browse workflow patterns and domain playbooks (enrichment, monitoring, verification, answer engines, legal/medical/financial/dev) | `knowledge/LINKUP_WORKFLOW_GUIDE.md` |
| Assemble a specific goal into an executable chain of steps with handoffs | `knowledge/LINKUP_WORKFLOW_OPTIMIZER_KNOWLEDGE.md` |
| Choose between `/search`, `/research`, and `/extract` | `knowledge/LINKUP_SPECIALIZED_ENDPOINTS.md` |
| Find a ready-made recipe to adapt | `workflows/` (see `workflows/README.md`) |

The `skills/` directory packages this same knowledge as installable
[Agent Skills](https://skills.sh/) (`npx skills add LinkupPlatform/skills`).
When reading this repo directly, use `knowledge/` and `workflows/` as the
source of truth — the copies under `skills/*/references/` are kept in sync
with them.

## Core rules that apply everywhere

- **Optimize for retrieval, not prose.** A Linkup query is an instruction to a retrieval system.
  Make the intended plan obvious: what to find, where to look, which fields to extract, and what
  counts as enough evidence.
- **Choose the request shape first.** Pick `depth` and `outputType` and any hard API filters
  (`includeDomains`, `excludeDomains`, `fromDate`, `toDate`) before writing the query text.
- **Never invent URLs, domains, or entities.** If a URL must be discovered before scraping, use
  `deep` and say "first find, then scrape."
- **Preserve source URLs** so every claim can be verified.
- **Use the smallest capable endpoint.** `fast`/`standard` for quick lookups, `deep` for
  discover-then-scrape chains, `/research` for multi-source investigations that can take minutes,
  `/extract` for bulk structured records from a known page.

## Typical flow

1. Read the user's goal and identify inputs, desired outputs, and consumer (human, code, CRM).
2. Pick the pattern in `LINKUP_WORKFLOW_GUIDE.md` (or a recipe in `workflows/`).
3. For each step, use `LINKUP_AGENT_QUERY_MENTAL_MODEL.md` to choose the shape, then
   `LINKUP_PROMPT_OPTIMIZER_KNOWLEDGE.md` for exact wording.
4. If a step needs deep investigation or bulk extraction, consult
   `LINKUP_SPECIALIZED_ENDPOINTS.md`.
