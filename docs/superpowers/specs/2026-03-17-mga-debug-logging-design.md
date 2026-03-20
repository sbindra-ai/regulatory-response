# MGA Debug Logging Design

## Goal

Add safe, metadata-only debugging around the Bayer myGenAssist GPT-5 calls and the surrounding copilot orchestration so developers can understand when MGA was called, when the workflow fell back to deterministic behavior, and where failures or slowdowns occurred.

## Context

The current server-side LLM path is intentionally small:

- `lib/server/llm/openai.ts` sends structured requests to Bayer myGenAssist v2 at `https://chat.int.bayer.com/api/v2`
- `lib/server/copilot/interpret-request.ts` uses MGA to interpret the regulatory question and falls back to deterministic heuristics on missing token or failure
- `lib/server/copilot/generate-plan.ts` uses MGA to draft the grounded internal plan and falls back to a deterministic plan when needed
- `lib/server/copilot/run-copilot.ts` orchestrates `interpret -> retrieve -> generate`

Today there is effectively no server-side observability in this flow. That makes it hard to debug whether a run skipped MGA because of configuration, reached MGA but failed on transport or parsing, or succeeded but still returned a weak final result because retrieval or evidence quality was limited.

The user explicitly requested stricter debug visibility, especially around the MGA GPT-5 pings, and explicitly requested that logs stay strictly metadata-only.

## Constraints

The logging design must preserve the existing product and security constraints:

- No prompt text in logs
- No model response content in logs
- No regulatory question text in logs
- No token values in logs
- No client-side logging of MGA internals
- Keep all LLM calls server-side
- Preserve the existing fallback behavior and typed contracts

The logging should help debugging without changing product behavior.

## Approaches Considered

### 1. Small Structured Server Logger With Workflow Events

Add a small server-only logger helper and emit consistent structured metadata from the MGA client wrapper and the copilot orchestration stages.

Pros:

- Keeps logging format consistent across the workflow
- Makes MGA call start, success, failure, and fallback reasons easy to inspect
- Avoids repeating ad hoc `console.*` shapes in multiple files
- Keeps the implementation small and aligned with hackathon scope

Cons:

- Adds one small shared utility instead of only touching existing files

### 2. Inline `console.*` Statements Only In `openai.ts`

Add direct `console.debug`, `console.info`, and `console.error` calls only around the MGA request in the LLM client wrapper.

Pros:

- Fastest implementation
- Covers the specific MGA ping point the user called out

Cons:

- Weak visibility into `interpret -> retrieve -> generate`
- Encourages duplicated log shapes later
- Makes correlation across stages harder

### 3. Full Request Tracing Threaded Through The Entire Workflow

Generate a request ID at the top of the run and thread it through all stages and helpers.

Pros:

- Strongest end-to-end observability
- Best fit if the system later grows into multiple server actions or background jobs

Cons:

- More plumbing than needed for the current request
- Slightly larger surface-area change for a small hackathon app

## Selected Approach

Use a small structured server logger with metadata-only events, and add one lightweight run identifier that can be created inside the copilot orchestration and passed into the MGA wrapper when available.

This keeps the implementation small, directly improves the MGA debugging path, and still gives enough cross-stage correlation to understand whether a run used MGA, fell back, or completed with weak evidence.

## Architecture

### Logging Helper

Add a server-only logging helper under `lib/server/` that centralizes how debug events are emitted.

The helper should:

- Accept an event name plus a flat metadata object
- Route to `console.info`, `console.warn`, or `console.error` depending on event severity
- Normalize common metadata such as timestamp and event namespace
- Only accept metadata fields that are safe to log

This helper is intentionally minimal. It is not a new observability framework and does not introduce transports, log aggregation, or external dependencies.

### Event Boundaries

Logging will be added at three levels:

1. MGA wrapper boundary in `lib/server/llm/openai.ts`
2. Copilot stage boundary in `lib/server/copilot/interpret-request.ts` and `lib/server/copilot/generate-plan.ts`
3. End-to-end orchestration boundary in `lib/server/copilot/run-copilot.ts`

These levels create clear units:

- The MGA wrapper explains what happened during the actual API ping
- The stage-level logs explain whether a stage used MGA or a fallback path
- The orchestration log explains the overall outcome of one copilot run

## Logging Events

### MGA Wrapper Events

`lib/server/llm/openai.ts` should emit metadata-only events for:

- `mga.request.skipped` when `MGA_TOKEN` is absent
- `mga.request.started` before calling `client.chat.completions.create`
- `mga.request.succeeded` after a successful response and parse
- `mga.request.failed` when transport, JSON extraction, JSON parse, or schema parse fails

Recommended metadata fields:

- `runId` if available
- `stage` such as `interpret-request` or `generate-plan`
- `model`
- `baseUrlHost`
- `maxTokens`
- `hasToken`
- `systemPromptLength`
- `userPromptLength`
- `responseTextLength`
- `latencyMs`
- `errorName`
- `statusCode` when the provider error exposes one safely
- `failureKind`
- `hasErrorDetails`

`failureKind` should be normalized into a few buckets such as:

- `transport`
- `missing-json-object`
- `invalid-json`
- `schema-parse`
- `unknown`

This gives better debugging signal than logging raw exception text. The implementation must never log prompt fragments, response fragments, validation payloads, or exception messages that could echo model content.

### Stage-Level Events

`lib/server/copilot/interpret-request.ts` should emit these canonical events:

- `copilot.interpret.started` at `info`
- `copilot.interpret.succeeded` at `info`
- `copilot.interpret.fallback` at `warn`

`lib/server/copilot/generate-plan.ts` should emit the matching plan-stage events:

- `copilot.plan.started` at `info`
- `copilot.plan.succeeded` at `info`
- `copilot.plan.fallback` at `warn`

Fallback events cover both deterministic fallback because no MGA token exists and fallback after an MGA request or parse failure.

Recommended metadata fields:

- `runId`
- `stage`
- `questionLength`
- `usedMga`
- `fallbackReason`
- `requestType` when available
- `evidenceCount` for plan generation
- `warningCount` or `gapCount` when useful after fallback

`fallbackReason` should be normalized to a short safe enum such as `missing-token`, `mga-failure`, or `validation-rejected`. The stage logs should explain why the returned value came from MGA or from fallback logic, without leaking any domain text.

### Orchestration Events

`lib/server/copilot/run-copilot.ts` should emit one correlated run boundary:

- `copilot.run.started`
- `copilot.run.completed`
- `copilot.run.failed`
- `copilot.run.rejected`

Severity rules:

- `copilot.run.started` at `info`
- `copilot.run.completed` at `info`
- `copilot.run.failed` at `error`
- `copilot.run.rejected` at `warn` for the empty-question guard

Recommended metadata fields:

- `runId`
- `questionLength`
- `evidenceCount`
- `warningCount`
- `assumptionCount`
- `openQuestionCount`
- `evidenceGapCount`
- `latencyMs`
- `usedMgaForInterpretation`
- `usedMgaForPlan`

This top-level view helps developers understand whether the run succeeded overall even if one stage fell back.

`copilot.run.rejected` should only log safe validation metadata such as `runId` and `questionLength`, and should not change the current user-facing empty-question error behavior.

## Data Flow

1. `runCopilot` generates a lightweight `runId`, creates a typed logging context, and logs run start.
2. `runCopilot` passes that logging context into `interpretRequest`.
3. `interpretRequest` logs stage start and either:
   - logs deterministic fallback because no MGA token is configured, or
   - calls `generateStructuredObject` with `runId` and `stage`, then logs MGA success or fallback-after-failure.
4. Retrieval runs as it does today. No new verbose per-hit logging is required for this request.
5. `runCopilot` passes the same logging context into `generatePlan`.
6. `generatePlan` repeats the same stage-level logging pattern and passes `runId` and `stage` to the MGA wrapper.
7. Each stage updates only its own execution slot in the logging context, recording whether MGA was used and whether fallback occurred.
8. `runCopilot` logs run completion with counts, final latency, and the stage usage metadata stored in the logging context.
9. If orchestration throws, `runCopilot` logs failure metadata before rethrowing.

## Interface Changes

A small amount of plumbing is acceptable to keep logs correlated.

Expected changes:

- Extend the MGA helper input type to optionally accept `runId` and `stage`
- Add a small typed logging context owned by `runCopilot`, for example a `CopilotRunLogContext` with:
  - immutable run metadata such as `runId`
  - one execution slot for `interpretRequest`
  - one execution slot for `generatePlan`
- Extend `interpretRequest` and `generatePlan` to accept that optional logging context from `runCopilot`
- Keep public behavior and returned schemas unchanged

The logging context is an internal orchestration aid only. Stage functions keep returning their current domain results, but may update their own execution slot inside the context before returning. That makes the boundary explicit without changing product-facing types.

## Error Handling Strategy

Logging must never become the source of product failures.

Rules:

- Logging helpers must be fire-and-forget and should not throw into product logic
- Existing fallback behavior stays intact
- Existing user-facing error messages stay intact
- Exceptions should still be rethrown where current behavior depends on them, but not before the relevant failure metadata is logged
- Failure metadata must stay content-safe, meaning no raw exception messages are logged unless they are first mapped to an explicitly safe enum or field

The design intentionally distinguishes three classes of issues:

- configuration issues, such as missing `MGA_TOKEN`
- provider or transport issues, such as request failure
- response handling issues, such as missing JSON or schema mismatch

That separation is the main debugging value of this change.

## Testing And Verification Strategy

Add focused tests around the MGA logging path rather than snapshotting all console output for the whole app.

### Tests To Add Or Update

Update `tests/server/llm/openai.test.ts` to verify:

- no-token path returns `null` and emits the expected skip metadata
- successful MGA call emits start and success metadata with default model `gpt-5`
- failed MGA call emits failure metadata with a normalized failure kind

Add or update stage-level tests if the current structure makes it easy to do so, especially for:

- `interpretRequest` fallback because token is missing
- `generatePlan` fallback after MGA error

### Verification Commands

After implementation, run:

- `npm run test`
- `npm run lint`

Optionally run `npm run build` if the logging helper changes shared server-side typing in a way that could affect build output.

## Acceptance Criteria

The logging enhancement is complete when all of the following are true:

- MGA requests emit metadata-only start, success, skip, and failure logs
- Logs never include prompt text, response text, question text, or secret values
- Logs use canonical stage and run event names with documented severity levels
- Interpretation and plan-generation stages clearly log whether they used MGA or deterministic fallback
- The end-to-end copilot run logs total latency and high-level result counts
- The run-level completion log derives `usedMgaForInterpretation` and `usedMgaForPlan` from the internal logging context without changing public result types
- Existing return types and user-visible behavior remain unchanged
- Tests cover the core MGA logging paths

## Out Of Scope

The following are intentionally excluded from this change:

- Client-side debug panels
- Persistent log storage or log shipping
- Prompt/response redaction because content logging is disallowed entirely
- Full distributed tracing infrastructure
- Broader retrieval logging beyond lightweight summary counts
- Changes to the regulatory response product behavior itself
