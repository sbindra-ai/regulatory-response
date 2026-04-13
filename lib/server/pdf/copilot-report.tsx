import { readFileSync } from "node:fs"
import { resolve } from "node:path"

import { Document, Image, Page, StyleSheet, Text, View } from "@react-pdf/renderer"

import { PRODUCT_DISPLAY_NAME } from "@/lib/copilot/product-meta"
import type { CopilotResult } from "@/lib/server/copilot/schemas"

type CopilotReportProps = {
  question: string
  result: CopilotResult
}

const BAYER_DARK = "#10384F"
const BAYER_BLUE = "#00BCFF"
const BLACK = "#0f172a"
const BODY = "#1e293b"
const MUTED = "#64748b"
const BORDER = "#cbd5e1"
const HEADER_BG = "#f1f5f9"
const TINT = "#f8fafc"

const bayerLogoPng = readFileSync(resolve(process.cwd(), "public/logos/Logo_Bayer.png"))

const s = StyleSheet.create({
  page: {
    paddingTop: 42,
    paddingBottom: 52,
    paddingHorizontal: 44,
    fontFamily: "Helvetica",
    fontSize: 9,
    color: BODY,
    lineHeight: 1.45,
  },
  /* --- Cover / document control (TLF spec style) --- */
  docHeader: {
    borderWidth: 1,
    borderColor: BORDER,
    marginBottom: 16,
  },
  docHeaderTop: {
    flexDirection: "row",
    alignItems: "flex-start",
    padding: 10,
    borderBottomWidth: 1,
    borderBottomColor: BORDER,
    backgroundColor: HEADER_BG,
  },
  logo: { width: 36, height: 36, marginRight: 12 },
  docTitleBlock: { flex: 1 },
  docTitle: {
    fontSize: 13,
    fontFamily: "Helvetica-Bold",
    color: BAYER_DARK,
    marginBottom: 2,
  },
  docSubtitle: { fontSize: 8.5, color: MUTED, marginBottom: 6 },
  docMetaRow: { flexDirection: "row", borderTopWidth: 0.5, borderTopColor: BORDER },
  docMetaLabel: {
    width: "28%",
    fontFamily: "Helvetica-Bold",
    fontSize: 8,
    color: MUTED,
    paddingVertical: 5,
    paddingHorizontal: 8,
    backgroundColor: TINT,
    borderRightWidth: 0.5,
    borderRightColor: BORDER,
  },
  docMetaValue: { flex: 1, fontSize: 8.5, paddingVertical: 5, paddingHorizontal: 8, color: BLACK },
  /* --- Numbered sections --- */
  sectionNum: {
    fontSize: 10,
    fontFamily: "Helvetica-Bold",
    color: BAYER_DARK,
    marginTop: 14,
    marginBottom: 6,
    paddingBottom: 3,
    borderBottomWidth: 1.5,
    borderBottomColor: BAYER_BLUE,
  },
  sectionIntro: { fontSize: 8, color: MUTED, marginBottom: 6, fontStyle: "italic" },
  /* --- Request text box --- */
  requestBox: {
    borderWidth: 1,
    borderColor: BORDER,
    backgroundColor: TINT,
    padding: 10,
    marginBottom: 4,
  },
  requestText: { fontSize: 9.5, lineHeight: 1.5, color: BLACK },
  /* --- Specification tables --- */
  table: { borderWidth: 1, borderColor: BORDER, marginBottom: 8 },
  tableHeaderRow: {
    flexDirection: "row",
    backgroundColor: HEADER_BG,
    borderBottomWidth: 1,
    borderBottomColor: BORDER,
  },
  tableRow: { flexDirection: "row", borderBottomWidth: 0.5, borderBottomColor: BORDER },
  tableCell: { paddingVertical: 4, paddingHorizontal: 6, fontSize: 8.5 },
  tableCellH: {
    paddingVertical: 5,
    paddingHorizontal: 6,
    fontSize: 8,
    fontFamily: "Helvetica-Bold",
    color: BAYER_DARK,
  },
  colSpecLabel: { width: "26%", borderRightWidth: 0.5, borderRightColor: BORDER },
  colSpecValue: { width: "74%" },
  colRef: { width: "34%", borderRightWidth: 0.5, borderRightColor: BORDER },
  colType: { width: "14%", borderRightWidth: 0.5, borderRightColor: BORDER },
  colDs: { width: "22%", borderRightWidth: 0.5, borderRightColor: BORDER },
  colLoc: { width: "30%" },
  colProg: { width: "42%", borderRightWidth: 0.5, borderRightColor: BORDER },
  colRel: { width: "10%", borderRightWidth: 0.5, borderRightColor: BORDER },
  colPath: { width: "48%" },
  mono: { fontFamily: "Courier", fontSize: 7.5, color: MUTED },
  small: { fontSize: 8, color: MUTED },
  bodyBold: { fontFamily: "Helvetica-Bold", color: BLACK },
  /* --- Plan narrative --- */
  planObjective: { fontFamily: "Helvetica-Bold", fontSize: 10, color: BAYER_DARK, marginBottom: 4 },
  planBody: { fontSize: 9.5, marginBottom: 8, lineHeight: 1.5 },
  /* --- Uncertainty --- */
  uCard: {
    borderLeftWidth: 2,
    borderLeftColor: BAYER_BLUE,
    paddingLeft: 8,
    paddingVertical: 4,
    marginBottom: 5,
  },
  uTitle: { fontFamily: "Helvetica-Bold", fontSize: 9, color: BAYER_DARK },
  uDetail: { fontSize: 8.5, color: MUTED, marginTop: 2 },
  warnBox: {
    marginTop: 10,
    borderWidth: 1,
    borderColor: BORDER,
    padding: 8,
    backgroundColor: "#fffbeb",
  },
  warnLabel: { fontFamily: "Helvetica-Bold", fontSize: 8, color: "#92400e", marginBottom: 4 },
  /* --- Footer --- */
  footer: {
    position: "absolute",
    bottom: 22,
    left: 44,
    right: 44,
    borderTopWidth: 0.5,
    borderTopColor: BORDER,
    paddingTop: 6,
    flexDirection: "row",
    justifyContent: "space-between",
    fontSize: 7.5,
    color: MUTED,
  },
})

function shortText(text: string, max: number): string {
  const t = text.replace(/\s+/g, " ").trim()
  if (t.length <= max) return t
  return `${t.slice(0, max - 1)}\u2026`
}

function SpecTableRow({ label, value }: { label: string; value: string | null }) {
  if (!value) return null
  return (
    <View style={s.tableRow} wrap={false}>
      <View style={[s.tableCell, s.colSpecLabel]}>
        <Text style={[s.tableCell, { fontFamily: "Helvetica-Bold", color: MUTED, fontSize: 8 }]}>{label}</Text>
      </View>
      <View style={[s.tableCell, s.colSpecValue]}>
        <Text>{value}</Text>
      </View>
    </View>
  )
}

function Section({ n, title, intro }: { n: number; title: string; intro?: string }) {
  return (
    <>
      <Text style={s.sectionNum}>
        {n}. {title.toUpperCase()}
      </Text>
      {intro ? <Text style={s.sectionIntro}>{intro}</Text> : null}
    </>
  )
}

export function CopilotReport({ question, result }: CopilotReportProps) {
  const generatedAt = new Date().toISOString().replace("T", " ").slice(0, 19) + " UTC"
  const { interpretation, responsePlan } = result
  const ranked = responsePlan.rankedCodeAssets ?? []

  return (
    <Document title="Copilot response plan specification" author={PRODUCT_DISPLAY_NAME}>
      <Page size="A4" style={s.page}>
        {/* Document control — TLF specification style */}
        <View style={s.docHeader}>
          <View style={s.docHeaderTop}>
            {/* eslint-disable-next-line jsx-a11y/alt-text -- @react-pdf/renderer Image has no alt prop */}
            <Image src={bayerLogoPng} style={s.logo} />
            <View style={s.docTitleBlock}>
              <Text style={s.docTitle}>Copilot response plan specification</Text>
              <Text style={s.docSubtitle}>{PRODUCT_DISPLAY_NAME}</Text>
              <Text style={[s.docSubtitle, { marginBottom: 0 }]}>
                Structured summary of interpretation, retrieved evidence, and recommended actions for internal
                planning (not submission-ready).
              </Text>
            </View>
          </View>
          <View style={s.docMetaRow}>
            <Text style={s.docMetaLabel}>Document date</Text>
            <Text style={s.docMetaValue}>{generatedAt}</Text>
          </View>
          <View style={s.docMetaRow}>
            <Text style={s.docMetaLabel}>Classification</Text>
            <Text style={s.docMetaValue}>Internal use only — draft for discussion</Text>
          </View>
          <View style={s.docMetaRow}>
            <Text style={s.docMetaLabel}>Evidence pool</Text>
            <Text style={s.docMetaValue}>
              {result.retrievalMetadata.evidencePool === "network" ? "Network share index" : "Repository index"} (
              {result.retrievalMetadata.method})
            </Text>
          </View>
        </View>

        <Section
          n={1}
          title="Original question"
          intro="Verbatim regulatory or analysis question submitted to the copilot."
        />
        <View style={s.requestBox}>
          <Text style={s.requestText}>{question}</Text>
        </View>

        <Section
          n={2}
          title="Interpretation summary"
          intro="Machine interpretation of scope, confidence, and analysis context (validate before relying on outputs)."
        />
        <View style={s.table}>
          <View style={s.tableHeaderRow}>
            <Text style={[s.tableCellH, s.colSpecLabel]}>Item</Text>
            <Text style={[s.tableCellH, s.colSpecValue]}>Specification</Text>
          </View>
          <SpecTableRow label="Request type" value={interpretation.requestType} />
          <SpecTableRow
            label="Confidence"
            value={`${interpretation.confidenceScore.overall}/100 (${interpretation.confidenceScore.level})`}
          />
          <SpecTableRow label="Summary" value={interpretation.summary} />
          <SpecTableRow label="Population" value={interpretation.population} />
          <SpecTableRow label="Endpoint" value={interpretation.endpoint} />
          <SpecTableRow label="Analysis type" value={interpretation.analysisType} />
          <SpecTableRow label="Statistical model" value={interpretation.statisticalModel} />
          <SpecTableRow label="Timepoints" value={interpretation.timepoints.join(", ") || "—"} />
          <SpecTableRow label="Output types" value={interpretation.outputTypes.join(", ") || "—"} />
          <SpecTableRow label="Datasets (hints)" value={interpretation.datasetHints.join(", ") || "—"} />
          <SpecTableRow label="Output families (hints)" value={interpretation.outputFamilyHints.join(", ") || "—"} />
          <SpecTableRow label="Interpretation score" value={`${interpretation.confidenceScore.interpretationScore}/100`} />
          <SpecTableRow label="Evidence relevance" value={`${interpretation.confidenceScore.evidenceRelevanceScore}/100`} />
          <SpecTableRow label="Evidence coverage" value={`${interpretation.confidenceScore.evidenceCoverageScore}/100`} />
        </View>
        {interpretation.confidenceScore.reasons.length > 0 ? (
          <View style={{ marginBottom: 10 }}>
            <Text style={[s.bodyBold, { fontSize: 8, marginBottom: 4 }]}>Confidence rationale</Text>
            {interpretation.confidenceScore.reasons.map((reason) => (
              <Text key={reason} style={{ fontSize: 8.5, marginBottom: 2, paddingLeft: 8 }}>
                {"\u2022"} {reason}
              </Text>
            ))}
          </View>
        ) : null}

        <Section
          n={3}
          title="Retrieved evidence"
          intro="Ranked corpus assets supporting the plan (titles, types, datasets, and locations)."
        />
        <View style={s.table}>
          <View style={s.tableHeaderRow}>
            <Text style={[s.tableCellH, s.colRef]}>Output / reference</Text>
            <Text style={[s.tableCellH, s.colType]}>Type</Text>
            <Text style={[s.tableCellH, s.colDs]}>Datasets</Text>
            <Text style={[s.tableCellH, s.colLoc]}>Location</Text>
          </View>
          {result.evidence.map((hit) => (
            <View key={hit.document.id} style={s.tableRow} wrap={false}>
              <View style={[s.tableCell, s.colRef]}>
                <Text style={{ fontFamily: "Helvetica-Bold", fontSize: 8.5 }}>{shortText(hit.document.title, 120)}</Text>
                <Text style={[s.small, { marginTop: 2 }]}>
                  {shortText(hit.retrievalReason, 140)}
                  {hit.vectorSimilarity !== null && hit.vectorSimilarity > 0
                    ? ` (${Math.round(hit.vectorSimilarity * 100)}% semantic)`
                    : ""}
                </Text>
              </View>
              <View style={[s.tableCell, s.colType]}>
                <Text>{hit.document.sourceType}</Text>
              </View>
              <View style={[s.tableCell, s.colDs]}>
                <Text>{hit.document.datasetNames.length ? hit.document.datasetNames.join(", ") : "—"}</Text>
              </View>
              <View style={[s.tableCell, s.colLoc]}>
                <Text style={s.mono}>{shortText(hit.document.path.replace(/\\/g, "/"), 96)}</Text>
              </View>
            </View>
          ))}
        </View>

        <Section
          n={4}
          title="Recommended approach & deliverables"
          intro="Suggested objective, narrative approach, datasets, outputs, and traceable citations."
        />
        <Text style={s.planObjective}>{responsePlan.objective}</Text>
        <Text style={s.planBody}>{responsePlan.recommendedApproach}</Text>

        {responsePlan.recommendedDatasets.length > 0 ? (
          <View style={[s.table, { marginBottom: 6 }]}>
            <View style={s.tableHeaderRow}>
              <Text style={[s.tableCellH, { width: "100%" }]}>Recommended datasets</Text>
            </View>
            <View style={s.tableRow}>
              <Text style={[s.tableCell, { width: "100%" }]}>{responsePlan.recommendedDatasets.join(", ")}</Text>
            </View>
          </View>
        ) : null}

        {responsePlan.candidateDatasetPaths.length > 0 ? (
          <View style={s.table}>
            <View style={s.tableHeaderRow}>
              <Text style={[s.tableCellH, { width: "22%" }]}>Dataset</Text>
              <Text style={[s.tableCellH, { width: "78%", borderLeftWidth: 0.5, borderLeftColor: BORDER }]}>
                Candidate path(s)
              </Text>
            </View>
            {responsePlan.candidateDatasetPaths.map((row, i) => (
              <View key={`${row.dataset}-${i}`} style={s.tableRow} wrap={false}>
                <Text style={[s.tableCell, { width: "22%", fontFamily: "Helvetica-Bold" }]}>{row.dataset}</Text>
                <Text style={[s.tableCell, s.mono, { width: "78%", borderLeftWidth: 0.5, borderLeftColor: BORDER }]}>
                  {shortText(row.path.replace(/\\/g, "/"), 110)}
                </Text>
              </View>
            ))}
          </View>
        ) : null}

        {responsePlan.candidateOutputs.length > 0 ? (
          <View style={{ marginBottom: 6 }}>
            <Text style={[s.bodyBold, { fontSize: 8, marginBottom: 3 }]}>Candidate outputs to reuse</Text>
            {responsePlan.candidateOutputs.map((o) => (
              <Text key={o} style={{ fontSize: 8.5, marginBottom: 2, paddingLeft: 8 }}>
                {"\u2022"} {o}
              </Text>
            ))}
          </View>
        ) : null}

        {responsePlan.deliverables.length > 0 ? (
          <View style={{ marginBottom: 6 }}>
            <Text style={[s.bodyBold, { fontSize: 8, marginBottom: 3 }]}>Deliverables</Text>
            {responsePlan.deliverables.map((d) => (
              <Text key={d} style={{ fontSize: 8.5, marginBottom: 2, paddingLeft: 8 }}>
                {"\u2022"} {d}
              </Text>
            ))}
          </View>
        ) : null}

        {responsePlan.citations.length > 0 ? (
          <View style={{ marginBottom: 8 }}>
            <Text style={[s.bodyBold, { fontSize: 8, marginBottom: 3 }]}>Evidence citation IDs</Text>
            <Text style={[s.mono, { fontSize: 8 }]}>{responsePlan.citations.join(", ")}</Text>
          </View>
        ) : null}

        {ranked.length > 0 ? (
          <>
            <Section
              n={5}
              title="Supporting programs & macros"
              intro="Highest-ranked SAS assets from this run (for programming traceability)."
            />
            <View style={s.table}>
              <View style={s.tableHeaderRow}>
                <Text style={[s.tableCellH, s.colProg]}>Program / macro</Text>
                <Text style={[s.tableCellH, s.colRel]}>Score</Text>
                <Text style={[s.tableCellH, s.colPath]}>Path</Text>
              </View>
              {ranked.slice(0, 40).map((row) => (
                <View key={row.documentId} style={s.tableRow} wrap={false}>
                  <View style={[s.tableCell, s.colProg]}>
                    <Text style={{ fontFamily: "Helvetica-Bold", fontSize: 8 }}>{row.title}</Text>
                    <Text style={[s.small, { marginTop: 1 }]}>{row.assetType}</Text>
                  </View>
                  <Text style={[s.tableCell, s.colRel]}>{Math.round(row.relevancePercent)}</Text>
                  <Text style={[s.tableCell, s.mono, s.colPath]}>{shortText(row.path.replace(/\\/g, "/"), 72)}</Text>
                </View>
              ))}
            </View>
          </>
        ) : null}

        <Section
          n={ranked.length > 0 ? 6 : 5}
          title="Assumptions, open questions & evidence gaps"
          intro="Items requiring human confirmation or additional evidence before external use."
        />
        {result.assumptions.map((item) => (
          <View key={item.title} style={s.uCard} wrap={false}>
            <Text style={s.uTitle}>{item.title}</Text>
            <Text style={s.uDetail}>{item.detail}</Text>
          </View>
        ))}
        {result.openQuestions.map((item) => (
          <View key={item.title} style={s.uCard} wrap={false}>
            <Text style={s.uTitle}>{item.title}</Text>
            <Text style={s.uDetail}>{item.detail}</Text>
          </View>
        ))}
        {result.evidenceGaps.map((item) => (
          <View key={item.title} style={s.uCard} wrap={false}>
            <Text style={s.uTitle}>{item.title}</Text>
            <Text style={s.uDetail}>{item.detail}</Text>
          </View>
        ))}

        {result.warnings.length > 0 ? (
          <View style={s.warnBox}>
            <Text style={s.warnLabel}>Warnings</Text>
            {result.warnings.map((w) => (
              <Text key={w} style={{ fontSize: 8.5, marginBottom: 2 }}>
                {"\u2013"} {w}
              </Text>
            ))}
          </View>
        ) : null}

        <View style={s.footer} fixed>
          <Text>{PRODUCT_DISPLAY_NAME} — Copilot specification | Internal use only</Text>
          <Text render={({ pageNumber, totalPages }) => `Page ${pageNumber} of ${totalPages}`} />
        </View>
      </Page>
    </Document>
  )
}
