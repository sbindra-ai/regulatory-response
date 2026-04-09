import { readFileSync } from "node:fs"
import { resolve } from "node:path"

import { Document, Image, Page, StyleSheet, Text, View } from "@react-pdf/renderer"

import { PRODUCT_DISPLAY_NAME } from "@/lib/copilot/product-meta"
import type { CopilotResult } from "@/lib/server/copilot/schemas"

type CopilotReportProps = {
  question: string
  result: CopilotResult
}

const BLACK = "#1a1a1a"
const DARK = "#333333"
const GREY = "#666666"
const LIGHT_GREY = "#999999"
const RULE = "#cccccc"
const ACCENT = "#0a7ccf"
const TINT = "#f5f5f5"

const bayerLogoPng = readFileSync(resolve(process.cwd(), "public/logos/Logo_Bayer.png"))

const s = StyleSheet.create({
  page: {
    paddingTop: 48,
    paddingBottom: 56,
    paddingHorizontal: 54,
    fontFamily: "Times-Roman",
    fontSize: 10.5,
    color: DARK,
    lineHeight: 1.55,
  },
  // Header
  headerRow: {
    flexDirection: "row",
    alignItems: "center",
    marginBottom: 4,
  },
  logo: { width: 28, height: 28, marginRight: 10 },
  headerTitle: { fontSize: 15, fontFamily: "Times-Bold", color: BLACK, letterSpacing: 0.3 },
  headerSub: { fontSize: 8, color: LIGHT_GREY, marginTop: 1, fontFamily: "Times-Roman" },
  headerRule: { height: 0.75, backgroundColor: ACCENT, marginTop: 10, marginBottom: 20 },
  // Sections
  sectionTitle: {
    fontSize: 12,
    fontFamily: "Times-Bold",
    color: BLACK,
    marginBottom: 4,
    marginTop: 18,
    textTransform: "uppercase",
    letterSpacing: 0.8,
  },
  rule: { height: 0.5, backgroundColor: RULE, marginBottom: 10 },
  // Question block
  questionBlock: {
    backgroundColor: TINT,
    borderLeftWidth: 2.5,
    borderLeftColor: ACCENT,
    padding: 10,
    paddingLeft: 12,
    marginBottom: 4,
  },
  questionText: { fontSize: 10.5, lineHeight: 1.6, fontFamily: "Times-Italic" },
  // Key-value fields
  fieldRow: { flexDirection: "row", marginBottom: 3, alignItems: "flex-start" },
  fieldLabel: {
    fontFamily: "Times-Bold",
    fontSize: 9,
    color: GREY,
    width: 110,
    textTransform: "uppercase",
    letterSpacing: 0.4,
  },
  fieldValue: { fontSize: 10.5, flex: 1, fontFamily: "Times-Roman" },
  // Chips
  chipRow: { flexDirection: "row", flexWrap: "wrap", gap: 4, marginTop: 1, marginBottom: 4 },
  chip: {
    backgroundColor: TINT,
    borderWidth: 0.5,
    borderColor: RULE,
    paddingVertical: 2,
    paddingHorizontal: 6,
    fontSize: 8,
    fontFamily: "Times-Bold",
    color: DARK,
    letterSpacing: 0.3,
  },
  // Evidence cards
  evidenceCard: {
    borderBottomWidth: 0.5,
    borderBottomColor: RULE,
    paddingVertical: 7,
    paddingHorizontal: 2,
  },
  evidenceTitle: { fontFamily: "Times-Bold", fontSize: 10.5, color: BLACK },
  evidenceBadge: {
    fontSize: 7,
    fontFamily: "Times-Bold",
    color: LIGHT_GREY,
    textTransform: "uppercase",
    letterSpacing: 0.5,
  },
  evidenceReason: { fontFamily: "Times-Italic", fontSize: 9.5, color: GREY, marginTop: 2 },
  evidencePath: { fontSize: 8, color: LIGHT_GREY, marginTop: 2, fontFamily: "Courier" },
  // Bullet lists
  bulletItem: { flexDirection: "row", marginBottom: 2 },
  bullet: { width: 14, fontSize: 10.5, color: GREY },
  bulletText: { flex: 1, fontSize: 10.5 },
  // Uncertainty
  uncertaintyCard: {
    borderLeftWidth: 1.5,
    borderLeftColor: RULE,
    paddingLeft: 10,
    paddingVertical: 4,
    marginBottom: 5,
  },
  uncertaintyTitle: { fontFamily: "Times-Bold", fontSize: 9.5, color: DARK },
  uncertaintyDetail: { fontSize: 9.5, color: GREY, marginTop: 1, fontFamily: "Times-Roman" },
  // Warnings
  warningBlock: {
    borderTopWidth: 0.5,
    borderTopColor: RULE,
    paddingTop: 8,
    marginTop: 10,
  },
  warningLabel: {
    fontFamily: "Times-Bold",
    fontSize: 9,
    color: GREY,
    textTransform: "uppercase",
    letterSpacing: 0.4,
    marginBottom: 4,
  },
  warningText: { fontSize: 9.5, marginBottom: 2, color: DARK },
  // Footer
  footer: {
    position: "absolute",
    bottom: 24,
    left: 54,
    right: 54,
    borderTopWidth: 0.5,
    borderTopColor: RULE,
    paddingTop: 6,
    flexDirection: "row",
    justifyContent: "space-between",
    fontSize: 7,
    color: LIGHT_GREY,
    fontFamily: "Times-Roman",
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
          <Text style={s.bullet}>{"\u2013"}</Text>
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
          {/* eslint-disable-next-line jsx-a11y/alt-text -- @react-pdf/renderer Image has no alt prop */}
          <Image src={bayerLogoPng} style={s.logo} />
          <View>
            <Text style={s.headerTitle}>{PRODUCT_DISPLAY_NAME}</Text>
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
        <FieldRow
          label="Confidence"
          value={`${result.interpretation.confidenceScore.overall}/100 (${result.interpretation.confidenceScore.level.charAt(0).toUpperCase() + result.interpretation.confidenceScore.level.slice(1)})`}
        />
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

        {/* Confidence Breakdown */}
        <Text style={[s.fieldLabel, { marginTop: 8, marginBottom: 4 }]}>CONFIDENCE BREAKDOWN</Text>
        <FieldRow label="Interpretation" value={`${result.interpretation.confidenceScore.interpretationScore}/100`} />
        <FieldRow label="Relevance" value={`${result.interpretation.confidenceScore.evidenceRelevanceScore}/100`} />
        <FieldRow label="Coverage" value={`${result.interpretation.confidenceScore.evidenceCoverageScore}/100`} />
        {result.interpretation.confidenceScore.reasons.length > 0 && (
          <View style={{ marginTop: 4 }}>
            {result.interpretation.confidenceScore.reasons.map((reason) => (
              <View key={reason} style={s.bulletItem}>
                <Text style={s.bullet}>{"\u2013"}</Text>
                <Text style={[s.bulletText, { fontSize: 9.5, color: GREY }]}>{reason}</Text>
              </View>
            ))}
          </View>
        )}

        {/* Evidence */}
        <SectionHeading>Evidence</SectionHeading>
        {result.evidence.map((hit) => (
          <View key={hit.document.id} style={s.evidenceCard} wrap={false}>
            <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center" }}>
              <Text style={s.evidenceTitle}>{hit.document.title}</Text>
              <Text style={s.evidenceBadge}>{hit.document.sourceType}</Text>
            </View>
            <Text style={s.evidenceReason}>
              {hit.retrievalReason}
              {hit.vectorSimilarity !== null && hit.vectorSimilarity > 0 && ` (${Math.round(hit.vectorSimilarity * 100)}% semantic match)`}
            </Text>
            {hit.document.datasetNames.length > 0 && <ChipRow items={hit.document.datasetNames} />}
            <Text style={s.evidencePath}>{hit.document.path}</Text>
          </View>
        ))}

        {/* Response Plan */}
        <SectionHeading>Response Plan</SectionHeading>
        <Text style={{ fontFamily: "Times-Bold", fontSize: 11, marginBottom: 4, color: BLACK }}>
          {result.responsePlan.objective}
        </Text>
        <Text style={{ marginBottom: 8 }}>{result.responsePlan.recommendedApproach}</Text>

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
            <Text style={s.warningLabel}>Warnings</Text>
            {result.warnings.map((w) => (
              <Text key={w} style={s.warningText}>
                {"\u2013"} {w}
              </Text>
            ))}
          </View>
        )}

        {/* Footer */}
        <View style={s.footer} fixed>
          <Text>{PRODUCT_DISPLAY_NAME} — Internal use only</Text>
          <Text render={({ pageNumber, totalPages }) => `Page ${pageNumber} of ${totalPages}`} />
        </View>
      </Page>
    </Document>
  )
}
