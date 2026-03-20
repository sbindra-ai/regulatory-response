# PDF Export Tool - Design Spec

## Overview

A server-side API route that accepts the copilot result and original question, renders a branded PDF report using `@react-pdf/renderer`, and returns it as a direct download.

## Trigger

An "Export PDF" button in `CopilotWorkbench`, visible only when `result` is non-null. Clicking it sends a POST to `/api/export-pdf` with the question and result, then triggers a browser download of the returned PDF.

## API Route

**`POST /api/export-pdf`**

- **Request body:** `{ question: string, result: CopilotResult }`
- **Validation:** Zod parse using `copilotResultSchema` + a string check on `question`
- **Response:** `application/pdf` with `Content-Disposition: attachment; filename="copilot-report.pdf"`
- **Error:** 400 JSON `{ error: string }` on validation failure

## PDF Document Layout

Single-flow vertical report rendered with `@react-pdf/renderer` React components:

### 1. Header

- Bayer logo (PNG, left-aligned) + "Regulatory-Response Copilot" title (right of logo)
- Generation timestamp (right-aligned or below title)
- Horizontal rule in Bayer blue (`#0a7ccf`)

### 2. Original Question

- Section heading: "Original Question"
- User's input text in a light-blue (`#eef3f8`) highlighted block

### 3. Interpretation

- Section heading: "Interpretation"
- Key-value pairs displayed as a two-column layout:
  - Request Type, Confidence, Population, Endpoint, Analysis Type, Statistical Model
- Timepoints, Output Types as inline comma-separated values
- Dataset Hints and Output Family Hints as chip-like labels

### 4. Evidence

- Section heading: "Evidence"
- Each evidence hit as a card/row containing:
  - Title (bold), source type badge, path
  - Matched terms (comma-separated)
  - Retrieval reason (italic)

### 5. Response Plan

- Section heading: "Response Plan"
- Objective (prominent text)
- Recommended Approach (body paragraph)
- Recommended Datasets (inline list)
- Candidate Outputs (bullet list)
- Deliverables (bullet list)
- Citations (list of evidence IDs)

### 6. Uncertainty & Warnings

- Three subsections (only rendered if non-empty): Assumptions, Open Questions, Evidence Gaps
  - Each item: title (bold) + detail (body text)
- Warnings rendered as a highlighted list at the bottom

## File Structure

| Action | File | Purpose |
|--------|------|---------|
| Install | `@react-pdf/renderer` | PDF generation library |
| Create | `app/api/export-pdf/route.ts` | Next.js Route Handler |
| Create | `lib/server/pdf/copilot-report.tsx` | React PDF document component |
| Create | `public/logos/Logo_Bayer.png` | PNG version of Bayer logo |
| Modify | `components/copilot/copilot-workbench.tsx` | Add "Export PDF" button |

## Styling

- **Primary/headings:** Bayer blue `#0a7ccf`
- **Body text:** Dark blue `#10283b`
- **Question block background:** Light blue `#eef3f8`
- **Section dividers:** 1pt horizontal rules in Bayer blue
- **Font:** Helvetica (PDF built-in, no embedding needed)
- **Page:** A4 portrait, 40pt margins

## Dependencies

- `@react-pdf/renderer` - React-based PDF document rendering

## Error Handling

- Invalid or missing request body returns 400 with descriptive error
- PDF rendering failures return 500 with generic error message
- Client-side: button disabled while download is in progress, error shown via existing error UI pattern
