# AGENTS.md

- Product goal: build a hackathon MVP for an evidence-backed Regulatory Response Copilot for SPA teams.
- Current state: the repo is a Next.js + TypeScript + shadcn foundation; the copilot workflow is planned but not implemented yet.
- Read these first before major work: `README.md`, `docs/superpowers/plans/2026-03-17-regulatory-response-copilot-mvp.md`, `docs/examples/define.xml`, and `docs/examples/programs/*.sas`.
- MVP scope: interpret a regulatory question, retrieve matching prior evidence, and draft a traceable response plan.
- Do not position the product as a SAS execution engine or a final authority-facing response writer.
- Bias implementation toward the example-backed use cases: AE summary, SOC/PT, AESI, EAIR, liver/CLO, and `ADLB`/figure requests.
- If evidence is weak, surface assumptions, open questions, and evidence gaps instead of guessing.
- Keep LLM calls server-side and ground outputs in retrieved repo evidence.
- Prefer typed contracts, deterministic parsing, and metadata-first hybrid retrieval over generic "chat with files" behavior.
- Preserve the existing App Router structure and keep imports at the top of files.
- If scope changes materially, update the MVP plan before continuing.
- Before claiming work is done, run the relevant verification steps or state clearly what was not verified.
