# Linkup Prompt Optimizer Knowledge

Use this file as the compact production knowledge base for a prompt optimizer that rewrites user
objectives into better Linkup Search API calls.

This is the detailed rulebook. Use `LINKUP_AGENT_QUERY_MENTAL_MODEL.md` first when an agent needs to
decide the request shape, then use this file for exact depth behavior, query templates, source
constraints, output type rules, LinkedIn wording, local-place rules, and known bad patterns.

The optimizer should output:

- `q`
- `depth`
- `outputType`
- optional API parameters such as `includeDomains`, `excludeDomains`, `fromDate`, `toDate`, and
  `maxResults`

## Core Goal

Optimize for retrieval behavior, not prose quality. The query sent to Linkup is an instruction to a
retrieval system. Good queries make the intended retrieval plan obvious:

- what information to find
- where to search, if known
- which URLs to scrape, if known or discoverable
- which fields to extract
- whether work can happen in parallel or must happen step by step
- what counts as enough evidence

Score rewrites on:

1. right tool calls
2. right source set
3. enough relevant response content
4. source URLs preserved for verification

A rewrite can improve tool calls and still fail if it narrows to the wrong sources.

## How Linkup Uses The Query

The Search API receives a request with a query, depth, output type, and optional domain/date
filters and image flag.

The high-level flow is:

1. Use the query and API settings to choose which retrieval actions to run.
2. Execute those actions (web search, scraping, and other tools).
3. Optionally format the retrieved evidence into a sourced answer or structured JSON.
4. Return the answer and its sources.

The answer-formatting step does not decide which pages to search or scrape. Query optimization
mainly affects the retrieval step.

## Depth Rules

Use `fast` when:

- the user needs one simple, latency-sensitive lookup
- snippets are enough
- the query can be short and keyword-like
- latency matters more than interpretation

`fast` is not agentic. In current behavior, it sends the query directly to a single web search.
Prompt wording will not make `fast` scrape, chain, or decompose the task.

Good:

```text
Stripe CEO
```

Bad:

```text
First find Stripe's pricing page, then scrape it and extract plan details.
```

Use `standard` when:

- one or a few independent web searches can answer the request
- a single known URL needs scraping
- one known URL needs scraping and several independent searches can run in parallel
- all independent facets can be named up front

`standard` is one planning turn. It can run multiple independent searches in parallel and can scrape a
URL already present in the query. It cannot reliably find a URL and then scrape that discovered URL in
the same request.

Good:

```text
Find Datadog's latest annual recurring revenue and customer count over $100k ARR.
Run separate searches for each metric and prefer investor relations sources.
```

```text
Scrape https://example.com/pricing. Extract plan names, prices, limits, and included features.
```

Bad for `standard`:

```text
Find Acme's pricing page, then scrape it and extract every plan.
```

That needs `deep` unless the pricing URL is already known.

Use `deep` when:

- the URL must be discovered before scraping
- multiple discovered pages need scraping
- the task needs follow-up retrieval after seeing results
- evidence likely lives inside full pages rather than snippets
- a human would open several tabs, follow leads, or verify multiple constraints

`deep` can search first, inspect results, then scrape URLs found by the previous step. Use explicit
step wording so the order is obvious.

Good:

```text
First find Acme's official pricing page. Then scrape it. Extract every plan name, price, billing
unit, limits, and included features. If the pricing page links to add-ons or enterprise details,
scrape those pages too.
```

## Query Shape

A good optimized query includes:

1. Target: entity, topic, URL, domain, person, or source family.
2. Retrieval action: `find`, `search`, `scrape`, `extract`, `count`, or `compare`.
3. Scope: official site, docs, pricing, investor relations, country, date range, or domain.
4. Fields: exact data to extract.
5. Order: only when using `deep`.
6. Evidence rule: source URL for each claim.

If an entity name can be confused with a common term, product, or model name, quote the exact entity
and add a disambiguator. Example: `"Clause AI" legal-tech startup`, not `Clause AI`, which can drift
toward Claude-related results.

For short acronyms, expand the phrase inside each facet instead of using acronym-only searches.
Example: use `Airbus "Engineering Bill of Materials" EBOM`, not only `Airbus EBOM`.

## Retrieval Shape

Classify the user's objective before writing the query:

- Single known fact: use `fast` or `standard`; concise keyword query.
- A few independent facts: use `standard`; ask for separate searches per fact.
- One known URL to read: use `standard` or `/fetch`; say "scrape" and list extraction fields.
- Unknown URL then page extraction: use `deep`; say "first find, then scrape."
- Multiple known URLs: use `deep`, or several parallel `standard`/`fetch` calls outside one request.
- Multi-entity or multi-dimension research: use `deep`; make the structure explicit.
- Parsed downstream data: use `structured` with a shallow schema.

## Standard Templates

### Independent Facets

```text
Find {objective}. Run separate web searches for: {facet_1}, {facet_2}, and {facet_3}. Prefer
{source_type}. Return {fields} and source URLs for each finding.
```

For `standard`, independent breadth is the main lever. Do not ask for repeated rewordings of the same
search. Ask for distinct facets, entities, dates, or source types.

### Known URL

```text
Scrape {url}. Extract {field_1}, {field_2}, and {field_3}. Preserve the source URL.
```

### Known URL Plus Parallel Searches

```text
Scrape {url}. Also run separate web searches for: {facet_1}, {facet_2}, and {facet_3}. Return the
source URL for each finding.
```

Use this when the user has one known page and also wants external context.

## Deep Templates

### Discover Then Scrape

```text
First find the official {page_type} for {entity}. Then scrape it. Also run a separate web search for
{related_context}. Extract {fields}. Return source URLs for each finding.
```

Do not be stingy in `deep`: if extra context is useful, ask for the extra web search directly rather
than conditionally.

### Multi-Page Extraction

```text
First find the official website for {entity}. Then scrape the homepage, about page, and relevant
product/docs/pricing pages. Also run separate web searches for {facet_1}, {facet_2}, and {facet_3}.
Extract {fields} and source URLs.
```

### Counting or Ranking

```text
Find the authoritative full list for {category}. Scrape the full list or table. Count only items
that meet {criteria}. Enumerate included and excluded items before giving the final count.
```

### Ambiguous Entity

```text
Find and scrape pages about {entity}, the {disambiguating_description}, at {domain}. Extract
{fields}. Prefer official pages and documentation.
```

Use with:

```json
{
  "includeDomains": ["{domain}"]
}
```

Only add `includeDomains` when the user provided the domain, a previous result found it, or the
domain is otherwise explicit. Do not invent domains.

## Tool-Specific Rules

### Web Search

Use search when the URL is unknown or the task is a simple fact lookup.

Prompts that steer search well:

```text
Find Snowflake's latest annual revenue from its most recent earnings release.
```

```text
Search for recent OpenAI partnership announcements. Run separate searches for funding, product
launches, and partnerships.
```

Names, noun phrases, unclear queries, and numbers without an explicit SIREN/SIRET are treated as web
search tasks.

### Web Scraping

Use scraping when the URL is known, or in `deep` after search results reveal a URL.

Prompts that steer scraping well:

```text
Scrape https://company.com/careers. Extract open roles, locations, departments, and seniority.
```

```text
First find the official annual report PDF for TotalEnergies 2024. Then scrape it and extract total
revenue, net income, and capex.
```

Do not invent URLs. If the optimizer wants scraping, it should either provide the exact URL or use
`deep` and say "first find the official URL, then scrape it."

### Image Search

The image tool is hidden unless `includeImages` is true. If images matter, the API parameter matters
more than query wording. With images enabled, ask for image search directly.

### LinkedIn

For LinkedIn, use direct wording that names the LinkedIn action: profile details, posts, post search,
or comments.

```text
Return the LinkedIn company profile details for {linkedin_profile_or_company_url}.
```

```text
Return the last 10 LinkedIn posts of {linkedin_profile_or_company_url}.
```

```text
Search LinkedIn posts about {topic}. Return post URLs, authors, dates, and post text snippets.
```

```text
Extract comments from {linkedin_post_url}
```

```text
Return the last 10 LinkedIn comments of {linkedin_profile_or_company_url}
```

Avoid verbose comments prompts. In practice, this phrasing routed to normal scraping instead of the
LinkedIn comments action:

```text
Extract the comments from this LinkedIn post: {url}. Return commenter names, profile URLs, comment
text, and dates.
```

When the task only needs LinkedIn profile URLs as evidence, say so explicitly:

```text
Extract LinkedIn profile URLs as text evidence only. Do not retrieve LinkedIn posts.
```

### Pappers, Yahoo Finance, Google Maps

Some tools are available only at certain depths. Standard requests exclude the Google Maps
and Yahoo Finance tools. Pappers should be used only when the query explicitly says a number is a
SIREN or SIRET.

Good:

```text
Use Pappers to look up the French company with SIREN 494367584.
```

Bad:

```text
Look up 494367584.
```

An unspecified number is treated as a general web search.

## Source Constraint Rules

Use hard API filters when the source family matters. Preference text such as "prefer PubMed" can be
too weak.

Use the narrowest reliable domain. A broad official domain can be noisy: `gov.uk` may return local
council pages when the real target is a statute on `legislation.gov.uk`. For legal/regulatory
questions, start with the exact statute, provision, instrument title, and narrow official domain;
only add broader government domains as a fallback.

Good for medical/guideline prompts:

```json
{
  "includeDomains": [
    "pubmed.ncbi.nlm.nih.gov",
    "pmc.ncbi.nlm.nih.gov",
    "thoracic.org",
    "ersnet.org"
  ]
}
```

For incident or local news prompts, keep the key entity in every facet:

```text
Run separate searches for: Renault ransomware claim, Renault official statement, Renault DMS/CRM
supplier involvement, and Renault French cybersecurity coverage.
```

If a narrow official domain may not contain the answer, include a fallback instruction:

```text
Search {official_domain} first. If no relevant result exists there, say none found and then search
{fallback_source_types}.
```

For rare academic, registry, or legal lookups, hard filters are not enough by themselves. Keep the
core entity, exact phrase, provision, or study design in the query, and ask Linkup to say no relevant
result was found instead of filling the answer with unrelated results from the right domain.

Use `includeDomains`, `excludeDomains`, `fromDate`, and `toDate` when those constraints are known.
These filters are enforced automatically, so the query does not need to repeat them unless it helps
clarify intent.

## Local Place Rules

For local-place prompts, preserve the exact name and native address. Do not over-normalize.

```text
Find public information for "{exact_place_name}" at "{exact_address}". Return official or social
profile, address confirmation, phone number, opening hours, category, review profile URLs if
available, and source URLs.
```

## Output Type Rules

Use `searchResults` when another agent or app will inspect, score, or synthesize sources.

Use `sourcedAnswer` when a user needs a direct answer.

Use `structured` when downstream code needs fields. Keep the schema shallow and aligned with the
query fields. Always provide `structuredOutputSchema`; do not switch a prompt to `structured` unless
the API call includes the schema.

## Known Bad Patterns

Avoid:

- keyword soup with no fields
- broad `tell me more`
- asking `standard` to discover a URL and then scrape it
- `fast` prompts with instructions or sequencing
- soft source preferences when exact source families matter
- over-polishing local place names and losing exact native spelling
- repeated rewordings of the same search instead of distinct facets
- invented URLs or invented domains
