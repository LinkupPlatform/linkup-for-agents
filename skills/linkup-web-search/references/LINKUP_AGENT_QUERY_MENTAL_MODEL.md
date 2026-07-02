# Linkup Agent Query Mental Model

Use this document before writing a Linkup Search API request. It teaches the agent how to reason from
a user's data request to the right retrieval shape.

This is the thinking guide, not the rulebook. After choosing the request shape, use
`LINKUP_PROMPT_OPTIMIZER_KNOWLEDGE.md` for exact depth rules, templates, source constraints,
LinkedIn wording, local-place rules, and bad patterns.

## What This File Is For

Use this file to answer:

- What data does the user already provide?
- What data should Linkup return?
- Which `depth`, `outputType`, and API parameters fit the job?
- How should the query exploit that depth?
- Should the agent make one Linkup call, chain calls outside Linkup, or let `deep` chain work inside
  Linkup?

Do not use this file as the source for exact prompt templates. Use the prompt optimizer knowledge
file for that.

## Core Principle

Do not start by writing `q`.

First choose the request shape:

1. Pick `depth`.
2. Pick `outputType`.
3. Pick hard API parameters.
4. Decide whether the work is independent or sequential.
5. Then write the query so Linkup's retrieval plan is obvious.

The query should not merely describe the user's goal. It should describe how Linkup should retrieve
the evidence.

## Step 1: Read The Data Request

Convert the user's request into a data contract.

Identify:

- Input: names, URLs, domains, LinkedIn URLs, SIREN/SIRET numbers, date ranges, geography, source
  families, or entity lists.
- Output: facts, fields, source URLs, full page content, a direct answer, or structured data.
- Constraints: official sources, freshness, country, domain, image requirement, confidence rule, or
  "say none found" behavior.
- Consumer: human reader, downstream agent, code, CRM, database, or spreadsheet.

This step prevents the agent from writing broad prompts like "tell me about X" when the real job is
to retrieve specific evidence.

## Step 2: Choose The Request Shape

Choose the smallest Linkup request shape that can produce the required evidence.

Use `fast` when the job is one simple lookup and snippets are enough.

Use `standard` when all useful retrieval work can be planned upfront.

Use `deep` when later retrieval depends on earlier results.

Use `searchResults` when another agent or application will inspect, rank, chain, or synthesize
sources.

Use `sourcedAnswer` when a human needs a direct answer with citations.

Use `structured` when software needs fields. Always include `structuredOutputSchema`.

Use API parameters for hard constraints such as domains, dates, images, and result limits.

Important: `fetch` can read page content, but it cannot produce structured output from a page. If the
final result must be structured fields, use Search API with `outputType: structured`.

## Step 3: Match Query Shape To Depth

### `standard`: Parallel Work Planned Upfront

Think of `standard` as upfront fan-out.

It is strongest when the query clearly separates independent work:

- several targeted web searches
- adjacent keyword searches for wider news or incident coverage
- a known URL scrape plus independent searches
- a known LinkedIn URL extraction
- structured extraction when the fields and schema are known

The query should list separate facets, entities, source families, or adjacent keywords. This helps
Linkup run separate targeted tool calls instead of one mixed search.

Do not ask `standard` to discover a URL and then scrape that discovered URL in the same request. Use
`deep`, or have the outer agent run one call to discover the URL and another call to read it.

### `deep`: Sequential Result Reuse

Think of `deep` as search, inspect, then reuse.

It is strongest when the query describes a dependency chain:

- find the official page, then scrape it
- find relevant LinkedIn URLs, then extract data from them
- search for likely source pages, then read the best pages
- follow relevant links from a discovered page
- verify a claim across multiple discovered sources

The query should use ordered language such as `first`, `then`, `after that`, and `if the page links
to`. This tells Linkup which results should feed later retrieval.

## Step 4: Decide Whether To Chain Outside Linkup

The agent can choose between one deeper Linkup call and several simpler calls.

Use one `deep` call when Linkup should handle the dependency chain internally.

Use several `standard` or Search API calls when the outer agent should inspect intermediate results,
choose the next URL or entity, apply business logic, or combine Linkup with other tools.

Use known URL scraping or full-content reading only when the page to read is already known, or after
a previous search step has selected the best URL.

## Step 5: Write The Query As A Retrieval Plan

The final query should make these choices visible:

- target entities or URLs
- independent searches that can run in parallel
- sequential steps that must happen in order
- adjacent keywords when coverage matters
- exact output fields
- source preferences and hard evidence rules
- what to do when no relevant source is found

For `sourcedAnswer`, guide which sources matter and how claims should be cited.

For `structured`, make the query fields match the schema fields.

For LinkedIn, name the exact action: profile details, posts, post search, comments, or profile URLs
as evidence. Use `standard` when the LinkedIn URL is known and `deep` when Linkup must find it first.

## Final Check

Before sending the request, verify:

- The depth matches the retrieval pattern.
- `standard` is used for upfront fan-out, not hidden sequencing.
- `deep` is used for result reuse, not just because the request feels important.
- The query names exact fields and source rules.
- Hard constraints are set as API parameters.
- `structured` has a schema.
- The query does not invent URLs, domains, entities, or facts.

If the agent needs exact wording examples, continue in `LINKUP_PROMPT_OPTIMIZER_KNOWLEDGE.md`.
