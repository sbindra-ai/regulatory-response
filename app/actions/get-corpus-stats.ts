"use server"

import { basename } from "node:path"

import { getKnowledgeBase } from "@/lib/server/copilot/knowledge-base"
import type { EvidencePool } from "@/lib/server/copilot/schemas"

const MAX_DOCUMENT_ROWS = 8_000
const MAX_ANALYSIS_ROWS = 8_000
const MAX_SAS_ROWS = 8_000

export type CorpusDocumentRow = {
  id: string
  path: string
  title: string
  sourceType: string
}

export type CorpusAnalysisDataSetRow = {
  path: string
  datasetName: string
}

export type CorpusSasProgramRow = {
  path: string
  fileName: string
}

export type CorpusStats = {
  evidencePool: EvidencePool
  totalDocuments: number
  generatedAt: string
  embeddingModel: string
  datasetsCount: number
  programsCount: number
  documentsByType: Record<string, number>
  uniqueDatasetNames: string[]
  documentsWithEmbeddings: number
  /** All indexed documents (for Knowledge base “Total documents” list). */
  documentRows: CorpusDocumentRow[]
  /** Transport / define datasets with dataset name + path. */
  analysisDataSetRows: CorpusAnalysisDataSetRow[]
  /** SAS programs: file name + full path (deduped by path). */
  sasProgramRows: CorpusSasProgramRow[]
}

export async function getCorpusStats(evidencePool: EvidencePool = "repository"): Promise<CorpusStats> {
  const { corpus } = getKnowledgeBase(evidencePool)

  const documentsByType: Record<string, number> = {}
  const datasetNames = new Set<string>()
  let documentsWithEmbeddings = 0

  for (const doc of corpus.documents) {
    documentsByType[doc.sourceType] = (documentsByType[doc.sourceType] || 0) + 1
    if (doc.embedding && doc.embedding.length > 0) documentsWithEmbeddings++
    for (const name of doc.datasetNames) datasetNames.add(name)
  }

  const documentRows: CorpusDocumentRow[] = corpus.documents
    .map((doc) => ({
      id: doc.id,
      path: doc.path.replace(/\\/g, "/"),
      title: doc.title,
      sourceType: doc.sourceType,
    }))
    .sort((a, b) => a.path.localeCompare(b.path))
    .slice(0, MAX_DOCUMENT_ROWS)

  const analysisDataSetRows: CorpusAnalysisDataSetRow[] = []
  const sasProgramRows: CorpusSasProgramRow[] = []
  const sasPathsSeen = new Set<string>()

  if (evidencePool === "repository") {
    for (const d of corpus.datasets) {
      const pathLabel = d.leaf
        ? `define.xml · ${d.leaf.replace(/\\/g, "/")}`
        : d.structure?.replace(/\\/g, "/") || "define.xml"
      analysisDataSetRows.push({
        path: pathLabel,
        datasetName: d.name,
      })
    }
    analysisDataSetRows.sort((a, b) => a.datasetName.localeCompare(b.datasetName))

    for (const p of corpus.programs) {
      const pathNorm = p.path.replace(/\\/g, "/")
      if (sasPathsSeen.has(pathNorm)) continue
      sasPathsSeen.add(pathNorm)
      sasProgramRows.push({
        path: pathNorm,
        fileName: basename(p.path),
      })
    }
    sasProgramRows.sort((a, b) => a.path.localeCompare(b.path))
  } else {
    for (const doc of corpus.documents) {
      const p = doc.path.replace(/\\/g, "/")
      if (/\.(sas7bdat|xpt)$/i.test(p)) {
        const base = basename(doc.path)
        const datasetName =
          doc.datasetNames[0] ?? base.replace(/\.[^.]+$/i, "").toUpperCase()
        analysisDataSetRows.push({ path: p, datasetName })
      }
      if (doc.sourceType === "program" || (doc.sourceType === "network-file" && /\.sas$/i.test(p))) {
        if (sasPathsSeen.has(p)) continue
        sasPathsSeen.add(p)
        sasProgramRows.push({
          path: p,
          fileName: basename(doc.path),
        })
      }
    }
    analysisDataSetRows.sort((a, b) => a.path.localeCompare(b.path))
    sasProgramRows.sort((a, b) => a.path.localeCompare(b.path))
  }

  const datasetsCount =
    evidencePool === "repository" ? corpus.datasets.length : analysisDataSetRows.length
  const programsCount = evidencePool === "repository" ? corpus.programs.length : sasProgramRows.length

  return {
    evidencePool,
    totalDocuments: corpus.documents.length,
    generatedAt: corpus.generatedAt,
    embeddingModel: corpus.embeddingModel ?? "unknown",
    datasetsCount,
    programsCount,
    documentsByType,
    uniqueDatasetNames: Array.from(datasetNames).sort(),
    documentsWithEmbeddings,
    documentRows,
    analysisDataSetRows: analysisDataSetRows.slice(0, MAX_ANALYSIS_ROWS),
    sasProgramRows: sasProgramRows.slice(0, MAX_SAS_ROWS),
  }
}
