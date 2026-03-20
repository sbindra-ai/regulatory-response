Before claiming work is done, run the relevant verification steps or state clearly what was not verified. For this repo, typically use:
- `npm run lint`
- `npm run test`
- `npm run build`
- `npm run ingest` when changing retrieval/corpus behavior or docs that depend on corpus generation.
Also ensure changes keep LLM calls server-side, preserve grounding in repo evidence, and stay within MVP scope.