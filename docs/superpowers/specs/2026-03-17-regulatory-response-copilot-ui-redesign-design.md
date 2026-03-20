# Regulatory Response Copilot UI Redesign Design

## Goal

Redesign the current MVP interface into a premium corporate workbench that feels clearly Bayer-facing, more professional, fully sans-serif, and easier to inspect during both stakeholder demos and real working sessions.

## Context

The current application already supports the intended MVP workflow in a single page:

- intake of a regulatory question
- server-side interpretation
- evidence inspection
- grounded response-plan review

The problem is not feature coverage. The problem is presentation quality and UX posture.

The current UI leans warm, editorial, and slightly atmospheric:

- serif display typography in the shell
- paper-like gradients and patterned overlays
- large landing-page hero treatment
- ornamental panel styling that feels more concept-piece than enterprise product

That visual language conflicts with the intended product context. This tool is for SPA, regulatory, and biostatistics contributors operating in a high-trust, time-sensitive setting. The interface needs to communicate clarity, control, and credibility immediately.

The user explicitly requested:

- a complete UI and UX redesign
- removal of serif fonts
- more professionalism
- inclusion of the Bayer SVG logo

## Design Context

The approved direction is:

- premium corporate workbench
- spacious demo clarity over dense operator tooling
- subtle Bayer branding rather than aggressive brand saturation
- a light interface with restrained blue emphasis
- one coherent workflow: ask, inspect, decide

## Constraints

- Preserve the existing App Router structure
- Keep imports at the top of files
- Do not reposition the product as a SAS execution engine or final authority-facing writer
- Keep the three-stage MVP story visible: interpretation, evidence, plan
- Maintain the existing server-first workflow and current product scope
- Improve mobile behavior by adapting the sequence, not by hiding core workflow steps
- Replace serif typography entirely
- Integrate the Bayer SVG from `public/logos/Logo_Bayer.svg`

## Approaches Considered

### 1. Executive Briefing Deck

Transform the homepage into a highly polished presentation surface with large editorial spacing, reduced tooling chrome, and a more narrative hero-to-workbench transition.

Pros:

- strongest demo impression
- easy for stakeholders to understand quickly

Cons:

- risks feeling too static
- can hide operational detail that users need when inspecting evidence and plan output

### 2. Evidence Command Table

Lean into analyst density with tighter tables, stronger operational hierarchy, and more screen-real-estate devoted to source detail and workflow metadata.

Pros:

- strongest utility posture
- efficient for power users

Cons:

- less aligned with the requested spacious premium tone
- weaker executive-demo quality

### 3. Premium Corporate Workbench

Keep the product as a real working tool, but redesign the shell, typography, spacing, panel language, and brand treatment to feel like a refined Bayer-facing internal product.

Pros:

- best fit for the requested professional tone
- preserves workflow credibility
- improves both demo quality and usability

Cons:

- requires coordinated changes across shell, typography, tokens, and panels rather than one isolated tweak

## Selected Approach

Use the premium corporate workbench direction.

This redesign keeps the product clearly operational while removing the current editorial styling. The result should feel presentation-ready, trustworthy, and disciplined without turning into a generic dashboard or a marketing page.

## UX Architecture

The page should be reorganized into three clear layers.

### 1. Global Product Header

Add a restrained application header at the top of the page.

Contents:

- Bayer SVG logo on the left
- product title and short descriptor
- a compact trust strip with exactly three items:
	- Grounded in repo evidence
	- Server-side reasoning
	- Corpus scope: README + Define-XML + 10 SAS examples

The header should establish institutional trust immediately. It should be functional, not promotional.

Layout:

- at desktop widths, use a two-column header with brand block on the left and the trust strip right-aligned
- at tablet widths, keep the brand block first and wrap the trust strip below it
- at mobile widths, stack the trust strip beneath the title and allow it to wrap into multiple rows

### 2. Intake Section

Replace the oversized hero treatment with a tighter introductory block that explains the product in operational language.

This section should contain:

- a concise title focused on the tool outcome
- a short supporting paragraph that clarifies scope and boundaries
- the main textarea for regulatory question input
- sample prompts presented as disciplined utility chips
- primary and secondary actions with clearer hierarchy

The intake area should feel like a command surface, not a landing-page hero.

### 3. Response Workspace

Preserve the three-panel workflow, but redesign it as a coordinated workbench.

Panel roles:

- Interpretation: what the ask means
- Evidence: what repo assets support the recommendation
- Response plan: what the user should do next

The three panels should feel interdependent rather than visually isolated cards. Internal spacing, headers, and section labels should reinforce the flow from interpretation to evidence to plan.

## Visual System

### Color Direction

Move from warm cream and editorial neutrals to cooler corporate neutrals.

Use the following default token direction for implementation:

- `--background`: `#eef3f8`
- `--foreground`: `#10283b`
- `--card`: `#ffffff`
- `--card-foreground`: `#10283b`
- `--muted`: `#f4f7fb`
- `--muted-foreground`: `#5d7183`
- `--border`: `#d7e2ec`
- `--input`: `#cdd8e3`
- `--primary`: `#0a7ccf`
- `--primary-foreground`: `#f7fbff`
- `--secondary`: `#e7f0f8`
- `--accent`: `#dceaf6`
- `--destructive`: `#b54848`

Target feel:

- light neutral page background
- crisp white or near-white surfaces
- slate and blue-tinted neutrals for text and dividers
- restrained Bayer-blue accents for primary actions, focus, key labels, and status markers

Avoid:

- paper-like beige backgrounds
- highly decorative radial atmospherics
- textured overlays that imply print or stationery
- heavy dark mode or glowing enterprise tropes

The page can retain a very subtle atmospheric tint, but only as low-contrast structure. The overall feel should be cleaner and flatter than the current implementation.

Component emphasis rules:

- primary buttons, focus rings, active chips, and key status markers use `--primary`
- panel backgrounds and form surfaces stay white or near-white
- supporting chips and metadata containers use `--muted` or `--secondary`
- do not apply Bayer blue as a full-page wash or large colored panel background

### Surface Language

Panels should use lighter chrome:

- fine borders
- modest elevation
- lower-radius corners than the current rounded editorial style
- clearer separation through alignment and spacing rather than decorative treatment

Use this surface rule consistently:

- outer panels use border plus modest shadow
- evidence rows use border plus muted background with no shadow
- avoid nested elevated surfaces inside elevated panels

Spacing rule:

- standard panel padding uses `clamp(1.25rem, 1.8vw, 1.75rem)`
- intake shell padding uses `clamp(1.5rem, 2vw, 2rem)`
- vertical gap between a panel header and its first content group uses `1rem`
- vertical gap between major content groups inside a panel uses `1.25rem`

Avoid nested card-on-card visual stacking where possible.

## Typography

Replace the serif display system entirely.

Recommended pairing:

- display and headings: `Manrope`
- body and dense interface text: `Source Sans 3`

Rationale:

- both are sans-serif
- both feel professional rather than trendy
- the pairing supports strong hierarchy without drifting into editorial or startup aesthetics

Typography rules:

- headings should be firm and compact, not literary
- body text should prioritize scannability and confidence
- labels and metadata should be precise, not over-stylized
- uppercase tracking should be used sparingly and only for small metadata contexts
- panel titles should use `--foreground`, not `--primary`, so emphasis stays on content rather than decoration

Base scale:

- page title: `clamp(2.5rem, 4vw, 4.25rem)`, weight `700`, line-height `1.02`
- section title: `clamp(1.625rem, 2vw, 2.125rem)`, weight `700`, line-height `1.08`
- panel title: `1.125rem`, weight `700`, line-height `1.2`
- body copy: `1rem`, weight `400`, line-height `1.65`
- secondary body copy: `0.9375rem`, weight `400`, line-height `1.55`
- metadata and chips: `0.75rem`, weight `600`, line-height `1.2`, letter-spacing `0.08em`

## Branding

Use Bayer branding with restraint.

### Logo Placement

The Bayer SVG from `public/logos/Logo_Bayer.svg` should appear in the global header as a trust marker.

Guidelines:

- keep the logo modest in size
- surround it with whitespace
- do not use it as a decorative hero object
- do not over-repeat the brand mark elsewhere on the page

### Brand Expression

Brand identity should come from:

- the presence of the Bayer logo
- disciplined spacing and product polish
- selective Bayer-blue accents

The interface should feel Bayer-aligned without becoming a brand campaign page.

## Panel Design

### Interpretation Panel

This panel should read as structured understanding, not freeform summary.

Emphasize:

- request type
- endpoints
- populations or subgroups
- timepoints
- output expectations

Use a compact structured layout with clear labels and grouped fields.

Field styling:

- labels use the metadata scale with `--muted-foreground`
- values use secondary body copy with `--foreground`
- each field group uses `0.75rem` spacing between label and value
- related fields can sit in a two-column sub-grid on desktop and stack on smaller widths

### Evidence Panel

This should become the most inspectable panel.

Emphasize:

- source name
- source type
- why the item matched
- dataset or output-family tags
- evidence strength cues when available

Tag source and rendering:

- tags come from backend evidence metadata when present; the frontend does not invent tag content
- dataset tags render as filled low-emphasis chips using `--secondary`
- output-family tags render as outlined chips using white background and `--border`
- both tag types use the metadata scale and sit in the same tag row, with dataset tags appearing first

Evidence entries should use a structured vertical list, not floating cards.

Each evidence item should contain four layers in this order:

1. source header row with source name on the left and source type on the right
2. match-reason paragraph directly underneath
3. tag row containing dataset tags and output-family tags
4. a short reuse cue or traceability note at the bottom

Separate items with row dividers or low-contrast inset containers, not independent elevated cards.

Inset container definition:

- background: `--muted`
- border: `1px solid var(--border)`
- radius: slightly smaller than the outer panel radius
- shadow: none

Overflow rule:

- do not add inner scrolling to evidence items for the default state
- the page owns vertical scrolling rather than the panel
- if more than 6 evidence items are returned, render the first 6 and reveal the remainder with an inline `Show all evidence` control inside the panel
- clicking the control expands the full list inline in normal document flow
- the expanded state changes the control label to `Show fewer evidence items` and collapses back to the first 6 when pressed again

### Response Plan Panel

This is the decision panel.

Separate the plan into clearly distinguishable blocks:

- recommended actions
- candidate data sources
- prior outputs to inspect or reuse
- assumptions
- open questions
- evidence gaps

Success should emphasize traceability rather than celebration.

Section structure:

- section order is Recommended actions -> Candidate data sources -> Prior outputs -> Assumptions -> Open questions -> Evidence gaps
- each section uses a small metadata-style heading in `--muted-foreground`
- each section body uses standard body copy or concise list rows in `--foreground`
- use `1rem` spacing between a section heading and its content and `1.25rem` spacing between sections
- Recommended actions should receive the highest emphasis and render as a numbered list or stacked ordered steps
- Assumptions, open questions, and evidence gaps should render as clearly separated rows so uncertainty remains visible rather than blending into prose

## Interaction And States

### Empty State

The empty state should teach the product in one glance.

It should explain:

- what to enter
- what the tool will return
- that outputs remain grounded in repo evidence

### Loading State

Loading should feel controlled and product-grade.

Guidelines:

- use structured skeletons or placeholders aligned to final layout
- avoid generic spinner-only treatment
- use restrained motion
- respect reduced-motion preferences

Animation rule:

- use a subtle pulse on skeleton blocks by default
- switch to static placeholders when reduced-motion is enabled

### Error State

Errors should feel operational.

Guidelines:

- clear direct language
- explain what failed
- preserve as much context as possible
- avoid dramatic styling or generic apology copy

### Success State

Successful output should foreground inspectability:

- interpretation is clear
- evidence is traceable
- plan sections are easy to review

Loading skeleton pattern:

- interpretation panel shows 4 to 6 field rows with label and value placeholders
- evidence panel shows 3 stacked evidence rows with header, text, tag, and reuse-cue placeholders
- response plan panel shows 3 grouped blocks with heading and paragraph placeholders

Error messaging pattern:

- title line should state the failure plainly, for example `Unable to build grounded plan`
- body line should state what remains available, for example interpretation or prior evidence if present
- recovery line should direct the user to retry, edit the question, or inspect the current evidence
- if deterministic fallback is active, that status should be stated explicitly rather than implied

## Responsive Strategy

Desktop should preserve the side-by-side workbench.

Breakpoints:

- desktop: `>= 1280px`
- tablet: `768px - 1279px`
- mobile: `< 768px`

Desktop layout rules:

- panel order remains Interpretation -> Evidence -> Response Plan
- use a three-column grid with width ratio `0.95fr 1.1fr 1fr`
- use `clamp(1.25rem, 1.8vw, 1.75rem)` gutters so spacing expands with viewport width
- panels align to the top and grow with content
- the page owns vertical scrolling by default; do not fix panel height to the viewport

Mobile should shift to a guided sequence:

1. intake
2. interpretation
3. evidence
4. response plan

This should be a genuine adaptation, not a squeezed three-column desktop layout. Labels, spacing, and section headers must remain strong enough that the tool still feels credible on smaller screens.

Mobile pattern:

- use one continuous vertical scroll
- keep all four sections visible in order on the page
- do not use pagination, accordions, or hidden step panels for the default mobile flow

Tablet should use a hybrid layout:

- intake remains full width
- interpretation and evidence appear first in stacked order
- response plan follows as a full-width section
- no critical content should move behind tabs, drawers, or accordions by default

## Accessibility And Quality

The redesign should improve clarity without reducing accessibility.

Requirements:

- maintain clear contrast across all text and interactive states
- keep focus states obvious and brand-consistent
- preserve keyboard accessibility for prompt selection and form actions
- ensure long evidence titles and plan text wrap cleanly
- avoid motion that becomes distracting in regulated or high-focus contexts
- expose scope boundaries in visible copy so the interface does not imply final authority-facing output generation

Focus ring pattern:

- outer ring: `2px solid color-mix(in srgb, var(--primary) 75%, white)`
- offset: `2px`
- radius follows the component radius
- apply consistently to textarea, buttons, prompt chips, and any interactive row

## Implementation Notes

Expected files to change:

- `app/layout.tsx`
- `app/globals.css`
- `app/page.tsx`
- `components/copilot/copilot-workbench.tsx`
- `components/copilot/question-form.tsx`
- `components/copilot/interpretation-panel.tsx`
- `components/copilot/evidence-panel.tsx`
- `components/copilot/response-plan-panel.tsx`
- optionally `components/ui/button.tsx` and `components/ui/card.tsx` if token alignment requires it

Expected implementation themes:

- replace the serif font import and variables in the root layout
- introduce new light-theme tokens and spacing behavior in global CSS
- remove ornamental textures and warm gradients
- add a compact header with Bayer branding
- tighten the introductory copy and page hierarchy
- redesign panels around structured information instead of decorative surfaces
- improve mobile sequencing for the workbench
- include explicit scope-boundary copy in the intro or support text stating that the tool produces a grounded starter plan, not a final authority-facing response

## Acceptance Criteria

The redesign is successful when all of the following are true:

- the page no longer uses serif fonts anywhere in the shell
- the Bayer logo is visibly integrated into the UI in a restrained professional way
- the overall tone reads as premium corporate rather than editorial
- the intake, interpretation, evidence, and plan flow is clearer than before
- panel states are more deliberate across empty, loading, success, and error conditions
- mobile behavior adapts the workflow into a readable sequence
- the interface visibly communicates that the tool is a grounded planning aid rather than a SAS engine or final response writer
- the page remains aligned with the current regulatory-response MVP scope

## Out Of Scope

The redesign does not introduce:

- new backend behavior
- new product workflow stages
- task-board functionality
- client-side LLM behavior
- a rebrand of the product mission
- a final authority-facing response writing experience