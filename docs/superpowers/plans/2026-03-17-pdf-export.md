# PDF Export Tool Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a server-side PDF export that renders the copilot result (question, interpretation, evidence, response plan, uncertainty) as a branded Bayer report, downloadable via an "Export PDF" button.

**Architecture:** A Next.js Route Handler (`POST /api/export-pdf`) accepts the copilot result JSON, renders a React PDF document using `@react-pdf/renderer`, and returns the PDF binary. The client triggers the download via `fetch` + blob URL. The PDF document component lives in `lib/server/pdf/copilot-report.tsx` and uses `@react-pdf/renderer` primitives exclusively (no HTML/CSS).

**Tech Stack:** `@react-pdf/renderer`, Next.js Route Handlers, Zod validation

---

## Chunk 1: Setup and PDF Document Component

### Task 1: Install dependency and create logo asset

**Files:**
- Modify: `package.json` (via npm install)
- Create: `public/logos/Logo_Bayer.png`

- [ ] **Step 1: Install @react-pdf/renderer**

```bash
npm install @react-pdf/renderer
```

- [ ] **Step 2: Convert SVG logo to PNG**

Use macOS `sips` to convert the existing SVG, or use `qlmanage`:

```bash
# If sips doesn't support SVG, use qlmanage to render a 200px PNG
qlmanage -t -s 200 -o /tmp public/logos/Logo_Bayer.svg && cp /tmp/Logo_Bayer.svg.png public/logos/Logo_Bayer.png
```

If neither works, download/create a PNG version of the Bayer cross logo manually and place at `public/logos/Logo_Bayer.png`. Alternatively, use a Node script with `sharp` or `resvg` to convert.

- [ ] **Step 3: Commit**

```bash
git add package.json package-lock.json public/logos/Logo_Bayer.png
git commit -m "feat: install @react-pdf/renderer and add Bayer PNG logo"
```

---

### Task 2: Create PDF document component

**Files:**
- Create: `lib/server/pdf/copilot-report.tsx`

This file defines the full PDF document using `@react-pdf/renderer` primitives: `Document`, `Page`, `View`, `Text`, `Image`, `StyleSheet`.

- [ ] **Step 1: Create the PDF component file**

Create `lib/server/pdf/copilot-report.tsx` with the following structure:

```tsx
import { readFileSync } from "node:fs"
import { resolve } from "node:path"

import { Document, Image, Page, StyleSheet, Text, View } from "@react-pdf/renderer"

import type { CopilotResult } from "@/lib/server/copilot/schemas"

type CopilotReportProps = {
  question: string
  result: CopilotResult
}

const BAYER_BLUE = "#0a7ccf"
const DARK_BLUE = "#10283b"
const LIGHT_BLUE = "#eef3f8"
const MUTED = "#5d7183"
const BORDER = "#d7e2ec"
const WARNING_BG = "#fef2f2"
const WARNING_BORDER = "#b5484833"

const bayerLogoPng = readFileSync(resolve(process.cwd(), "public/logos/Logo_Bayer.png"))

const s = StyleSheet.create({
  page: {
    paddingTop: 40,
    paddingBottom: 50,
    paddingHorizontal: 40,
    fontFamily: "Helvetica",
    fontSize: 10,
    color: DARK_BLUE,
    lineHeight: 1.5,
  },
  // Header
  headerRow: {
    flexDirection: "row",
    alignItems: "center",
    marginBottom: 6,
  },
  logo: { width: 32, height: 32, marginRight: 10 },
  headerTitle: { fontSize: 14, fontFamily: "Helvetica-Bold", color: DARK_BLUE },
  headerSub: { fontSize: 8, color: MUTED, marginTop: 2 },
  headerRule: { height: 1.5, backgroundColor: BAYER_BLUE, marginTop: 8, marginBottom: 16 },
  // Sections
  sectionTitle: {
    fontSize: 12,
    fontFamily: "Helvetica-Bold",
    color: BAYER_BLUE,
    marginBottom: 6,
    marginTop: 14,
  },
  rule: { height: 0.5, backgroundColor: BORDER, marginBottom: 10 },
  // Question block
  questionBlock: {
    backgroundColor: LIGHT_BLUE,
    borderRadius: 4,
    padding: 10,
    marginBottom: 4,
  },
  questionText: { fontSize: 10, lineHeight: 1.6 },
  // Key-value fields
  fieldRow: { flexDirection: "row", marginBottom: 4 },
  fieldLabel: { fontFamily: "Helvetica-Bold", fontSize: 9, color: MUTED, width: 120 },
  fieldValue: { fontSize: 10, flex: 1 },
  // Chips
  chipRow: { flexDirection: "row", flexWrap: "wrap", gap: 4, marginTop: 2, marginBottom: 4 },
  chip: {
    backgroundColor: LIGHT_BLUE,
    borderRadius: 3,
    paddingVertical: 2,
    paddingHorizontal: 6,
    fontSize: 8,
    fontFamily: "Helvetica-Bold",
    color: DARK_BLUE,
  },
  // Evidence cards
  evidenceCard: {
    borderWidth: 0.5,
    borderColor: BORDER,
    borderRadius: 4,
    padding: 8,
    marginBottom: 6,
  },
  evidenceTitle: { fontFamily: "Helvetica-Bold", fontSize: 10 },
  evidenceBadge: {
    fontSize: 7,
    fontFamily: "Helvetica-Bold",
    color: MUTED,
    textTransform: "uppercase",
    letterSpacing: 0.5,
  },
  evidenceReason: { fontStyle: "italic", fontSize: 9, color: MUTED, marginTop: 3 },
  evidencePath: { fontSize: 8, color: MUTED, marginTop: 2 },
  // Bullet lists
  bulletItem: { flexDirection: "row", marginBottom: 2 },
  bullet: { width: 12, fontSize: 10 },
  bulletText: { flex: 1, fontSize: 10 },
  // Uncertainty
  uncertaintyCard: {
    backgroundColor: LIGHT_BLUE,
    borderRadius: 4,
    padding: 8,
    marginBottom: 4,
  },
  uncertaintyTitle: { fontFamily: "Helvetica-Bold", fontSize: 9 },
  uncertaintyDetail: { fontSize: 9, color: MUTED, marginTop: 2 },
  // Warnings
  warningBlock: {
    backgroundColor: WARNING_BG,
    borderWidth: 0.5,
    borderColor: WARNING_BORDER,
    borderRadius: 4,
    padding: 8,
    marginTop: 6,
  },
  warningLabel: { fontFamily: "Helvetica-Bold", fontSize: 9, color: "#b54848", marginBottom: 4 },
  warningText: { fontSize: 9, marginBottom: 2 },
  // Footer
  footer: {
    position: "absolute",
    bottom: 20,
    left: 40,
    right: 40,
    flexDirection: "row",
    justifyContent: "space-between",
    fontSize: 7,
    color: MUTED,
  },
})

function SectionHeading({ children }: { children: string }) {
  return (
    <>
      <Text style={s.sectionTitle}>{children}</Text>
      <View style={s.rule} />
    </>
  )
}

function FieldRow({ label, value }: { label: string; value: string | null }) {
  if (!value) return null
  return (
    <View style={s.fieldRow}>
      <Text style={s.fieldLabel}>{label}</Text>
      <Text style={s.fieldValue}>{value}</Text>
    </View>
  )
}

function ChipRow({ items }: { items: string[] }) {
  if (items.length === 0) return null
  return (
    <View style={s.chipRow}>
      {items.map((item) => (
        <Text key={item} style={s.chip}>
          {item}
        </Text>
      ))}
    </View>
  )
}

function BulletList({ items }: { items: string[] }) {
  return (
    <View>
      {items.map((item) => (
        <View key={item} style={s.bulletItem}>
          <Text style={s.bullet}>{"\u2022"}</Text>
          <Text style={s.bulletText}>{item}</Text>
        </View>
      ))}
    </View>
  )
}

function UncertaintySection({
  items,
  title,
}: {
  items: Array<{ detail: string; title: string }>
  title: string
}) {
  if (items.length === 0) return null
  return (
    <>
      <Text style={[s.fieldLabel, { marginTop: 8, marginBottom: 4 }]}>{title}</Text>
      {items.map((item) => (
        <View key={item.title} style={s.uncertaintyCard}>
          <Text style={s.uncertaintyTitle}>{item.title}</Text>
          <Text style={s.uncertaintyDetail}>{item.detail}</Text>
        </View>
      ))}
    </>
  )
}

export function CopilotReport({ question, result }: CopilotReportProps) {
  const generatedAt = new Date().toISOString().replace("T", " ").slice(0, 19) + " UTC"

  return (
    <Document>
      <Page size="A4" style={s.page}>
        {/* Header */}
        <View style={s.headerRow}>
          <Image src={bayerLogoPng} style={s.logo} />
          <View>
            <Text style={s.headerTitle}>Regulatory-Response Copilot</Text>
            <Text style={s.headerSub}>Generated {generatedAt}</Text>
          </View>
        </View>
        <View style={s.headerRule} />

        {/* Original Question */}
        <SectionHeading>Original Question</SectionHeading>
        <View style={s.questionBlock}>
          <Text style={s.questionText}>{question}</Text>
        </View>

        {/* Interpretation */}
        <SectionHeading>Interpretation</SectionHeading>
        <FieldRow label="Request Type" value={result.interpretation.requestType} />
        <FieldRow label="Confidence" value={result.interpretation.confidence} />
        <FieldRow label="Population" value={result.interpretation.population} />
        <FieldRow label="Endpoint" value={result.interpretation.endpoint} />
        <FieldRow label="Analysis Type" value={result.interpretation.analysisType} />
        <FieldRow label="Statistical Model" value={result.interpretation.statisticalModel} />
        <FieldRow label="Timepoints" value={result.interpretation.timepoints.join(", ")} />
        <FieldRow label="Output Types" value={result.interpretation.outputTypes.join(", ")} />
        <View style={s.fieldRow}>
          <Text style={s.fieldLabel}>Datasets</Text>
          <ChipRow items={result.interpretation.datasetHints} />
        </View>
        <View style={s.fieldRow}>
          <Text style={s.fieldLabel}>Output Families</Text>
          <ChipRow items={result.interpretation.outputFamilyHints} />
        </View>

        {/* Evidence */}
        <SectionHeading>Evidence</SectionHeading>
        {result.evidence.map((hit) => (
          <View key={hit.document.id} style={s.evidenceCard} wrap={false}>
            <View style={{ flexDirection: "row", justifyContent: "space-between" }}>
              <Text style={s.evidenceTitle}>{hit.document.title}</Text>
              <Text style={s.evidenceBadge}>{hit.document.sourceType}</Text>
            </View>
            <Text style={s.evidenceReason}>{hit.retrievalReason}</Text>
            {hit.document.datasetNames.length > 0 && <ChipRow items={hit.document.datasetNames} />}
            <Text style={s.evidencePath}>{hit.document.path}</Text>
          </View>
        ))}

        {/* Response Plan */}
        <SectionHeading>Response Plan</SectionHeading>
        <Text style={{ fontFamily: "Helvetica-Bold", fontSize: 11, marginBottom: 4 }}>
          {result.responsePlan.objective}
        </Text>
        <Text style={{ marginBottom: 6 }}>{result.responsePlan.recommendedApproach}</Text>

        {result.responsePlan.recommendedDatasets.length > 0 && (
          <>
            <Text style={s.fieldLabel}>Recommended Datasets</Text>
            <ChipRow items={result.responsePlan.recommendedDatasets} />
          </>
        )}

        {result.responsePlan.candidateOutputs.length > 0 && (
          <>
            <Text style={[s.fieldLabel, { marginTop: 6 }]}>Candidate Outputs</Text>
            <BulletList items={result.responsePlan.candidateOutputs} />
          </>
        )}

        {result.responsePlan.deliverables.length > 0 && (
          <>
            <Text style={[s.fieldLabel, { marginTop: 6 }]}>Deliverables</Text>
            <BulletList items={result.responsePlan.deliverables} />
          </>
        )}

        {result.responsePlan.citations.length > 0 && (
          <>
            <Text style={[s.fieldLabel, { marginTop: 6 }]}>Citations</Text>
            <BulletList items={result.responsePlan.citations} />
          </>
        )}

        {/* Uncertainty & Warnings */}
        <SectionHeading>Uncertainty & Warnings</SectionHeading>
        <UncertaintySection title="ASSUMPTIONS" items={result.assumptions} />
        <UncertaintySection title="OPEN QUESTIONS" items={result.openQuestions} />
        <UncertaintySection title="EVIDENCE GAPS" items={result.evidenceGaps} />

        {result.warnings.length > 0 && (
          <View style={s.warningBlock}>
            <Text style={s.warningLabel}>WARNINGS</Text>
            {result.warnings.map((w) => (
              <Text key={w} style={s.warningText}>
                {"\u2022"} {w}
              </Text>
            ))}
          </View>
        )}

        {/* Footer */}
        <View style={s.footer} fixed>
          <Text>Regulatory-Response Copilot - Internal Use Only</Text>
          <Text render={({ pageNumber, totalPages }) => `Page ${pageNumber} / ${totalPages}`} />
        </View>
      </Page>
    </Document>
  )
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/server/pdf/copilot-report.tsx
git commit -m "feat: add PDF document component for copilot report"
```

---

## Chunk 2: API Route and UI Integration

### Task 3: Create the API route handler

**Files:**
- Create: `app/api/export-pdf/route.ts`

- [ ] **Step 1: Create the route handler**

Create `app/api/export-pdf/route.ts`:

```ts
import { renderToBuffer } from "@react-pdf/renderer"
import { z } from "zod"

import { CopilotReport } from "@/lib/server/pdf/copilot-report"
import { copilotResultSchema } from "@/lib/server/copilot/schemas"

const exportRequestSchema = z.object({
  question: z.string().min(1),
  result: copilotResultSchema,
})

export async function POST(request: Request): Promise<Response> {
  let body: unknown

  try {
    body = await request.json()
  } catch {
    return Response.json({ error: "Invalid JSON body." }, { status: 400 })
  }

  const parsed = exportRequestSchema.safeParse(body)

  if (!parsed.success) {
    return Response.json(
      { error: "Invalid request body.", details: parsed.error.issues },
      { status: 400 },
    )
  }

  try {
    const buffer = await renderToBuffer(
      <CopilotReport question={parsed.data.question} result={parsed.data.result} />,
    )

    return new Response(buffer, {
      headers: {
        "Content-Type": "application/pdf",
        "Content-Disposition": 'attachment; filename="copilot-report.pdf"',
      },
    })
  } catch (error) {
    console.error("PDF render failed:", error)
    return Response.json({ error: "Failed to generate PDF." }, { status: 500 })
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add app/api/export-pdf/route.ts
git commit -m "feat: add POST /api/export-pdf route handler"
```

---

### Task 4: Add Export PDF button to the workbench

**Files:**
- Modify: `components/copilot/copilot-workbench.tsx`

- [ ] **Step 1: Add the export handler and button**

Modify `components/copilot/copilot-workbench.tsx`:

1. Add a `useState` for `exporting` state
2. Add an `exportPdf` async function that POSTs to `/api/export-pdf`, gets the blob, creates a download link
3. Render an "Export PDF" button after the workbench grid, visible only when `state.result` is non-null

The updated component should look like:

```tsx
"use client"

import { useActionState, useState } from "react"

import { type RunCopilotActionState, runCopilotAction } from "@/app/actions/run-copilot"
import { EvidencePanel } from "@/components/copilot/evidence-panel"
import { InterpretationPanel } from "@/components/copilot/interpretation-panel"
import { QuestionForm } from "@/components/copilot/question-form"
import { ResponsePlanPanel } from "@/components/copilot/response-plan-panel"
import { Button } from "@/components/ui/button"
import { demoPrompts } from "@/lib/copilot/demo-prompts"

const initialRunCopilotActionState: RunCopilotActionState = {
  error: null,
  question: "",
  result: null,
}

export function CopilotWorkbench() {
  const [state, formAction, pending] = useActionState(runCopilotAction, {
    ...initialRunCopilotActionState,
    question: demoPrompts[0]?.question ?? "",
  })
  const [question, setQuestion] = useState(demoPrompts[0]?.question ?? "")
  const [exporting, setExporting] = useState(false)

  async function exportPdf() {
    if (!state.result) return
    setExporting(true)

    try {
      const response = await fetch("/api/export-pdf", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ question: state.question, result: state.result }),
      })

      if (!response.ok) {
        throw new Error("Export failed")
      }

      const blob = await response.blob()
      const url = URL.createObjectURL(blob)
      const link = document.createElement("a")
      link.href = url
      link.download = "copilot-report.pdf"
      link.click()
      URL.revokeObjectURL(url)
    } catch (error) {
      console.error("PDF export failed:", error)
    } finally {
      setExporting(false)
    }
  }

  return (
    <div className="space-y-6">
      <QuestionForm
        error={state.error}
        formAction={formAction}
        pending={pending}
        question={question}
        samplePrompts={demoPrompts}
        setQuestion={setQuestion}
      />

      <div className="workbench-grid">
        <InterpretationPanel interpretation={state.result?.interpretation ?? null} pending={pending} />
        <EvidencePanel evidence={state.result?.evidence ?? []} pending={pending} />
        <ResponsePlanPanel pending={pending} result={state.result} />
      </div>

      {state.result && (
        <div className="flex justify-end">
          <Button onClick={exportPdf} disabled={exporting} variant="outline" size="lg">
            {exporting ? "Exporting\u2026" : "Export PDF"}
          </Button>
        </div>
      )}
    </div>
  )
}
```

- [ ] **Step 2: Commit**

```bash
git add components/copilot/copilot-workbench.tsx
git commit -m "feat: add Export PDF button to copilot workbench"
```

---

### Task 5: Verify

- [ ] **Step 1: Run tests**

```bash
npm run test
```

Expected: all tests pass (no existing tests broken)

- [ ] **Step 2: Run lint**

```bash
npm run lint
```

Expected: 0 errors

- [ ] **Step 3: Run build**

```bash
npm run build
```

Expected: production build succeeds

- [ ] **Step 4: Manual smoke test**

1. Start the dev server: `npm run dev`
2. Submit a demo prompt and wait for results
3. Click "Export PDF"
4. Verify the downloaded PDF contains all sections: header with Bayer logo, question, interpretation, evidence, response plan, uncertainty/warnings

- [ ] **Step 5: Final commit if any fixups needed**

```bash
git add -A
git commit -m "fix: pdf export fixups from smoke test"
```
