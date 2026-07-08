---
id: sales.qualitative_icp_validation
title: Qualitative ICP Validation & Tiering
category: sales
summary: Surface extra candidate companies for a natural-language ICP and check the qualitative traits your firmographic data can't see, against real public evidence.
user_goal: I can describe my ideal customer in plain language, but my company database only understands things like revenue, location, and industry. I want the traits it can't answer checked against real evidence, without making every user wait for every company to be checked.
inputs:
  - natural language ICP description
  - the specific qualitative criteria that the firmographic schema cannot answer (for example "offers pay-as-you-go pricing")
  - a firmographically-qualified company list, if one already exists
  - industry and geography
  - the tier definition (what separates a strong match from a partial or unproven one)
outputs:
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
gets a confirmed / unclear / not-found status, the exact evidence behind it, and a source URL. Strong
matches are surfaced immediately; borderline cases are sent to a background check instead of blocking
the list.

## When To Use

Use this once a natural-language ICP has already been split into two parts: criteria the firmographic
schema already answers (revenue, location, headcount, industry, recent news), and criteria it cannot
— usually a specific, checkable behavior such as a pricing model, a product capability, a hiring
pattern, or a public statement. This workflow handles the second part. It also looks for candidate
companies that a firmographic filter alone would miss, because the qualitative trait is often
discussed in public before it shows up in any structured database.

## Inputs To Ask For

- The full natural-language ICP, in the user's own words.
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
name: Discover candidates from where the trait is actually discussed
purpose: Find companies a firmographic filter would miss, because the qualitative trait shows up in public discussion before it shows up in any database.
linkup.search:
  q: Find companies in {industry} and {geography} that may match this qualitative trait: {qualitative_criteria}. The broader target profile is {natural_language_icp}. Run separate web searches for: Reddit threads recommending or comparing {industry} tools with {qualitative_criteria}, "alternatives to {reference_competitor}" or "vs" comparison pages that mention {qualitative_criteria}, and directory or "best of" list pages for {industry} tools with {qualitative_criteria}. Return company name, website, the exact quote or snippet showing the trait, and source URL.
  depth: standard
  outputType: searchResults
expected_behavior:
  - Multiple independent web search calls, one per named facet (Reddit, comparison pages, directories).
uses_previous_step: false
produces:
  - candidate_companies_from_signals
```

```yaml
step: 2
name: Check the criterion on each candidate's own site
purpose: A forum mention is a lead, not proof. Confirm or rule out the exact criterion using the company's own public pages.
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
uses_previous_step: candidate_companies_from_signals
produces:
  - criterion_check_results
```

```yaml
step: 3
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
  - Runs asynchronously, one job per company still marked unclear after step 2.
  - Does not block the first tiered list from being shown.
uses_previous_step: criterion_check_results
produces:
  - background_verification_results
```

```yaml
step: 4
name: Build the tiered recommendation list
purpose: Combine firmographic fit with the on-site check, and upgrade results as background jobs complete.
linkup.search:
  q: Using firmographic fit for {firmographic_qualified_companies}, on-site criterion checks {criterion_check_results}, and any completed background verification {background_verification_results}, assign each company a tier using this definition: {tier_definition}. Return company name, website, firmographic fit, criterion status, evidence, source URLs, tier, and whether background verification is still pending.
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

- `company_name`
- `website`
- `firmographic_fit`
- `criterion_status` (`confirmed`, `not_found`, `unclear`)
- `evidence_snippet`
- `source_urls`
- `tier`
- `background_verification_pending`

## Handoffs

Show the tiered list immediately using step 2's on-site checks. Write tier and evidence into the CRM
or lead workspace, then update the record automatically when a step 3 background job completes and
turns an `unclear` status into `confirmed` or `not_found`. Pass tier-1 companies to an account
enrichment workflow for full profiling before outreach.

## Failure Modes

- A Reddit or forum mention can be outdated, biased, or about a different company with a similar name.
  Confirm the official website before treating a mention as evidence, and treat community discovery as
  a lead to check, not as proof on its own.
- Pricing and product pages are often gated behind "contact sales" or a login. Mark these `unclear` and
  route them to background verification instead of guessing a tier.
- Background research has a real cost per company. Only escalate companies that already passed
  firmographic filtering and came back `unclear` from step 2, not the full candidate pool.
- If the natural-language ICP bundles several qualitative traits into one sentence, split each into
  its own checkable statement before running step 1 and step 2, so every search stays narrow.
