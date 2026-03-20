# Regulatory Response Copilot MVP Implementation Plan

**For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a hackathon-ready Next.js MVP that turns a regulatory question into a grounded, evidence-backed response plan by interpreting the request, retrieving the most relevant example assets in this repository, and generating a traceable draft that a human can review and refine.

**Architecture:** Keep the app as a single server-first Next.js application. Ingest `README.md`, `docs/examples/define.xml`, and the SAS example programs into a local typed knowledge base at build time. Run a three-stage copilot pipeline on the server: request interpretation -> hybrid evidence retrieval -> grounded response-plan generation. Present each stage side by side in the UI so users can see the interpretation, the evidence, and the generated plan before trusting it.

**Tech Stack:** Next.js App Router, React 19, TypeScript, shadcn UI, Tailwind CSS, Zod, OpenAI SDK against Bayer myGenAssist v2, `fast-xml-parser`, `minisearch`, Vitest, Testing Library, `tsx`

## Executive Summary

The repository already contains the frontend foundation, but none of the actual hackathon workflows. The strongest implementation direction is not "chat with all files" and not "generate a final agency response." The best MVP is a **regulatory response planning copilot** that:

1. Accepts a regulatory question.
2. Converts it into a structured analysis intent.
3. Retrieves the most relevant study assets from the supplied examples.
4. Produces a grounded starter plan with explicit sources, assumptions, and gaps.

That direction is supported by all three evidence sources:

- `README.md` defines the product as an interpreter + knowledge search + response draft builder.
- `docs/examples/programs/*.sas` show the actual output families the tool needs to reason about: AE summary tables, SOC/PT tables, AESI follow-ups, EAIR tables, subject-level liver/INR plots, BMD subgroup figures, and derived datasets for narratives.
- `docs/examples/define.xml` provides machine-readable ADaM metadata, dataset structures, variable definitions, methods, and linked transport references that can ground recommendations for datasets, variables, and likely derivations.

## External References

Use these to justify trust and grounding decisions in implementation notes or demo narration:

- [NIST AI RMF: Generative AI Profile](https://www.nist.gov/publications/artificial-intelligence-risk-management-framework-generative-artificial-intelligence)
- [21 CFR Part 11 Subpart B](https://www.ecfr.gov/current/title-21/chapter-I/subchapter-A/part-11/subpart-B)
- [FDA Study Data Technical Conformance Guide](https://www.fda.gov/regulatory-information/search-fda-guidance-documents/study-data-technical-conformance-guide-technical-specifications-document)
- [CDISC Define-XML v2.1](https://www.cdisc.org/standards/data-exchange/define-xml/define-xml-v2-1)
- [CDISC ADaMIG v1.3](https://www.cdisc.org/standards/foundational/adam/adamig-v1-3)
- [CDISC ADaM Examples of Traceability](https://www.cdisc.org/standards/foundational/adam/adam-examples-traceability-v1-0)
- [MedDRA Data Retrieval and Presentation: Points to Consider](https://files.meddra.org/www/Website%20Files/PtCs/001175_datretptc_r3_25_mar2025.htm)
- [ICH E9(R1) Addendum on Estimands](https://database.ich.org/sites/default/files/E9-R1_Step4_Guideline_2019_1203.pdf)
- [Build advanced retrieval-augmented generation systems](https://learn.microsoft.com/en-us/azure/developer/ai/advanced-retrieval-augmented-generation)
- [Guidelines for Human-AI Interaction](https://www.microsoft.com/en-us/research/project/guidelines-for-human-ai-interaction/)

## Final Outcome This Plan Targets

At the end of execution, the repository should contain a demoable regulatory-response copilot that:

- understands a narrow but credible set of regulatory-response asks
- grounds its recommendations in the supplied examples
- produces a traceable response plan instead of an opaque answer
- makes unsupported requests visibly uncertain instead of confidently wrong

## Chunk 1: MVP Execution

### Task 1: Contracts and Runtime Shell

**Files:**
- Modify: `package.json`
- Create: `vitest.config.ts`
- Create: `vitest.setup.ts`
- Create: `lib/server/env.ts`
- Create: `lib/server/copilot/schemas.ts`
- Create: `lib/copilot/demo-prompts.ts`

- [ ] Add the runtime and test dependencies from the plan: `zod`, `fast-xml-parser`, `minisearch`, `openai`, `vitest`, `@testing-library/react`, `@testing-library/jest-dom`, `jsdom`, and `tsx`.
- [ ] Add scripts for `test`, `test:watch`, and `ingest` without removing the existing `dev`, `build`, and `lint` flows.
- [ ] Add Vitest config and setup so Node-side parser tests and lightweight React component tests can run in this repo.
- [ ] Add `lib/server/env.ts` to centralize server-only environment access and optional `MGA_TOKEN` plus optional `MGA_MODEL` handling.
- [ ] Add `lib/server/copilot/schemas.ts` with Zod contracts for request interpretation, evidence documents, evidence hits, response plans, assumptions, open questions, and evidence gaps.
- [ ] Add `lib/copilot/demo-prompts.ts` with a narrow set of example asks biased toward AE summary, SOC/PT, AESI, EAIR, liver/CLO, and `ADLB`/figure scenarios.
- [ ] Run `npm run lint` to confirm the shell compiles cleanly before adding domain logic.

**Acceptance Criteria:**
- The repo can run `npm run test` and `npm run ingest`.
- Typed schemas exist for every stage of the copilot pipeline.
- Demo prompts reflect the example-backed use cases called out in `AGENTS.md`.

### Task 2: Evidence Ingestion

**Files:**
- Create: `lib/server/knowledge/parse-readme.ts`
- Create: `lib/server/knowledge/parse-define-xml.ts`
- Create: `lib/server/knowledge/parse-sas-programs.ts`
- Create: `lib/server/knowledge/build-corpus.ts`
- Create: `scripts/build-knowledge-base.ts`
- Create: `data/copilot/evidence-corpus.json`
- Create: `tests/server/knowledge/parse-define-xml.test.ts`
- Create: `tests/server/knowledge/parse-sas-programs.test.ts`

- [ ] Write the failing tests for `define.xml` parsing so the build emits typed metadata for at least `ADSL`, `ADAE`, `ADCM`, `ADLB`, `ADTTE`, and `ADVS`.
- [ ] Run the parser tests and confirm they fail because the ingestion code does not exist yet.
- [ ] Implement `parse-define-xml.ts` to extract dataset descriptions, structure/class metadata, transport leaf references, and selected variable metadata needed for grounding.
- [ ] Write the failing tests for SAS program parsing so the build emits 10 typed records with program purpose, datasets used, and output family tags.
- [ ] Run the SAS parser tests and confirm they fail for the expected reason.
- [ ] Implement `parse-sas-programs.ts` to extract header metadata plus deterministic heuristics for AE overall, SOC/PT, AESI, EAIR, liver/CLO, BMD, and derived dataset patterns.
- [ ] Implement `parse-readme.ts` and `build-corpus.ts` so the README brief, define metadata, and SAS program summaries become one typed evidence corpus.
- [ ] Implement `scripts/build-knowledge-base.ts` and generate `data/copilot/evidence-corpus.json`.
- [ ] Run `npm run test` and `npm run ingest` to confirm the corpus is deterministic and repo-local.

**Acceptance Criteria:**
- `npm run ingest` writes a stable typed corpus file.
- The corpus contains one README brief entry, define metadata for the targeted analysis datasets, and 10 SAS example program entries.
- The corpus is grounded only in repo evidence.

### Task 3: Interpretation and Retrieval

**Files:**
- Create: `lib/server/llm/openai.ts`
- Create: `lib/server/copilot/prompts.ts`
- Create: `lib/server/copilot/interpret-request.ts`
- Create: `lib/server/copilot/query-terms.ts`
- Create: `lib/server/copilot/knowledge-base.ts`
- Create: `lib/server/copilot/retrieve-evidence.ts`
- Create: `tests/server/copilot/retrieve-evidence.test.ts`

- [ ] Write the failing retrieval tests for a few representative requests such as AE summary, AESI fatigue, liver/CLO, and BMD subgroup asks.
- [ ] Run those tests and confirm the expected failures before implementing the retrieval pipeline.
- [ ] Implement `knowledge-base.ts` to load the generated corpus on the server and expose typed accessors only.
- [ ] Implement `query-terms.ts` so interpreted asks expand into deterministic search terms, dataset hints, output-family hints, and ranking clues.
- [ ] Implement `retrieve-evidence.ts` with metadata-first scoring and `minisearch` text lookup so every hit has a score, source path, source type, reuse reason, and matched dataset or output-family tags.
- [ ] Implement `openai.ts`, `prompts.ts`, and `interpret-request.ts` so interpretation stays server-side, uses the OpenAI SDK against Bayer myGenAssist v2 at `https://chat.int.bayer.com/api/v2`, defaults to the verified free GPT-5 slug `gpt-5`, validates against Zod, and can fall back to deterministic heuristics when no `MGA_TOKEN` is available.
- [ ] Run `npm run test` to confirm representative queries retrieve the expected evidence families.

**Acceptance Criteria:**
- Interpretation returns typed fields instead of free-form chat.
- Retrieval cites concrete repo assets and explains why they were surfaced.
- No client-side LLM calls are introduced.

### Task 4: Grounded Plan Orchestration

**Files:**
- Create: `app/actions/run-copilot.ts`
- Create: `lib/server/copilot/generate-plan.ts`
- Create: `lib/server/copilot/run-copilot.ts`
- Create: `tests/server/copilot/run-copilot.test.ts`

- [ ] Write the failing orchestration tests for the end-to-end `interpret -> retrieve -> generate` flow.
- [ ] Run those tests and confirm the failure is caused by missing orchestration code rather than broken test setup.
- [ ] Implement `generate-plan.ts` so the output is a grounded internal response plan with objectives, data sources, candidate prior outputs, recommended actions, assumptions, open questions, and evidence gaps.
- [ ] Implement `run-copilot.ts` to orchestrate interpretation, retrieval, and plan generation into one serializable result object.
- [ ] Implement the server action in `app/actions/run-copilot.ts` so the UI can submit a request without exposing provider credentials to the browser.
- [ ] Run `npm run test` to confirm unsupported requests become visibly uncertain instead of confidently specific.

**Acceptance Criteria:**
- The returned object includes interpretation, evidence, plan, warnings, assumptions, open questions, and gaps.
- The plan is framed as a traceable starting point for SPA teams, not a final authority-facing response.
- Weak evidence stays visible in the result.

### Task 5: Demo UI Workbench

**Files:**
- Modify: `app/page.tsx`
- Modify: `app/globals.css`
- Create: `components/copilot/copilot-workbench.tsx`
- Create: `components/copilot/question-form.tsx`
- Create: `components/copilot/interpretation-panel.tsx`
- Create: `components/copilot/evidence-panel.tsx`
- Create: `components/copilot/response-plan-panel.tsx`

- [ ] Write the failing component test, if needed, for the workbench shell or otherwise identify the smallest UI seam to exercise.
- [ ] Replace the current static homepage with a single copilot workbench that keeps the existing visual language but centers the regulatory workflow.
- [ ] Add a top-level question form with one-click sample prompts from `lib/copilot/demo-prompts.ts`.
- [ ] Add side-by-side panels for interpretation, evidence, and generated response plan.
- [ ] Add explicit empty, loading, success, and error states so the demo flow is legible even when evidence is weak or the provider is unavailable.
- [ ] Run `npm run lint` and the targeted tests to confirm the workbench is stable.

**Acceptance Criteria:**
- The home page demonstrates the full `interpret -> evidence -> plan` story in one screen.
- Sample prompts make the supported use cases easy to demo.
- The UI never hides uncertainty or grounding details.

### Task 6: Verification and Docs

**Files:**
- Modify: `README.md`
- Modify: `package.json`

- [ ] Update `README.md` with local setup, `npm run ingest`, `npm run test`, `npm run dev`, `npm run build`, and `MGA_TOKEN` usage notes, including the Bayer v2 base URL and default `gpt-5` model.
- [ ] Document the demo flow as: paste question -> interpret request -> review evidence -> review grounded response plan.
- [ ] Run `npm run ingest`.
- [ ] Run `npm run lint`.
- [ ] Run `npm run test`.
- [ ] Run `npm run build`.
- [ ] Only after all checks pass, move to final review and branch-completion steps.

**Acceptance Criteria:**
- The repo is demoable from a clean install.
- Verification commands are documented and runnable.
- Scope stays hackathon-small: no auth, no uploads, no vector DB, and no stretch task board.
