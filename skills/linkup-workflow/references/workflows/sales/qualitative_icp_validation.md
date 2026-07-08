---
id: sales.qualitative_icp_validation
title: Qualitative ICP Validation & Tiering
category: sales
summary: Surface extra candidate companies for a natural-language ICP and check the qualitative traits your firmographic data can't see, against real public evidence.
user_goal: I can describe my ideal customer in plain language, but my company database only understands things like revenue, location, and industry. I want the traits it can't answer checked against real evidence, without making every user wait for every company to be checked.
inputs:
  - natural language ICP description, if the client already has one
  - the client's own website and case studies, if the ICP needs to be derived rather than given
  - the specific qualitative criteria that the firmographic schema cannot answer (for example "offers pay-as-you-go pricing")
  - a firmographically-qualified company list, if one already exists
  - industry and geography
  - the tier definition (what separates a strong match from a partial or unproven one)
outputs:
  - a plain-language ICP definition backed by the client's own customer evidence, when one had to be derived
  - extra candidate companies discovered from community and directory sources
  - a confirmed / unclear / not-found status for each qualitative criterion, per company
  - evidence snippets and source URLs behind every status
  - a tiered company list combining firmographic fit and qualitative evidence
  - a list of companies still pending deeper background verification
linkup_strength: Finds companies where a qualitative trait is actually discussed in public (forums, comparison pages, directories), then reads each company's own website and other public sources to confirm or rule out that exact trait.
handoff_tools:
  - CRM or lead workspace
  - spreadsheet
  - account enrichment workflow
---

# Qualitative ICP Validation & Tiering

## What The User Gets

A company list that goes beyond firmographic filters: for every qualitative trait the schema cannot
answer (a pricing model, a product behavior, a public reputation, a stated commitment), each candidate
gets a confirmed / unclear / not-found status, the exact evidence behind it, and a source URL.

The workflow runs in three phases, in this order:

1. **Cast a wide net.** Combine research-based and search-based discovery to build a large raw pool —
   deliberately over-inclusive, since discovery cannot tell a real match from a lookalike on its own.
2. **Validate every candidate.** Run the whole pool through the per-company check, batched into a
   handful of calls rather than one call per company. This is where the noise from phase 1 gets
   filtered out — it is the job of this phase, not a failure of phase 1.
3. **Return only what survived.** The deliverable is the validated set: `confirmed` companies, plus
   anything `unclear` that a background check later resolves. `not_found` companies are dropped from
   the delivered list, not shown as a failure.

## When To Use

Use this once an ICP has been split into two parts: criteria the firmographic schema already answers
(revenue, location, headcount, industry, recent news), and criteria it cannot — usually a specific,
checkable behavior such as a pricing model, a product capability, a hiring pattern, or a public
statement. This workflow handles the second part. If the client cannot state that qualitative
criterion cleanly yet, start with step 1 and derive it from patterns across their own customers first,
rather than guessing. The workflow also looks for candidate companies that a firmographic filter alone
would miss, because the qualitative trait is often discussed in public before it shows up in any
structured database. When the goal is a small, fast preview, `search` alone (step 2) is enough. When the
goal is a validated list to actually act on, run `research` (step 2b) for breadth and `search` (step 2)
for a targeted top-up, pool everything together, and let step 3 validate the combined set — the two
discovery steps are complementary inputs to one pool, not a choice between them.

## Inputs To Ask For

- The full natural-language ICP, in the user's own words — or, if the client cannot articulate one
  cleanly, their own website and a handful of customer case studies to derive it from.
- The qualitative criteria rewritten as concrete, checkable statements. "Flexible pricing" is not
  checkable; "offers a self-serve pay-as-you-go plan without a sales call" is.
- Any company list that already passed firmographic filtering, so it can be validated rather than
  rediscovered.
- Industry, geography, and a couple of known reference companies or competitors, to anchor the search.
- The tier definition: what counts as a strong match, a partial match, and a pass with no evidence
  either way.

## Linkup Workflow

```yaml
step: 1
name: Establish the ICP from the client's own evidence
purpose: Many clients cannot state their qualitative ICP cleanly. Derive it from patterns across their own case studies before inventing criteria.
linkup.search:
  q: Scrape {client_website} customer stories, case studies, and testimonials pages. Also run a separate web search for independent reviews and press coverage of {client_name}'s customers. Extract, for each customer mentioned, company size, industry, geography, and the specific operational problem {client_name} solved for them. Return the recurring patterns across customers and source URLs for each.
  depth: standard
  outputType: structured
  structuredOutputSchema:
    type: object
    properties:
      customer_examples:
        type: array
        items:
          type: object
          properties:
            company_name:
              type: string
            company_size:
              type: string
            problem_solved:
              type: string
            source_url:
              type: string
          required:
            - company_name
            - problem_solved
            - source_url
      recurring_patterns:
        type: array
        items:
          type: string
    required:
      - customer_examples
      - recurring_patterns
expected_behavior:
  - A known-URL scrape of the client's own site plus independent searches to cross-check it.
uses_previous_step: false
produces:
  - derived_icp_patterns
```

Skip step 1 when the client already has a specific, checkable qualitative criterion in hand. Use it
only to derive or sanity-check one from scratch.

```yaml
step: 2
name: Discover candidates from where the trait is actually discussed
purpose: Find a handful of companies fast, cheap, and synchronously — good for a first look or a quick top-up to an existing list.
linkup.search:
  q: Find companies in {industry} and {geography} that may match this qualitative trait: {qualitative_criteria}. The broader target profile is {natural_language_icp}. Run separate web searches for: Reddit and forum threads recommending or comparing {industry} tools with {qualitative_criteria}, "alternatives to {reference_competitor}" or "vs" comparison pages that mention {qualitative_criteria}, directory or "best of" list pages for {industry} tools with {qualitative_criteria}, finance/CFO/controller job postings that describe {qualitative_criteria} as part of the role, and recent funding, expansion, or hiring announcements in {industry} and {geography} that indicate {qualitative_criteria}. Return company name, website, the exact quote or snippet showing the trait, and source URL.
  depth: standard
  outputType: searchResults
expected_behavior:
  - Multiple independent web search calls, one per named facet (Reddit, comparison pages, directories, job postings, funding news). Typically returns a couple dozen raw results, several of which are candidate companies rather than aggregator pages.
uses_previous_step: derived_icp_patterns
produces:
  - candidate_companies_from_signals
```

Run step 2 alone only for a quick, small preview. For a list meant to be validated and acted on, also
run step 2b and pool both outputs before moving to step 3 — research covers breadth, search fills in
anything research missed (a specific competitor, a specific directory).

```yaml
step: 2b
name: Discover a large candidate pool via Research
purpose: A single research call can independently investigate many sources in parallel and return a large, named, sourced candidate list in one pass — the primary source of volume for a 100+ candidate pool.
linkup.research:
  q: Find as many potential ICP customers as possible for {client_name}. ICP definition: {natural_language_icp} with this qualitative trait as a hard requirement: {qualitative_criteria}. Look broadly across funding/expansion news, company directories, job boards (especially finance/CFO/controller hiring posts that describe {qualitative_criteria} as part of the role), and industry press. Do not stop at a small sample — list as many distinct qualifying companies as you can find, even if evidence for some is thinner than others. For each company, return company name and a short evidence note with a source URL.
  mode: research
  reasoningDepth: L
  outputType: structured
  structuredOutputSchema:
    type: object
    properties:
      companies:
        type: array
        items:
          type: object
          properties:
            company_name:
              type: string
            evidence:
              type: string
            source_url:
              type: string
          required:
            - company_name
    required:
      - companies
expected_behavior:
  - Runs for several minutes (5-10 at reasoningDepth L) and returns a larger, broader candidate list than a single standard search, each with its own source.
  - Keep the schema's required fields minimal (just company_name). Requiring evidence or source_url on every entry can cause the model to silently drop companies it found but couldn't cleanly cite, shrinking the list.
uses_previous_step: derived_icp_patterns
produces:
  - candidate_companies_from_signals
```

```yaml
step: 3
name: Check the criterion on every candidate's own site
purpose: Discovery is deliberately noisy — a name on a funding list is a lead, not proof. This step is what actually separates real matches from lookalikes, so it must cover the full pool from step 2 and step 2b combined, not a sample of it.
linkup.search:
  q: For each company in {firmographic_qualified_companies} and {candidate_companies_from_signals}, first find the page most likely to state this: {qualitative_criteria}. That is usually the pricing, plans, product, or documentation page. Then scrape that page. Extract whether {qualitative_criteria} is stated explicitly, the exact supporting text, and the source URL. If no relevant page is found, say so instead of guessing.
  depth: deep
  outputType: structured
  structuredOutputSchema:
    type: object
    properties:
      results:
        type: array
        items:
          type: object
          properties:
            company_name:
              type: string
            website:
              type: string
            criterion_status:
              type: string
              enum: [confirmed, not_found, unclear]
            evidence_snippet:
              type: string
            source_url:
              type: string
          required:
            - company_name
            - website
            - criterion_status
    required:
      - results
expected_behavior:
  - A find-then-scrape chain per company, since the exact page is not known in advance.
  - For a large pool (50-100+ candidates), split into batches of roughly 10-15 companies per call instead of one call per company or one call for the entire pool — small enough that the model can genuinely check each one, large enough to avoid running dozens of near-identical calls.
uses_previous_step: candidate_companies_from_signals
produces:
  - criterion_check_results
```

```yaml
step: 4
name: Send unclear cases to background verification
purpose: Some evidence is genuinely gated (a "contact sales" pricing page, a login-only product tour). Investigate those in the background instead of blocking the list on them.
linkup.research:
  q: Investigate whether {company_name} ({website}) matches this qualitative criterion: {qualitative_criteria}. Check pricing pages, product documentation, help center articles, review sites, and recent public statements. Cross-check any conflicting claims between sources. Return a clear confirmed / not_found / unclear verdict, the strongest supporting evidence, and source URLs.
  mode: investigate
  reasoningDepth: S
  outputType: structured
  structuredOutputSchema:
    type: object
    properties:
      company_name:
        type: string
      verdict:
        type: string
        enum: [confirmed, not_found, unclear]
      evidence:
        type: string
      source_urls:
        type: array
        items:
          type: string
    required:
      - company_name
      - verdict
      - source_urls
expected_behavior:
  - Runs asynchronously, one job per company still marked unclear after step 3.
  - Does not block the first tiered list from being shown.
uses_previous_step: criterion_check_results
produces:
  - background_verification_results
```

```yaml
step: 5
name: Build the validated recommendation list
purpose: Combine firmographic fit with the on-site check, drop everything that didn't hold up, and upgrade results as background jobs complete.
linkup.search:
  q: Using firmographic fit for {firmographic_qualified_companies}, on-site criterion checks {criterion_check_results}, and any completed background verification {background_verification_results}, assign each company a tier using this definition: {tier_definition}. Exclude any company whose criterion_status is not_found from the returned list. Return company name, website, firmographic fit, criterion status, evidence, source URLs, tier, and whether background verification is still pending.
  depth: standard
  outputType: structured
  structuredOutputSchema:
    type: object
    properties:
      companies:
        type: array
        items:
          type: object
          properties:
            company_name:
              type: string
            website:
              type: string
            firmographic_fit:
              type: string
            criterion_status:
              type: string
            evidence:
              type: string
            source_urls:
              type: array
              items:
                type: string
            tier:
              type: string
            background_verification_pending:
              type: boolean
          required:
            - company_name
            - website
            - criterion_status
            - tier
            - source_urls
    required:
      - companies
expected_behavior:
  - Structured synthesis across firmographic input and both validation steps.
uses_previous_step: criterion_check_results
produces:
  - tiered_company_list
```

## Output Contract

The delivered list contains only `confirmed` companies, plus `unclear` ones still pending a background
job. `not_found` companies are excluded from the deliverable — keep them in an internal log for
auditability, but do not present them as recommendations.

- `company_name`
- `website`
- `firmographic_fit`
- `criterion_status` (`confirmed`, or `unclear` pending background verification)
- `evidence_snippet`
- `source_urls`
- `tier`
- `background_verification_pending`

## Handoffs

Show the validated list immediately using step 3's on-site checks. Write tier and evidence into the CRM
or lead workspace, then update the record automatically when a step 4 background job completes and
turns an `unclear` status into `confirmed` (add it to the list) or `not_found` (drop it). Pass tier-1
companies to an account enrichment workflow for full profiling before outreach.

## Failure Modes

- Community sources are not equally useful for every criterion type. Reddit is strong for opinion-based
  criteria (people naming a tool they dislike, or describing their own setup while asking for advice),
  but posters are usually anonymous — a thread can confirm the *pattern* exists ("a 45-person company
  with US and UK offices still on spreadsheets") without ever naming the company. Treat these as
  validation of the pattern, not as named candidates, and rely on funding/expansion news and directory
  facets for company names instead.
- A single `standard` call that blends several facets (community, comparison pages, directories,
  funding news) can let one or two facets dominate the results and starve the others, especially when
  one facet (e.g. "best of" list content) is simply more abundant on the web than another (e.g. funding
  news). If a specific facet is producing too few results, split it into its own follow-up call rather
  than assuming the signal doesn't exist.
- Some third-party "AI intel" or "sentiment summary" sites present a bulleted list of supposed Reddit
  or forum threads with no working link back to the original post. Treat any claimed community mention
  without a resolvable source URL as unverified, and do not add it to the candidate list or evidence
  trail until an independent search finds the real thread.
- The structured schema's required fields control list size more than the query wording does. In
  testing, the identical prompt at reasoningDepth `L` returned 19 companies when `evidence` and
  `source_url` were required on every entry, and 71 when only `company_name` was required — the model
  was silently dropping companies it found but couldn't cleanly cite. If step 2b returns fewer
  candidates than expected, loosen the schema before assuming the pool itself is small.
- With the loosened schema, roughly the back third of a large list tends to be weak on its own —
  companies pulled from generic "top funded startups" listicles with no real connection to the
  qualitative criterion (e.g. "raised $100M Series C" with nothing about multi-entity operations).
  This is expected, not a discovery failure: step 2/2b's job is to cast the net, step 3's job is to
  filter it. Do not pre-filter the pool by hand before step 3 on the assumption that the weaker-looking
  entries are wrong — some of them will confirm; that is what the validation step is for.
- A single-pass "confirmed" verdict from step 3 can still be wrong for small or lesser-known companies
  with a thin web footprint — a scrape can surface a same-named or related legal entity without
  enough context to tell if it is the same company. Route anything with ambiguous entity identity to
  step 4 even if step 3 labeled it "confirmed," and let the deeper, multi-source background check
  (official filings, funding press, YC/Crunchbase profiles) make the final call.
- A Reddit or forum mention can be outdated, biased, or about a different company with a similar name.
  Confirm the official website before treating a mention as evidence, and treat community discovery as
  a lead to check, not as proof on its own.
- Pricing and product pages are often gated behind "contact sales" or a login. Mark these `unclear` and
  route them to background verification instead of guessing a tier.
- Background research has a real cost per company. Only escalate companies that already passed
  firmographic filtering and came back `unclear` from step 3, not the full candidate pool.
- If the natural-language ICP bundles several qualitative traits into one sentence, split each into
  its own checkable statement before running step 2 and step 3, so every search stays narrow.
