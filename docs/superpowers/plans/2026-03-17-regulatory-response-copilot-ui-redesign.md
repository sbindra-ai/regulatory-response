# Regulatory Response Copilot UI Redesign Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the current Next.js MVP into a premium, fully sans-serif, Bayer-branded corporate workbench without changing the underlying server-side copilot workflow.

**Architecture:** Keep the current single-page App Router flow and existing copilot action pipeline intact. Replace the warm editorial shell with a structured product header, tighter intake section, and more inspectable interpretation, evidence, and response-plan panels backed by the existing data contracts.

**Tech Stack:** Next.js App Router, React 19, TypeScript, Tailwind CSS v4, shadcn UI, Vitest, Testing Library

---

## Chunk 1: UI Shell And Visual System

### Task 1: Add Failing UI Regression Tests

**Files:**
- Create: `tests/components/copilot-header-and-form.test.tsx`
- Modify: `tests/components/copilot-panels.test.tsx`
- Read for context: `components/copilot/question-form.tsx`
- Read for context: `components/copilot/interpretation-panel.tsx`
- Read for context: `components/copilot/evidence-panel.tsx`
- Read for context: `components/copilot/response-plan-panel.tsx`

- [ ] Step 1: Write a failing header-and-form test that expects a Bayer-branded workbench header, explicit trust-strip copy, and scope-boundary intake copy.
- [ ] Step 2: Run `npm test -- tests/components/copilot-header-and-form.test.tsx` and verify it fails for the expected missing component or copy.
- [ ] Step 3: Extend `tests/components/copilot-panels.test.tsx` with failing assertions for the redesigned panel structure: structured interpretation fields, response-plan section headings, and evidence expansion behavior when more than six hits are present.
- [ ] Step 4: Run `npm test -- tests/components/copilot-panels.test.tsx` and verify the new assertions fail for the expected reasons.

### Task 2: Implement The Header, Fonts, And Global Tokens

**Files:**
- Create: `components/copilot/workbench-header.tsx`
- Modify: `app/layout.tsx`
- Modify: `app/page.tsx`
- Modify: `app/globals.css`
- Modify: `components/ui/button.tsx`

- [ ] Step 1: Replace the root serif/display font setup in `app/layout.tsx` with the approved sans-serif pairing and keep font variables consistent with Tailwind theme usage.
- [ ] Step 1: Replace the root serif/display font setup in `app/layout.tsx` with `Manrope` and `Source Sans 3`, using `next/font/google` and preserving CSS variables for heading and body usage in the Tailwind theme.
- [ ] Step 2: Add `components/copilot/workbench-header.tsx` with the Bayer SVG, product title, descriptor, and the three-item trust strip from the approved spec.
- [ ] Step 3: Update `app/page.tsx` to render the new header and a tighter product intro instead of the current hero/aside composition.
- [ ] Step 4: Replace the current warm editorial token set in `app/globals.css` with the spec tokens exactly: `--background #eef3f8`, `--foreground #10283b`, `--card #ffffff`, `--muted #f4f7fb`, `--muted-foreground #5d7183`, `--border #d7e2ec`, `--input #cdd8e3`, `--primary #0a7ccf`, `--primary-foreground #f7fbff`, `--secondary #e7f0f8`, `--accent #dceaf6`, and `--destructive #b54848`.
- [ ] Step 5: Implement the approved spacing and typography primitives in `app/globals.css`, including `clamp(1.25rem, 1.8vw, 1.75rem)` panel padding, `clamp(1.5rem, 2vw, 2rem)` intake padding, the approved heading scale, and the subtle pulse skeleton animation with reduced-motion fallback.
- [ ] Step 6: Implement the approved focus-ring pattern and lighter surface language in `app/globals.css` and `components/ui/button.tsx`, including obvious focus states, lower-radius controls, and consistent hover, active, and disabled states.
- [ ] Step 6: Run `npm test -- tests/components/copilot-header-and-form.test.tsx` and verify the header-and-form test now passes.

## Chunk 2: Intake And Panel Redesign

### Task 3: Redesign Intake Copy And Form Layout

**Files:**
- Modify: `components/copilot/question-form.tsx`
- Read for context: `lib/copilot/demo-prompts.ts`

- [ ] Step 1: Update the intake copy so it frames the UI as a grounded starter-plan workspace, not a final response writer.
- [ ] Step 2: Redesign the form layout and sample prompt area to match the premium corporate workbench structure while preserving the current form action and prompt behavior.
- [ ] Step 2: Redesign the form layout and sample prompt area to match the premium corporate workbench structure, using the approved intake padding, muted support containers, and explicit scope-boundary messaging.
- [ ] Step 3: Keep the supported demo scenarios legible and explicitly visible in the intake section.
- [ ] Step 4: Re-run `npm test -- tests/components/copilot-header-and-form.test.tsx` and confirm the form assertions still pass after layout changes.

### Task 4: Redesign Interpretation, Evidence, And Response Plan Panels

**Files:**
- Modify: `components/copilot/interpretation-panel.tsx`
- Modify: `components/copilot/evidence-panel.tsx`
- Modify: `components/copilot/response-plan-panel.tsx`
- Modify: `components/copilot/copilot-workbench.tsx`

- [ ] Step 1: Update `components/copilot/interpretation-panel.tsx` to use a structured field layout with metadata-style labels, professional empty/loading states, and the spec’s grouped-field hierarchy.
- [ ] Step 2: Update `components/copilot/evidence-panel.tsx` to use inset record rows styled with `--muted`, bordered/no-shadow surfaces, differentiated dataset/output tags, traceability cues, the first-six-items default view, and the `Show all evidence` / `Show fewer evidence items` inline toggle.
- [ ] Step 3: Update `components/copilot/response-plan-panel.tsx` to render the approved section order and section styling: recommended actions, candidate data sources, prior outputs, assumptions, open questions, evidence gaps, citations, and warnings, with clear section headings and visible uncertainty.
- [ ] Step 4: Adjust `components/copilot/copilot-workbench.tsx` and any supporting layout classes to match the spec breakpoints and grid behavior: desktop `>=1280px` with `0.95fr 1.1fr 1fr`, tablet `768px-1279px` stacked hybrid layout, and mobile `<768px` continuous vertical sequence.
- [ ] Step 5: Make sure loading, empty, success, and error states across all three panels match the spec’s skeleton and messaging requirements rather than leaving the current placeholders in place.
- [ ] Step 5: Run `npm test -- tests/components/copilot-panels.test.tsx` and verify all redesigned panel assertions pass.

## Chunk 3: Verification

### Task 5: Run Full Verification For The Redesign

**Files:**
- Verify only: `app/layout.tsx`, `app/page.tsx`, `app/globals.css`, `components/copilot/*.tsx`, `components/ui/button.tsx`, `tests/components/*.test.tsx`

- [ ] Step 1: Run `npm test -- tests/components/copilot-header-and-form.test.tsx tests/components/copilot-panels.test.tsx` and verify the targeted UI tests pass.
- [ ] Step 2: Run `npm test` and verify the full test suite passes or capture any unrelated failures clearly.
- [ ] Step 3: Run `npm run lint` and verify the redesigned UI remains lint-clean.
- [ ] Step 4: If needed for confidence, run `npm run build` and verify the app still compiles successfully.