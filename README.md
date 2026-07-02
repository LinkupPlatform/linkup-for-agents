# Linkup for Agents

A context pack that teaches AI coding agents how to use [Linkup](https://www.linkup.so) well.

Linkup is a web search API built for AI applications: real-time search, citation-backed answers,
deep research, page fetching, structured JSON output, and source control. This repository gives your
agent everything it needs to turn a plain-language goal into effective Linkup API calls and
multi-step workflows.

## Who this is for

- **Builders** who want to plug Linkup into their product (enrichment, chatbots, research agents,
  monitoring, verification) but don't yet know which calls to make.
- **Coding agents** (Cursor, Claude Code, and similar) that need reliable, up-to-date context on how
  Linkup behaves so they write correct calls the first time.

## How to use it

**Option 1 — Install the skills (recommended for coding agents).**
The pack's skills are published as a standalone registry entry. One command
installs auto-loading skills into your project — your agent references them
whenever a task involves web search, extraction, research, or workflow
design:

```bash
npx skills add LinkupPlatform/skills
```

**Option 2 — Give the whole repo to your coding agent.**
Clone this repo to get the full pack — knowledge files, workflow recipes,
and the skills — then tell your agent to read `AGENTS.md` first. It will
route itself to the right document based on your task.

```bash
git clone https://github.com/LinkupPlatform/linkup-for-agents.git
```

**Option 3 — Point your agent at one file.**
If you already know what you need, drop a single file into your agent's context:

- Writing one good search query → `knowledge/LINKUP_PROMPT_OPTIMIZER_KNOWLEDGE.md`
- Designing a multi-step agent workflow → `knowledge/LINKUP_WORKFLOW_GUIDE.md`
- Choosing between Search and Research → `knowledge/LINKUP_SPECIALIZED_ENDPOINTS.md`

## What's inside

### `knowledge/` — how Linkup works and how to prompt it

| File | Use it to |
|------|-----------|
| `LINKUP_API_REFERENCE.md` | Get the big picture: endpoints, output types, depth, domain controls, auth. Start here if you're new to Linkup. |
| `LINKUP_AGENT_QUERY_MENTAL_MODEL.md` | Reason from a data request to the right request shape (depth, output type, chaining) before writing a query. |
| `LINKUP_PROMPT_OPTIMIZER_KNOWLEDGE.md` | Write an exact, high-quality query: depth rules, templates, source constraints, LinkedIn wording, and known bad patterns. |
| `LINKUP_WORKFLOW_GUIDE.md` | Map a business goal to a workflow. Eight patterns: enrichment, research, monitoring, verification, content generation, procurement, answer engines, and verticalized agents. |
| `LINKUP_WORKFLOW_OPTIMIZER_KNOWLEDGE.md` | Turn a goal into a chain of Linkup steps with inputs, outputs, and handoffs to other tools. |
| `LINKUP_SPECIALIZED_ENDPOINTS.md` | Decide when to use the async `/research` agent or the `/extract` endpoint instead of `/search`. |

### `workflows/` — ready-to-adapt recipes

Concrete, copy-and-fill workflow templates organized by team:

- `sales/` — lead lists, account enrichment, buyer discovery, outbound personalization, monitoring
- `marketing/` — content research, competitor messaging, campaign angles, proof mining, SEO sources
- `research/` — meeting prep, company dossiers, market maps, competitor and funding trackers, sector
  risk and technical landscape reports

Each recipe follows the format in `workflows/WORKFLOW_SCHEMA.md`.

### `skills/` — installable, auto-loading skills

The same knowledge packaged as [Agent Skills](https://skills.sh/), one
self-contained directory per capability. They ship here as part of the full
pack and are published for one-command install as
`npx skills add LinkupPlatform/skills`. Once installed, they load
automatically when a matching task comes up:

| Skill | Use for |
|-------|---------|
| `linkup-search` | Any web lookup or research query — the default |
| `linkup-fetch-url` | Reading one known URL as clean Markdown |
| `linkup-deep-research` | Minutes-long, multi-source investigations (`/v1/research`) |
| `linkup-bulk-extract` | Bulk structured rows from one listing page (`/v1/extract`) |
| `linkup-build-workflow` | Turning a business goal into a multi-step workflow |

Each skill bundles the knowledge files it needs in its own `references/`
directory, so it works standalone after install. The `knowledge/` and
`workflows/` directories remain the canonical source; skill copies are
kept in sync with them.

## Suggested reading order

1. `knowledge/LINKUP_API_REFERENCE.md` — what Linkup can do.
2. `knowledge/LINKUP_AGENT_QUERY_MENTAL_MODEL.md` — how to think before querying.
3. `knowledge/LINKUP_PROMPT_OPTIMIZER_KNOWLEDGE.md` — how to write the query.
4. `knowledge/LINKUP_WORKFLOW_GUIDE.md` and `LINKUP_WORKFLOW_OPTIMIZER_KNOWLEDGE.md` — how to compose steps.
5. `workflows/` — worked examples to adapt.

## License

MIT — see [LICENSE](LICENSE).
