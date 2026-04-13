import type { EvidenceSourceType } from "@/lib/server/copilot/schemas"

export type PdfChunk = {
  id: string
  title: string
  sourceType: EvidenceSourceType
  path: string
  text: string
  sectionTitle: string
  referencedDatasets: string[]
  referencedOutputs: string[]
  keywords: string[]
}

export type PdfFileConfig = {
  path: string
  sourceType: EvidenceSourceType
  label: string
}

/** Map a repo-relative PDF path to evidence metadata (used when ingesting docs/examples/documents/*.pdf). */
export function inferPdfFileConfig(relativePosixPath: string): PdfFileConfig {
  const file = relativePosixPath.split("/").pop() ?? relativePosixPath
  const lower = file.toLowerCase()
  const label = file.replace(/\.pdf$/i, "")
  let sourceType: EvidenceSourceType = "network-file"
  if (lower.includes("statistical") && lower.includes("analysis")) sourceType = "sap-section"
  else if (lower.includes("tlf")) sourceType = "tlf-spec"
  else if (lower.includes("ads") && lower.includes("spec")) sourceType = "ads-spec"
  else if (lower.includes("adrg")) sourceType = "adrg-section"
  else if (lower.includes("fda")) sourceType = "fda-request"
  else if (lower.includes("case") && lower.includes("level")) sourceType = "case-data"
  return { path: relativePosixPath, sourceType, label }
}

export const PDF_FILE_CONFIGS: PdfFileConfig[] = [
  { path: "docs/examples/21651_statistical_analysis_plan_v2.0.pdf", sourceType: "sap-section", label: "SAP" },
  { path: "docs/examples/21651_tlf_specification_v2.0.pdf", sourceType: "tlf-spec", label: "TLF Spec" },
  { path: "docs/examples/bay3427080_ia_main001_ads_specification_v1.0.pdf", sourceType: "ads-spec", label: "ADS Spec" },
  { path: "docs/examples/adrg.pdf", sourceType: "adrg-section", label: "ADRG" },
  { path: "docs/examples/fda_request_fracture_incidences.pdf", sourceType: "fda-request", label: "FDA IR Fracture Incidences" },
  { path: "docs/examples/tlf_spec_for_fda_request_fracture_incidences.pdf", sourceType: "tlf-spec", label: "TLF Spec FDA Fracture" },
  { path: "docs/examples/FDA IR Fracture.pdf", sourceType: "fda-request", label: "FDA IR Fracture" },
  { path: "docs/examples/case_level_data_for_the_subjects_listed_below.pdf", sourceType: "case-data", label: "Case Level Data" },
]

const KNOWN_DATASETS = [
  "ADSL", "ADAE", "ADLB", "ADCM", "ADMH", "ADMK", "ADQS", "ADTTE", "ADVS", "ADEG", "ADEX",
]

const TARGET_CHUNK_WORDS = 600
const MIN_CHUNK_WORDS = 100

function extractReferencedDatasets(text: string): string[] {
  const found: string[] = []
  for (const ds of KNOWN_DATASETS) {
    if (new RegExp(`\\b${ds}\\b`, "i").test(text)) {
      found.push(ds)
    }
  }
  return found
}

function extractReferencedOutputs(text: string): string[] {
  const outputs: string[] = []
  // Match table/figure/listing references like "Table 14.1.2" or "Figure 8.3.5"
  for (const match of text.matchAll(/(?:Table|Figure|Listing)\s+[\d.]+/gi)) {
    outputs.push(match[0])
  }
  return [...new Set(outputs)]
}

function extractKeywords(text: string): string[] {
  const keywords: string[] = []
  const lowerText = text.toLowerCase()

  const domainTerms = [
    "adverse event", "safety", "efficacy", "endpoint", "population",
    "kaplan-meier", "survival", "incidence", "frequency", "baseline",
    "treatment-emergent", "serious", "bone mineral density", "fracture",
    "laboratory", "liver", "vasomotor", "menopause", "elinzanetant",
    "placebo", "randomized", "double-blind", "subgroup",
  ]

  for (const term of domainTerms) {
    if (lowerText.includes(term)) {
      keywords.push(term)
    }
  }

  return keywords
}

/**
 * Split PDF text into chunks by section headings or paragraph breaks.
 * Targets ~500-800 words per chunk.
 */
function chunkText(text: string, label: string): Array<{ sectionTitle: string; text: string }> {
  // Try to split by numbered section headings (e.g., "1.2 Population" or "8.3.5 Lab Results")
  const sectionPattern = /\n(?=\d+(?:\.\d+)*\s+[A-Z])/g
  let sections = text.split(sectionPattern).filter((s) => s.trim().length > 0)

  // If no numbered sections found, split by double newlines (paragraph breaks)
  if (sections.length <= 1) {
    sections = text.split(/\n\s*\n/).filter((s) => s.trim().length > 0)
  }

  const chunks: Array<{ sectionTitle: string; text: string }> = []
  let currentChunk = ""
  let currentTitle = label

  for (const section of sections) {
    const sectionWords = section.split(/\s+/).length
    const currentWords = currentChunk.split(/\s+/).length

    // Extract section title from first line
    const firstLine = section.split("\n")[0]?.trim() ?? ""
    const titleMatch = firstLine.match(/^(\d+(?:\.\d+)*\s+.{3,80})/)

    if (currentWords + sectionWords > TARGET_CHUNK_WORDS && currentWords >= MIN_CHUNK_WORDS) {
      // Flush current chunk
      chunks.push({ sectionTitle: currentTitle, text: currentChunk.trim() })
      currentChunk = section
      currentTitle = titleMatch ? titleMatch[1] : `${label} (continued)`
    } else {
      if (titleMatch && currentChunk.length === 0) {
        currentTitle = titleMatch[1]
      }
      currentChunk += `\n${section}`
    }
  }

  // Flush remaining
  if (currentChunk.trim().length > 0) {
    chunks.push({ sectionTitle: currentTitle, text: currentChunk.trim() })
  }

  // If we got no chunks (very short document), use the whole text
  if (chunks.length === 0 && text.trim().length > 0) {
    chunks.push({ sectionTitle: label, text: text.trim() })
  }

  return chunks
}

function sanitizeId(value: string): string {
  return value.replace(/[^a-z0-9_-]/gi, "_").toLowerCase().slice(0, 60)
}

export async function parsePdfFile(
  _filePath: string,
  buffer: Buffer,
  config: PdfFileConfig,
): Promise<PdfChunk[]> {
  const { PDFParse } = await import("pdf-parse")
  let fullText: string

  try {
    const pdf = new PDFParse({ data: new Uint8Array(buffer) })
    const textResult = await pdf.getText()
    fullText = textResult.text
    await pdf.destroy()
  } catch (error) {
    console.warn(`Failed to parse PDF ${config.path}:`, error instanceof Error ? error.message : error)
    return []
  }

  if (!fullText || fullText.trim().length === 0) {
    console.warn(`PDF ${config.path} produced no text`)
    return []
  }

  const chunks = chunkText(fullText, config.label)

  return chunks.map((chunk, index) => {
    const referencedDatasets = extractReferencedDatasets(chunk.text)
    const referencedOutputs = extractReferencedOutputs(chunk.text)
    const keywords = extractKeywords(chunk.text)

    return {
      id: `pdf:${sanitizeId(config.label)}_${index}`,
      title: `${config.label}: ${chunk.sectionTitle}`,
      sourceType: config.sourceType,
      path: config.path,
      text: chunk.text,
      sectionTitle: chunk.sectionTitle,
      referencedDatasets,
      referencedOutputs,
      keywords: [...new Set([
        ...keywords,
        ...referencedDatasets.map((d) => d.toLowerCase()),
        config.sourceType,
      ])],
    }
  })
}
