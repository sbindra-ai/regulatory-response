import { createHash } from "node:crypto"

import type { EvidenceDocument } from "@/lib/server/copilot/schemas"

import { parseDefineXml, type DefineDataset } from "@/lib/server/knowledge/parse-define-xml"
import { parseReadme, type ReadmeBrief } from "@/lib/server/knowledge/parse-readme"
import { parseSasPrograms, type SasProgramRecord, type SasProgramSource } from "@/lib/server/knowledge/parse-sas-programs"
import type { PdfChunk } from "@/lib/server/knowledge/parse-pdf-documents"

export type EvidenceCorpus = {
  generatedAt: string
  embeddingModel: string | null
  embeddingDimensions: number | null
  brief: ReadmeBrief
  datasets: DefineDataset[]
  programs: SasProgramRecord[]
  documents: EvidenceDocument[]
}

export type BuildCorpusInput = {
  defineXml: string
  /** Path stored on dataset metadata documents (matches Define-XML file location in the repo). */
  defineDatasetDocumentPath?: string
  embeddings?: Map<string, number[]>
  embeddingModel?: string | null
  embeddingDimensions?: number | null
  generatedAt?: string
  pdfChunks?: PdfChunk[]
  programSources: SasProgramSource[]
  readmeContent: string
}

function deriveStableGeneratedAt({
  defineXml,
  programSources,
  readmeContent,
}: Omit<BuildCorpusInput, "generatedAt">): string {
  const hash = createHash("sha256")
  const orderedProgramSources = [...programSources].sort((left, right) => left.path.localeCompare(right.path))

  hash.update(readmeContent)
  hash.update(defineXml)

  for (const source of orderedProgramSources) {
    hash.update(source.path)
    hash.update(source.content)
  }

  const digest = hash.digest("hex")
  const baseTimestamp = BigInt(Date.UTC(2024, 0, 1))
  const oneYearInMilliseconds = BigInt(365 * 24 * 60 * 60 * 1000)
  const offset = BigInt(`0x${digest.slice(0, 12)}`) % oneYearInMilliseconds

  return new Date(Number(baseTimestamp + offset)).toISOString()
}

function buildDatasetDocuments(datasets: DefineDataset[]): EvidenceDocument[] {
  return datasets.map((dataset) => ({
    id: `dataset:${dataset.name}`,
    title: `${dataset.name} dataset metadata`,
    sourceType: "dataset",
    path: "docs/examples/define.xml",
    summary: [dataset.label, dataset.structure].filter(Boolean).join(". "),
    keywords: [
      dataset.name.toLowerCase(),
      dataset.label.toLowerCase(),
      ...(dataset.className ? [dataset.className.toLowerCase()] : []),
    ],
    datasetNames: [dataset.name],
    outputFamilies: [],
    sourceText: [
      dataset.label,
      dataset.structure,
      dataset.leaf ?? "",
      dataset.variables.map((variable) => `${variable.name}: ${variable.label}`).join(" | "),
    ]
      .filter(Boolean)
      .join("\n"),
    embedding: null,
  }))
}

function buildStructuredProgramSummary(program: SasProgramRecord): string {
  const parts: string[] = []

  parts.push(`Purpose: ${program.purpose}`)

  if (program.studyNumber || program.compound) {
    const study = [program.studyNumber, program.compound].filter(Boolean).join(" - ")
    parts.push(`Study: ${study}`)
  }

  if (program.datasetsUsed.length > 0) {
    parts.push(`Datasets: ${program.datasetsUsed.join(", ")}`)
  }

  if (program.statisticalMethods.length > 0) {
    parts.push(`Statistical Methods: ${program.statisticalMethods.join(", ")}`)
  }

  if (program.titlesAndFootnotes.length > 0) {
    parts.push(`Analysis: ${program.titlesAndFootnotes.join(". ")}`)
  }

  if (program.filterConditions.length > 0) {
    parts.push(`Populations: ${program.filterConditions.join(", ")}`)
  }

  if (program.parameters.length > 0) {
    parts.push(`Parameters: ${program.parameters.join(", ")}`)
  }

  if (program.analysisVariables.length > 0) {
    parts.push(`Variables: ${program.analysisVariables.join(", ")}`)
  }

  if (program.visitTimepoints.length > 0) {
    parts.push(`Timepoints: ${program.visitTimepoints.join(", ")}`)
  }

  return parts.join("\n")
}

function buildProgramDocuments(programs: SasProgramRecord[]): EvidenceDocument[] {
  return programs.map((program) => ({
    id: `program:${program.name}`,
    title: program.title,
    sourceType: "program",
    path: program.path,
    summary: buildStructuredProgramSummary(program),
    keywords: program.keywords,
    datasetNames: program.datasetsUsed,
    outputFamilies: program.outputFamilies,
    sourceText: program.sourceText,
    embedding: null,
  }))
}

function sanitizePdfText(text: string): string {
  // Replace non-ASCII characters that can trip up Vite's JSON-to-JS conversion
  return text.replace(/[^\x20-\x7E\n\r\t]/g, " ")
}

function buildPdfDocuments(chunks: PdfChunk[]): EvidenceDocument[] {
  return chunks.map((chunk) => {
    const cleanText = sanitizePdfText(chunk.text)
    const summary = cleanText.slice(0, 1500)
    return {
      id: chunk.id,
      title: sanitizePdfText(chunk.title),
      sourceType: chunk.sourceType,
      path: chunk.path,
      summary,
      keywords: chunk.keywords,
      datasetNames: chunk.referencedDatasets,
      outputFamilies: chunk.referencedOutputs,
      sourceText: summary,
      embedding: null,
    }
  })
}

function buildBriefDocument(brief: ReadmeBrief): EvidenceDocument {
  return {
    id: brief.id,
    title: brief.title,
    sourceType: "brief",
    path: brief.path,
    summary: brief.summary,
    keywords: brief.keywords,
    datasetNames: [],
    outputFamilies: [],
    sourceText: brief.sourceText,
    embedding: null,
  }
}

export function buildCorpus({
  defineXml,
  defineDatasetDocumentPath = "docs/examples/define.xml",
  embeddings,
  embeddingModel = null,
  embeddingDimensions = null,
  generatedAt,
  pdfChunks = [],
  programSources,
  readmeContent,
}: BuildCorpusInput): EvidenceCorpus {
  const orderedProgramSources = [...programSources].sort((left, right) => left.path.localeCompare(right.path))
  const brief = parseReadme(readmeContent)
  const datasets = parseDefineXml(defineXml)
  const programs = parseSasPrograms(orderedProgramSources)
  const documents = [
    buildBriefDocument(brief),
    ...buildDatasetDocuments(datasets, defineDatasetDocumentPath),
    ...buildProgramDocuments(programs),
    ...buildPdfDocuments(pdfChunks),
  ]

  if (embeddings) {
    for (const doc of documents) {
      doc.embedding = embeddings.get(doc.id) ?? null
    }
  }

  return {
    generatedAt:
      generatedAt ??
      deriveStableGeneratedAt({
        defineXml,
        programSources: orderedProgramSources,
        readmeContent,
      }),
    embeddingModel,
    embeddingDimensions,
    brief,
    datasets,
    programs,
    documents,
  }
}
